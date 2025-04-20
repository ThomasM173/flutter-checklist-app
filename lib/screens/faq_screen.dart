// lib/screens/faq_screen.dart
import 'package:flutter/material.dart';
import '../widget/app_drawer.dart';
import '../widget/bottom_nav_bar.dart';

class FAQScreen extends StatelessWidget {
  const FAQScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final faqs = [
      {'q': 'How do I reset my checklist?', 'a': 'Tap the 🔄 Reset button on the checklist page.'},
      {'q': 'Can I use offline?', 'a': 'Yes, all checklists are stored locally.'},
      // …add more
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('FAQ'), backgroundColor: Colors.redAccent),
      drawer: const AppDrawer(currentIndex: 0),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: faqs.length,
        itemBuilder: (_, i) => ExpansionTile(
          title: Text(faqs[i]['q']!, style: const TextStyle(color: Colors.white)),
          children: [Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(faqs[i]['a']!, style: const TextStyle(color: Colors.white70)),
          )],
        ),
      ),
    );
  }
}
