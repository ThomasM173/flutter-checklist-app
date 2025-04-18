import 'package:flutter/material.dart';
import 'map_screen.dart';
import 'flight_conditions_screen.dart';
import 'learning_game_screen.dart';
import 'checklist_screens/cessna_172_checklist.dart';
import 'aircraft_screens/piper_pa28_screen.dart';
import 'aircraft_screens/diamond_da40_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  void _onBottomNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const FlightConditionsScreen()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LearningGameScreen()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> aircraftList = [
      {
        'title': 'Cessna 172',
        'image': 'assets/images/cessna172.jpeg',
        'screen': const Cessna172ChecklistScreen(),
      },
      {
        'title': 'Piper PA-28',
        'image': 'assets/images/piper.jpeg',
        'screen': const PiperPA28Screen(),
      },
      {
        'title': 'Diamond DA40',
        'image': 'assets/images/aircraft3.jpeg',
        'screen': const DiamondDA40Screen(),
      },
      {
        'title': 'Tecnam P2002',
        'image': 'assets/images/aircraft4.jpeg',
        'screen': null,
      },
      {
        'title': 'Cirrus SR20',
        'image': 'assets/images/aircraft5.jpeg',
        'screen': null,
      },
      {
        'title': 'Cessna 152',
        'image': 'assets/images/aircraft6.jpeg',
        'screen': null,
      },
      {
        'title': 'Diamond DA42',
        'image': 'assets/images/aircraft7.jpeg',
        'screen': null,
      },
      {
        'title': 'Piper Seneca',
        'image': 'assets/images/aircraft8.jpeg',
        'screen': null,
      },
    ];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.redAccent),
              child: Text(
                'Menu',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.map),
              title: const Text('Contact Us'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MapScreen()),
              ),
            ),
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.redAccent,
        elevation: 6,
        title: const Text("✈ ClearedToGo"),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 9),
            child: Image.asset(
              'assets/images/cleared_logo.png',
              width: 50,
              height: 50,
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 10),
            const Text(
              "Select Your Aircraft",
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.1,
                children: aircraftList.map((aircraft) {
                  return AircraftCard(
                    title: aircraft['title'],
                    imageAsset: aircraft['image'],
                    onTap: aircraft['screen'] != null
                        ? () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => aircraft['screen']),
                            )
                        : () {}, // Optional: show a SnackBar if not available
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
        selectedFontSize: 12,
        unselectedFontSize: 12,
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

class AircraftCard extends StatelessWidget {
  final String title;
  final String imageAsset;
  final VoidCallback onTap;

  const AircraftCard({
    super.key,
    required this.title,
    required this.imageAsset,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
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
            Expanded(child: Image.asset(imageAsset, fit: BoxFit.contain)),
            const SizedBox(height: 8),
            Text(
              title,
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
  }
}
