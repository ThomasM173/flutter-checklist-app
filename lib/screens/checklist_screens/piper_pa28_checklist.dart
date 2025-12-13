// flutter_application_1/screens/aircraft_screens/piper_pa28_checklist_screen.dart

// ignore_for_file: library_private_types_in_public_api

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pdfWidgets;
import 'package:pdf/pdf.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:clearedtogo/services/pdf_upload_service.dart';
import 'package:clearedtogo/services/auth_service.dart';
import '../aircraft_screens/piper_pa28_emergency_screen.dart';
import '../aircraft_screens/piper_pa28_emergency_game.dart';
import '../aircraft_screens/piper_pa28_screen.dart';
import 'package:clearedtogo/utils/weather_service.dart';
import 'package:clearedtogo/utils/weather_boundaries.dart';

class PiperPA28ChecklistScreen extends StatefulWidget {
  const PiperPA28ChecklistScreen({super.key});

  @override
  _PiperPA28ChecklistScreenState createState() => 
      _PiperPA28ChecklistScreenState();
}

class _PiperPA28ChecklistScreenState extends State<PiperPA28ChecklistScreen> {
  final Set<String> _activeWeatherConditions = {};
  late Map<String, Map<String, bool>> checklistSections;
  final TextEditingController _airportController = TextEditingController();
  bool _weatherLoading = false;
  String? _weatherError;
  Map<String, dynamic>? _metarData;

