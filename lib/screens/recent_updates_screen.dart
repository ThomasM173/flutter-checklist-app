import 'package:flutter/material.dart';
import '../widget/app_drawer.dart';
import '../widget/bottom_nav_bar.dart';

class RecentUpdatesScreen extends StatelessWidget {
  const RecentUpdatesScreen({super.key});

  static const String updatesText = '''
v1.0.0 –Initial Release
''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AppBar(
          centerTitle: true,
          title: const Text(
            'Recent Updates',
            style: TextStyle(color: Colors.black),
          ),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFADD8E6), Color(0xFF87CEEB)], // Light blue → sky blue
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
                  'assets/images/NewLogo.png', // Ensure this exists and is in pubspec.yaml
                  height: 150,
                  fit: BoxFit.contain,
                ),
              ),
              const Text(
                updatesText,
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
