import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';

import '../config/config.dart';
import 'supabase_auth_service.dart';

/// Outcome of a purchase / restore attempt, surfaced to the paywall UI.
enum IapResult { purchased, restored, pending, cancelled, error }

class IapOutcome {
  final IapResult result;
  final String? productId;
  final String? message;
  const IapOutcome(this.result, {this.productId, this.message});
}

/// StoreKit 2 in-app purchase flow with Supabase-backed entitlement.
///
/// On a verified purchase/restore this writes
/// `profiles.subscription_status = 'premium'` (+ product id + expiry) via an
/// authenticated Supabase call. RLS restricts profile updates to the caller's
/// own row, so this is safe client-side FOR NOW.
///
/// LIMITATION (client-side entitlement only): renewals, lapses, refunds and
/// cancellations are not tracked. Production needs App Store Server
/// Notifications V2 -> an Edge Function that updates `profiles`. See
/// docs/supabase_migration.md.
class IapService {
  IapService._();
  static final IapService instance = IapService._();
  factory IapService() => instance;

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  bool _available = false;
  bool get isAvailable => _available;

  List<ProductDetails> _products = const [];
  List<ProductDetails> get products => _products;

  /// Emits every processed purchase update so the paywall can react.
  final _outcomes = StreamController<IapOutcome>.broadcast();
  Stream<IapOutcome> get outcomes => _outcomes.stream;

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // Opt into StoreKit 2 on iOS so verificationData carries a signed JWS
    // transaction rather than a legacy receipt blob.
    if (!kIsWeb && Platform.isIOS) {
      try {
        await InAppPurchaseStoreKitPlatform.enableStoreKit2();
      } catch (e) {
        debugPrint('IapService: enableStoreKit2 failed (continuing): $e');
      }
    }

    _available = await _iap.isAvailable();
    _sub = _iap.purchaseStream.listen(
      _onPurchaseUpdates,
      onError: (Object e) => _outcomes.add(
        IapOutcome(IapResult.error, message: e.toString()),
      ),
    );

    if (_available) {
      await loadProducts();
    }
  }

  Future<void> loadProducts() async {
    final resp = await _iap.queryProductDetails(kIapProductIds);
    if (resp.error != null) {
      debugPrint('IapService: queryProductDetails error: ${resp.error}');
    }
    if (resp.notFoundIDs.isNotEmpty) {
      debugPrint(
        'IapService: product IDs not found in store: ${resp.notFoundIDs} '
        '(expected until the real products exist in App Store Connect).',
      );
    }
    _products = resp.productDetails;
  }

  ProductDetails? productById(String id) {
    for (final p in _products) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Starts the native purchase sheet. Result arrives asynchronously on
  /// [outcomes]. Returns false if the store is unavailable / product missing.
  Future<bool> buy(String productId) async {
    if (!_available) return false;
    final product = productById(productId);
    if (product == null) return false;
    final param = PurchaseParam(productDetails: product);
    // Auto-renewable subscriptions go through buyNonConsumable.
    return _iap.buyNonConsumable(purchaseParam: param);
  }

  Future<void> restore() => _iap.restorePurchases();

  Future<void> _onPurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      switch (p.status) {
        case PurchaseStatus.pending:
          _outcomes.add(IapOutcome(IapResult.pending, productId: p.productID));
          break;

        case PurchaseStatus.canceled:
          if (p.pendingCompletePurchase) await _iap.completePurchase(p);
          _outcomes.add(IapOutcome(IapResult.cancelled, productId: p.productID));
          break;

        case PurchaseStatus.error:
          if (p.pendingCompletePurchase) await _iap.completePurchase(p);
          _outcomes.add(IapOutcome(
            IapResult.error,
            productId: p.productID,
            message: p.error?.message ?? 'Purchase failed',
          ));
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          final verification = _verify(p);
          if (verification.ok) {
            try {
              await SupabaseAuthService.instance.setSubscription(
                premium: true,
                productId: p.productID,
                expiresAt: verification.expiresAt,
              );
              _outcomes.add(IapOutcome(
                p.status == PurchaseStatus.restored
                    ? IapResult.restored
                    : IapResult.purchased,
                productId: p.productID,
              ));
            } catch (e) {
              _outcomes.add(IapOutcome(
                IapResult.error,
                productId: p.productID,
                message: 'Entitlement save failed: $e',
              ));
            }
          } else {
            _outcomes.add(IapOutcome(
              IapResult.error,
              productId: p.productID,
              message: 'Could not verify purchase: ${verification.reason}',
            ));
          }
          if (p.pendingCompletePurchase) await _iap.completePurchase(p);
          break;
      }
    }
  }

  // --- StoreKit 2 transaction verification (client-side, best-effort) -----
  //
  // verificationData.serverVerificationData is the StoreKit 2 signed JWS
  // (`header.payload.signature`, base64url). We decode the payload and sanity
  // check it: right product, not revoked, and read the expiry. We do NOT
  // cryptographically verify the JWS signature here — that needs Apple's root
  // certs / a server (the documented follow-up).
  _Verification _verify(PurchaseDetails p) {
    final raw = p.verificationData.serverVerificationData;
    if (raw.isEmpty) {
      return const _Verification(false, reason: 'no verification data');
    }

    // Legacy StoreKit 1 receipt (not a 3-part JWS): accept but no expiry.
    final parts = raw.split('.');
    if (parts.length != 3) {
      return _Verification(
        kIapProductIds.contains(p.productID),
        reason: 'non-JWS receipt',
      );
    }

    try {
      final payload = json.decode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      ) as Map<String, dynamic>;

      final productOk = payload['productId'] == p.productID &&
          kIapProductIds.contains(p.productID);
      final notRevoked = payload['revocationDate'] == null &&
          payload['revocationReason'] == null;

      DateTime? expiresAt;
      final expMs = payload['expiresDate'];
      if (expMs is num) {
        expiresAt = DateTime.fromMillisecondsSinceEpoch(expMs.toInt(),
            isUtc: true);
      }

      if (!productOk) {
        return const _Verification(false, reason: 'product mismatch');
      }
      if (!notRevoked) {
        return const _Verification(false, reason: 'transaction revoked');
      }
      return _Verification(true, expiresAt: expiresAt);
    } catch (e) {
      return _Verification(false, reason: 'payload parse failed: $e');
    }
  }

  void dispose() {
    _sub?.cancel();
    _outcomes.close();
  }
}

class _Verification {
  final bool ok;
  final String? reason;
  final DateTime? expiresAt;
  const _Verification(this.ok, {this.reason, this.expiresAt});
}