  final Map<String, Map<String, List<String>>> _weatherChecklistItems = {
    'cold': {
      '1️⃣ Cabin Checks': [
        '✅ Check for frost or ice on wings, control surfaces, and pitot-static system.',
        '✅ Drain fuel sumps carefully to check for ice crystals.',
        '✅ Ensure oil viscosity is suitable for cold weather.',
        '✅ Check cabin heater and defroster operation.',
      ],
      '🔟 After Engine Start': [
        '✅ Allow longer warm-up at 1000 RPM.',
      ],
    },
    'hot': {
      '5️⃣ Nose': [
        '✅ Check for vapor lock potential.',
        '✅ Inspect for soft or expanded tires due to heat.',
      ],
      '✈️ Cruise': [
        '✅ Calculate density altitude.',
      ],
    },
    'rain': {
      '6️⃣ Left Wing': [
        '✅ Confirm pitot heat ON and pitot cover removed.',
        '✅ Check seals for water intrusion.',
      ],
      '🛫 Taxi': [
        '✅ Taxi cautiously to avoid hydroplaning.',
        '✅ Test brakes early.',
      ],
    },
    'ifrc': {
      '🌧 IFR Conditions': [
        '✅ Check lights (beacon, nav, strobe).',
        '✅ Confirm vacuum/suction system operational.',
        '✅ Cross-check alternate airports.',
        '✅ File IFR flight plan if necessary.',
      ]
    },
    'windy': {
      '🛫 Taxi': [
        '✅ Use control inputs for wind correction during taxi.',
      ],
      '🛫 Before Takeoff': [
        '✅ Prepare for crosswind takeoff technique.',
      ]
    },
    'storm': {
      '⚠️ Weather Avoidance': [
        '✅ Avoid thunderstorm cells and icing conditions.',
        '✅ Confirm pitot heat functional.',
        '✅ Review escape strategy for weather deviations.',
      ]
    }
  };
  @override
void initState() {
  super.initState();
  checklistSections = {
    "CHECK A (ONLY FIRST FLIGHT OF DAY)": {
      "Control Lock                      – REMOVE.": false,
      "First Aid Kit                    – CHECK.": false,
      "Fire Extinguisher                – CHECK.": false,
      "Flap                             – SET 40°.": false,
      "Magneto Switch                  – OFF.": false,
      "Park Brake                       – ON.": false,
      "Fuel Tank Selector                – ON.": false,
      "Master Switch                     – ON.": false,
      "Navigation Light                 – ON.": false,
      "Anti-Collision Light                – ON.": false,
      "Pitot Heater                      – ON.": false,
      "Landing Light                     – ON.": false,
      "External Check (Lights, Pitot Heat, Stall Warner) – ON.": false,
      "All Electrics                      – OFF.": false,
      "Master Switch                     – OFF.": false,
      "All Fuel Drains                    – CHECK.": false,
      "Trim, Check Full Range            – ON.": false,
      "Windscreen                         – CLEAR.": false,

    },
    "TRANSIT CHECK (Check A Complete)": {
      "Control Lock                      – REMOVE.": false,
      "Park Brake                         – ON.": false,
      "Magneto Switch                  – OFF / KEY OUT.": false,
      "Master Switch                     – ON.": false,
      "Fuel Contents                        – CHECK.": false,
      "Master Switch                     – OFF.": false,
      "Windscreen                         – CLEAR.": false,

    },
    "STARBOARD/RIGHT WING": {
      "Flap                               – CONDITION, HINGES.": false,
      "Wing Surface (Upper and Lower)   – CONDITION, INSPECTION COVERS IN PLACE.": false,
      "Alieron                            – CONDITION, HINGES, FULL & FREE MOVEMENT.": false,
      "Wing Tip and Navigation Light    – SECURE.": false,
      "Leading Edge                      – CONDITION, AIR INLET CLEAR, FUEL VENT CLEAR.": false,
      "Fuel                               – CONTENTS SUFFICIENT, VENT CLEAR, CAP SECURE.": false,
      "Fuel Drain                        – CHECK FOR LEAKS.": false,
      "Landing Gear                     – TYRE CONDITION, BREAK PIPE.": false,

    },
    "FRONT FUSELAGE & ENGINE": {
      "Windscreen                        – CLEAR.": false,
      "Engine                            – CHECK CLEAR.": false,
      "Oil Contents                       – CHECK CLEAR.": false,
      "Engine Panel (Starboard)           – CHECK CLEAR.": false,
      "Engine Intakes                    – CLEAR, ALTERNATOR BELT SECURE": false,
      "Propeller                         – CONDITION, SECURE": false,
      "Brake Fluid Level                 – CHECK CLEAR.": false,
      "Engine Panel (Port)              – CHECK CLEAR.": false,
      "Fuel Drain                       – CHECK.": false,
      "Nose Gear                        – CHECK.": false,

    },
    "PORT/LEFT WING": {
      "Landing Gear                     – TYRE CONDITION, BREAK PIPE.": false,
      "Fuel Drain                        – CHECK FOR LEAKS.": false,
      "Fuel                               – CONTENTS SUFFICIENT, VENT CLEAR, CAP SECURE.": false,
      "Leading Edge                      – CONDITION, AIR INLET CLEAR, FUEL VENT CLEAR.": false,
      "Stall Warner                     – CHECK CLEAR.": false,
      "Pitot Head & Static              – CHECK CLEAR.": false,
      "Wing Tip and Navigation Light    – SECURE.": false,
      "Alieron                            – CONDITION, HINGES, FULL & FREE MOVEMENT.": false,
      "Wing Surface (Upper and Lower)   – CONDITION, INSPECTION COVERS IN PLACE.": false,
      "Flap                               – CONDITION, HINGES.": false,

    },
    "REAR FUSELAGE & TAIL": {
      "Rear Fuselage Skin              – CONDITION.": false,
      "Radio Aerials                   – SECURE.": false,
      "Tail Skid                      – CONDITION": false,
      "Elevator & Trim Tab             – CONDITION, FULL/FREE MOVEMENT, TAB LOCK NUT SECURE": false,
      "Fin & Rudder                    – CONDITION, FULL/FREE MOVEMENT, SECURE": false,
      "Beacon & Navigation Light      – SECURE": false,

    },
    "INTERNAL": {
      "Passenger Brief                  – COMPLETE.": false,
      "Cabin Doors                      – CLOSED & LATCHED TOP AND BOTTOM": false,
      "Seats, Belts, Shoulder Harness  – ADJUST & LOCK.": false,
      "Headset                          – CONNECTED.": false,
      "Park Brake                        – ON": false,
      "Trimmer                          – NORMAL RANGE, SET TAKEOFF": false,
      "Circuit Breakers                 – ALL IN.": false,
      "Flight Instruments               – ASI ZERO, ALT SET AIRFIELD HEIGHT OR ZERO": false,
      "Flight Controls                  – FULL & FREE MOVEMENT.": false,
      "Carburettor Heat                 – CHECK OPERATION, SET COLD": false,

    },
    "ENGINE START": {
      "Battery Master                   – ON.": false,
      "ATC (Start-Up) - IF APPLICIBLE  – REQUEST/NOTIFY.": false,
      "Annunciator Panel                – SELECT DAY/NIGHT, TEST, LOW VOLTAGE ON, LOCATE STARTER WARNING LIGHT": false,
      "Fuel                             – SELECT LOWER TANK.": false,
      "Fuel Pump                        – ON, CHECK PRESSURE, OFF": false,
      "Radios                           – OFF.": false,
      "Alternator                       – ON.": false,
      "Mixture                          – CHECK OPERATION, SET RICH.": false,
      "Throttle                         – FRICTION LOOSE, CHECK OPERATION, OPEN ¼ INCH.": false,
      "Prime (Up to 3 strokes)          – AS REQUIRED, CHECK LOCKED.": false,
      "Anti-Collision Light/Beacon     – FIN STROBE ON.": false,
      "Propeller Area                   – CLEAR PROP.": false,
      "Starter                          – OPERATE.": false,
      "RPM                             – SET 1200 RPM.": false,
      "Starter Warning Light            – OUT, IF NOT CLOSE DOWN.": false,
      "Oil Pressure                     – GREEN (<30s), IF NOT CLOSE DOWN.": false,

    },
    "AFTER STARTING": {
      "Headset                         – FITTED & MICROPHONE ADJUSTED, SET SQUELCH.": false,
      "Annunciators                    – OUT": false,
      "Magnetos                        – DEAD CUT CHECK (L, R, BOTH).": false,
      "Suction                         – WITHIN LIMITS (3 TO 5).": false,
      "Gyro Instruments                – SYNCRONISED DI WITH COMPASS, CHECK AI LEVEL.": false,
      "Ammeter                         – CHARGING": false,
      "Flaps                            – SELECT 40° IN STAGES, RETRACT IN STAGES.": false,
      "Naviagtion Aids                 – TUNED, TESTED, IDENTIFIED.": false,
      "Transponder                     – SET 7000, TEST, SET STBY.": false,
      "Radios                          – TUNED, AUDIO PANEL SET, VOL SET, CALL.": false,
      "Altimeter                       – SET QFE OR QNH, CHECK WITHIN LIMITS.": false,
      "Time & Hobbs                    – RECORD": false,

    },
    "TAXI": {
      "ATC (Taxi)                       – REQUEST/NOTIFY.": false,
      "Brake Check                      – PERFORM.": false,
      "Flight Instruments               – CHECK (Compass, Gyro, Turn Coordinator, AI).": false,

    },
    "POWER CHECKS": {
      "Aircraft                       – INTO WIND, CLEAR BEHIND.": false,
      "Brakes                       – HOLD ON.": false,
      "Fuel                        – CHANGE TO FULLER TANK": false,
      "Oil Temperature               – SUFFICIENT FOR RUN UP.": false,
      "Throttle                      – SET 2000 RPM, CHECK BRAKES HOLDING.": false,
      "Alternator                     – FUNCTIONING, CHECK AMMETER CHARGING.": false,
      "Suction                      – SUFFICIENT (APPROX 5 REQUIRED).": false,
      "Carburettor Heat              – HOT, CHECK DROP, SET COLD.": false,
      "Magnetos                      – CHECK, L, R, BOTH (MAX DROP 175RPM, MAX DIFFERENCE 50RPM).": false,
      "Throttle                      – CLOSE IDLE (500-700RPM), MIN OIL PRESSURE 25PSI, SET 1200RPM.": false,

    },
    "PRE TAKE-OFF": {
      "Elevator Trim                    – SET TAKEOFF.": false,
      "Throttle Friction Lock           – SET FINGER TIGHT.": false,
      "Mixture                          – RICH.": false,
      "Carburetor Heat                  – COLD.": false,
      "Magnetos                        – ON BOTH.": false,
      "Fuel Pump                       – CONDITION": false,
      "Fuel                           – SELECT FULLER TANK.": false,
      "Primer                           – COVERED.": false,
      "Flaps                            – SET AS REQUIRED.": false,
      "Flight Instruments               – CHECK (Compass, Gyro, Turn Coordinator, AI).": false,
      "Gauges                           – WITHIN LIMITS, CHECK OAT.": false,
      "Pitot Heat                      – AS REQUIRED (ON IF OAT <5°C).": false,
      "Cabin Doors                      – CLOSED & LOCKED, WINDOW CLOSED.": false,
      "Seats, Seat Belts & Harnesses    – ADJUST & LOCK.": false,
      "Flying Controls                 – FULL AND FREE MOVEMENT.": false,
      "Transponder                      – SET ALT.": false,
      "Landing & Strobe Lights          – ON.": false,

    },
    "AFTER TAKE-OFF": {
      "Flaps                            – UP.": false,
      "Engine                           – T'S & P'S.": false,
      "Trim                             – SET .": false,

    },
    "TOP OF CLIMB, CRUISE, APPROACH": {
      "Fuel                             – CONTENTS SUFFICIENT.": false,
      "Radio                            – FREQ, TEST VOL AND TRANSPONDER.": false,
      "Engine                           – CARB HEAT, GAUGES.": false,
      "DI & Compass                      – DI & COMPASS.": false,
      "Altimeter                        – QNH OR 1013 OR QFE.": false,
      "Landing & Strobe Lights          – ON.": false,

    },
    "LANDING - CHEF": {
      "Carburettor Heat                  – ON.": false,
      "Harnesses                        – SECURE.": false,
      "Engine                           – GAUGES.": false,
      "Fuel                             – CONTENTS CHECK, MIXTURE RICH.": false,
      "Carburettor Heat                  – OFF (300FT).": false,

    },
    "AFTER LANDING": {
      "Clear of Runway                  – STOP.": false,
      "Carburetor Heat                  – COLD.": false,
      "Flaps                            – UP.": false,
      "Trimmer                          – NEUTRAL.": false,
      "Throttle Friction Nut            – SLACKEN.": false,
      "Fuel Pump                        – OFF": false,
      "Pitot Heat                       – OFF.": false,
      "Landing & Strobe Lights          – OFF.": false,
      "Transponder & Nav Aids           – OFF.": false,
      "Fuel Contents                    – CHECK & REFUEL IF NECESSARY.": false,

    },
    "SHUTDOWN": {
      "Park Brake                       – ON": false,
      "Throttle                         – 1200 RPM.": false,
      "Time & Hobbs                     – RECORD.": false,
      "Magnetos                         – DEAD CUT CHECK (L, R, BOTH).": false,
      "Radios                           – OFF.": false,
      "Throttle                         – OFF.": false,
      "Mixture                          – IDLE CUT OFF.": false,
      "Magneto Switch                  – WHEN ENGINE STOPPED, REMOVE KEY.": false,
      "Master Switch                    – OFF.": false,
      "Harnesses                        – STOWED NEATLY.": false,
      "Chocks                           – AS REQUIRED.": false,

    },
  };
    loadChecklist();
  }

