
class WeatherBoundaries {
  /// Checks for serious carburettor icing at any power
  static bool carbIcingRisk(double oat, double dew) {
    return oat >= 0 && oat <= 17 && dew >= 0 && dew <= 15;
  }

  /// Temperature < 5°C risk
  static bool tempRiskLow(double temp) {
    return temp < 5.0;
  }

  /// Temperature > 30°C risk
  static bool tempRiskHigh(double temp) {
    return temp > 30.0;
  }

  /// Humidity > 70% risk
  static bool humidityRiskHigh(double humidity) {
    return humidity > 70.0;
  }

  /// Humidity < 20% risk
  static bool humidityRiskLow(double humidity) {
    return humidity < 20.0;
  }

  /// Wind risk: gusts > 20 knots
  static bool windRisk(double? speed, double? gusts) {
    return (gusts != null && gusts > 20.0) || (speed != null && speed > 20.0);
  }

  /// Weather phenomena risk: parse raw METAR for adverse codes
  static Map<String, bool> weatherPhenomenaRisk(String rawMetar, String remarks) {
    final raw = '${rawMetar.toUpperCase()} ${remarks.toUpperCase()}';
    return {
      'rain': raw.contains('RA'),
      'snow': raw.contains('SN') || raw.contains('SG') || raw.contains('IC'),
      'freezing': raw.contains('FZRA') || raw.contains('PL'),
      'hail': raw.contains('GR'),
      'thunderstorm': raw.contains('TS'),
      'showerCb': raw.contains('SHRA') && raw.contains('CB'),
    };
  }

  /// VFR limits risk: visibility <5km or ceiling <1500ft or not VFR category
  static bool vfrLimitsRisk(double visibilityKm, double? ceilingFt, String category) {
    return visibilityKm < 5.0 || (ceilingFt != null && ceilingFt < 1500.0) || category != 'VFR';
  }
  
  /// Terrain risk: Scotland (EGPN-EGPE), Wales (EGFF area), SW England (EGTE-EGHH)
  static bool terrainRisk(String icao, double? lat, double? lon) {
    final upperIcao = icao.toUpperCase();
    if (upperIcao.startsWith('EGPN') || upperIcao.startsWith('EGPE') ||
        upperIcao.startsWith('EGFF') || upperIcao.startsWith('EGTE') ||
        upperIcao.startsWith('EGHH')) {
      return true;
    }
    // Fallback to coords if needed (Scotland/Wales/SW England approx)
    if (lat != null && lon != null) {
      // Scotland: ~55-61N, 1-7W; Wales: ~51-53N, 3-5W; SW England: ~50-52N, 1-5W
      if ((lat >= 55.0 && lat <= 61.0 && lon >= -7.0 && lon <= -1.0) ||
          (lat >= 51.0 && lat <= 53.0 && lon >= -5.0 && lon <= -3.0) ||
          (lat >= 50.0 && lat <= 52.0 && lon >= -5.0 && lon <= -1.0)) {
        return true;
      }
    }
    return false;
  }
}
