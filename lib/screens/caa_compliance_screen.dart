// lib/screens/caa_compliance_screen.dart
import 'package:flutter/material.dart';
import '../widget/app_drawer.dart';
import '../widget/bottom_nav_bar.dart';

class CAAComplianceScreen extends StatelessWidget {
  const CAAComplianceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CAA Compliance'),
        backgroundColor: Colors.redAccent,
      ),
      drawer: const AppDrawer(currentIndex: 0),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
      backgroundColor: Colors.white,
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'ClearedToGo is built with aviation safety and compliance in mind. '
            'We are currently in communication with the UK Civil Aviation Authority (CAA) to ensure our materials meet their standards.\n\n'
            'At this stage, no official CAA content is used in the app. All information and features are based on publicly available aviation best practices.\n\n'
            'Once we have formal permission or guidance, we aim to fully integrate CAA-endorsed resources to enhance pilot safety and compliance.\n\n'
            'Until then, all tools and checklists are offered to support pilot awareness and planning, but are not a substitute for official documentation or training.',
            style: TextStyle(color: Colors.black87, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
