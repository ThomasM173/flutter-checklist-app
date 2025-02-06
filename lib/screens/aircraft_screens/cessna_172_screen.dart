import 'package:flutter/material.dart';
import '/utils/web_scraper.dart'; // ✅ Utility to fetch real-time data

class Cessna172Screen extends StatefulWidget {
  const Cessna172Screen({super.key});

  @override
  _Cessna172ScreenState createState() => _Cessna172ScreenState();
}

class _Cessna172ScreenState extends State<Cessna172Screen> {
  String aircraftInfo = "Loading aircraft details...";

  @override
  void initState() {
    super.initState();
    fetchAircraftData();
  }

  void fetchAircraftData() async {
    String data = await WebScraper.getCessnaData(); // ✅ Fetches website data
    setState(() {
      aircraftInfo = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900], // Dark Grey Theme
      appBar: AppBar(
        title: Text("Cessna 172 Information"),
        backgroundColor: Colors.red,
        elevation: 5,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ Aircraft Name & Model
            Text(
              "🛩 Cessna 172 Skyhawk",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            SizedBox(height: 10),

            // ✅ Real-Time Aircraft Data
            Card(
              color: Colors.grey[850],
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  aircraftInfo,
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
            SizedBox(height: 20),

            // ✅ Aircraft Specifications
            _buildInfoCard("📏 Dimensions", "Wingspan: 36 ft 1 in\nLength: 27 ft 2 in\nHeight: 8 ft 11 in"),
            _buildInfoCard("⚙️ Performance", "Cruise Speed: 122 knots\nRange: 640 NM\nService Ceiling: 13,500 ft"),
            _buildInfoCard("🛠️ Engine", "Type: Lycoming O-320\nPower: 160 HP\nFuel Burn: 8.5 GPH"),

            // ✅ Button for Pre-Flight Checklist
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/cessna_172_checklist');
                },
                child: Text("📋 Pre-Flight Checklist", style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Reusable Card Widget for Information Sections
  Widget _buildInfoCard(String title, String content) {
    return Card(
      color: Colors.grey[850],
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: Colors.red, fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 5),
            Text(content, style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
