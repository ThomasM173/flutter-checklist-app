# Premium Feature Integration Guide

This guide shows how to integrate the paywall system into your features.

## Configuration

The paywall system is controlled by the `kDisablePaywallForDev` flag in `lib/config/config.dart`:

```dart
const bool kDisablePaywallForDev = true;  // Dev bypass enabled
```

- Set to `true` for development - all users get premium access automatically
- Set to `false` for production - only users with `isPremium = true` get access

## Usage Examples

### 1. Wrapping an Entire Screen

```dart
import 'package:flutter_application_1/widgets/premium_feature_wrapper.dart';

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

### 2. Conditional Feature within a Screen

```dart
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/services/entitlement_service.dart';
import 'package:flutter_application_1/widgets/premium_feature_wrapper.dart';

class MyScreen extends StatefulWidget {
  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  final _authService = AuthService();
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
import 'package:flutter_application_1/widgets/premium_feature_wrapper.dart';

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
  // If no access, paywall is automatically shown
},
```

### 4. Inline Premium Badge

```dart
import 'package:flutter_application_1/widgets/premium_feature_wrapper.dart';

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

### During Development (kDisablePaywallForDev = true)
- All users automatically have premium access
- Paywall screen can still be accessed via menu
- Upgrade button in paywall will grant premium in local storage

### For Production Testing (kDisablePaywallForDev = false)
1. Create a new account via signup
2. User will have `isPremium = false` by default
3. Navigate to a premium feature - should see paywall
4. Tap "Upgrade to Premium" (will show "not yet implemented" message)
5. Manually set premium via Account Details screen (in dev)

## Future Integration: Google Play Billing

When ready to integrate real billing:

1. Add dependency in `pubspec.yaml`:
```yaml
dependencies:
  in_app_purchase: ^3.1.0
```

2. Replace TODOs in `PaywallScreen._handleUpgrade()`:
```dart
// Initialize billing
final InAppPurchase inAppPurchase = InAppPurchase.instance;

// Query products
final ProductDetailsResponse response = await inAppPurchase.queryProductDetails(
  {kMonthlySubscriptionId, kYearlySubscriptionId}
);

// Launch purchase flow
final PurchaseParam purchaseParam = PurchaseParam(
  productDetails: selectedProduct,
);
await inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);

// Listen to purchase stream and verify
```

3. Replace TODOs in `EntitlementService.grantPremium()`:
```dart
// Verify purchase with Google
// Send purchase token to your backend
// Backend verifies with Google Play Developer API
// Backend updates user premium status
// Update local state
```

## Architecture Notes

- **EntitlementService**: Central service for premium checks
- **AuthService**: Stores user premium status (`isPremium` field)
- **PaywallScreen**: Full-screen upgrade UI
- **PremiumFeatureWrapper**: Reusable widget for gating features
- **config.dart**: Dev bypass flag

All premium state is stored locally in SharedPreferences for now. In production, you'll want to verify this with your backend on each app launch.
