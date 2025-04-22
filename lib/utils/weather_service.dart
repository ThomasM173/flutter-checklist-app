// lib/utils/weather_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  static const String _apiKey = '6ebb11e27af34b20899f9da2dc74b448';

  /// Fetches and flattens decoded METAR for [icao].
  /// Throws on non‑200 or no results.
  static Future<Map<String, String>> getDecodedMETAR(String icao) async {
    final uri = Uri.parse('https://api.checkwx.com/metar/$icao/decoded');
    final resp = await http.get(uri, headers: {'X-API-Key': _apiKey});

    if (resp.statusCode != 200) {
      throw Exception('METAR request failed: ${resp.statusCode}');
    }

    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    if ((body['results'] as int? ?? 0) == 0) {
      throw Exception('No METAR data for $icao');
    }

    final raw = body['data'][0] as Map<String, dynamic>;

    // geometry -> [lon, lat]
    final coords = raw['geometry']?['coordinates'] as List<dynamic>?;
    final lon = coords != null && coords.length >= 2 ? coords[0].toString() : '';
    final lat = coords != null && coords.length >= 2 ? coords[1].toString() : '';

    return {
      'icao'        : raw['station']?.toString()    ?? '',
      'name'        : raw['name']?.toString()       ?? '',
      'location'    : raw['location']?.toString()   ?? '',
      'latitude'    : lat,
      'longitude'   : lon,
      'observed'    : raw['observed']?.toString()   ?? '',
      'temperature' : raw['temperature']?['celsius']?.toString() ?? '',
      'wind'        : '${raw['wind']?['degrees'] ?? ''}° @ ${raw['wind']?['speed_kts'] ?? ''} kt',
      'visibility'  : raw['visibility']?['meters']?.toString() ?? '',
      'clouds'      : (raw['clouds'] is List && (raw['clouds'] as List).isNotEmpty)
                         ? (raw['clouds'] as List).first['text'].toString()
                         : 'Clear skies',
    };
  }

  /// Fetches up to 6 decoded TAF periods for [icao], flattened to strings.
  /// Throws on non‑200.
  static Future<List<Map<String, String>>> getForecast(String icao) async {
    final uri = Uri.parse('https://api.checkwx.com/taf/$icao/decoded');
    final resp = await http.get(uri, headers: {'X-API-Key': _apiKey});

    if (resp.statusCode != 200) {
      throw Exception('TAF request failed: ${resp.statusCode}');
    }

    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    if ((body['results'] as int? ?? 0) == 0) return [];

    final taf = body['data'][0] as Map<String, dynamic>;
    final periods = (taf['forecast'] as List<dynamic>? ?? []).take(6);

    return periods.map((item) {
      final m = item as Map<String, dynamic>;
      return {
        'time'        : m['timestamp']?['from']?.toString()      ?? '',
        'category'    : m['flight_category']?.toString()        ?? '',
        'temperature' : m['temperature']?['celsius']?.toString() ?? '',
        'wind'        : '${m['wind']?['degrees'] ?? ''}° @ ${m['wind']?['speed_kts'] ?? ''} kt',
        'visibility'  : m['visibility']?['meters']?.toString()   ?? '',
        'clouds'      : (m['clouds'] is List && (m['clouds'] as List).isNotEmpty)
                           ? (m['clouds'] as List).first['text'].toString()
                           : 'Clear skies',
      };
    }).toList();
  }
}
