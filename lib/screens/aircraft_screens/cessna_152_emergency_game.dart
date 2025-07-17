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
  // Placeholder for reset logic
  void resetChecklist() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Checklist reset!')),
    );
    // TODO: Add your reset logic here
  }

  // Placeholder for PDF generation logic
  void generatePDF() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PDF generated!')),
    );
    // TODO: Add your PDF generation logic here
  }

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

    Widget _iconButton(
      IconData icon,
      String label,
      Color color,
      VoidCallback onPressed,
    ) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: ElevatedButton.icon(
            icon: Icon(icon, color: Colors.white),
            label: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              minimumSize: const Size.fromHeight(60),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: onPressed,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text(
          'Select Emergency Game Scenario',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.orange[400],
        elevation: 6,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.separated(
                itemCount: emergencyOptions.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final option = emergencyOptions[index];
                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[400],
                      foregroundColor: Colors.white,
                      elevation: 4,
                      minimumSize: const Size.fromHeight(70),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: Colors.white, width: 1),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                option['screen'] as Widget),
                      );
                    },
                    child: Center(
                      child: Text(
                        option['title'] as String,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _iconButton(Icons.refresh, 'Reset', Colors.red, resetChecklist),
                _iconButton(Icons.picture_as_pdf, 'PDF', Colors.blue, generatePDF),
                _iconButton(
                  Icons.info_outline,
                  'Details',
                  Colors.orange,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            const Cessna152EmergencyDetailsScreen()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class Cessna152EmergencyDetailsScreen extends StatelessWidget {
  const Cessna152EmergencyDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Game Details'),
        backgroundColor: Colors.orange[400],
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          'Here you can provide more information about the emergency game scenarios, instructions, or any other details.',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
