import 'package:flutter/material.dart';
import 'package:clearedtogo/services/auth_service.dart';
import 'package:clearedtogo/services/entitlement_service.dart';
import 'package:clearedtogo/screens/paywall_screen.dart';

/// A widget wrapper that conditionally shows premium content or a paywall
/// 
/// Usage:
/// ```dart
/// PremiumFeatureWrapper(
///   child: YourPremiumFeature(),
///   featureName: 'Advanced Checklists',
/// )
/// ```
class PremiumFeatureWrapper extends StatelessWidget {
  final Widget child;
  final String? featureName;
  final String? description;

  const PremiumFeatureWrapper({
    super.key,
    required this.child,
    this.featureName,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final entitlementService = EntitlementService(authService);

    return FutureBuilder<void>(
      future: authService.init(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (entitlementService.userHasPremium) {
          return child;
        }

        return _PaywallPlaceholder(
          featureName: featureName ?? 'Premium Feature',
          description: description,
        );
      },
    );
  }
}

/// Internal widget that displays a paywall placeholder
class _PaywallPlaceholder extends StatelessWidget {
  final String featureName;
  final String? description;

  const _PaywallPlaceholder({
    required this.featureName,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF87CEEB), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Premium icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.workspace_premium,
              size: 48,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            featureName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),

          // Description
          Text(
            description ?? 'This is a Premium feature',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20),

          // Upgrade button
          ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const PaywallScreen(),
                ),
              );

              // If user upgraded, refresh the parent widget
              if (result == true && context.mounted) {
                // Trigger a rebuild by navigating back and forth
                // or use a state management solution in production
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const PaywallScreen(),
                  ),
                );
              }
            },
            icon: const Icon(Icons.upgrade),
            label: const Text('Upgrade to Premium'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF87CEEB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A simpler inline paywall widget for list items or compact spaces
class InlinePremiumBadge extends StatelessWidget {
  final VoidCallback? onTap;

  const InlinePremiumBadge({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const PaywallScreen(),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(
              Icons.workspace_premium,
              size: 16,
              color: Colors.white,
            ),
            SizedBox(width: 4),
            Text(
              'PREMIUM',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper function to check premium access and show paywall if needed
Future<bool> checkPremiumAccess(BuildContext context) async {
  final authService = AuthService();
  await authService.init();
  final entitlementService = EntitlementService(authService);

  if (entitlementService.userHasPremium) {
    return true;
  }

  // Show paywall
  final result = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) => const PaywallScreen(),
    ),
  );

  return result ?? false;
}
