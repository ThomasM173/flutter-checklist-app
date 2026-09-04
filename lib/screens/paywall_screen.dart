import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:clearedtogo/config/config.dart';
import 'package:clearedtogo/services/iap_service.dart';
import 'package:clearedtogo/services/supabase_auth_service.dart';
import 'package:clearedtogo/services/entitlement_service.dart';
import 'package:clearedtogo/screens/privacy_policy.dart';
import 'package:clearedtogo/screens/auth/login_screen.dart';

/// Custom paywall — manually presents subscription title, length and price
/// plus functional Privacy Policy and Terms of Use (EULA) links, per App
/// Store Review Guideline 3.1.2(c). Purchases go through StoreKit 2
/// ([IapService]); a verified purchase writes premium entitlement to the
/// user's Supabase profile.
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  final _auth = SupabaseAuthService();
  final _iap = IapService();
  late final _entitlement = EntitlementService(_auth);

  StreamSubscription<IapOutcome>? _iapSub;
  bool _loading = true;
  bool _busy = false;
  String? _pendingProductId;
  String? _storeMessage;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _auth.init();
    if (kIapEnabled) {
      await _iap.init();
      _iapSub = _iap.outcomes.listen(_handleOutcome);
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _iapSub?.cancel();
    super.dispose();
  }

  void _handleOutcome(IapOutcome o) {
    if (!mounted) return;
    switch (o.result) {
      case IapResult.pending:
        setState(() {
          _busy = true;
          _storeMessage = 'Completing purchase…';
        });
        return;
      case IapResult.purchased:
      case IapResult.restored:
        setState(() {
          _busy = false;
          _pendingProductId = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(o.result == IapResult.restored
                ? 'Purchases restored — Premium is active.'
                : 'Premium unlocked. Thank you!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
        return;
      case IapResult.cancelled:
        setState(() {
          _busy = false;
          _pendingProductId = null;
          _storeMessage = null;
        });
        return;
      case IapResult.error:
        setState(() {
          _busy = false;
          _pendingProductId = null;
          _storeMessage = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(o.message ?? 'Something went wrong with the store.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
    }
  }

  Future<void> _buy(String productId) async {
    if (_busy) return;

    // Must be signed in — entitlement is stored on the Supabase profile.
    if (!_auth.isSignedIn) {
      final navigator = Navigator.of(context);
      final messenger = ScaffoldMessenger.of(context);
      final signedIn = await navigator.push<Object?>(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      await _auth.init();
      if (!_auth.isSignedIn && signedIn != true) {
        if (mounted) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Please sign in first so we can attach your '
                  'subscription to your account.'),
            ),
          );
        }
        return;
      }
    }

    // Dev bypass: no store round-trip, just grant + close.
    if (kDisablePaywallForDev) {
      setState(() => _busy = true);
      try {
        await _entitlement.grantPremium();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Premium granted (Dev Mode — no charge).'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        }
      } finally {
        if (mounted) setState(() => _busy = false);
      }
      return;
    }

    if (!_iap.isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('The App Store is not available right now.')),
      );
      return;
    }

    setState(() {
      _busy = true;
      _pendingProductId = productId;
      _storeMessage = 'Opening App Store…';
    });
    final started = await _iap.buy(productId);
    if (!started && mounted) {
      setState(() {
        _busy = false;
        _pendingProductId = null;
        _storeMessage = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This subscription isn\'t available yet. (The product must be '
            'created and approved in App Store Connect.)',
          ),
        ),
      );
    }
  }

  Future<void> _restore() async {
    if (_busy) return;
    if (kDisablePaywallForDev) {
      await _entitlement.grantPremium();
      if (mounted) Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _busy = true;
      _storeMessage = 'Restoring purchases…';
    });
    await _iap.restore();
    // Result (or "nothing to restore") comes back on the outcomes stream.
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && _busy) {
        setState(() {
          _busy = false;
          _storeMessage = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No previous purchases to restore.')),
        );
      }
    });
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open $url')),
        );
      }
    }
  }

  // --- price / length helpers -------------------------------------------

  String _priceFor(String productId, String fallback) =>
      _iap.productById(productId)?.price ?? fallback;

  String _titleFor(String productId, String fallback) {
    final t = _iap.productById(productId)?.title ?? '';
    final cleaned = t.replaceAll(RegExp(r'\s*\([^)]*\)\s*$'), '').trim();
    return cleaned.isEmpty ? fallback : cleaned;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('ClearedToGo Premium',
            style: TextStyle(color: Colors.black)),
        iconTheme: const IconThemeData(color: Colors.black),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFADD8E6), Color(0xFF87CEEB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 4,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: kIapEnabled ? _buildStoreBody() : _buildLaunchFreeBody(),
            ),
    );
  }

  Widget _buildLaunchFreeBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.workspace_premium,
                size: 52, color: Colors.white),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Unlock ClearedToGo Premium',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        const SizedBox(height: 8),
        Text(
          'Weather-integrated checklists, PAVE history, PDF records '
          'saved to your account and shared with your flight school.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.green),
          ),
          child: Column(
            children: [
              const Icon(Icons.celebration, color: Colors.green, size: 32),
              const SizedBox(height: 8),
              const Text(
                'Premium features are free during our launch period',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
              ),
              const SizedBox(height: 4),
              Text(
                'No purchase needed — just sign in and everything is unlocked.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () async {
            // Re-resolve real entitlement (trial/comped/paid) rather than
            // assuming true, so a genuinely expired account isn't waved
            // through the paywall it's still meant to see.
            final profile = await _auth.refreshProfile();
            if (mounted) Navigator.of(context).pop(profile?.isPremium ?? false);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF87CEEB),
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Got it',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
              ),
              child: const Text('Privacy Policy'),
            ),
            TextButton(
              onPressed: () => _openUrl(kTermsOfUseUrl),
              child: const Text('Terms of Use (EULA)'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStoreBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.workspace_premium,
                size: 52, color: Colors.white),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Unlock ClearedToGo Premium',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        const SizedBox(height: 8),
        Text(
          'Weather-integrated checklists, PAVE history, PDF records '
          'saved to your account and shared with your flight school.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
        ),
        const SizedBox(height: 24),

        // --- Subscription options (title / length / price) ---
        _PlanCard(
          title: _titleFor(kYearlySubscriptionId, 'Premium — Yearly'),
          length: kIapProductLength[kYearlySubscriptionId] ?? '1 year',
          price: _priceFor(kYearlySubscriptionId, kYearlyPrice),
          highlighted: true,
          badge: 'BEST VALUE',
          busy: _busy && _pendingProductId == kYearlySubscriptionId,
          onTap: () => _buy(kYearlySubscriptionId),
        ),
        const SizedBox(height: 12),
        _PlanCard(
          title: _titleFor(kMonthlySubscriptionId, 'Premium — Monthly'),
          length: kIapProductLength[kMonthlySubscriptionId] ?? '1 month',
          price: _priceFor(kMonthlySubscriptionId, kMonthlyPrice),
          busy: _busy && _pendingProductId == kMonthlySubscriptionId,
          onTap: () => _buy(kMonthlySubscriptionId),
        ),

        if (_storeMessage != null) ...[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 8),
              Text(_storeMessage!, style: TextStyle(color: Colors.grey[700])),
            ],
          ),
        ],

        const SizedBox(height: 20),
        TextButton(
          onPressed: _busy ? null : _restore,
          child: const Text('Restore Purchases'),
        ),

        const SizedBox(height: 8),
        // --- Guideline 3.1.2(c) disclosure ---
        Text(
          'Payment is charged to your Apple Account at confirmation. '
          'The subscription renews automatically for the same period '
          'and price unless cancelled at least 24 hours before the '
          'end of the current period. Manage or cancel any time in '
          'your Apple Account settings.',
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const PrivacyPolicyScreen(),
                ),
              ),
              child: const Text('Privacy Policy'),
            ),
            TextButton(
              onPressed: () => _openUrl(kTermsOfUseUrl),
              child: const Text('Terms of Use (EULA)'),
            ),
          ],
        ),

        if (kDisablePaywallForDev)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.amber[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber),
            ),
            child: Text(
              'Dev Mode: tapping a plan grants Premium immediately, '
              'with no App Store charge.',
              style: TextStyle(fontSize: 11, color: Colors.amber[900]),
            ),
          ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String title;
  final String length;
  final String price;
  final bool highlighted;
  final String? badge;
  final bool busy;
  final VoidCallback onTap;

  const _PlanCard({
    required this.title,
    required this.length,
    required this.price,
    required this.onTap,
    this.highlighted = false,
    this.badge,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: busy ? null : onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: highlighted ? const Color(0xFF87CEEB) : Colors.grey.shade300,
            width: highlighted ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.black),
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF87CEEB),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(badge!,
                              style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text('Auto-renewing subscription · $length',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
            const SizedBox(width: 12),
            busy
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text(price,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black)),
          ],
        ),
      ),
    );
  }
}
