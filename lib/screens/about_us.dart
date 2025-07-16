import 'package:flutter/material.dart';
import '../widget/bottom_nav_bar.dart';
import '../widget/app_drawer.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  static const String aboutText = '''
We’re David Cooper and Thomas Malins — Engineering and Management students at the University of Exeter, and co-founders of ClearedToGo.

As aviation enthusiasts and GA pilots, we built this app to solve a simple but critical problem: staying organised, consistent, and situationally aware in the cockpit. 

ClearedToGo is a dynamic checklist and learning companion — designed specifically to support General Aviation pilots with the routines, flows, and reminders that matter most.

We believe that structured checklists and a clear mental model can significantly enhance flight safety. 
Our goal is to help pilots build stronger habits, reduce mental load, and stay one step ahead — both on the ground and in the air.

Thanks for using the app — and fly safe!

— David & Thomas
''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AppBar(
          centerTitle: true,
          title: const Text(
            'About Us',
            style: TextStyle(color: Colors.black),
          ),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors:  [Color(0xFFADD8E6), Color(0xFF87CEEB)], // Light blue to sky blue
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 1,
          iconTheme: const IconThemeData(color: Colors.black), // Burger icon black
        ),
      ),
      drawer: const AppDrawer(currentIndex: 0),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Large logo at the top
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Image.asset(
                  'assets/images/NewLogo.png', // Make sure your logo is in assets/images/logo.png
                  height: 150, // Adjust size as needed
                  fit: BoxFit.contain,
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: const Text(
                  aboutText,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.justify,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
