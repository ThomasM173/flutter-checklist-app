import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/contact_us.dart';
import 'package:flutter_application_1/screens/flight_conditions_screen.dart';
import 'package:flutter_application_1/screens/learning_game_screen.dart';
import 'package:flutter_application_1/screens/checklist_screens/cessna_172_checklist.dart';
import 'package:flutter_application_1/screens/checklist_screens/cessna_152_checklist.dart';
import 'package:flutter_application_1/screens/checklist_screens/piper_pa28_checklist.dart';
import 'package:flutter_application_1/screens/aircraft_screens/piper_pa28_screen.dart';
import '../widget/app_drawer.dart';
import '../widget/bottom_nav_bar.dart';

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
        // stay on Home
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
        'screen': const Cessna152ChecklistScreen(),
      },
      {
        'title': 'Cessna 172',
        'image': 'assets/images/cessna172.jpeg',
        'screen': const Cessna172ChecklistScreen(),
      },
      {
        'title': 'Piper PA-28',
        'image': 'assets/images/piper.jpeg',
        'screen': const PiperPA28ChecklistScreen(),
      },
      {
        'title': 'Cirrus SR20',
        'image': 'assets/images/cirrussr20.jpeg',
        'screen': null,
      },
      {
        'title': 'Cirrus SR22',
        'image': 'assets/images/cirrussr22.jpeg',
        'screen': null,
      },
      {
        'title': 'Diamond DA40',
        'image': 'assets/images/diamondda40.jpeg',
        'screen': null,
      },
      {
        'title': 'Diamond DA42',
        'image': 'assets/images/diamondda42.jpeg',
        'screen': null,
      },
      {
        'title': 'Tecnam P2002',
        'image': 'assets/images/tecnamp2002.jpeg',
        'screen': null,
      },
      {
        'title': 'Tecnam P2010',
        'image': 'assets/images/tecnamp2010.jpeg',
        'screen': null,
      },
    ];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      drawer: const AppDrawer(currentIndex: 0),

      appBar: AppBar(
        backgroundColor: Colors.redAccent,
        elevation: 6,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: const Text("ClearedToGo"),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 9),
            child: Image.asset(
              'assets/images/logo.jpg',
              width: 50,
              height: 50,
            ),
          ),
        ],
      ),

      body: Padding(
  padding: const EdgeInsets.all(16.0),
  child: Column(
    children: [
      const SizedBox(height: 10),
      const Text(
        "Select Aircraft",
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
      const SizedBox(height: 10),
      Expanded(
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.1,
          children: aircraftList.map((aircraft) {
            return GestureDetector(
              onTap: aircraft['screen'] != null
                  ? () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => aircraft['screen']),
                      )
                  : () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Coming soon!')),
                      );
                    },
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  color: Colors.white,
                  border: Border.all(color: Colors.black, width: 1.5),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade400,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Image.asset(
                        aircraft['image'],
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      aircraft['title'],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    ],
  ),
),


      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onBottomNavTap,
        backgroundColor: Colors.black,
        selectedItemColor: Colors.greenAccent,
        unselectedItemColor: Colors.white,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.cloud_queue),
            label: 'Flight',
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
