// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '/widget/bottom_nav_bar.dart';

class Cessna152Screen extends StatefulWidget {
  const Cessna152Screen({super.key});

  @override
  _Cessna152ScreenState createState() => _Cessna152ScreenState();
}

class _Cessna152ScreenState extends State<Cessna152Screen> {
  Future<void> _launchMoreInfo() async {
    const url = 'https://en.wikipedia.org/wiki/Cessna_152';
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
          "Cessna 152",
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
                "The Cessna 152 is a reliable two-seat, fixed tricycle gear general aviation aircraft, globally popular for flight training and private use. It’s forgiving, easy to maintain, and an ideal platform for learning fundamentals of flight. The 152 builds on the Cessna 150 design with a more powerful engine and improved systems, making it durable and capable for decades of operation.",
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
                        "Wingspan: 33 ft 4 in\nLength: 24 ft 1 in\nHeight: 8 ft 6 in",
                  ),
                  _buildSpecCard(
                    icon: Icons.speed,
                    title: "Performance",
                    content:
                        "Max Speed: 126 kt\nCruise: 107 kt\nRange: 415 NM",
                    isLarger: true,
                  ),
                  _buildSpecCard(
                    icon: Icons.settings_input_composite,
                    title: "Engine",
                    content:
                        "Lycoming O-235\n110 HP @ 2,600 RPM\nFuel Burn: ~6 GPH",
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
                "• Ideal for beginner pilots\n• Low operating costs\n• Excellent visibility\n• Reliable and easy to fly\n• Parts availability worldwide",
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),
              const SizedBox(height: 16),

              _sectionTitle("⚠️ Limitations"),
              const Text(
                "• Limited useful load (~500 lbs with full fuel)\n• Slower cruise speed than modern trainers\n• No modern avionics in most models",
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),
              const SizedBox(height: 16),

              _sectionTitle("📘 Use Cases"),
              const Text(
                "Primary flight training, local sightseeing, time-building for aspiring commercial pilots, occasional solo trips.",
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
                          Navigator.pushNamed(context, '/cessna_152_checklist'),
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
                          Navigator.pushNamed(context, '/cessna_152_emergency_screen'),
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
                      Navigator.pushNamed(context, '/cessna_152_emergency_game'),
                ),
              ),
              const SizedBox(height: 24),

              Center(
                child: OutlinedButton.icon(
                  onPressed: _launchMoreInfo,
                  icon: const Icon(Icons.link, color: Colors.black),
                  label: const Text(
                    "Wikipedia: Cessna 152",
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
