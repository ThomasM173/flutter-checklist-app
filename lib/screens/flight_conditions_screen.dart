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
  Map<String, dynamic>? _stationInfo;
  List<Map<String, String>> _hazards = [];

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
      _stationInfo = null;
      _hazards = [];
    });
    try {
      final metar = await WeatherService.getDecodedMETAR(code);
      final taf = await WeatherService.getForecast(code);
      final stationInfo = await WeatherService.getStationInfo(code);
      final hazards = await WeatherService.getHazards(code);

      setState(() {
        _metar = metar;
        _taf = taf;
        _stationInfo = stationInfo;
        _hazards = hazards;
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
      backgroundColor: Colors.white,
      drawer: Drawer(
        child: ListView(
          children: const [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.lightBlue),
              child: Text('Menu', style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(leading: Icon(Icons.home), title: Text('Home')),
            ListTile(leading: Icon(Icons.settings), title: Text('Settings')),
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFB0E0E6), Color(0xFF00BFFF)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        title: const Text('Flight Conditions', style: TextStyle(color: Colors.black)),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _icaoController,
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[200],
                      hintText: 'ICAO (e.g. EGLL)',
                      hintStyle: const TextStyle(color: Colors.black54),
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
                    backgroundColor: Colors.lightBlueAccent,
                    padding: const EdgeInsets.all(14),
                  ),
                  child: const Icon(Icons.search, color: Colors.black),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_loading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_error != null)
              Expanded(
                child: Center(
                  child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 16)),
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
          _infoRow('ICAO', _metar!['icao'], Icons.flight_takeoff),
          _infoRow('Name', _metar!['name'], Icons.location_city),
          _infoRow('Latitude', _metar!['latitude'], Icons.my_location),
          _infoRow('Longitude', _metar!['longitude'], Icons.my_location),
          _infoRow('Elevation', _metar!['elevation'], Icons.terrain),
          if (_stationInfo != null) ...[
            _infoRow('City', _stationInfo!['city'], Icons.location_city),
            _infoRow('State', _stationInfo!['state'], Icons.flag),
            _infoRow('Country', _stationInfo!['country'], Icons.public),
            _infoRow('Reporting', _stationInfo!['reporting'], Icons.info_outline),
            _infoRow('Runways', (_stationInfo!['runways'] as List).join(', '), Icons.run_circle),
          ],
        ]),
        _sectionTitle('Observed'),
        _infoRow('Time', _metar!['observed'], Icons.access_time),
        _sectionTitle('Conditions'),
        _dataCard([
          _infoRow('Temperature', _metar!['temperature'], Icons.thermostat),
          _infoRow('Dew Point', _metar!['dewpoint'], Icons.grain),
          _infoRow('Humidity', _metar!['humidity'], Icons.water_drop),
          _infoRow('Wind', _metar!['wind'], Icons.air),
          _infoRow('Visibility', _metar!['visibility'], Icons.remove_red_eye),
          _infoRow('Clouds', _metar!['clouds'], Icons.cloud),
          _infoRow('Flight Category', _metar!['category'], Icons.flight),
          _infoRow('Altimeter', _metar!['altimeter'], Icons.speed),
          _infoRow('Runway Condition', _metar!['runway'], Icons.run_circle),
        ]),
        _sectionTitle('Raw METAR & Remarks'),
        _infoRow('METAR', _metar!['raw'], Icons.code),
        _infoRow('Remarks', _metar!['remarks'], Icons.comment),
        _infoRow('Translated Remarks', _metar!['translatedRemarks'], Icons.translate),
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
                  color: Colors.grey[200],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(_getCategoryIcon(f['category'] ?? ''), color: Colors.black54),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                f['time']!,
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text('Cat: ${f['category']}', style: const TextStyle(color: Colors.black87)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        if (_hazards.isNotEmpty) ...[
          _sectionTitle('Hazards (PIREPs / SIGMETs / G-AIRMETs)'),
          Column(
            children: _hazards.map((h) => _buildHazardCard(h)).toList(),
          ),
        ],
      ],
    ),
  );
}

Widget _buildHazardCard(Map<String, String> hazard) {
  // Typical keys based on your WeatherService hazard data:
  // type, station, raw, time, altitude, severity, conditions, flightLevels, phenomenon, movement, intensity, etc.
  IconData icon;
  switch (hazard['type']?.toUpperCase()) {
    case 'PIREPS':
      icon = Icons.flight;
      break;
    case 'SIGMET':
      icon = Icons.warning;
      break;
    case 'G-AIRMET':
      icon = Icons.shield;
      break;
    default:
      icon = Icons.report_problem;
  }

  return Card(
    color: Colors.grey[100],
    margin: const EdgeInsets.symmetric(vertical: 6),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.black54),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${hazard['type']} @ ${hazard['station']}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              if (hazard['time'] != null)
                Text(hazard['time']!, style: const TextStyle(color: Colors.black54)),
            ],
          ),
          const SizedBox(height: 8),
          if (hazard['severity'] != null)
            _infoRow('Severity', hazard['severity'], Icons.priority_high),
          if (hazard['altitude'] != null)
            _infoRow('Altitude', hazard['altitude'], Icons.height),
          if (hazard['flightLevels'] != null)
            _infoRow('Flight Levels', hazard['flightLevels'], Icons.flight),
          if (hazard['conditions'] != null)
            _infoRow('Conditions', hazard['conditions'], Icons.cloud_queue),
          if (hazard['phenomenon'] != null)
            _infoRow('Phenomenon', hazard['phenomenon'], Icons.flash_on),
          if (hazard['movement'] != null)
            _infoRow('Movement', hazard['movement'], Icons.directions_run),
          if (hazard['intensity'] != null)
            _infoRow('Intensity', hazard['intensity'], Icons.speed),
          if (hazard['raw'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('Raw: ${hazard['raw']}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
            ),
        ],
      ),
    ),
  );
}


  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 4),
        child: Text(text, style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
      );

  Widget _infoRow(String label, String? value, IconData icon) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.black54),
            const SizedBox(width: 8),
            Text('$label:', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
            const SizedBox(width: 6),
            Expanded(child: Text(value ?? 'N/A', style: const TextStyle(color: Colors.black))),
          ],
        ),
      );

  Widget _dataCard(List<Widget> children) => Card(
        color: Colors.grey[100],
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Padding(padding: const EdgeInsets.all(12), child: Column(children: children)),
      );

  IconData _getCategoryIcon(String category) {
    switch (category.toUpperCase()) {
      case 'VFR':
        return Icons.wb_sunny;
      case 'MVFR':
        return Icons.cloud_queue;
      case 'IFR':
        return Icons.foggy;
      case 'LIFR':
        return Icons.thunderstorm;
      default:
        return Icons.help_outline;
    }
  }
}
