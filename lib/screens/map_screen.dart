import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  // Email launcher
  void _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@clearedtogo.app', // Change to your actual support email
      query: Uri.encodeFull('subject=Support Request'),
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  // Google Form launcher
  void _launchGoogleForm() async {
    final Uri formUri = Uri.parse('https://docs.google.com/forms/d/e/1FAIpQLSc_RV1Tq0qgVE6sGPLQMij7ESsicX74ECK1-Vf-trFoCIZPFw/viewform?usp=dialog'); // Replace with your form link
    if (await canLaunchUrl(formUri)) {
      await launchUrl(formUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Contact Us"),
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "Need help? Found an issue? Want us to update a checklist?\n\nWe're here for you!",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _launchEmail,
              child: const Text("Contact via Email"),
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: _launchGoogleForm,
              child: const Text("Submit via Google Form"),
            ),
          ],
        ),
      ),
    );
  }
}
