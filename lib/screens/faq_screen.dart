import 'package:flutter/material.dart';
import '../widget/app_drawer.dart';
import '../widget/bottom_nav_bar.dart';

class FAQScreen extends StatelessWidget {
  const FAQScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final faqs = [
      {
        'q': 'How do I reset my checklist?',
        'a': 'Tap the 🔄 Reset button on the checklist page.'
      },
      {
        'q': 'Can I use the app offline?',
        'a': 'Yes, all checklists and learning modules are stored locally.'
      },
      {
        'q': 'What is the Dynamic Checklist?',
        'a': 'It’s an intelligent checklist that adapts to your inputs and flight conditions, helping you reflect and stay situationally aware.'
      },
      {
        'q': 'Where does the information come from?',
        'a': 'We use trusted CAA and aircraft manufacturer sources to ensure accuracy.'
      },
      {
        'q': 'Can I track my progress?',
        'a': 'Yes! You’ll see completed items and get learning feedback as you go.'
      },
      {
        'q': 'How do insights improve my safety?',
        'a': 'Our checklist highlights common human factors and encourages safer decision-making before and during flight.'
      },
      {
        'q': 'Can I contribute feedback or ideas?',
        'a': 'Absolutely. We’re pilot-driven — your input helps us improve.'
      },
    ];

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AppBar(
          centerTitle: true,
          title: const Text(
            'FAQ',
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
          iconTheme: const IconThemeData(color: Colors.black), // Burger icon black
        ),
      ),
      drawer: const AppDrawer(currentIndex: 0),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
      backgroundColor: Colors.white,
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        itemCount: faqs.length,
        itemBuilder: (_, i) => Card(
          color: Colors.grey[200],
          margin: const EdgeInsets.symmetric(vertical: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ExpansionTile(
            title: Text(
              faqs[i]['q']!,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  faqs[i]['a']!,
                  style: const TextStyle(color: Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
