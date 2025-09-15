import 'dart:convert';
import '../utils/weather_service.dart';

class WeatherBoundaries {
  /// Checks for serious carburettor icing at any power
  static bool carbIcingRisk(double oat, double dew) {
    return oat >= 0 && oat <= 17 && dew >= 0 && dew <= 15;
  }
}