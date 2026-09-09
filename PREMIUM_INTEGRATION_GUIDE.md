# Premium Feature Integration Guide

This guide shows how to integrate the paywall system into your features.

> Rewritten 10 Sept 2026 to match the current Supabase-backed entitlement
> system. The previous version of this doc predated the AWS Amplify ->
> Supabase migration and described a SharedPreferences-based `AuthService`
> that no longer exists — if you're reading an old copy, everything below
> supersedes it.

## Configuration

Two separate flags in `lib/config/config.dart` control premium access — they
answer different questions, and both matter:

```dart
/// Dev-only bypass. Grants premium locally without touching Supabase at all.
const bool kDisablePaywallForDev = true;

/// Launch flag. Controls whether the real StoreKit purchase flow is reachable.
const bool kIapEnabled = false;
```

- **`kDisablePaywallForDev`** — local developer convenience. When `true`,
  `EntitlementService.userHasPremium` always returns `true`, no Supabase call
  involved. Set `false` to test against your real entitlement state.
- **`kIapEnabled`** — the production launch flag. It does **not** control dev
  access; it controls whether `PaywallScreen` and `PremiumPricingScreen` show
  real purchase buttons. Right now it's `false`: those screens instead show a
  "Premium features are free during our launch period" message, because
  entitlement is currently granted via a free trial (and comped flight
  schools) rather than payment. Flipping it to `true` re-enables the already-
  built StoreKit purchase flow with no other code changes required — see
  Architecture below for why.

Neither flag is what actually decides if a given user has premium — that's
always resolved server-side. See Architecture.

## Usage Examples

### 1. Wrapping an Entire Screen

```dart
import 'package:clearedtogo/widgets/premium_feature_wrapper.dart';

class AdvancedChecklistScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PremiumFeatureWrapper(
      featureName: 'Advanced Checklists',
      description: 'Access unlimited aircraft checklists with real-time weather integration',
      child: Scaffold(
        appBar: AppBar(title: Text('Advanced Checklists')),
        body: YourActualContent(),
      ),
    );
  }
}
```

> **Note:** `PremiumFeatureWrapper` is fully implemented and functional, but
> as of this rewrite it isn't actually used by any screen in the app yet
> (checked: no `PremiumFeatureWrapper(` call sites outside its own definition
> file). It's ready to wrap a real feature whenever one needs gating.

### 2. Conditional Feature within a Screen

```dart
import 'package:clearedtogo/services/supabase_auth_service.dart';
import 'package:clearedtogo/services/entitlement_service.dart';
import 'package:clearedtogo/widgets/premium_feature_wrapper.dart';

class MyScreen extends StatefulWidget {
  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  final _authService = SupabaseAuthService();
  late final _entitlementService = EntitlementService(_authService);

  @override
  void initState() {
    super.initState();
    _authService.init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Free content available to everyone
          Text('Basic Features'),
          BasicFeatureWidget(),

          // Premium content
          if (_entitlementService.userHasPremium)
            PremiumFeatureWidget()
          else
            InlinePremiumBadge(),
        ],
      ),
    );
  }
}
```

### 3. Check Access Before Navigation

```dart
import 'package:clearedtogo/widgets/premium_feature_wrapper.dart';

onTap: () async {
  final hasAccess = await checkPremiumAccess(context);
  if (hasAccess) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PremiumFeatureScreen(),
      ),
    );
  }
  // If no access, the paywall is shown automatically and this becomes true
  // once the user closes it having gained access (trial/comped/purchase).
},
```

### 4. Inline Premium Badge

```dart
import 'package:clearedtogo/widgets/premium_feature_wrapper.dart';

ListTile(
  title: Text('Advanced Analytics'),
  trailing: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      InlinePremiumBadge(),
      Icon(Icons.chevron_right),
    ],
  ),
  onTap: () async {
    await checkPremiumAccess(context);
  },
)
```

## Examples in Current App

These are illustrative — none of this is live code today, just showing how
you'd apply the pattern above to an existing screen if you wanted to gate it.

### Example 1: PDF Export (Already Free, Could Be Premium)

If you wanted to make PDF generation a premium feature:

```dart
// In cessna_152_checklist.dart

ElevatedButton(
  onPressed: () async {
    // Check premium access
    final hasAccess = await checkPremiumAccess(context);
    if (hasAccess) {
      await generatePDF();
    }
  },
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text('Generate PDF'),
      if (!_entitlementService.userHasPremium)
        Padding(
          padding: EdgeInsets.only(left: 8),
          child: InlinePremiumBadge(),
        ),
    ],
  ),
)
```

### Example 2: PAVE Assessment (Could Be Premium)

```dart
// In preflight_ground_systems_hub.dart

_buildSystemCard(
  context: context,
  icon: Icons.assessment,
  title: 'PAVE Assessment',
  description: 'Risk assessment tool',
  isPremium: true,  // Add this flag
  onTap: () async {
    final hasAccess = await checkPremiumAccess(context);
    if (hasAccess) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PAVEAssessmentScreen(),
        ),
      );
    }
  },
)
```

### Example 3: Weather Integration (Could Be Premium)

