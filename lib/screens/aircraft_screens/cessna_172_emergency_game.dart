import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/game_screens/cessna_172_EFATRA.dart';
import 'package:flutter_application_1/screens/game_screens/cessna_172_EFATRNA.dart';
import 'package:flutter_application_1/screens/game_screens/cessna_172_EFDTR.dart';
import 'package:flutter_application_1/screens/game_screens/cessna_172_ElecFire.dart';
import 'package:flutter_application_1/screens/game_screens/cessna_172_FDS.dart';
import 'package:flutter_application_1/screens/game_screens/cessna_172_FIF.dart';
import 'package:flutter_application_1/screens/game_screens/cessna_172_PFL.dart';

class Cessna172EmergencyGame extends StatefulWidget {
  const Cessna172EmergencyGame({super.key});

  @override
  State<Cessna172EmergencyGame> createState() => _Cessna172EmergencyGameState();
}

class _Cessna172EmergencyGameState extends State<Cessna172EmergencyGame> {
  @override
  Widget build(BuildContext context) {
    final emergencyOptions = [
      {
        'title': 'Engine Failure In Flight / PFL',
        'screen': const Cessna172PFL(),
      },
      {
        'title': 'Engine Failure After Takeoff (RWY Available)',
        'screen': const Cessna172EFATRA(),
      },
      {
        'title': 'Engine Failure After Takeoff (RWY NOT Available)',
        'screen': const Cessna172EFATRNA(),
      },
      {
        'title': 'Engine Failure During Takeoff Roll',
        'screen': const Cessna172EFDTR(),
      },
      {
        'title': 'Electrical Fire',
        'screen': const Cessna172ElecFire(),
      },
      {
        'title': 'Fire During Start',
        'screen': const Cessna172FDS(),
      },
      {
        'title': 'Fire In Flight',
        'screen': const Cessna172FIF(),
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Emergency Game Scenario'),
        backgroundColor: Colors.orange,
        elevation: 6,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: emergencyOptions.map((option) {
            return ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                foregroundColor: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => option['screen'] as Widget),
                );
              },
              child: Center(
                child: Text(
                  option['title'] as String,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
