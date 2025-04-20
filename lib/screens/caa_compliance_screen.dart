// lib/screens/caa_compliance_screen.dart
import 'package:flutter/material.dart';
import '../widget/app_drawer.dart';
import '../widget/bottom_nav_bar.dart';

class CAAComplianceScreen extends StatelessWidget {
  const CAAComplianceScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CAA Compliance'), backgroundColor: Colors.redAccent),
      drawer: const AppDrawer(currentIndex: 0),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: const Text(
          'This app adheres to all CAA regulations, including ...',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ),
    );
  }
}
