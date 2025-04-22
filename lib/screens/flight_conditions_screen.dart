// lib/screens/flight_conditions_screen.dart

import 'package:flutter/material.dart';
import '../utils/weather_service.dart';
import '../widget/bottom_nav_bar.dart';

class FlightConditionsScreen extends StatefulWidget {
  const FlightConditionsScreen({Key? key}) : super(key: key);

  @override
  State<FlightConditionsScreen> createState() =>
      _FlightConditionsScreenState();
}

class _FlightConditionsScreenState
    extends State<FlightConditionsScreen> {
  final TextEditingController _icaoController =
      TextEditingController(text: 'EGLL');
  bool _loading = false;
  String? _error;
  Map<String, String>? _metar;
  List<Map<String, String>> _taf = [];

  @override
  void initState() {
    super.initState();
    _fetch('EGLL');
  }

  Future<void> _fetch(String code) async {
    setState(() {
      _loading = true;
      _error = null;
      _metar = null;
      _taf = [];
    });

    try {
      final metar = await WeatherService.getDecodedMETAR(code);
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
        title: const Text('Flight Conditions'),
        backgroundColor: Colors.redAccent,
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ICAO search bar
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _icaoController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[800],
                      hintText: 'ICAO (e.g. EGLL)',
                      hintStyle:
                          const TextStyle(color: Colors.white60),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    onSubmitted: (v) => _fetch(v.trim()),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () =>
                      _fetch(_icaoController.text.trim()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.all(14),
                  ),
                  child: const Icon(Icons.search,
                      color: Colors.white),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Loading / error / data
            if (_loading)
              const Expanded(
                  child:
                      Center(child: CircularProgressIndicator()))
            else if (_error != null)
              Expanded(
                child: Center(
                  child: Text(
                    _error!,
                    style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 16),
                  ),
                ),
              )
            else if (_metar != null)
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      // Station Info
                      _sectionTitle('Station Info'),
                      Card(
                        color: Colors.grey[900],
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              _infoRow('ICAO', _metar!['icao']!),
                              _infoRow('Name', _metar!['name']!),
                              _infoRow(
                                  'Location', _metar!['location']!),
                              _infoRow(
                                  'Latitude', _metar!['latitude']!),
                              _infoRow(
                                  'Longitude', _metar!['longitude']!),
                            ],
                          ),
                        ),
                      ),

                      // METAR Observed
                      const Divider(color: Colors.white24),
                      _sectionTitle('METAR Observed'),
                      _infoRow('Time', _metar!['observed']!),

                      // Current Conditions
                      const Divider(color: Colors.white24),
                      _sectionTitle('Current Conditions'),
                      _infoRow('Temperature',
                          '${_metar!['temperature']}°C'),
                      _infoRow('Wind', _metar!['wind']!),
                      _infoRow('Visibility',
                          '${_metar!['visibility']} m'),
                      _infoRow('Clouds', _metar!['clouds']!),

                      // TAF Forecast
                      const Divider(color: Colors.white24),
                      _sectionTitle('TAF (next 6 periods)'),
                      SizedBox(
                        height: 180,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _taf.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 12),
                          itemBuilder: (_, i) {
                            final f = _taf[i];
                            return SizedBox(
                              width: 160,
                              child: Card(
                                color: Colors.grey[850],
                                shape:
                                    RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(8),
                                ),
                                child: Padding(
                                  padding:
                                      const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        f['time']!,
                                        style:
                                            const TextStyle(
                                          fontWeight:
                                              FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(
                                          height: 6),
                                      _miniRow(
                                          'Cat', f['category']!),
                                      _miniRow('T',
                                          '${f['temperature']}°C'),
                                      _miniRow('Wind', f['wind']!),
                                      _miniRow('Vis',
                                          '${f['visibility']}m'),
                                      const Spacer(),
                                      Text(
                                        f['clouds']!,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color:
                                                Colors.white70),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              )
            else
              const Expanded(child: SizedBox()),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Text(
              '$label:',
              style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(value,
                  style:
                      const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

  Widget _miniRow(String label, String value) =>
      Row(
        children: [
          Text(
            '$label:',
            style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white)),
          ),
        ],
      );

  Widget _sectionTitle(String text) =>
      Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 4),
        child: Text(
          text,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold),
        ),
      );
}