  Future<void> loadChecklist() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      checklistSections.forEach((section, items) {
        items.forEach((key, value) {
          bool? savedValue = prefs.getBool('PiperPA28-$section - $key');
          if (savedValue != null) {
            checklistSections[section]![key] = savedValue;
          }
        });
      });
    });
  }

  void updateChecklist(String section, String key, bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      checklistSections[section]![key] = value;
    });
    prefs.setBool('PiperPA28-$section - $key', value);
  }

  void resetChecklist() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      checklistSections.forEach((section, items) {
        items.forEach((key, _) {
          checklistSections[section]![key] = false;
          prefs.setBool('PiperPA28-$section - $key', false);
        });
      });
    });
  }

void toggleWeatherCondition(String key) {
  final items = _weatherChecklistItems[key];
  if (items == null) return;

  setState(() {
    if (_activeWeatherConditions.contains(key)) {
      // REMOVE weather checklist items
      items.forEach((section, checklistItems) {
        for (var item in checklistItems) {
          checklistSections[section]?.remove(item);
        }
        checklistSections[section]?.remove('__weather__');
        if (checklistSections[section]?.isEmpty ?? false) {
          checklistSections.remove(section);
        }
      });
      _activeWeatherConditions.remove(key);
    } else {
      // ADD weather checklist items
      items.forEach((section, checklistItems) {
        checklistSections.putIfAbsent(section, () => {});
        checklistSections[section]!['__weather__'] = true;
        for (var item in checklistItems) {
          checklistSections[section]!.putIfAbsent(item, () => false);
        }
      });
      _activeWeatherConditions.add(key);
    }
  });
}

