import 'package:clearedtogo/utils/weather_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WeatherService METAR parsing', () {
    test('parses humidity and wind from AVWX response fields', () {
      final body = {
        'station': 'EGLL',
        'raw': 'EGLL 211750Z AUTO 05006KT 9999 NCD 23/12 Q1027',
        'temperature': {'value': 23.0},
        'dewpoint': {'value': 12.0},
        'relative_humidity': 0.5,
        'wind_direction': {'value': 50},
        'wind_speed': {'value': 25},
        'wind_gust': {'value': 35},
        'visibility': {'value': 9999, 'unit': 'm'},
        'flight_rules': 'VFR',
        'clouds': [],
        'remarks': '',
        'translations': {'remarks': []},
        'info': {
          'name': 'London Heathrow Airport',
          'coordinates': [-0.461941, 51.4706],
          'elevation_ft': 83,
        },
        'altimeter': {'value': 1027, 'unit': 'hPa'},
      };

      final parsed = WeatherService.parseMETARBody(body);

      expect(parsed['humidity'], '50%');
      expect(parsed['wind'], '050° @ 25 kt');
      expect(parsed['windRisk'], isTrue);
      expect(parsed['carbIcingRisk'], isFalse);
      expect(parsed['vfrLimitsRisk'], isFalse);
    });
  });
}
