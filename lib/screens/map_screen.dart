// lib/screens/contact_screen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// A simple contact page with email and Google Form launchers
class MapScreen extends StatelessWidget {
  const MapScreen({Key? key}) : super(key: key);

  Future<void> _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@clearedtogo.app',
      queryParameters: {
        'subject': 'Support Request',
      },
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      debugPrint('Could not launch $emailUri');
    }
  }

  Future<void> _launchGoogleForm() async {
    final Uri formUri = Uri.parse(
      'https://docs.google.com/forms/d/e/1FAIpQLSc_RV1Tq0qgVE6sGPLQMij7ESsicX74ECK1-Vf-trFoCIZPFw/viewform?usp=dialog',
    );
    if (await canLaunchUrl(formUri)) {
      await launchUrl(formUri);
    } else {
      debugPrint('Could not launch $formUri');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Us'),
        backgroundColor: Colors.red,
      ),
      body: Container(
        padding: const EdgeInsets.all(20),
        alignment: Alignment.center,
        color: Colors.blueGrey.shade900,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Need help? Found an issue?\nWant us to update a checklist?",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _launchEmail,
              child: const Text('Contact via Email'),
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: _launchGoogleForm,
              child: const Text('Submit via Google Form'),
            ),
          ],
        ),
      ),
    );
  }
}
