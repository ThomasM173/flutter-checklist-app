import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widget/app_drawer.dart';
import '../widget/bottom_nav_bar.dart';

class ContactUs extends StatelessWidget {
  const ContactUs({super.key});

  void _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@clearedtogo.app',
      query: Uri.encodeFull('subject=Support Request'),
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  void _launchGoogleForm() async {
    final Uri formUri = Uri.parse(
        'https://docs.google.com/forms/d/e/1FAIpQLSc_RV1Tq0qgVE6sGPLQMij7ESsicX74ECK1-Vf-trFoCIZPFw/viewform?usp=dialog');
    if (await canLaunchUrl(formUri)) {
      await launchUrl(formUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AppBar(
          centerTitle: true,
          title: const Text(
            'Contact Us',
            style: TextStyle(color: Colors.black),
          ),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFADD8E6), Color(0xFF87CEEB)], // Light blue to sky blue
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black), // Black burger icon
        ),
      ),
      drawer: const AppDrawer(currentIndex: 0), // ✅ Same as CAAComplianceScreen
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: Image.asset(
                  'assets/images/NewLogo.png',
                  height: 150,
                  fit: BoxFit.contain,
                ),
              ),
              const Text(
                "Need help? Found an issue?\nWant us to update a checklist?\n\nWe're here for you!",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.black),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFADD8E6),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _launchEmail,
                  child: const Text(
                    "Contact via Email",
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFADD8E6),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _launchGoogleForm,
                  child: const Text(
                    "Submit via Google Form",
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
