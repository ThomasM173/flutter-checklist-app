import 'package:flutter/material.dart';
import 'package:clearedtogo/screens/contact_us.dart';
import 'package:clearedtogo/screens/about_us.dart';
import 'package:clearedtogo/screens/privacy_policy.dart';
import 'package:clearedtogo/screens/caa_compliance_screen.dart';
import 'package:clearedtogo/screens/faq_screen.dart';
import 'package:clearedtogo/screens/recent_updates_screen.dart';
import 'package:clearedtogo/screens/auth/account_details_screen.dart';
import 'package:clearedtogo/screens/auth/login_screen.dart';
import 'package:clearedtogo/screens/paywall_screen.dart';
import 'package:clearedtogo/screens/premium_pricing_screen.dart';
import 'package:clearedtogo/screens/pdf/pdf_list_screen.dart';
import 'package:clearedtogo/services/auth_service.dart';
import 'package:clearedtogo/services/entitlement_service.dart';
import '../screens/home_screen.dart';

class AppDrawer extends StatelessWidget {
  final int currentIndex;
  const AppDrawer({super.key, required this.currentIndex});

  void _navigate(BuildContext context, Widget page) {
    Navigator.pop(context); // Close drawer
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.grey[100],
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF87CEEB)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/NewLogo.png',
                  fit: BoxFit.contain,
                  height: 75, // Adjust height as needed
                ),
                const SizedBox(height: 8),
                const Text(
                  'ClearedToGo',
                  style: TextStyle(color: Colors.black, fontSize: 20),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home, color: Colors.black),
            title: const Text('Home', style: TextStyle(color: Colors.black)),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.map, color: Colors.black),
            title: const Text('Contact Us', style: TextStyle(color: Colors.black)),
            onTap: () => _navigate(context, const ContactUs()),
          ),
          ListTile(
            leading: const Icon(Icons.info, color: Colors.black),
            title: const Text('About Us', style: TextStyle(color: Colors.black)),
            onTap: () => _navigate(context, const AboutUsScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip, color: Colors.black),
            title: const Text('Privacy Policy', style: TextStyle(color: Colors.black)),
            onTap: () => _navigate(context, const PrivacyPolicyScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.gavel, color: Colors.black),
            title: const Text('CAA Compliance', style: TextStyle(color: Colors.black)),
            onTap: () => _navigate(context, const CAAComplianceScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.question_answer, color: Colors.black),
            title: const Text('FAQ', style: TextStyle(color: Colors.black)),
            onTap: () => _navigate(context, const FAQScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.update, color: Colors.black),
            title: const Text('Recent Updates', style: TextStyle(color: Colors.black)),
            onTap: () => _navigate(context, const RecentUpdatesScreen()),
          ),
          const Divider(color: Colors.black),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf, color: Colors.black),
            title: const Text('My PDFs', style: TextStyle(color: Colors.black)),
            onTap: () => _navigate(context, const PdfListScreen()),
          ),
          FutureBuilder<bool>(
            future: _checkPremiumStatus(),
            builder: (context, snapshot) {
              final isPremium = snapshot.data ?? false;
              return ListTile(
                leading: const Icon(
                  Icons.workspace_premium,
                  color: Colors.black,
                ),
                title: const Text(
                  'Premium',
                  style: TextStyle(
                    color: Colors.black,
                  ),
                ),
                trailing: isPremium 
                    ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
                    : null,
                onTap: () {
                  _navigate(context, const PremiumPricingScreen());
                },
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.person, color: Colors.black),
            title: const Text('Account Details', style: TextStyle(color: Colors.black)),
            onTap: () => _navigate(context, const AccountDetailsScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            onTap: () async {
              // Show confirmation dialog
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );

              if (confirmed == true && context.mounted) {
                await AuthService().logout();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              }
            },
          ),
          const Divider(color: Colors.black),
          ListTile(
            leading: const Icon(Icons.close, color: Colors.black),
            title: const Text('Close Menu', style: TextStyle(color: Colors.black)),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Future<bool> _checkPremiumStatus() async {
    final authService = AuthService();
    await authService.init();
    final entitlementService = EntitlementService(authService);
    return entitlementService.userHasPremium;
  }
}
