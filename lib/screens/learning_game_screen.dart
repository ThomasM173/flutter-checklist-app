import 'package:flutter/material.dart';

class LearningGameScreen extends StatelessWidget {
  const LearningGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(title: Text("Learning Game"), backgroundColor: Colors.red),
      body: Center(
        child: Text(
          "🚀 Learning Game Coming Soon!",
          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
