import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  static Future<Map<String, dynamic>> getDecodedMETAR(String airportCode) async {
    final apiKey = '6ebb11e27af34b20899f9da2dc74b448';
    final url = 'https://api.checkwx.com/metar/$airportCode/decoded';

    final response = await http.get(
      Uri.parse(url),
      headers: {'X-API-Key': apiKey},
    );

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      if (jsonData['results'] > 0) {
        return jsonData['data'][0]; // Decoded METAR data
      } else {
        return {"error": "No METAR data available for $airportCode"};
      }
    } else {
      return {"error": "Failed to load METAR data: ${response.statusCode}"};
    }
  }

  static Future<List<Map<String, dynamic>>> getForecast(String airportCode) async {
    final apiKey = '6ebb11e27af34b20899f9da2dc74b448';
    final url = 'https://api.checkwx.com/taf/$airportCode/decoded';

    final response = await http.get(
      Uri.parse(url),
      headers: {'X-API-Key': apiKey},
    );

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      if (jsonData['results'] > 0 && jsonData['data'].isNotEmpty) {
        final taf = jsonData['data'][0];
        final forecastList = taf['forecast'] as List<dynamic>;

        // Only return the first 6 forecast periods
        return forecastList.take(6).map((item) {
          return {
            'time': item['timestamp']?['from'] ?? 'N/A',
            'category': item['flight_category'] ?? 'N/A',
            'wind_speed': item['wind']?['speed_kts']?.toString() ?? '0',
            'wind_dir': item['wind']?['degrees']?.toString() ?? '--',
            'visibility': item['visibility']?['meters']?.toString() ?? '--',
            'clouds': item['clouds'] != null && item['clouds'].isNotEmpty
                ? item['clouds'][0]['text']
                : 'Clear',
          };
        }).toList();
      } else {
        return [];
      }
    } else {
      return [];
    }
  }
}
