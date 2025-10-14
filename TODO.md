# TODO: Add New Weather Parameters to Checklists

## Overview
Integrate new weather parameters (Temperature, Humidity, Wind, Weather Phenomena, Visibility & Cloud Ceiling, Terrain Awareness) into the app's weather boundaries, service, and Cessna 152 checklist. Build on existing carb icing logic with AVWX ICAO integration. Add dynamic checklist items based on METAR data, with specific placements per user specs.

## Steps
- [ ] Step 1: Update `lib/utils/weather_boundaries.dart` - Add static methods for new risks (tempLow/High, humidityHigh/Low, windRisk (>20kt gusts), weatherPhenomenaRisk (parse codes), vfrLimitsRisk, terrainRisk).
- [ ] Step 2: Enhance `lib/utils/weather_service.dart` - In `getDecodedMETAR`, parse gusts, ceiling, phenomena from raw METAR/remarks; compute all new risks; add to return map (e.g., 'tempLowRisk', 'phenomenaRisks').
- [ ] Step 3: Update `lib/screens/checklist_screens/cessna_152_checklist.dart` - Add new maps for condition-specific items (e.g., `_temperatureChecklistItems`, `_humidityChecklistItems`); add update methods (e.g., `updateTemperatureItem`); integrate in `_fetchWeatherAndUpdateChecklist`; update UI METAR summary for new risks.
- [ ] Step 4: Generalize to other checklists - Check for other checklist files (e.g., Piper PA-28); apply similar updates if found.
- [ ] Step 5: Testing/Validation - Run `flutter analyze`; test with sample ICAO (e.g., EGCC); verify dynamic items, PDF export, error handling.

## Notes
- Use exact item wording from user specs.
- Wind gusts threshold: >20 knots.
- Weather Phenomena: Parse raw METAR for codes; add actions/warnings accordingly.
- VFR: Flag global warning if minima not met.
- Terrain: Use ICAO prefix or coords for regions.
- Persistence: Save/load new dynamic items via SharedPreferences.
- No new dependencies needed.
