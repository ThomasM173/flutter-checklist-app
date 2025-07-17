import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/contact_us.dart';
import 'package:flutter_application_1/screens/about_us.dart';
import 'package:flutter_application_1/screens/privacy_policy.dart';
import 'package:flutter_application_1/screens/caa_compliance_screen.dart';
import 'package:flutter_application_1/screens/faq_screen.dart';
import 'package:flutter_application_1/screens/recent_updates_screen.dart';
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
                  'assets/images/newlogo.png',
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
            leading: const Icon(Icons.close, color: Colors.black),
            title: const Text('Close Menu', style: TextStyle(color: Colors.black)),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
