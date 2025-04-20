import 'package:flutter/material.dart';
import '../utils/weather_service.dart';
import '../widget/bottom_nav_bar.dart';

class FlightConditionsScreen extends StatefulWidget {
  const FlightConditionsScreen({super.key});
  @override
  State<FlightConditionsScreen> createState() => _FlightConditionsScreenState();
}

class _FlightConditionsScreenState extends State<FlightConditionsScreen> {
  final _icaoController = TextEditingController(text: "EGLL");
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _metar;
  List<Map<String, dynamic>> _taf = [];

  @override
  void initState() {
    super.initState();
    _load("EGLL");
  }

  Future<void> _load(String code) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final metar = await WeatherService.getDecodedMETAR(code);
      if (metar.containsKey('error')) {
        throw Exception(metar['error']);
      }
      final taf = await WeatherService.getForecast(code);

      setState(() {
        _metar = metar;
        _taf = taf;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Flight Conditions"),
        backgroundColor: Colors.redAccent,
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Search row
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _icaoController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[800],
                      hintText: "ICAO (e.g. EGLL)",
                      hintStyle: const TextStyle(color: Colors.white60),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    onSubmitted: (v) => _load(v.trim()),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _load(_icaoController.text.trim()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.all(14),
                  ),
                  child: const Icon(Icons.search, color: Colors.white),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Loading / error / content
            if (_loading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_error != null)
              Expanded(
                child: Center(
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
              )
            else if (_metar != null)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Station & time
                    Text(
                      _metar!['station'] ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _metar!['observed'] ?? '',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 16),

                    // 6‑hour TAF scroll
                    SizedBox(
                      height: 160,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _taf.length,
                        itemBuilder: (_, i) {
                          final f = _taf[i];
                          return Container(
                            width: 140,
                            margin: const EdgeInsets.only(right: 12),
                            child: Card(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      f['time'] ?? '',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 6),
                                    Text("Cat: ${f['category']}", style: const TextStyle(fontSize: 12)),
                                    Text("T: ${f['temp']}°C",  style: const TextStyle(fontSize: 12)),
                                    Text("Wind: ${f['wind_speed']}kt", style: const TextStyle(fontSize: 12)),
                                    Text("Vis: ${f['visibility']}m",  style: const TextStyle(fontSize: 12)),
                                    const Spacer(),
                                    Text(
                                      f['clouds'] ?? 'Clear',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              )
            else
              const Expanded(child: SizedBox()), // should never hit
          ],
        ),
      ),
    );
  }
}
