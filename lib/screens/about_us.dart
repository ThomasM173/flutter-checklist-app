// lib/screens/about_us_screen.dart
import 'package:flutter/material.dart';
import '../widget/bottom_nav_bar.dart';
import '../widget/app_drawer.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About Us'), backgroundColor: Colors.redAccent),
      drawer: const AppDrawer(currentIndex: 0),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'ClearedToGo is a mobile checklist and learning app for general aviation pilots. Our mission is to provide ...',
            style: TextStyle(color: Colors.white70, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
