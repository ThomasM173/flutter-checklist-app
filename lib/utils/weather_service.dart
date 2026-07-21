import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/weather_boundaries.dart';

class WeatherService {
  static const String _token = 'dev-PdSRG3eHIS_NXKZD5jHtvACnHsmN_Y1W4aLnhNY';
  static const String _baseUrl = 'https://avwx.rest/api';

  static dynamic _extractValue(dynamic obj) {
    if (obj is Map<String, dynamic>) {
      return obj['value'];
    }
    if (obj is Map) {
      return obj['value'];
    }
    return obj;
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.replaceAll('%', '').trim());
    if (value is Map) return _parseDouble(_extractValue(value));
    return null;
  }

  static String _parseString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is num) return value.toString();
    if (value is Map) return _extractValue(value)?.toString() ?? '';
    return value.toString();
  }

  static String _formatNumber(double value) {
    if (value == value.toInt().toDouble()) {
      return value.toInt().toString();
    }
    return value.toString();
  }

  static Map<String, dynamic> parseMETARBody(Map<String, dynamic> body) {
    final station = body['station']?.toString() ?? '';
    final name = body['info']?['name']?.toString() ?? '';
    final coords = body['info']?['coordinates'] as List?;
    final latitude = coords != null && coords.length >= 2 ? coords[1].toString() : '';
    final longitude = coords != null && coords.length >= 2 ? coords[0].toString() : '';
    final observed = body['time']?['dt']?.toString() ?? '';
    final temp = _parseString(body['temperature'] != null ? _extractValue(body['temperature']) : null);
    final dewpoint = _parseString(body['dewpoint'] != null ? _extractValue(body['dewpoint']) : null);

    final humidityRaw = body['relative_humidity'] != null
        ? _parseDouble(body['relative_humidity'])
        : body['humidity'] != null
            ? _parseDouble(body['humidity'])
            : null;
    final humidityVal = humidityRaw != null ? humidityRaw * 100 : null;
    final humidity = humidityVal != null ? '${humidityVal.round()}%' : '';

    final elevation = body['info']?['elevation_ft']?.toString() ?? '';
    final category = body['flight_rules']?.toString() ?? '';
    final raw = body['raw']?.toString() ?? '';
    final remarks = body['remarks']?.toString() ?? '';

    final translatedRemarksValue = body['translations']?['remarks'];
    String translatedRemarks = '';
    if (translatedRemarksValue is List) {
      translatedRemarks = translatedRemarksValue.join('; ');
    } else if (translatedRemarksValue is String) {
      translatedRemarks = translatedRemarksValue;
    } else if (translatedRemarksValue is Map) {
      translatedRemarks = translatedRemarksValue.entries.map((entry) => '${entry.key}: ${entry.value}').join('; ');
    }

    final windDirValue = _parseDouble(body['wind_direction'] ?? body['wind']?['direction']);
    final windSpeedValue = _parseDouble(body['wind_speed'] ?? body['wind']?['speed']);
    final windGustsValue = _parseDouble(body['wind_gust'] ?? body['wind']?['gusts']);
    final windDir = windDirValue != null ? windDirValue.round().toString().padLeft(3, '0') : '';
    final windSpeed = windSpeedValue != null ? _formatNumber(windSpeedValue) : '';
    final windUnit = body['units']?['wind_speed']?.toString() ?? body['wind']?['speed']?['unit']?.toString() ?? 'kt';
    final windGusts = windGustsValue != null ? _formatNumber(windGustsValue) : '';

    final visibilityVal = _parseDouble(body['visibility'])?.toString() ?? '';
    final visibilityUnit = body['visibility']?['unit']?.toString() ?? '';

    final altimeter = body['altimeter'] != null ? _extractValue(body['altimeter'])?.toString() ?? '' : '';
    final altUnit = body['altimeter']?['unit']?.toString() ?? 'hPa';

    final oat = double.tryParse(temp);
    final dew = double.tryParse(dewpoint);
    final humidityPercent = humidityVal != null ? humidityVal : null;
    final windSpeedVal = windSpeedValue;
    final windGustsVal = windGustsValue;
    final visibilityKm = visibilityUnit == 'm' ? (double.tryParse(visibilityVal) ?? 0) / 1000 : double.tryParse(visibilityVal) ?? 0;

    bool carbIcing = false;
    if (oat != null && dew != null) {
      carbIcing = WeatherBoundaries.carbIcingRisk(oat, dew);
    }

    bool tempLowRisk = false;
    bool tempHighRisk = false;
    if (oat != null) {
      tempLowRisk = WeatherBoundaries.tempRiskLow(oat);
      tempHighRisk = WeatherBoundaries.tempRiskHigh(oat);
    }

    bool humidityHighRisk = false;
    bool humidityLowRisk = false;
    if (humidityPercent != null) {
      humidityHighRisk = WeatherBoundaries.humidityRiskHigh(humidityPercent);
      humidityLowRisk = WeatherBoundaries.humidityRiskLow(humidityPercent);
    }

    bool windRisk = WeatherBoundaries.windRisk(windSpeedVal, windGustsVal);

    final phenomenaRisks = WeatherBoundaries.weatherPhenomenaRisk(raw, translatedRemarks);

    double? ceilingFt;
    if (body['clouds'] is List && (body['clouds'] as List).isNotEmpty) {
      final clouds = body['clouds'] as List;
      for (final cloud in clouds) {
        final type = cloud['type']?.toString() ?? '';
        if (type == 'BKN' || type == 'OVC') {
          final altFt = cloud['altitude'] != null ? double.tryParse(_extractValue(cloud['altitude'])?.toString() ?? '') : null;
          if (altFt != null && (ceilingFt == null || altFt < ceilingFt)) {
            ceilingFt = altFt;
          }
        }
      }
    }

    bool vfrLimitsRisk = WeatherBoundaries.vfrLimitsRisk(visibilityKm, ceilingFt, category);

    bool terrainRisk = WeatherBoundaries.terrainRisk(station, latitude != '' ? double.tryParse(latitude) : null, longitude != '' ? double.tryParse(longitude) : null);

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
      'tempLowRisk': tempLowRisk,
      'tempHighRisk': tempHighRisk,
      'humidity': humidity,
      'humidityValue': humidityPercent,
      'humidityHighRisk': humidityHighRisk,
      'humidityLowRisk': humidityLowRisk,
      'wind': '$windDir° @ $windSpeed $windUnit',
      'windSpeed': windSpeedValue,
      'windGusts': windGustsValue,
      'windRisk': windRisk,
      'visibility': '$visibilityVal $visibilityUnit',
      'clouds': clouds,
      'elevation': '$elevation ft',
      'category': category,
      'altimeter': '$altimeter $altUnit',
      'raw': raw,
      'remarks': remarks.isNotEmpty ? remarks : 'None',
      'translatedRemarks': translatedRemarks.isNotEmpty ? translatedRemarks : 'None available',
      'phenomenaRisks': phenomenaRisks,
      'vfrLimitsRisk': vfrLimitsRisk,
      'terrainRisk': terrainRisk,
      'runway': 'Not Reported',
    };
  }

  static Future<Map<String, dynamic>> getDecodedMETAR(String icao) async {
    final uri = Uri.parse('$_baseUrl/metar/$icao?options=info,translate');
    final resp = await http.get(uri, headers: {
      'Authorization': 'Token $_token',
    });

    if (resp.statusCode != 200) {
      throw Exception('METAR error: ${resp.statusCode}');
    }

    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    return parseMETARBody(body);
  }

  static Future<List<Map<String, String>>> getForecast(String icao) async {
    final uri = Uri.parse('$_baseUrl/taf/$icao?options=translate');
    final resp = await http.get(uri, headers: {'Authorization': 'Token $_token'});

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


//i dont think this is used
  static Future<List<Map<String, String>>> getHazards(String icao) async {
    final List<Map<String, String>> hazards = [];

    // First, get the station coordinates to use for AIR/SIGMET lookup
    double latitude = 51.5074; // Default to London
    double longitude = -0.1278; // Defult to London
    
    try {
      // Get station info to get accurate coordinates
      final stationInfoUri = Uri.parse('$_baseUrl/station/$icao');
      final stationResp = await http.get(stationInfoUri, headers: {'Authorization': 'Token $_token'});
      
      if (stationResp.statusCode == 200) {
        final stationData = jsonDecode(stationResp.body) as Map<String, dynamic>;
        final coords = stationData['location'] as List?;
        if (coords != null && coords.length >= 2) {
          latitude = coords[1]?.toDouble() ?? 51.5074;
          longitude = coords[0]?.toDouble() ?? -0.1278;
        }
      }
    } catch (e) {
      // Error fetching station coordinates
    }

    // Fetch PIREPs
    try {
      final pirepUri = Uri.parse('$_baseUrl/pirep/$icao');
      final pirepResp = await http.get(pirepUri, headers: {'Authorization': 'Token $_token'});
      if (pirepResp.statusCode == 200) {
        final data = jsonDecode(pirepResp.body);
        if (data is List) {
          for (final entry in data) {
            final aircraft = (entry['aircraft'] is Map) ? entry['aircraft']['type']?.toString() ?? 'Unknown' : 'Unknown';
            final altitude = (entry['altitude'] is Map) ? entry['altitude']['repr']?.toString() ?? 'N/A' : 'N/A';
            final icing = (entry['icing'] is Map) ? entry['icing']['severity']?.toString() ?? 'None' : 'None';
            final turbulence = (entry['turbulence'] is Map) ? entry['turbulence']['severity']?.toString() ?? 'None' : 'None';
            final wxCodes = (entry['wx_codes'] is List) ? (entry['wx_codes'] as List).where((w) => w != null).map((w) => _extractValue(w)?.toString() ?? '').where((w) => w.isNotEmpty).join(', ') : 'None';
            
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
      }
    } catch (e) {
      // Error fetching PIREP
    }

    // Fetch combined AIRMET/SIGMET data using the actual airport coordinates
    try {
      final airSigmetUri = Uri.parse('$_baseUrl/airsigmet/$latitude,$longitude');
      final airSigmetResp = await http.get(airSigmetUri, headers: {'Authorization': 'Token $_token'});

      if (airSigmetResp.statusCode == 200) {
        final data = jsonDecode(airSigmetResp.body);

        // The API returns a Map with 'reports' key containing the actual data
        if (data is Map && data.containsKey('reports')) {
          final reports = data['reports'];
          if (reports is List) {
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
        }
      }
    } catch (e) {
      // Error fetching AIR/SIGMET
    }

    // NOTAM endpoint is not included in the subscription - skipping NOTAM functionality

    return hazards;
  }

  static Future<Map<String, dynamic>> getStationInfo(String icao) async {
    final uri = Uri.parse('$_baseUrl/station/$icao');
    final resp = await http.get(uri, headers: {'Authorization': 'Token $_token'});

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
