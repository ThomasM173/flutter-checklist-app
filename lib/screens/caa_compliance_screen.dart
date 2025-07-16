import 'package:flutter/material.dart';
import '../widget/app_drawer.dart';
import '../widget/bottom_nav_bar.dart';

class CAAComplianceScreen extends StatelessWidget {
  const CAAComplianceScreen({super.key});

  static const String complianceText = '''
ClearedToGo is built with aviation safety and compliance in mind. 
We are currently in communication with the UK Civil Aviation Authority (CAA) to ensure our materials meet their standards.

At this stage, no official CAA content is used in the app. All information and features are based on publicly available aviation best practices.

Once we have formal permission or guidance, we aim to fully integrate CAA-endorsed resources to enhance pilot safety and compliance.

Until then, all tools and checklists are offered to support pilot awareness and planning, but are not a substitute for official documentation or training.
''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AppBar(
          centerTitle: true,
          title: const Text(
            'CAA Compliance',
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
          iconTheme: const IconThemeData(color: Colors.black), // Black burger icon
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
                  'assets/images/NewLogo.png', // Ensure this asset exists and is listed in pubspec.yaml
                  height: 150,
                  fit: BoxFit.contain,
                ),
              ),
              const Text(
                complianceText,
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
