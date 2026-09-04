/// App configuration constants.
library;

/// Dev bypass for the paywall.
/// true  -> all premium checks pass without a purchase (local testing).
/// false -> real StoreKit entitlement is enforced.
const bool kDisablePaywallForDev = true;

/// Launch feature flag. Premium access always flows through
/// has_premium_access() (active trial, comped flight schools, and — once
/// this flips true — real paid subscribers, all resolved the same way).
/// false -> paywall/premium screens show a "free during launch" message
///          instead of a purchase button; the StoreKit code below is
///          fully intact but unreachable.
/// true  -> the existing StoreKit purchase flow runs for real and, on a
///          verified purchase, writes subscription_status/
///          subscription_expires_at, which has_premium_access() already
///          knows how to read. No other code changes needed.
const bool kIapEnabled = false;

/// App version (display only).
const String kAppVersion = '1.0.0';

/// Fallback subscription pricing shown before StoreKit `ProductDetails` load
/// (StoreKit is the source of truth for the real, localised price).
const String kMonthlyPrice = '£10';
const String kYearlyPrice = '£100';

// ===========================================================================
// StoreKit / In-App Purchase
// ===========================================================================

/// TODO(IAP): replace with the REAL product IDs created in App Store Connect.
/// These placeholders will NOT resolve against the store — querying them
/// returns "not found" until the real auto-renewable subscription products
/// exist and are in a purchasable state.
const String kMonthlySubscriptionId = 'TODO_REPLACE_clearedtogo_premium_monthly';
const String kYearlySubscriptionId = 'TODO_REPLACE_clearedtogo_premium_yearly';

/// All subscription product IDs the paywall queries.
const Set<String> kIapProductIds = {
  kMonthlySubscriptionId,
  kYearlySubscriptionId,
};

/// Human-readable subscription length per product, for the Guideline
/// 3.1.2(c) disclosure block.
const Map<String, String> kIapProductLength = {
  kMonthlySubscriptionId: '1 month',
  kYearlySubscriptionId: '1 year',
};

/// Functional legal links required on the paywall by Guideline 3.1.2(c).
/// TODO: point kTermsOfUseUrl at your own hosted EULA if you don't want to
/// use Apple's standard licence.
const String kPrivacyPolicyUrl =
    'https://clearedtogo.app/privacy'; // TODO: real URL
const String kTermsOfUseUrl =
    'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';
