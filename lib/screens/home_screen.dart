import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/flight_conditions_screen.dart';
import 'package:flutter_application_1/screens/learning_game_screen.dart';
import 'package:flutter_application_1/screens/checklist_screens/cessna_172_checklist.dart';
import 'package:flutter_application_1/screens/checklist_screens/cessna_152_checklist.dart';
import 'package:flutter_application_1/screens/checklist_screens/piper_pa28_checklist.dart';
import 'package:flutter_application_1/screens/aircraft_screens/cessna_152_emergency_screen.dart';
import 'package:flutter_application_1/screens/aircraft_screens/cessna_152_screen.dart';
import 'package:flutter_application_1/screens/aircraft_screens/cessna_172_emergency_screen.dart';
import 'package:flutter_application_1/screens/aircraft_screens/cessna_172_screen.dart';
import 'package:flutter_application_1/screens/aircraft_screens/piper_pa28_emergency_screen.dart';
import 'package:flutter_application_1/screens/aircraft_screens/piper_pa28_screen.dart';
import '../widget/app_drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  void _onBottomNavTap(int index) {
    setState(() => _selectedIndex = index);
    switch (index) {
      case 0:
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const FlightConditionsScreen()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LearningGameScreen()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final aircraftList = <Map<String, dynamic>>[
      {
        'title': 'Cessna 152',
        'image': 'assets/images/cessna152.jpeg',
        'checklistScreen': const Cessna152ChecklistScreen(),
        'emergencyScreen': const Cessna152EmergencyScreen(),
        'infoScreen': const Cessna152Screen(),
      },
      {
        'title': 'Cessna 172',
        'image': 'assets/images/cessna172.jpeg',
        'checklistScreen': const Cessna172ChecklistScreen(),
        'emergencyScreen': const Cessna172EmergencyScreen(),
        'infoScreen': const Cessna172Screen(),
      },
      {
        'title': 'Piper PA-28',
        'image': 'assets/images/piper.jpeg',
        'checklistScreen': const PiperPA28ChecklistScreen(),
        'emergencyScreen': const PiperPA28EmergencyScreen(),
        'infoScreen': const PiperPA28Screen(),
      },
    ];

    return Scaffold(
      backgroundColor: Colors.grey[200],
      drawer: const AppDrawer(currentIndex: 0),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFADD8E6), Color(0xFF87CEEB)], // Light blue to sky blue
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 4,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: const Text(
          "ClearedToGo",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ClipOval(
              child: Image.asset(
                'assets/images/Newlogo.png',
                width: 44,
                height: 44,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    itemCount: aircraftList.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final aircraft = aircraftList[index];
                      return InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => aircraft['checklistScreen']),
                        ),
                        borderRadius: BorderRadius.circular(20),
                        splashColor: Colors.deepPurple.shade100,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.shade300,
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.asset(
                                  aircraft['image'],
                                  width: 110,
                                  height: 70,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Center(
                                  child: Text(
                                    aircraft['title'],
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                              Column(
                                children: [
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => aircraft['emergencyScreen']),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.red,
                                      side: const BorderSide(color: Colors.black),
                                      minimumSize: const Size(90, 30),
                                      padding: const EdgeInsets.symmetric(horizontal: 10),
                                    ),
                                    child: const Text('Emergency Checklist', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => aircraft['infoScreen']),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.black,
                                      side: const BorderSide(color: Colors.black),
                                      minimumSize: const Size(90, 30),
                                      padding: const EdgeInsets.symmetric(horizontal: 10),
                                    ),
                                    child: const Text('Aircraft Info', style: TextStyle(fontSize: 12)),
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => aircraft['checklistScreen']),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.black,
                                      side: const BorderSide(color: Colors.black),
                                      minimumSize: const Size(90, 30),
                                      padding: const EdgeInsets.symmetric(horizontal: 10),
                                    ),
                                    child: const Text('Aircraft Checklist', style: TextStyle(fontSize: 11)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 90,
            left: 0,
            right: 0,
            child: Center(
              child: Image.asset(
                'assets/images/Newlogo.png',
                height: 160, // Increased logo size
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.0),
              child: Text(
                "Fly safe, Fly smart.\nClearedToGo is here to help you, every step of the way.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onBottomNavTap,
        backgroundColor: Colors.black,
        selectedItemColor: Colors.greenAccent,
        unselectedItemColor: Colors.white,
        showUnselectedLabels: true,
        iconSize: 28.0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.cloud_queue),
            label: 'Weather',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.videogame_asset),
            label: 'Game',
          ),
        ],
      ),
    );
  }
}
