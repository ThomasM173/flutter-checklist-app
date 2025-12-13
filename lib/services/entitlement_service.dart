import 'package:clearedtogo/services/auth_service.dart';
import 'package:clearedtogo/config/config.dart';

/// Service to manage user entitlements and premium features
/// 
/// This service determines whether a user has access to premium features.
/// In development, it uses kDisablePaywallForDev to bypass checks.
/// In production, it will integrate with Google Play Billing.
class EntitlementService {
  final AuthService _authService;

  EntitlementService(this._authService);

  /// Check if the current user has premium access
  /// 
  /// Returns true if:
  /// - Dev bypass is enabled (kDisablePaywallForDev = true), OR
  /// - User is logged in and has isPremium = true
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
  /// TODO: integrate Google Play Billing here
  /// - Verify purchase with Google Play
  /// - Update backend with purchase token
  /// - Handle subscription renewal/cancellation
  Future<void> grantPremium() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      throw Exception('No user logged in');
    }

    // Update user's premium status
    await _authService.updatePremiumStatus(true);

    // TODO: integrate Google Play Billing here
    // Example flow:
    // 1. final BillingClient billingClient = BillingClient(...);
    // 2. await billingClient.launchBillingFlow(sku: kMonthlySubscriptionId);
    // 3. await billingClient.acknowledgePurchase(purchaseToken);
    // 4. Send purchase token to backend for verification
    // 5. Backend confirms with Google and updates user premium status
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
