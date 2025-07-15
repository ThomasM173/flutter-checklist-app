import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/game_screens/piper_pa28_EFATRA.dart';
import 'package:flutter_application_1/screens/game_screens/piper_pa28_EFATRNA.dart';
import 'package:flutter_application_1/screens/game_screens/piper_pa28_EFDTR.dart';
import 'package:flutter_application_1/screens/game_screens/piper_pa28_ElecFire.dart';
import 'package:flutter_application_1/screens/game_screens/piper_pa28_FDS.dart';
import 'package:flutter_application_1/screens/game_screens/piper_pa28_FIF.dart';
import 'package:flutter_application_1/screens/game_screens/piper_pa28_PFL.dart';

class PiperPA28EmergencyGame extends StatefulWidget {
  const PiperPA28EmergencyGame({super.key});

  @override
  State<PiperPA28EmergencyGame> createState() => _PiperPA28EmergencyGameState();
}

class _PiperPA28EmergencyGameState extends State<PiperPA28EmergencyGame> {
  @override
  Widget build(BuildContext context) {
    final emergencyOptions = [
      {
        'title': 'Engine Failure In Flight / PFL',
        'screen': const PiperPA28PFL(),
      },
      {
        'title': 'Engine Failure After Takeoff (RWY Available)',
        'screen': const PiperPA28EFATRA(),
      },
      {
        'title': 'Engine Failure After Takeoff (RWY NOT Available)',
        'screen': const PiperPA28EFATRNA(),
      },
      {
        'title': 'Engine Failure During Takeoff Roll',
        'screen': const PiperPA28EFDTR(),
      },
      {
        'title': 'Electrical Fire',
        'screen': const PiperPA28ElecFire(),
      },
      {
        'title': 'Fire During Start',
        'screen': const PiperPA28FDS(),
      },
      {
        'title': 'Fire In Flight',
        'screen': const PiperPA28FIF(),
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
