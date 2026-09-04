import 'package:clearedtogo/services/supabase_auth_service.dart';
import 'package:clearedtogo/config/config.dart';

/// Service to manage user entitlements and premium features
///
/// This service determines whether a user has access to premium features.
/// In development, it uses kDisablePaywallForDev to bypass checks. In
/// production, `Profile.isPremium` is the real result of the has_premium_access()
/// Supabase function — true for an active trial, a comped flight school, or
/// (once the kIapEnabled launch flag flips on) a live StoreKit subscription.
class EntitlementService {
  final SupabaseAuthService _authService;

  EntitlementService(this._authService);

  /// Check if the current user has premium access
  ///
  /// Returns true if:
  /// - Dev bypass is enabled (kDisablePaywallForDev = true), OR
  /// - The user's real entitlement (trial / comped school / paid
  ///   subscription — see has_premium_access()) is true
  bool get userHasPremium {
    // Dev bypass - allows testing premium features without payment
    if (kDisablePaywallForDev) {
      return true;
    }

    // Production check - verify user's premium status
    return _authService.currentUser?.isPremium ?? false;
  }

  /// Grant premium access to the current user
  ///
  /// For now, this just updates the local user account.
  /// Billing integration is pending.
  /// In production, this would verify purchases and record subscription state.
  Future<void> grantPremium() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      throw Exception('No user logged in');
    }

    await _authService.updatePremiumStatus(true);

    // Billing integration is pending.
    // When available, verify purchases with Google Play and record subscription state.
  }

  /// Revoke premium access (for testing or cancellation)
  Future<void> revokePremium() async {
    await _authService.updatePremiumStatus(false);
  }

  /// Check if a specific feature requires premium
  ///
  /// This allows fine-grained control over which features are premium.
  /// For now, all premium features use the same check.
  bool hasAccessToFeature(String featureId) {
    return userHasPremium;
  }

  /// Get a user-friendly message about premium status
  String get premiumStatusMessage {
    if (kDisablePaywallForDev) {
      return 'Premium access enabled (Dev Mode)';
    }
    if (userHasPremium) {
      return 'Premium Member';
    }
    return 'Free Account';
  }
}
