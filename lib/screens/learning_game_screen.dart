import 'package:flutter/material.dart';
import '../widget/bottom_nav_bar.dart';
import '../screens/home_screen.dart';

// Import all emergency game screens
import 'aircraft_screens/cessna_172_emergency_game.dart';
import 'aircraft_screens/cessna_152_emergency_game.dart';
import 'aircraft_screens/piper_pa28_emergency_game.dart';
import 'aircraft_screens/diamond_da40_emergency_game.dart';
import 'aircraft_screens/diamond_da42_emergency_game.dart';
import 'aircraft_screens/cirrus_sr20_emergency_game.dart';
import 'aircraft_screens/cirrus_sr22_emergency_game.dart';
import 'aircraft_screens/tecnam_p2002_emergency_game.dart';
import 'aircraft_screens/tecnam_p2010_emergency_game.dart';

class LearningGameScreen extends StatelessWidget {
  const LearningGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text("Pilot Learning Games"),
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text(
              "Select an aircraft to start its emergency procedure game.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
            const SizedBox(height: 25),

            _buildGameButton(context, "Cessna 172", Cessna172EmergencyGame()),
            _buildGameButton(context, "Cessna 152", Cessna152EmergencyGame()),
            _buildGameButton(context, "Piper PA-28", PiperPA28EmergencyGame()),
            _buildGameButton(context, "Diamond DA40", CirrusSr22EmergencyGame()),
            _buildGameButton(context, "Diamond DA42", CirrusSr22EmergencyGame()),
            _buildGameButton(context, "Cirrus SR20", CirrusSr20EmergencyGame()),
            _buildGameButton(context, "Cirrus SR22", CirrusSr22EmergencyGame()),
            _buildGameButton(context, "Tecnam P2002", CirrusSr22EmergencyGame()),
            _buildGameButton(context, "Tecnam P2010", CirrusSr22EmergencyGame()),

            const Spacer(),

            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                  (route) => false, // removes all previous routes
                );
              },
              icon: const Icon(Icons.home),
              label: const Text("Return to Home"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
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
          backgroundColor: Colors.redAccent,
          minimumSize: const Size(double.infinity, 50),
        ),
        child: Text("🛩 $title"),
      ),
    );
  }
}
