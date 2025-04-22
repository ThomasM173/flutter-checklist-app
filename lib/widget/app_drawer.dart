import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/map_screen.dart';
import 'package:flutter_application_1/screens/about_us.dart';
import 'package:flutter_application_1/screens/privacy_policy.dart';
import 'package:flutter_application_1/screens/caa_compliance_screen.dart';
import 'package:flutter_application_1/screens/faq_screen.dart';
import 'package:flutter_application_1/screens/recent_updates_screen.dart';
import '../widget/bottom_nav_bar.dart';

class AppDrawer extends StatelessWidget {
  final int currentIndex;
  const AppDrawer({super.key, required this.currentIndex});

  void _navigate(BuildContext context, Widget page) {
    Navigator.pop(context); // close drawer
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.grey[900],
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.redAccent),
            child: Center(
              child: Text(
                'ClearedToGo',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
          ),

          // Home button (go back to first route)
          ListTile(
            leading: const Icon(Icons.home, color: Colors.white),
            title: const Text('Home', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context); // close drawer
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          ),

          // Contact Us
          ListTile(
            leading: const Icon(Icons.map, color: Colors.white),
            title: const Text('Contact Us', style: TextStyle(color: Colors.white)),
            onTap: () => _navigate(context, const MapScreen()),
          ),

          // About Us
          ListTile(
            leading: const Icon(Icons.info, color: Colors.white),
            title: const Text('About Us', style: TextStyle(color: Colors.white)),
            onTap: () => _navigate(context, const AboutUsScreen()),
          ),

          // Privacy Policy
          ListTile(
            leading: const Icon(Icons.privacy_tip, color: Colors.white),
            title: const Text('Privacy Policy', style: TextStyle(color: Colors.white)),
            onTap: () => _navigate(context, const PrivacyPolicyScreen()),
          ),

          // CAA Compliance
          ListTile(
            leading: const Icon(Icons.gavel, color: Colors.white),
            title: const Text('CAA Compliance', style: TextStyle(color: Colors.white)),
            onTap: () => _navigate(context, const CAAComplianceScreen()),
          ),

          // FAQ
          ListTile(
            leading: const Icon(Icons.question_answer, color: Colors.white),
            title: const Text('FAQ', style: TextStyle(color: Colors.white)),
            onTap: () => _navigate(context, const FAQScreen()),
          ),

          // Recent Updates
          ListTile(
            leading: const Icon(Icons.update, color: Colors.white),
            title: const Text('Recent Updates', style: TextStyle(color: Colors.white)),
            onTap: () => _navigate(context, const RecentUpdatesScreen()),
          ),
        ],
      ),
    );
  }
}
