import 'package:flutter/material.dart';
import '../widget/app_drawer.dart';
import '../widget/bottom_nav_bar.dart';
import 'aircraft_screens/cessna_152_emergency_game.dart';
import 'aircraft_screens/cessna_172_emergency_game.dart';
import 'aircraft_screens/piper_pa28_emergency_game.dart';

class LearningGameScreen extends StatelessWidget {
  const LearningGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AppBar(
          centerTitle: true,
          title: const Text(
            "Pilot Training Games",
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
          elevation: 4,
          iconTheme: const IconThemeData(color: Colors.black), // Burger icon black
        ),
      ),
      drawer: const AppDrawer(currentIndex: 2),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text(
              "Select an aircraft to start the emergency procedures game",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.black),
            ),
            const SizedBox(height: 25),
            _buildGameButton(context, "Cessna 152", const Cessna152EmergencyGame()),
            _buildGameButton(context, "Cessna 172", const Cessna172EmergencyGame()),
            _buildGameButton(context, "Piper PA-28", const PiperPA28EmergencyGame()),
            const SizedBox(height: 20),
            const Text(
              "More games are on the way, they will arrive with updates!!",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black),
            ),
            const SizedBox(height: 10),
            Image.asset('assets/images/NewLogo.png', height: 200, fit: BoxFit.contain),
            const Spacer(),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 2),
    );
  }

  Widget _buildGameButton(BuildContext context, String title, Widget screen) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => screen),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF87CEEB),
          minimumSize: const Size(double.infinity, 50),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: Text("🛩 $title", style: const TextStyle(color: Colors.black)),
        ),
      ),
    );
  }
}
