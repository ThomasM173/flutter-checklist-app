import 'package:flutter/material.dart';
import '../checklist_screens/diamond_da40_checklist.dart';

class DiamondDA40Screen extends StatelessWidget {
  const DiamondDA40Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: Text("Diamond DA40 - Info"), backgroundColor: Colors.red),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("🛩 Diamond DA40", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DiamondDA40ChecklistScreen()),
              ),
              child: Text("📋 Pre-Flight Checklist", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
