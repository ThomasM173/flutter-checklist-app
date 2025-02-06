import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  static Future<Map<String, String>> getMETAR(String airportCode) async {
    try {
      final response = await http.get(Uri.parse(
          "https://avwx.rest/api/metar/$airportCode?token=YOUR_API_KEY"));

      if (response.statusCode == 200) {
        Map<String, dynamic> jsonData = jsonDecode(response.body);
        return {
          "Raw METAR": jsonData["raw"] ?? "N/A",
          "Time": jsonData["time"]["dt"] ?? "Unknown",
          "Wind": "${jsonData["wind_direction"]["value"]}° at ${jsonData["wind_speed"]["value"]} knots",
          "Visibility": "${jsonData["visibility"]["value"]} km",
          "Conditions": jsonData["flight_category"] ?? "Unknown"
        };
      } else {
        return {"Error": "Failed to load METAR data"};
      }
    } catch (e) {
      return {"Error": "Network Error: $e"};
    }
  }
}
