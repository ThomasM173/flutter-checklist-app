// lib/screens/recent_updates_screen.dart
import 'package:flutter/material.dart';
import '../widget/app_drawer.dart';
import '../widget/bottom_nav_bar.dart';

class RecentUpdatesScreen extends StatelessWidget {
  const RecentUpdatesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final updates = [
      'v1.2.0 – Added 6‑hour forecast in Flight Conditions',
      'v1.1.0 – Two‑column grid on Home',
      'v1.0.0 – Initial release',
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Recent Updates'), backgroundColor: Colors.redAccent),
      drawer: const AppDrawer(currentIndex: 0),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: updates.length,
        itemBuilder: (_, i) => ListTile(
          leading: const Icon(Icons.update, color: Colors.white),
          title: Text(updates[i], style: const TextStyle(color: Colors.white70)),
        ),
      ),
    );
  }
}
