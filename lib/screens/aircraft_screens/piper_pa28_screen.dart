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
    const url = 'https://en.wikipedia.org/wiki/Piper_PA28';
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
        title: const Text("Cessna 152"),
        backgroundColor: Colors.purple,
        elevation: 4,
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Header
            Container(
              height: 220,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color.fromARGB(255, 58, 62, 183), Colors.deepPurple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Center(
                child: Text(
                  'Cessna 152',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [Shadow(blurRadius: 4, color: Colors.black45)],
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle("✈ Overview"),
                  const Text(
                    "The Cessna 152 is a two-seat, fixed tricycle gear general aviation aircraft, popular for flight training and personal use. It’s known for being forgiving, easy to fly, and widely available.",
                    style: TextStyle(fontSize: 16),
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
                        content: "Wingspan: 33 ft 4 in\nLength: 24 ft 1 in",
                      ),
                      _buildSpecCard(
                        icon: Icons.speed,
                        title: "Performance",
                        content: "Max Speed: 126 kt\nRange: ~415 NM",
                      ),
                      _buildSpecCard(
                        icon: Icons.settings_input_composite,
                        title: "Engine",
                        content: "Lycoming O-235\n110 HP\n~6 GPH",
                      ),
                      _buildSpecCard(
                        icon: Icons.local_gas_station,
                        title: "Fuel",
                        content: "24.5 gal usable\nAVGAS 100LL",
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _sectionTitle("✅ Strengths"),
                  const Text(
                    "• Ideal for beginner pilots\n• Low operating costs\n• Excellent visibility\n• Widely supported by parts and instructors",
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),

                  _sectionTitle("⚠️ Limitations"),
                  const Text(
                    "• Limited useful load (~500 lbs with full fuel)\n• Slower cruise compared to modern trainers\n• No IFR-certified avionics in most models",
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),

                  _sectionTitle("📘 Use Cases"),
                  const Text(
                    "Primary flight training, local sightseeing, time-building, light solo travel.",
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text("Pre-Flight"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () => Navigator.pushNamed(context, '/cessna_152_checklist'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.report_problem),
                          label: const Text("Emergency"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orangeAccent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () => Navigator.pushNamed(context, '/cessna_152_emergency'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Center(
                    child: TextButton.icon(
                      onPressed: _launchMoreInfo,
                      icon: const Icon(Icons.link),
                      label: const Text("Wikipedia: Cessna 152"),
                      style: TextButton.styleFrom(foregroundColor: Colors.lightBlue),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecCard({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Card(
      color: Colors.grey[600],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.redAccent, size: 28),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Text(
              content,
              style: const TextStyle(color: Colors.black, fontSize: 14),
            ),
          ],
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
          color: Colors.black87,
        ),
      ),
    );
  }
}
