/// App configuration constants
/// 
/// These settings control various aspects of the app behavior,
/// particularly useful for development and testing.
library;

/// Dev bypass for paywall
/// Set to true to bypass all premium checks during development
/// Set to false in production to enforce actual premium subscriptions
const bool kDisablePaywallForDev = true;

/// App version
const String kAppVersion = '1.0.0';

/// Subscription pricing (static for now)
const String kMonthlyPrice = '£10';
const String kYearlyPrice = '£100';

/// Google Play Billing product IDs for future integration.
/// Replace these values with the actual IDs from the Play Console
/// before production release.
const String kMonthlySubscriptionId = 'premium_monthly';
const String kYearlySubscriptionId = 'premium_yearly';
