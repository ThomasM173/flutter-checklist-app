// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '/widget/bottom_nav_bar.dart';

class PiperPA28Screen extends StatefulWidget {
  const PiperPA28Screen({super.key});

  @override
  _PiperPA28ScreenState createState() => _PiperPA28ScreenState();
}

class _PiperPA28ScreenState extends State<PiperPA28Screen> {
  Future<void> _launchMoreInfo() async {
    const url = 'https://en.wikipedia.org/wiki/Piper_PA-28_Cherokee';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open link.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFADD8E6), Color(0xFF87CEEB)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        title: const Text(
          "Piper PA-28",
          style: TextStyle(color: Colors.black),
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle("✈ Overview"),
              const Text(
                "The Piper PA-28 Cherokee is a family of light aircraft designed for flight training, air taxi, and personal use. It features a low wing, tricycle landing gear, and a single-engine layout, and is appreciated for its docile handling and solid performance.",
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),
              const SizedBox(height: 16),

              _sectionTitle("📸 Cockpit Layout"),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: const DecorationImage(
                    image: AssetImage('assets/images/cessna152cockpit.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              _sectionTitle("📊 Specifications"),
              GridView.count(
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                shrinkWrap: true,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 3 / 2,
                children: [
                  _buildSpecCard(
                    icon: Icons.straighten,
                    title: "Dimensions",
                    content:
                        "Wingspan: 35 ft 5 in\nLength: 24 ft 7 in\nHeight: 7 ft 3 in",
                  ),
                  _buildSpecCard(
                    icon: Icons.speed,
                    title: "Performance",
                    content:
                        "Max Speed: 123 kt\nCruise: 115 kt\nRange: 515 NM",
                    isLarger: true,
                  ),
                  _buildSpecCard(
                    icon: Icons.settings_input_composite,
                    title: "Engine",
                    content:
                        "Lycoming O-320\n150-180 HP\nFuel Burn: ~9 GPH",
                  ),
                  _buildSpecCard(
                    icon: Icons.local_gas_station,
                    title: "Fuel",
                    content: "50 gal usable\nAVGAS 100LL",
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _sectionTitle("✅ Strengths"),
              const Text(
                "• Low wing design offers smooth ride\n• Comfortable cabin and seating\n• Robust airframe\n• Good cross-country capability",
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),
              const SizedBox(height: 16),

              _sectionTitle("⚠️ Limitations"),
              const Text(
                "• Slightly heavier controls than Cessna trainers\n• Lower visibility compared to high-wing aircraft\n• Higher stall speed than some competitors",
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),
              const SizedBox(height: 16),

              _sectionTitle("📘 Use Cases"),
              const Text(
                "Flight training, personal travel, touring, aerial photography, light utility work.",
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle_outline, color: Colors.black),
                      label: const Text(
                        "Pre-Flight",
                        style: TextStyle(color: Colors.black),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.lightBlueAccent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () =>
                          Navigator.pushNamed(context, '/piper_pa28_checklist'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.report_problem, color: Colors.black),
                      label: const Text(
                        "Emergency",
                        style: TextStyle(color: Colors.black),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(color: Colors.black),
                        ),
                        elevation: 2,
                      ),
                      onPressed: () =>
                          Navigator.pushNamed(context, '/piper_pa28_emergency_screen'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.videogame_asset, color: Colors.black),
                  label: const Text(
                    "Emergency Game",
                    style: TextStyle(color: Colors.black),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () =>
                      Navigator.pushNamed(context, '/piper_pa28_emergency_game'),
                ),
              ),
              const SizedBox(height: 24),

              Center(
                child: OutlinedButton.icon(
                  onPressed: _launchMoreInfo,
                  icon: const Icon(Icons.link, color: Colors.black),
                  label: const Text(
                    "Wikipedia: Piper PA-28",
                    style: TextStyle(color: Colors.black),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.black),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpecCard({
    required IconData icon,
    required String title,
    required String content,
    bool isLarger = false,
  }) {
    return Container(
      constraints: isLarger ? const BoxConstraints(minHeight: 140) : null,
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.black),
        ),
        elevation: 4,
        shadowColor: Colors.black,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Colors.black, size: 28),
              const SizedBox(height: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const Spacer(),
              Text(
                content,
                style: const TextStyle(fontSize: 14, color: Colors.black),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }
}
