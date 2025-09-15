import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/weather_boundaries.dart';

class WeatherService {
  static const String _token = 'dev-tE6NuvekB1AceDI4vB3xpHxplJ48LwTfAEqZxxg';
  static const String _baseUrl = 'https://avwx.rest/api';

  static Future<Map<String, dynamic>> getDecodedMETAR(String icao) async {
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

      // 🔑 Parse them into doubles
    final oat = double.tryParse(temp);
    final dew = double.tryParse(dewpoint);

    // 🔑 Apply boundary rule here
    bool carbIcing = false;
    if (oat != null && dew != null) {
      carbIcing = WeatherBoundaries.carbIcingRisk(oat, dew);
    }


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
      'Air Temperature': oat,
      'Dewpoint': dew,
      'carbIcingRisk': carbIcing,
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
//i dont think this is used
  static Future<List<Map<String, String>>> getHazards(String icao) async {
    final List<Map<String, String>> hazards = [];

    // First, get the station coordinates to use for AIR/SIGMET lookup
    double latitude = 51.5074; // Default to London
    double longitude = -0.1278; // Defult to London
    
    try {
      // Get station info to get accurate coordinates
      final stationInfoUri = Uri.parse('$_baseUrl/station/$icao');
      final stationResp = await http.get(stationInfoUri, headers: {'Authorization': 'Bearer $_token'});
      
      if (stationResp.statusCode == 200) {
        final stationData = jsonDecode(stationResp.body) as Map<String, dynamic>;
        final coords = stationData['location'] as List?;
        if (coords != null && coords.length >= 2) {
          latitude = coords[1]?.toDouble() ?? 51.5074;
          longitude = coords[0]?.toDouble() ?? -0.1278;
          print('Using coordinates for $icao: $latitude, $longitude');
        }
      }
    } catch (e) {
      print('Error fetching station coordinates: $e');
    }

    // Fetch PIREPs
    try {
      final pirepUri = Uri.parse('$_baseUrl/pirep/$icao');
      final pirepResp = await http.get(pirepUri, headers: {'Authorization': 'Bearer $_token'});
      if (pirepResp.statusCode == 200) {
        final data = jsonDecode(pirepResp.body);
        if (data is List) {
          for (final entry in data) {
            final aircraft = (entry['aircraft'] is Map) ? entry['aircraft']['type']?.toString() ?? 'Unknown' : 'Unknown';
            final altitude = (entry['altitude'] is Map) ? entry['altitude']['repr']?.toString() ?? 'N/A' : 'N/A';
            final icing = (entry['icing'] is Map) ? entry['icing']['severity']?.toString() ?? 'None' : 'None';
            final turbulence = (entry['turbulence'] is Map) ? entry['turbulence']['severity']?.toString() ?? 'None' : 'None';
            final wxCodes = (entry['wx_codes'] is List) ? (entry['wx_codes'] as List).map((w) => w['value']?.toString() ?? '').where((w) => w != null && w.isNotEmpty).join(', ') : 'None';
            
            hazards.add({
              'type': 'PIREP',
              'raw': entry['raw']?.toString() ?? 'Unknown',
              'station': entry['station']?.toString() ?? 'N/A',
              'time': entry['time']?['dt']?.toString() ?? 'N/A',
              'aircraft': aircraft,
              'altitude': altitude,
              'severity': icing != 'None' ? icing : turbulence != 'None' ? turbulence : 'None',
              'conditions': wxCodes,
              'phenomenon': icing != 'None' ? 'ICING' : turbulence != 'None' ? 'TURBULENCE' : 'None',
            });
          }
        }
      } else {
        print('PIREP API returned status: ${pirepResp.statusCode}');
      }
    } catch (e) {
      print('Error fetching PIREP: $e');
    }

    // Fetch combined AIRMET/SIGMET data using the actual airport coordinates
    try {
      final airSigmetUri = Uri.parse('$_baseUrl/airsigmet/$latitude,$longitude');
      print('Fetching AIR/SIGMET for $icao from: $airSigmetUri');
      final airSigmetResp = await http.get(airSigmetUri, headers: {'Authorization': 'Bearer $_token'});
      print('AIR/SIGMET API response status: ${airSigmetResp.statusCode}');
      
      if (airSigmetResp.statusCode == 200) {
        final data = jsonDecode(airSigmetResp.body);
        print('AIR/SIGMET API response data type: ${data.runtimeType}');
        
        // The API returns a Map with 'reports' key containing the actual data
        if (data is Map && data.containsKey('reports')) {
          final reports = data['reports'];
          if (reports is List) {
            print('AIR/SIGMET reports contains ${reports.length} items');
            for (final entry in reports) {
              final startTime = entry['start_time']?['dt']?.toString() ?? '';
              final endTime = entry['end_time']?['dt']?.toString() ?? '';
              final altitude = entry['altitude'] is Map ? entry['altitude']['repr']?.toString() ?? 'N/A' : 'N/A';
              final phenomenon = entry['phenomenon']?.toString() ?? 'Unknown';
              final severity = entry['severity']?.toString() ?? 'Moderate';
              final bulletin = entry['bulletin']?.toString() ?? '';
              
              // Determine if this is AIRMET or SIGMET based on bulletin or other criteria
              final type = bulletin.contains('SIGMET') ? 'SIGMET' : 'AIRMET';
              
              hazards.add({
                'type': type,
                'raw': entry['raw']?.toString() ?? 'Unknown',
                'station': entry['station']?.toString() ?? 'N/A',
                'time': startTime.isNotEmpty && endTime.isNotEmpty ? '$startTime → $endTime' : 'N/A',
                'altitude': altitude,
                'phenomenon': phenomenon,
                'severity': severity,
                'conditions': phenomenon,
              });
            }
          }
        } else {
          print('AIR/SIGMET API returned unexpected format');
          print('Data keys: ${data.keys}');
        }
      } else {
        print('AIR/SIGMET API returned status: ${airSigmetResp.statusCode}');
        print('Response body: ${airSigmetResp.body}');
      }
    } catch (e) {
      print('Error fetching AIR/SIGMET: $e');
    }

    // NOTAM endpoint is not included in the subscription - skipping NOTAM functionality
    print('NOTAM endpoint not available in current subscription - skipping NOTAM hazard type');

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
