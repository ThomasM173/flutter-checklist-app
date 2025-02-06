import 'package:flutter/material.dart';
import '../utils/weather_service.dart';

class FlightConditionsScreen extends StatefulWidget {
  const FlightConditionsScreen({super.key});

  @override
  _FlightConditionsScreenState createState() => _FlightConditionsScreenState();
}

class _FlightConditionsScreenState extends State<FlightConditionsScreen> {
  Map<String, String> weatherData = {"Status": "Fetching weather data..."};

  @override
  void initState() {
    super.initState();
    fetchWeather();
  }

  void fetchWeather() async {
    Map<String, String> data = await WeatherService.getMETAR("EGLF"); // Change ICAO code as needed
    setState(() {
      weatherData = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Flight Conditions"), backgroundColor: Colors.red),
      body: Center(
        child: weatherData.containsKey("Error")
            ? Text(weatherData["Error"]!, style: TextStyle(color: Colors.white))
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("📍 Airport: Farnborough (EGLF)", style: TextStyle(color: Colors.white, fontSize: 20)),
                  SizedBox(height: 10),
                  Text("⏰ Time: ${weatherData["Time"]}", style: TextStyle(color: Colors.white)),
                  Text("🌬 Wind: ${weatherData["Wind"]}", style: TextStyle(color: Colors.white)),
                  Text("🌫 Visibility: ${weatherData["Visibility"]}", style: TextStyle(color: Colors.white)),
                  Text("🌦 Conditions: ${weatherData["Conditions"]}", style: TextStyle(color: Colors.white)),
                  SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: fetchWeather,
                    child: Text("🔄 Refresh Weather"),
                  ),
                ],
              ),
      ),
    );
  }
}
