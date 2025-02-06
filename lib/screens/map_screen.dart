import 'package:flutter/material.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Map"), backgroundColor: Colors.red),
      body: Center(child: Text("Map feature coming soon!", style: TextStyle(color: Colors.white))),
    );
  }
}
