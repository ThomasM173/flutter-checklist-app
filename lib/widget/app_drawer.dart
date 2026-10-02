import 'package:flutter/material.dart';
import 'package:clearedtogo/theme/app_colors.dart';
import 'package:clearedtogo/screens/contact_us.dart';
import 'package:clearedtogo/screens/about_us.dart';
import 'package:clearedtogo/screens/privacy_policy.dart';
import 'package:clearedtogo/screens/caa_compliance_screen.dart';
import 'package:clearedtogo/screens/faq_screen.dart';
import 'package:clearedtogo/screens/recent_updates_screen.dart';
import 'package:clearedtogo/screens/auth/account_details_screen.dart';
import 'package:clearedtogo/screens/auth/login_screen.dart';
import 'package:clearedtogo/screens/auth/flight_school_membership_screen.dart';
import 'package:clearedtogo/screens/completions/my_completions_screen.dart';
import 'package:clearedtogo/services/supabase_auth_service.dart';
import 'package:clearedtogo/services/entitlement_service.dart';

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
      backgroundColor: AppColors.cardBackground,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(gradient: AppColors.headerGradient),
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
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home, color: AppColors.bodyText),
            title: const Text('Home',
                style: TextStyle(color: AppColors.bodyText)),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/home');
            },
          ),
          ListTile(
            leading:
                const Icon(Icons.picture_as_pdf, color: AppColors.bodyText),
            title: const Text('My Checklists',
                style: TextStyle(color: AppColors.bodyText)),
            subtitle: const Text('Completed checklist PDFs',
                style: TextStyle(color: AppColors.subtleText, fontSize: 12)),
            onTap: () => _navigate(context, const MyCompletionsScreen()),
          ),
          FutureBuilder<_FlightSchoolStatus>(
            future: _loadFlightSchoolStatus(),
            builder: (context, snapshot) {
              final status = snapshot.data;
              return ListTile(
                leading:
                    const Icon(Icons.school, color: AppColors.bodyText),
                title: const Text('Flight School',
                    style: TextStyle(color: AppColors.bodyText)),
                subtitle: status == null
                    ? null
                    : Text(status.statusText,
                        style: const TextStyle(
                            color: AppColors.subtleText, fontSize: 12)),
                onTap: () =>
                    _navigate(context, const FlightSchoolMembershipScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.person, color: AppColors.bodyText),
            title: const Text('Account Details',
                style: TextStyle(color: AppColors.bodyText)),
            onTap: () => _navigate(context, const AccountDetailsScreen()),
          ),
          const Divider(color: AppColors.border),
          ListTile(
            leading: const Icon(Icons.map, color: AppColors.bodyText),
            title: const Text('Contact Us',
                style: TextStyle(color: AppColors.bodyText)),
            onTap: () => _navigate(context, const ContactUs()),
          ),
          ListTile(
            leading: const Icon(Icons.info, color: AppColors.bodyText),
            title: const Text('About Us',
                style: TextStyle(color: AppColors.bodyText)),
            onTap: () => _navigate(context, const AboutUsScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip, color: AppColors.bodyText),
            title: const Text('Privacy Policy',
                style: TextStyle(color: AppColors.bodyText)),
            onTap: () => _navigate(context, const PrivacyPolicyScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.gavel, color: AppColors.bodyText),
            title: const Text('CAA Compliance',
                style: TextStyle(color: AppColors.bodyText)),
            onTap: () => _navigate(context, const CAAComplianceScreen()),
          ),
          ListTile(
            leading:
                const Icon(Icons.question_answer, color: AppColors.bodyText),
            title: const Text('FAQ',
                style: TextStyle(color: AppColors.bodyText)),
            onTap: () => _navigate(context, const FAQScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.update, color: AppColors.bodyText),
            title: const Text('Recent Updates',
                style: TextStyle(color: AppColors.bodyText)),
            onTap: () => _navigate(context, const RecentUpdatesScreen()),
          ),
          const Divider(color: AppColors.border),
          FutureBuilder<bool>(
            future: _checkSignedIn(),
            builder: (context, snapshot) {
              final signedIn = snapshot.data ?? false;

              // Sign-in is optional only when kRequireLoginForAllFeatures is
              // false; under the mandatory-login default this branch is not
              // reachable in practice (AuthGate routes signed-out users to
              // LoginScreen before the drawer can ever build), but it's kept
              // so the drawer still degrades sensibly if that flag flips.
              if (!signedIn) {
                return ListTile(
                  leading: const Icon(Icons.login, color: AppColors.bodyText),
                  title: const Text('Login / Sign Up',
                      style: TextStyle(color: AppColors.bodyText)),
                  onTap: () => _navigate(context, const LoginScreen()),
                );
              }

              return ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Logout',
                    style: TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold)),
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Logout'),
                      content:
                          const Text('Are you sure you want to logout?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          style:
                              TextButton.styleFrom(foregroundColor: Colors.red),
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true && context.mounted) {
                    await SupabaseAuthService().logout();
                    if (context.mounted) {
                      Navigator.of(context)
                          .pushNamedAndRemoveUntil('/login', (route) => false);
                    }
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Future<_FlightSchoolStatus> _loadFlightSchoolStatus() async {
    final authService = SupabaseAuthService();
    await authService.init();
    final entitlementService = EntitlementService(authService);
    final school = await authService.currentFlightSchool();
    final statusText = entitlementService.membershipStatusText(
      profile: authService.currentUser,
      school: school,
    );
    return _FlightSchoolStatus(statusText: statusText);
  }

  Future<bool> _checkSignedIn() async {
    final authService = SupabaseAuthService();
    await authService.init();
    return authService.isSignedIn;
  }
}

class _FlightSchoolStatus {
  final String statusText;
  const _FlightSchoolStatus({required this.statusText});
}
