import 'package:flutter/material.dart';
import '../widget/bottom_nav_bar.dart';
import '../screens/home_screen.dart';

// Import all emergency game screens
import 'aircraft_screens/cessna_152_emergency_game.dart';
import 'aircraft_screens/cessna_172_emergency_game.dart';
import 'aircraft_screens/piper_pa28_emergency_game.dart';

class LearningGameScreen extends StatelessWidget {
  const LearningGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Pilot Training Games",
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: const Color(0xFF87CEEB),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
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

            _buildGameButton(context, "Cessna 152", Cessna152EmergencyGame()),
            _buildGameButton(context, "Cessna 172", Cessna172EmergencyGame()),
            _buildGameButton(context, "Piper PA-28", PiperPA28EmergencyGame()),

            const SizedBox(height: 20),  // Space before the message

            const Text(
              "More games are on the way, they will arrive with updates!!",
              textAlign: TextAlign.center,
              style: TextStyle(
               fontSize: 16,
               fontWeight: FontWeight.w500,
               color: Color.fromARGB(255, 84, 69, 69),
              ),
            ),

            const Spacer(),

            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                  (route) => false,
                );
              },
              icon: const Icon(Icons.home, color: Colors.black),
              label: const Text(
                "Return to Home",
                style: TextStyle(color: Colors.black),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF87CEEB),
              ),
            ),
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
          child: Text(
            "🛩 $title",
            style: const TextStyle(color: Colors.black),
          ),
        ),
      ),
    );
  }
}
