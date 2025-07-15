import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/game_screens/cessna_152_EFATRA.dart';
import 'package:flutter_application_1/screens/game_screens/cessna_152_EFATRNA.dart';
import 'package:flutter_application_1/screens/game_screens/cessna_152_EFDTR.dart';
import 'package:flutter_application_1/screens/game_screens/cessna_152_ElecFire.dart';
import 'package:flutter_application_1/screens/game_screens/cessna_152_FDS.dart';
import 'package:flutter_application_1/screens/game_screens/cessna_152_FIF.dart';
import 'package:flutter_application_1/screens/game_screens/cessna_152_PFL.dart';

class Cessna152EmergencyGame extends StatefulWidget {
  const Cessna152EmergencyGame({super.key});

  @override
  State<Cessna152EmergencyGame> createState() => _Cessna152EmergencyGameState();
}

class _Cessna152EmergencyGameState extends State<Cessna152EmergencyGame> {
  @override
  Widget build(BuildContext context) {
    final emergencyOptions = [
      {
        'title': 'Engine Failure In Flight / PFL',
        'screen': const Cessna152PFL(),
      },
      {
        'title': 'Engine Failure After Takeoff (RWY Available)',
        'screen': const Cessna152EFATRA(),
      },
      {
        'title': 'Engine Failure After Takeoff (RWY NOT Available)',
        'screen': const Cessna152EFATRNA(),
      },
      {
        'title': 'Engine Failure During Takeoff Roll',
        'screen': const Cessna152EFDTR(),
      },
      {
        'title': 'Electrical Fire',
        'screen': const Cessna152ElecFire(),
      },
      {
        'title': 'Fire During Start',
        'screen': const Cessna152FDS(),
      },
      {
        'title': 'Fire In Flight',
        'screen': const Cessna152FIF(),
      },
    ];

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('Select Emergency Game Scenario'),
        backgroundColor: Colors.orange[400],
        elevation: 6,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.separated(
          itemCount: emergencyOptions.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final option = emergencyOptions[index];
            return ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[400],
                foregroundColor: Colors.black,
                elevation: 4,
                minimumSize: const Size.fromHeight(50), // makes button height at least 50
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
          },
        ),
      ),
    );
  }
}
