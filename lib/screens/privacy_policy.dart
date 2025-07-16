import 'package:flutter/material.dart';
import '../widget/app_drawer.dart';
import '../widget/bottom_nav_bar.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const String policyText = '''
ClearedToGo does not currently collect or store any personal data. 
All checklists and app features run locally on your device.

After completing a checklist, you may download a PDF version for your own records — this file is not shared or uploaded anywhere.

In future, we plan to introduce user accounts for better personalisation. At that point, we’ll update this policy and ensure data is handled securely and transparently.

Thanks for trusting us — and fly safe!
''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AppBar(
          centerTitle: true,
          title: const Text(
            'Privacy Policy',
            style: TextStyle(color: Colors.black),
          ),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFADD8E6), Color(0xFF87CEEB)], // Light blue to sky blue
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black), // Burger icon black
        ),
      ),
      drawer: const AppDrawer(currentIndex: 0),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Image.asset(
                  'assets/images/NewLogo.png', // Ensure this asset is in place and listed in pubspec.yaml
                  height: 150,
                  fit: BoxFit.contain,
                ),
              ),
              const Text(
                policyText,
                style: TextStyle(color: Colors.black, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
