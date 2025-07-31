import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  static const String _token = 'dev-tE6NuvekB1AceDI4vB3xpHxplJ48LwTfAEqZxxg';
  static const String _baseUrl = 'https://avwx.rest/api';

  static Future<Map<String, String>> getDecodedMETAR(String icao) async {
    final uri = Uri.parse('$_baseUrl/metar/$icao?options=info,translate');
    final resp = await http.get(uri, headers: {
      'Authorization': 'Bearer $_token',
    });

    if (resp.statusCode != 200) {
      throw Exception('METAR error: ${resp.statusCode}');
    }

    final body = jsonDecode(resp.body) as Map<String, dynamic>;

    final station = body['station']?.toString() ?? '';
    final name = body['info']?['name']?.toString() ?? '';
    final coords = body['info']?['coordinates'] as List?;
    final latitude = coords != null && coords.length >= 2 ? coords[1].toString() : '';
    final longitude = coords != null && coords.length >= 2 ? coords[0].toString() : '';
    final observed = body['time']?['dt']?.toString() ?? '';
    final temp = body['temperature']?['value']?.toString() ?? '';
    final dewpoint = body['dewpoint']?['value']?.toString() ?? '';
    final humidity = body['humidity']?.toString() ?? '';
    final elevation = body['info']?['elevation_ft']?.toString() ?? '';
    final category = body['flight_rules']?.toString() ?? '';
    final raw = body['raw']?.toString() ?? '';
    final remarks = body['remarks']?.toString() ?? '';
    final translatedRemarks = (body['translations']?['remarks'] as List?)?.join('; ') ?? '';

    final windDir = body['wind']?['direction']?['value']?.toString() ?? '';
    final windSpeed = body['wind']?['speed']?['value']?.toString() ?? '';
    final windUnit = body['wind']?['speed']?['unit']?.toString() ?? 'kt';

    final visibilityVal = body['visibility']?['value']?.toString() ?? '';
    final visibilityUnit = body['visibility']?['unit']?.toString() ?? '';

    final altimeter = body['altimeter']?['value']?.toString() ?? '';
    final altUnit = body['altimeter']?['unit']?.toString() ?? 'hPa';

    String clouds = 'Clear skies';
    if (body['clouds'] is List && (body['clouds'] as List).isNotEmpty) {
      clouds = (body['clouds'] as List)
          .map((e) => e['repr']?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .join(', ');
    }

    return {
      'icao': station,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'observed': observed,
      'temperature': '$temp°C',
      'dewpoint': '$dewpoint°C',
      'humidity': '$humidity%',
      'wind': '$windDir° @ $windSpeed $windUnit',
      'visibility': '$visibilityVal $visibilityUnit',
      'clouds': clouds,
      'elevation': '$elevation ft',
      'category': category,
      'altimeter': '$altimeter $altUnit',
      'raw': raw,
      'remarks': remarks.isNotEmpty ? remarks : 'None',
      'translatedRemarks': translatedRemarks.isNotEmpty ? translatedRemarks : 'None available',
      'runway': 'Not Reported',
    };
  }

  static Future<List<Map<String, String>>> getForecast(String icao) async {
    final uri = Uri.parse('$_baseUrl/taf/$icao?options=translate');
    final resp = await http.get(uri, headers: {'Authorization': 'Bearer $_token'});

    if (resp.statusCode != 200) {
      throw Exception('TAF error: ${resp.statusCode}');
    }

    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    final periods = (body['forecast'] as List<dynamic>? ?? []).take(6);

    return periods.map((item) {
      final m = item as Map<String, dynamic>;

      final start = m['start_time']?['dt']?.toString() ?? m['time']?['from']?.toString() ?? '';
      final end = m['end_time']?['dt']?.toString() ?? m['time']?['to']?.toString() ?? '';
      final cat = m['flight_rules']?.toString() ?? m['flight_category']?.toString() ?? '';

      return {
        'time': '$start → $end',
        'category': cat,
      };
    }).toList();
  }

  static String _firFromIcao(String icao) {
    if (icao.startsWith('EG')) return 'EGTT'; // UK
    if (icao.startsWith('LF')) return 'LFFF'; // France
    if (icao.startsWith('EH')) return 'EHAA'; // Amsterdam
    return ''; // Unknown / unsupported FIR
  }

  static Future<List<Map<String, String>>> getHazards(String icao) async {
    final List<Map<String, String>> hazards = [];

    final endpoints = ['pirep', 'gairmet'];
    for (final endpoint in endpoints) {
      final uri = Uri.parse('$_baseUrl/$endpoint/$icao');
      try {
        final resp = await http.get(uri, headers: {'Authorization': 'Bearer $_token'});
        if (resp.statusCode != 200) continue;

        final data = jsonDecode(resp.body);
        if (data is List) {
          for (final entry in data) {
            hazards.add({
              'type': endpoint.toUpperCase(),
              'raw': entry['raw']?.toString() ?? 'Unknown',
              'station': entry['station']?.toString() ?? 'N/A',
              'time': entry['time']?['dt']?.toString() ?? '',
            });
          }
        }
      } catch (_) {
        // skip on error
      }
    }

    // Now fetch SIGMET using FIR
    final fir = _firFromIcao(icao);
    if (fir.isNotEmpty) {
      final uri = Uri.parse('$_baseUrl/sigmet/$fir');
      try {
        final resp = await http.get(uri, headers: {'Authorization': 'Bearer $_token'});
        if (resp.statusCode == 200) {
          final data = jsonDecode(resp.body);
          if (data is List) {
            for (final entry in data) {
              hazards.add({
                'type': 'SIGMET',
                'raw': entry['raw']?.toString() ?? 'Unknown',
                'station': entry['station']?.toString() ?? 'N/A',
                'time': entry['time']?['dt']?.toString() ?? '',
              });
            }
          }
        }
      } catch (_) {
        // skip on error
      }
    }

    return hazards;
  }

  static Future<Map<String, dynamic>> getStationInfo(String icao) async {
    final uri = Uri.parse('$_baseUrl/station/$icao');
    final resp = await http.get(uri, headers: {'Authorization': 'Bearer $_token'});

    if (resp.statusCode != 200) {
      throw Exception('Station info error: ${resp.statusCode}');
    }

    final body = jsonDecode(resp.body) as Map<String, dynamic>;

    final runways = (body['runways'] as List?)
        ?.map((r) => r['ident1']?.toString() ?? '')
        .where((r) => r.isNotEmpty)
        .toList();

    return {
      'city': body['city']?.toString() ?? '',
      'state': body['state']?.toString() ?? '',
      'country': body['country']?.toString() ?? '',
      'reporting': body['reporting']?.toString() ?? '',
      'runways': runways ?? [],
    };
  }
}
