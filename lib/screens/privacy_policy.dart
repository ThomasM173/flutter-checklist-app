// lib/screens/privacy_policy_screen.dart
import 'package:flutter/material.dart';
import '../widget/app_drawer.dart';
import '../widget/bottom_nav_bar.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy'), backgroundColor: Colors.purple),
      drawer: const AppDrawer(currentIndex: 0),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
      backgroundColor: Colors.white,
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'ClearedToGo does not currently collect or store any personal data. '
            'All checklists and app features run locally on your device.\n\n'
            'After completing a checklist, you may download a PDF version for your own records — this file is not shared or uploaded anywhere.\n\n'
            'In future, we plan to introduce user accounts for better personalisation. At that point, we’ll update this policy and ensure data is handled securely and transparently.\n\n'
            'Thanks for trusting us — and fly safe!',
            style: TextStyle(color: Colors.black87, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