void updateCarbIcingItem(bool risk) {
  const internalSection = "INTERNAL";
  const powerChecksSection = "POWER CHECKS";

  const internalKey = "CARBURETTOR ICING RISK - TAKE CAUTION";
  const powerKey = "CARBURETTOR ICING RISK - TAKE CAUTION";

  setState(() {
    if (risk) {
      // Add to INTERNAL at the end
      checklistSections.putIfAbsent(internalSection, () => {});
      checklistSections[internalSection]![internalKey] = false;

      // Add to POWER CHECKS before Carburettor Heat
      checklistSections.putIfAbsent(powerChecksSection, () => {});
      final Map<String, bool> powerItems = checklistSections[powerChecksSection]!;

      final Map<String, bool> newPowerItems = {};
      bool inserted = false;

      for (var entry in powerItems.entries) {
        // Insert warning before any key that contains "Carburettor Heat"
        if (!inserted && entry.key.contains("Carburettor Heat")) {
          newPowerItems[powerKey] = false;
          inserted = true;
        }
        newPowerItems[entry.key] = entry.value;
      }

      // If no carb heat found, append at end
      if (!inserted) {
        newPowerItems[powerKey] = false;
      }

      checklistSections[powerChecksSection] = newPowerItems;
    } else {
      // Remove from INTERNAL
      checklistSections[internalSection]?.remove(internalKey);

      // Remove from POWER CHECKS
      checklistSections[powerChecksSection]?.remove(powerKey);
    }
  });
}

