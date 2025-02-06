import 'package:flutter/material.dart';
import 'map_screen.dart';
import 'flight_conditions_screen.dart';
import 'learning_game_screen.dart';
import 'aircraft_screens/cessna_172_screen.dart';
import 'aircraft_screens/piper_pa28_screen.dart';
import 'aircraft_screens/diamond_da40_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: Text("✈ Mobile Checklist"),
        backgroundColor: Colors.red,
        centerTitle: true,
        elevation: 5,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 20),
            Text(
              "Select Your Aircraft",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            SizedBox(height: 10),

            // Aircraft Selection
            Expanded(
              child: ListView(
                children: [
                  AircraftCard(title: "Cessna 172", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => Cessna172Screen()))),
                  AircraftCard(title: "Piper PA-28", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PiperPA28Screen()))),
                  AircraftCard(title: "Diamond DA40", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => DiamondDA40Screen()))),
                ],
              ),
            ),

            Divider(color: Colors.white, thickness: 1, height: 30),

            // Map, Flight Conditions, Learning Game Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FeatureButton(label: "🌍 Map", icon: Icons.map, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => MapScreen()))),
                SizedBox(width: 10),
                FeatureButton(label: "🌦 Flight Conditions", icon: Icons.cloud, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => FlightConditionsScreen()))),
                SizedBox(width: 10),
                FeatureButton(label: "🎮 Learning Game", icon: Icons.videogame_asset, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => LearningGameScreen()))),
              ],
            ),
            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

// Aircraft Selection Card
class AircraftCard extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const AircraftCard({super.key, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: Colors.grey[850],
        elevation: 5,
        margin: EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
              Icon(Icons.arrow_forward_ios, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

// Feature Buttons for Map, Flight Conditions, Learning Game
class FeatureButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const FeatureButton({super.key, required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        shadowColor: Colors.redAccent,
        elevation: 5,
      ),
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white),
      label: Text(label, style: TextStyle(color: Colors.white, fontSize: 16)),
    );
  }
}
