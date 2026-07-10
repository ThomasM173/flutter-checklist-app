import 'package:flutter/material.dart';
import 'package:clearedtogo/services/auth_service.dart';
import 'package:clearedtogo/services/entitlement_service.dart';
import 'package:clearedtogo/config/config.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  final _authService = AuthService();
  late final _entitlementService = EntitlementService(_authService);
  bool _isProcessing = false;

  Future<void> _handleUpgrade() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      // Purchase flow is not implemented yet.
      // When billing is integrated, this should:
      // - initialize InAppPurchase
      // - query product details
      // - launch the purchase flow
      // - verify purchase tokens with the backend
      // - grant premium access on success

      // For now (dev mode): just grant premium directly
      if (kDisablePaywallForDev) {
        await _entitlementService.grantPremium();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Premium access granted! (Dev Mode)'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Close paywall and return success
          Navigator.of(context).pop(true);
        }
      } else {
        // In production, show error that billing isn't implemented yet
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Billing not yet implemented. Coming soon!'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upgrade failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text(
          'Upgrade to Premium',
          style: TextStyle(color: Colors.black),
        ),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Premium badge icon
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.workspace_premium,
                  size: 60,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Title
            const Text(
              'Unlock Premium Features',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Get unlimited access to all features',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),

            // Premium features list
            _buildFeatureItem(
              Icons.checklist_rounded,
              'Advanced Checklists',
              'Access to all aircraft checklists with weather integration',
            ),
            _buildFeatureItem(
              Icons.picture_as_pdf,
              'PDF Generation',
              'Generate and export professional PDF checklists',
            ),
            _buildFeatureItem(
              Icons.cloud,
              'Weather Integration',
              'Real-time weather data and METAR information',
            ),
            _buildFeatureItem(
              Icons.assessment,
              'PAVE Assessment',
              'Complete risk assessment tools and history tracking',
            ),
            _buildFeatureItem(
              Icons.sync,
              'Cloud Sync',
              'Sync your progress across all devices (coming soon)',
            ),
            _buildFeatureItem(
              Icons.support_agent,
              'Priority Support',
              'Get help faster with premium support',
            ),
            const SizedBox(height: 32),

            // Pricing section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'Choose Your Plan',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Monthly option
                  _buildPricingOption(
                    'Monthly',
                    kMonthlyPrice,
                    'per month',
                    false,
                  ),
                  const SizedBox(height: 12),
                  
                  // Yearly option (popular)
                  _buildPricingOption(
                    'Yearly',
                    kYearlyPrice,
                    'per year',
                    true,
                    savings: 'Save 17%!',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Dev mode indicator
            if (kDisablePaywallForDev)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.amber[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.code, color: Colors.amber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Dev Mode: Premium will be granted without payment',
                        style: TextStyle(
                          color: Colors.amber[900],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Upgrade button
            ElevatedButton(
              onPressed: _isProcessing ? null : _handleUpgrade,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF87CEEB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: _isProcessing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Upgrade to Premium',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(height: 16),

            // Terms text
            Text(
              'By upgrading, you agree to our Terms of Service and Privacy Policy. '
              'Subscriptions automatically renew unless cancelled.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF87CEEB).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF87CEEB),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingOption(
    String title,
    String price,
    String period,
    bool isPopular, {
    String? savings,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPopular ? const Color(0xFF87CEEB).withOpacity(0.1) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPopular ? const Color(0xFF87CEEB) : Colors.grey[300]!,
          width: isPopular ? 2 : 1,
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
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    if (isPopular) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF87CEEB),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'POPULAR',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  period,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                if (savings != null)
                  Text(
                    savings,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            price,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
