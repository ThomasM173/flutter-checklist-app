import 'package:flutter/material.dart';

class HomeButton extends StatelessWidget {
  final String label;
  final String route;

  const HomeButton({super.key, required this.label, required this.route});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      width: 250,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          padding: EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: () => Navigator.pushNamed(context, route),
        child: Text(label, style: TextStyle(fontSize: 18, color: Colors.white)),
      ),
    );
  }
}
