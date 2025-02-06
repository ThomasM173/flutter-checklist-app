import 'package:flutter/material.dart';
import '../checklist_screens/piper_pa28_checklist.dart';

class PiperPA28Screen extends StatelessWidget {
  const PiperPA28Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: Text("Piper PA-28 - Info"), backgroundColor: Colors.red),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("🛩 Piper PA-28", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PiperPA28ChecklistScreen()),
              ),
              child: Text("📋 Pre-Flight Checklist", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
