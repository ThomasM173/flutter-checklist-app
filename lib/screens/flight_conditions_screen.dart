import 'package:flutter/material.dart';
import '../utils/weather_service.dart';
import '../widget/bottom_nav_bar.dart';

class FlightConditionsScreen extends StatefulWidget {
  const FlightConditionsScreen({super.key});

  @override
  State<FlightConditionsScreen> createState() => _FlightConditionsScreenState();
}

class _FlightConditionsScreenState extends State<FlightConditionsScreen> {
  final TextEditingController _icaoController = TextEditingController(text: "EGLF");
  Map<String, dynamic> weather = {};
  List<dynamic> forecast = [];
  bool isLoading = true;
  String? error;

  void fetchWeather(String code) async {
    setState(() {
      isLoading = true;
      error = null;
    });

    final data = await WeatherService.getDecodedMETAR(code.toUpperCase());
    final forecastData = await WeatherService.getForecast(code.toUpperCase());

    setState(() {
      isLoading = false;
      if (data.containsKey("error")) {
        error = data["error"];
        weather = {};
        forecast = [];
      } else {
        weather = data;
        forecast = forecastData;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    fetchWeather(_icaoController.text);
  }

  Widget buildTile(String title, String? value, IconData? icon) {
    return value == null
        ? const SizedBox()
        : Card(
            color: Colors.grey[850],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (icon != null) Icon(icon, color: Colors.white70, size: 20),
                      if (icon != null) const SizedBox(width: 6),
                      Text(title, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(value, style: const TextStyle(color: Colors.white, fontSize: 16)),
                ],
              ),
            ),
          );
  }

  Widget buildForecastCard(dynamic item) {
    return Card(
      color: Colors.blueGrey[900],
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item['time'] ?? 'N/A',
              style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text("Flight Cat: ${item['category'] ?? 'N/A'}", style: const TextStyle(color: Colors.white)),
            Text("Wind: ${item['wind_speed']}kt ${item['wind_dir']}", style: const TextStyle(color: Colors.white)),
            Text("Visibility: ${item['visibility']}m", style: const TextStyle(color: Colors.white)),
            Text("Clouds: ${item['clouds'] ?? 'None'}", style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Flight Conditions"), backgroundColor: Colors.red),
      backgroundColor: Colors.black,
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
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'ICAO Code (e.g. EGLL)',
                      labelStyle: const TextStyle(color: Colors.white70),
                      border: const OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => fetchWeather(_icaoController.text),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text("Get Weather"),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (isLoading)
              const CircularProgressIndicator()
            else if (error != null)
              Text(error!, style: const TextStyle(color: Colors.redAccent))
            else
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("📍 ${weather["station"] ?? "Unknown"}",
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          buildTile("Time", weather["observed"], Icons.access_time),
                          buildTile("Flight Category", weather["flight_category"], Icons.flight),
                          buildTile("Temperature", "${weather["temperature"]["celsius"]} °C", Icons.thermostat),
                          buildTile("Dewpoint", "${weather["dewpoint"]["celsius"]} °C", Icons.water_drop),
                          buildTile("Humidity", weather["humidity"]?.toString(), Icons.opacity),
                          buildTile("Wind", "${weather["wind"]["degrees"]}° at ${weather["wind"]["speed_kts"]} kt", Icons.air),
                          buildTile("Visibility", "${weather["visibility"]["meters"]} m", Icons.visibility),
                          buildTile("Altimeter", "${weather["barometer"]["hpa"]} hPa", Icons.compress),
                          buildTile("Clouds", weather["clouds"]?[0]?['text'], Icons.cloud),
                          buildTile("Remarks", weather["remarks"], Icons.note),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text("Forecast (Next 6 Hours):",
                        style: TextStyle(fontSize: 18, color: Colors.white70, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 140,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: forecast.length,
                        itemBuilder: (context, index) => buildForecastCard(forecast[index]),
                      ),
                    )
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
