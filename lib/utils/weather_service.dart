// lib/utils/weather_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  // Replace with your AVWX token
  static const String _token = 'YOUR_AVWX_TOKEN';
  static const String _baseUrl = 'https://avwx.rest/api';

  /// Fetches and flattens METAR data for [icao].
  /// Throws on non-200 or no-data.
  static Future<Map<String, String>> getDecodedMETAR(String icao) async {
    final uri = Uri.parse('$_baseUrl/metar/$icao?options=info');
    final resp = await http.get(uri, headers: {'Authorization': _token});
    if (resp.statusCode != 200) {
      throw Exception('METAR error: ${resp.statusCode}');
    }

    final body = jsonDecode(resp.body) as Map<String, dynamic>;

    // Station & metadata
    final station  = (body['station']  as String?) ?? '';
    final name     = (body['info']?['name'] as String?) ?? '';
    final coords   = body['info']?['coordinates'] as List<dynamic>?; 
    final latitude = coords != null && coords.length >= 2 ? coords[1].toString() : '';
    final longitude=
        coords != null && coords.length >= 2 ? coords[0].toString() : '';

    // Time
    final observed = (body['time']?['dt'] as String?) ?? '';

    // Conditions
    final tempVal  = body['temperature']?['value']?.toString() ?? '';
    final windDeg  = body['wind']?['value']?.toString()         ?? '';
    final windKts  = body['wind']?['speed']?.toString()         ?? '';
    final windUnit = (body['wind']?['unit_speed'] as String?)    ?? 'kt';
    final visibilityVal = body['visibility']?['value']?.toString() ?? '';
    final visibilityUnit= (body['visibility']?['unit'] as String?)   ?? '';

    // Clouds array → e.g. "FEW,", "SCT,"
    String clouds = 'Clear skies';
    if (body['clouds'] is List && (body['clouds'] as List).isNotEmpty) {
      clouds = (body['clouds'] as List)
          .map((c) => c['repr'] as String? ?? '')
          .where((s) => s.isNotEmpty)
          .join(', ');
    }

    return {
      'icao'       : station,
      'name'       : name,
      'latitude'   : latitude,
      'longitude'  : longitude,
      'observed'   : observed,
      'temperature': '$tempVal°C',
      'wind'       : '$windDeg° @ $windKts $windUnit',
      'visibility' : '$visibilityVal $visibilityUnit',
      'clouds'     : clouds,
    };
  }

  /// Fetches up to 6 decoded TAF periods for [icao].
  /// Throws on non-200.
  static Future<List<Map<String, String>>> getForecast(String icao) async {
    final uri = Uri.parse('$_baseUrl/taf/$icao?options=');
    final resp = await http.get(uri, headers: {'Authorization': _token});
    if (resp.statusCode != 200) {
      throw Exception('TAF error: ${resp.statusCode}');
    }

    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    final periods = (body['forecast'] as List<dynamic>? ?? []).take(6);

    return periods.map((item) {
      final m = item as Map<String, dynamic>;

      // AVWX TAF uses start_time/end_time
      final start = (m['start_time'] as String?) 
                      ?? (m['time']?['from'] as String?) 
                      ?? '';
      final end   = (m['end_time']   as String?) 
                      ?? (m['time']?['to']   as String?) 
                      ?? '';
      final cat   = (m['flight_rules'] as String?) 
                      ?? (m['flight_category'] as String?) 
                      ?? '';

      return {
        'time'    : '$start → $end',
        'category': cat,
      };
    }).toList();
  }
}
