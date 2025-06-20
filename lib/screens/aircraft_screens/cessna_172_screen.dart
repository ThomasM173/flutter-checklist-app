import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '/widget/bottom_nav_bar.dart';

class Cessna172Screen extends StatefulWidget {
  const Cessna172Screen({super.key});

  @override
  _Cessna172ScreenState createState() => _Cessna172ScreenState();
}

class _Cessna172ScreenState extends State<Cessna172Screen> {
  String aircraftInfo = "Loading aircraft details...";

 

  Future<void> _launchMoreInfo() async {
    const url = 'https://en.wikipedia.org/wiki/Cessna_172';
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
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text("Cessna 172 Skyhawk"),
        backgroundColor: Colors.redAccent,
        elevation: 4,
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero image
            Container(
              height: 200,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/cessna172.jpeg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  const Text(
                    "🛩 Cessna 172 Skyhawk",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Real-time fetched data
                  Card(
                    color: Colors.grey[850],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        aircraftInfo,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Specs grid
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
                        content: "Wingspan\n36 ft 1 in\nLength\n27 ft 2 in",
                      ),
                      _buildSpecCard(
                        icon: Icons.speed,
                        title: "Performance",
                        content: "Cruise\n122 kt\nRange\n640 NM",
                      ),
                      _buildSpecCard(
                        icon: Icons.engineering,
                        title: "Engine",
                        content: "Lycoming O‑320\n160 HP\n8.5 GPH",
                      ),
                      _buildSpecCard(
                        icon: Icons.speed,
                        title: "Fuel",
                        content: "Total\n56 gal\nUsable\n53 gal",
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Pre-flight & Emergency Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.checklist_rtl, size: 24),
                          label: const Text("Pre‑Flight Checklist"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: const TextStyle(fontSize: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () => Navigator.pushNamed(
                              context, '/cessna_172_checklist'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.warning, size: 24),
                          label: const Text("Emergency"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orangeAccent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () => Navigator.pushNamed(
                              context, '/cessna_172_emergency'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // More info link
                  Center(
                    child: TextButton(
                      onPressed: _launchMoreInfo,
                      child: const Text(
                        "🔗 Learn More on Wikipedia",
                        style: TextStyle(
                          decoration: TextDecoration.underline,
                          color: Colors.lightBlueAccent,
                          fontSize: 16,
                        ),
                      ),
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
      color: Colors.grey[850],
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
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Text(
              content,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
