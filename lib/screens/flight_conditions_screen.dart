import 'package:flutter/material.dart';
import '../utils/weather_service.dart';
import '../widget/bottom_nav_bar.dart';

class FlightConditionsScreen extends StatefulWidget {
  const FlightConditionsScreen({Key? key}) : super(key: key);

  @override
  State<FlightConditionsScreen> createState() => _FlightConditionsScreenState();
}

class _FlightConditionsScreenState extends State<FlightConditionsScreen> {
  final TextEditingController _icaoController = TextEditingController(text: 'EGLL');
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
        backgroundColor: Colors.purple,
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _icaoController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[900],
                      hintText: 'ICAO (e.g. EGLL)',
                      hintStyle: const TextStyle(color: Colors.white60),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (v) => _fetch(v.trim()),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _fetch(_icaoController.text.trim()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    padding: const EdgeInsets.all(14),
                  ),
                  child: const Icon(Icons.search, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_loading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_error != null)
              Expanded(
                child: Center(
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.purple, fontSize: 16),
                  ),
                ),
              )
            else if (_metar != null)
              Expanded(child: _buildData())
            else
              const Expanded(child: SizedBox()),
          ],
        ),
      ),
    );
  }

  Widget _buildData() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Station Info'),
          _dataCard([
            _infoRow('ICAO', _metar!['icao']),
            _infoRow('Name', _metar!['name']),
            _infoRow('Latitude', _metar!['latitude']),
            _infoRow('Longitude', _metar!['longitude']),
          ]),
          _sectionTitle('Observed'),
          _infoRow('Time', _metar!['observed']),
          _sectionTitle('Conditions'),
          _infoRow('Temperature', _metar!['temperature']),
          _infoRow('Wind', _metar!['wind']),
          _infoRow('Visibility', _metar!['visibility']),
          _infoRow('Clouds', _metar!['clouds']),
          _sectionTitle('TAF (next 6 periods)'),
          SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _taf.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                final f = _taf[i];
                return SizedBox(
                  width: 160,
                  child: Card(
                    color: Colors.grey[850],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(f['time']!, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 6),
                          Text('Cat: ${f['category']}', style: const TextStyle(color: Colors.white70)),
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
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 4),
        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      );

  Widget _infoRow(String label, String? value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Text('$label:', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            Expanded(child: Text(value ?? 'N/A', style: const TextStyle(color: Colors.white))),
          ],
        ),
      );

  Widget _dataCard(List<Widget> children) => Card(
        color: Colors.grey[900],
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Padding(padding: const EdgeInsets.all(12), child: Column(children: children)),
      );
}
