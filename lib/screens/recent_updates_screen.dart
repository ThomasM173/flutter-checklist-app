// lib/screens/recent_updates_screen.dart
import 'package:flutter/material.dart';
import '../widget/app_drawer.dart';
import '../widget/bottom_nav_bar.dart';

class RecentUpdatesScreen extends StatelessWidget {
  const RecentUpdatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final updates = [
      'v1.3.0 – Added downloadable PDF export for completed checklists',
      'v1.2.1 – Fixed minor UI spacing issues on smaller devices',
      'v1.2.0 – Added 6‑hour weather forecast in Flight Conditions',
      'v1.1.2 – FAQ and About Us pages added to improve user understanding',
      'v1.1.0 – Introduced new two‑column grid layout on Home screen',
      'v1.0.5 – Improved checklist screen performance for faster loading',
      'v1.0.0 – Initial release with core dynamic checklist functionality',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recent Updates'),
        backgroundColor: Colors.purple,
      ),
      drawer: const AppDrawer(currentIndex: 0),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
      backgroundColor: Colors.white,
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: updates.length,
        itemBuilder: (_, i) => ListTile(
          leading: const Icon(Icons.update, color: Colors.black54),
          title: Text(
            updates[i],
            style: const TextStyle(color: Colors.black87),
          ),
        ),
      ),
    );
  }
}