```dart
// Wrap weather button with premium check

if (_entitlementService.userHasPremium) {
  ElevatedButton(
    onPressed: _fetchWeather,
    child: Text('Fetch Weather Data'),
  )
} else {
  Column(
    children: [
      ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PaywallScreen()),
          );
        },
        child: Row(
          children: [
            Text('Fetch Weather Data'),
            SizedBox(width: 8),
            InlinePremiumBadge(),
          ],
        ),
      ),
    ],
  )
}
```

## Testing

### Local development (`kDisablePaywallForDev = true`, the default)
- Every user automatically has premium access — `EntitlementService.userHasPremium`
  short-circuits to `true` before any Supabase call.
- `PaywallScreen` is still reachable via the menu; tapping a plan grants
  premium immediately with no store round-trip (see the amber "Dev Mode"
  banner it shows in this state).

### Testing real entitlement (`kDisablePaywallForDev = false`)
1. Create a new account via signup — it gets a 90-day free trial
   automatically (`profiles.trial_ends_at`), so it will show as premium
   immediately. This is expected, not a bug.
2. To test the *no-access* path, either wait out the trial or (for manual
   testing) set `trial_ends_at` to a past timestamp directly on that row via
   the Supabase dashboard — there's no in-app control for this, by design.
3. With `kIapEnabled = false` (current default): premium/paywall screens show
   the "free during launch" message, no purchase attempted.
4. With `kIapEnabled = true`: tapping upgrade opens the real StoreKit
   purchase sheet (requires the real product IDs to exist and be approved in
   App Store Connect — see Architecture).

## Architecture

- **`has_premium_access(p_user_id)`** (Supabase Postgres function, see
  `supabase/migrations/20260904100000_entitlement.sql`) — the single source
  of truth for entitlement. Returns `true` if ANY of: the user's free trial
  is still active, their flight school is comped, or they have a live paid
  subscription (`subscription_status = 'premium'` and
  `subscription_expires_at` in the future). All three paths resolve through
  this one function — there's no separate code path for paying users.
- **`SupabaseAuthService`** — replaces the old `AuthService`. Calls
  `has_premium_access()` via RPC every time the user's profile is (re)loaded
  and caches the result as `Profile.isPremium`. This is a real, live
  entitlement value, not a locally-stored flag — despite `Profile` also
  carrying the raw `subscriptionStatus` field for display purposes, nothing
  should compare that string directly; always read `.isPremium`.
- **`EntitlementService`** — thin wrapper: applies the `kDisablePaywallForDev`
  bypass, otherwise reads `Profile.isPremium`. `grantPremium()` /
  `revokePremium()` write directly to `profiles.subscription_status` (dev/
  testing convenience — the real path is `IapService` below).
- **`IapService`** — StoreKit 2 purchase flow (`in_app_purchase` +
  `in_app_purchase_storekit`), fully built and functional, currently dormant
  behind `kIapEnabled`. On a verified purchase it calls
  `SupabaseAuthService.setSubscription(...)`, which writes
  `subscription_status`/`subscription_expires_at` — the exact columns
  `has_premium_access()` already reads for path (c). Turning on `kIapEnabled`
  needs no code changes, only real product IDs approved in App Store Connect
  (`kMonthlySubscriptionId`/`kYearlySubscriptionId` in `config.dart` are
  still `TODO_REPLACE_...` placeholders).
  - **Android / Google Play Billing: not implemented.** The `in_app_purchase`
    plugin is nominally cross-platform, but `IapService._verify()` decodes
    Apple's StoreKit 2 JWS transaction format specifically — Google Play's
    receipt format is different and untested here. There's no Play
    Console product configuration, no Android-specific verification path,
    and nothing in this codebase has been run against Play Billing. Treat
    this as unbuilt, not "coming soon" — it would need its own verification
    branch in `_verify()` before it could work, not just a config flip.
  - Documented limitation either way: purchase verification is client-side
    only (no cryptographic signature check, no server-side renewal/refund
    tracking). Production hardening needs App Store Server Notifications V2
    -> an Edge Function that updates `profiles` — see `docs/supabase_migration.md`.
- **`PaywallScreen`** — full-screen upgrade UI. Branches on `kIapEnabled`:
  shows the real StoreKit plan cards when `true`, or a "free during launch"
  card when `false` (see `lib/screens/paywall_screen.dart`).
- **`PremiumPricingScreen`** — a second, separate premium-marketing screen
  reachable from the app drawer. Not StoreKit-integrated directly; when
  `kIapEnabled` is `true` its upgrade button navigates to the real
  `PaywallScreen` instead. Two screens exist for historical reasons — this
  doc isn't taking a position on consolidating them, just describing what's
  there.
- **`PremiumFeatureWrapper` / `InlinePremiumBadge` / `checkPremiumAccess()`**
  (`lib/widgets/premium_feature_wrapper.dart`) — reusable gating widgets, all
  reading `EntitlementService.userHasPremium`. Currently unused by any real
  feature (see the note under Usage Example 1).
- **`config.dart`** — `kDisablePaywallForDev` (dev bypass) and `kIapEnabled`
  (launch flag), plus the StoreKit product ID / pricing constants.

All premium state lives in Supabase (`profiles.trial_ends_at`,
`profiles.subscription_status`/`subscription_expires_at`,
`flight_schools.plan_type`), resolved server-side by `has_premium_access()`
on every profile load. Nothing is stored in `SharedPreferences` — if you find
code that says otherwise, it predates this rewrite and is wrong.