Future<void> _fetchWeatherAndUpdateChecklist() async {
  final icao = _airportController.text.trim().toUpperCase();
  if (icao.isEmpty) {
    setState(() {
      _weatherError = 'Please enter an ICAO code';
    });
    return;
  }

  setState(() {
    _weatherLoading = true;
    _weatherError = null;
  });

  try {
    final metarData = await WeatherService.getDecodedMETAR(icao);
    setState(() {
      _metarData = metarData;
      _weatherLoading = false;
    });

    // Update carb icing boundary
    final carbIcingRisk = metarData['carbIcingRisk'] as bool? ?? false;
    updateCarbIcingItem(carbIcingRisk);

  } catch (e) {
    setState(() {
      _weatherError = 'Failed to fetch weather data: $e';
      _weatherLoading = false;
    });
  }
}


  Future<void> generatePDF() async {
    if (!mounted) return;
    if (!(Platform.isAndroid || Platform.isIOS)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("PDF generation only works on Android/iOS")),
      );
      return;
    }

    final pdf = pdfWidgets.Document();
    try {
      final fontData =
          await rootBundle.load("assets/fonts/NotoSans-Regular.ttf");
      final pdfFont = pdfWidgets.Font.ttf(fontData);

      pdf.addPage(
        pdfWidgets.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: pdfWidgets.EdgeInsets.all(40),
          theme: pdfWidgets.ThemeData.withFont(base: pdfFont),
          header: (context) {
            final authService = AuthService();
            final user = authService.currentUser;
            
            return pdfWidgets.Column(
              crossAxisAlignment: pdfWidgets.CrossAxisAlignment.start,
              children: [
                pdfWidgets.Text(
                  "Piper PA28 Checklist",
                  style: pdfWidgets.TextStyle(
                    fontSize: 28,
                    fontWeight: pdfWidgets.FontWeight.bold,
                  ),
                ),
                if (user?.fullName != null || user?.licenseNumber != null || user?.homeBase != null)
                  pdfWidgets.SizedBox(height: 8),
                if (user?.fullName != null)
                  pdfWidgets.Text(
                    "Pilot: ${user!.fullName}",
                    style: pdfWidgets.TextStyle(fontSize: 12, color: PdfColors.grey800),
                  ),
                if (user?.licenseNumber != null)
                  pdfWidgets.Text(
                    "License: ${user!.licenseNumber}",
                    style: pdfWidgets.TextStyle(fontSize: 12, color: PdfColors.grey800),
                  ),
                if (user?.homeBase != null)
                  pdfWidgets.Text(
                    "Home Base: ${user!.homeBase}",
                    style: pdfWidgets.TextStyle(fontSize: 12, color: PdfColors.grey800),
                  ),
                pdfWidgets.Divider(thickness: 2),
                pdfWidgets.SizedBox(height: 10),
              ],
            );
          },
          footer: (context) => pdfWidgets.Column(
            children: [
              pdfWidgets.Divider(),
              pdfWidgets.SizedBox(height: 5),
              pdfWidgets.Row(
                mainAxisAlignment: pdfWidgets.MainAxisAlignment.spaceBetween,
                children: [
                  pdfWidgets.Text(
                    "Generated: ${DateTime.now().toString().split('.')[0]}",
                    style: pdfWidgets.TextStyle(fontSize: 8, color: PdfColors.grey700),
                  ),
                  pdfWidgets.Text(
                    "Page ${context.pageNumber} of ${context.pagesCount}",
                    style: pdfWidgets.TextStyle(fontSize: 8, color: PdfColors.grey700),
                  ),
                ],
              ),
            ],
          ),
          build: (context) => [
            ...checklistSections.entries.map((entry) => pdfWidgets.Column(
                  crossAxisAlignment: pdfWidgets.CrossAxisAlignment.start,
                  children: [
                    pdfWidgets.Text(entry.key,
                        style: pdfWidgets.TextStyle(
                            fontSize: 18,
                            fontWeight: pdfWidgets.FontWeight.bold)),
                    pdfWidgets.SizedBox(height: 5),
                    ...entry.value.entries
                        .where((item) => item.key != '__weather__')
                        .map((item) => pdfWidgets.Padding(
                          padding: pdfWidgets.EdgeInsets.only(left: 10, bottom: 3),
                          child: pdfWidgets.Text(
                            "${item.value ? '☑' : '☐'} ${item.key}",
                            style: pdfWidgets.TextStyle(fontSize: 14),
                          ),
                        )),
                    pdfWidgets.SizedBox(height: 10),
                  ],
                )),
          ],
        ),
      );

      final output = await getTemporaryDirectory();
      final file = File("${output.path}/piper_pa28_checklist.pdf");
      final pdfBytes = await pdf.save();
      await file.writeAsBytes(pdfBytes);
      
      // Upload to backend (non-blocking)
      try {
        await PdfUploadService().uploadPdf(
          pdfBytes,
          title: 'Piper PA28 Checklist - ${DateTime.now().toString().split(' ')[0]}',
          aircraftId: 'G-PA28', // Replace with actual registration if available
          type: 'piper_pa28_checklist',
        );
      } catch (e) {
        debugPrint('Failed to upload PDF to backend: $e');
        // Continue with local file opening even if upload fails
      }
      
      OpenFile.open(file.path);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("PDF error occurred.")),
        );
      }
    }
  }

  Map<String, dynamic> getCompletionProgress() {
    int total = 0;
    int completed = 0;
    checklistSections.forEach((section, items) {
      items.forEach((key, value) {
        // Exclude the special __weather__ key from counting
        if (key == '__weather__') return;
        total++;
        if (value) completed++;
      });
    });
    double percentage = total > 0 ? (completed / total) : 0.0;
    return {
      'text': "$completed of $total items completed",
      'completed': completed,
      'total': total,
      'percentage': percentage,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text("Piper PA28 - Pre-Flight Checklist",
        style: TextStyle(color: Colors.black), // Black title text
        ),
        iconTheme: IconThemeData(color: Colors.black),
        flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFADD8E6), Color(0xFF87CEEB)], // Light blue to sky blue
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
               ),
             ),
           ),
           backgroundColor: Colors.transparent,
           elevation: 4,
         ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              height: 60, // ⬅️ Make button taller
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PiperPA28EmergencyScreen())),
                icon: Icon(Icons.warning, color: Colors.white),
                label: Text(
                  "Emergency Procedures",
                  style: TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold, 
                    color: Colors.white
                    ),
                ),
              ),
            ),
            SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _airportController,
                  style: TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    hintText: 'Enter ICAO (e.g. EGLL)',
                    hintStyle: TextStyle(color: Colors.black),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none),
                  ),
                ),
              ),
              Column(
                children: [
              IconButton(
  icon: Icon(Icons.search, color: Colors.black),
  onPressed: _fetchWeatherAndUpdateChecklist,
),


                  SizedBox(height: 2),
                  Text("Search",
                      style: TextStyle(color: Colors.black, fontSize: 12)),
                ],
              )
            ]),
            SizedBox(height: 10),
            Container(
              height: 100,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  children: [
                    _weatherButton('Cold', Icons.ac_unit, 'cold'),
                    SizedBox(width: 10),
                    _weatherButton('Hot', Icons.wb_sunny, 'hot'),
                    SizedBox(width: 10),
                    _weatherButton('Rain', Icons.grain, 'rain'),
                    SizedBox(width: 10),
                    _weatherButton('IFR', Icons.cloud, 'ifrc'),
                    SizedBox(width: 10),
                    _weatherButton('Windy', Icons.air, 'windy'),
                    SizedBox(width: 10),
                    _weatherButton('Storm', Icons.flash_on, 'storm'),
                  ],
                ),
              ),
            ),
            SizedBox(height: 14),
            Builder(
              builder: (context) {
                final progress = getCompletionProgress();
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            progress['text'],
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${(progress['percentage'] * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progress['percentage'],
                          minHeight: 20,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            progress['percentage'] == 1.0
                                ? Colors.green
                                : Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            SizedBox(height: 14),
            ...checklistSections.entries.map((entry) => ChecklistExpansionTile(
                  key: ValueKey(entry.key),
                  title: entry.key,
                  items: entry.value,
                  updateChecklist: (key, value) =>
                      updateChecklist(entry.key, key, value),
                )),
            SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _iconButton(Icons.refresh, 'Reset', Colors.red, resetChecklist),
                _iconButton(
                    Icons.picture_as_pdf, 'PDF', Colors.blue, generatePDF),
                _iconButton(
                    Icons.info_outline,
                    'Details',
                    Colors.orange,
                    () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => PiperPA28Screen()))),
              ],
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

Widget _weatherButton(String label, IconData icon, String conditionKey) {
  final isActive = _activeWeatherConditions.contains(conditionKey);

  return InkWell(
    onTap: () => toggleWeatherCondition(conditionKey),
    borderRadius: BorderRadius.circular(30),
    splashColor: Colors.white24,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: isActive ? Color(0xFF87CEEB) : Colors.blueGrey.shade700,
            shape: BoxShape.rectangle,
            border: Border.all(color: Colors.black, width: 1.5),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey,
                blurRadius: 4,
                offset: Offset(1, 2),
              ),
            ],
          ),
          padding: EdgeInsets.all(14),
          child: Icon(icon, color: Colors.white, size: 26),
        ),
        SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.black, fontSize: 12)),
      ],
    ),
  );
}

  Widget _iconButton(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          splashColor: Colors.white24,
          child: AnimatedContainer(
            duration: Duration(milliseconds: 300),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                    color: Colors.black38, blurRadius: 6, offset: Offset(2, 3))
              ],
            ),
            padding: EdgeInsets.all(18),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
        ),
        SizedBox(height: 8),
        Text(label, style: TextStyle(color: Colors.black)),
      ],
    );
  }
}

class ChecklistExpansionTile extends StatelessWidget {
  final String title;
  final Map<String, bool> items;
  final Function(String, bool) updateChecklist;

  const ChecklistExpansionTile({
    super.key,
    required this.title,
    required this.items,
    required this.updateChecklist,
  });

  @override
  Widget build(BuildContext context) {
    final entries = items.entries.where((e) => e.key != '__weather__').toList();
    final bool isSectionComplete = entries.every((e) => e.value);
    final bool hasUncheckedItems = entries.any((e) => !e.value);

    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Card(
        color: Colors.white,
        margin: EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: isSectionComplete ? Colors.green : Colors.black,
            width: 2,
          ),
        ),
        elevation: 3,
        shadowColor: Colors.white,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (isSectionComplete)
                      Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: Icon(Icons.check_circle, color: Colors.green, size: 20),
                      ),
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (items.containsKey('__weather__'))
                  Container(
                    margin: EdgeInsets.only(left: 6),
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Color(0xFFADD8E6).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Color(0xFFADD8E6).withOpacity(0.6),
                      ),
                    ),
                    child: Text('WX',
                        style: TextStyle(color: Color(0xFFADD8E6), fontSize: 12)),
                  ),
              ],
            ),
            childrenPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            children: [
              ...entries.map((entry) {
                final isWeatherAdded = items.containsKey('__weather__');
                final Color highlightColor = isWeatherAdded
                    ? Color(0xFFADD8E6).withOpacity(0.1)
                    : Colors.transparent;
                final bool isWeatherWarning = entry.key.contains("RISK") || entry.key.contains("⚠️");
                
                // Parse item name and action
                final parts = entry.key.split('–');
                final itemName = parts[0].trim();
                final action = parts.length > 1 ? parts[1].trim() : '';
                
                return Container(
                  color: highlightColor,
                  child: InkWell(
                    onTap: () => updateChecklist(entry.key, !entry.value),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Custom checkbox
                          GestureDetector(
                            onTap: () => updateChecklist(entry.key, !entry.value),
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: entry.value ? Colors.green : Colors.white,
                                border: Border.all(
                                  color: Colors.black,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Item name on the left (flexible to wrap)
                          Expanded(
                            flex: 3,
                            child: Text(
                              itemName,
                              style: TextStyle(
                                color: isWeatherWarning ? Colors.red : Colors.black,
                                fontSize: 14,
                                fontWeight: isWeatherWarning ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Action on the right (flexible to wrap)
                          if (action.isNotEmpty)
                            Expanded(
                              flex: 2,
                              child: Text(
                                action,
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  color: isWeatherWarning ? Colors.red : Colors.black,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 10, right: 4),
                  child: TextButton.icon(
                    icon: Icon(
                      hasUncheckedItems ? Icons.select_all : Icons.remove_done,
                      color: hasUncheckedItems ? Colors.green : Colors.red,
                    ),
                    label: Text(
                      hasUncheckedItems ? "Select All" : "Deselect All",
                      style: TextStyle(
                        color: hasUncheckedItems ? Colors.green : Colors.red,
                      ),
                    ),
                    onPressed: () {
                      for (var entry in entries) {
                        updateChecklist(entry.key, hasUncheckedItems);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
