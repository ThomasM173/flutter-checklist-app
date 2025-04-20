// flutter_application_1/screens/aircraft_screens/cessna_172_checklist_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pdfWidgets;
import 'package:pdf/pdf.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../aircraft_screens/cessna_172_emergency_screen.dart';
import '../aircraft_screens/cessna_172_screen.dart';

class Cessna172ChecklistScreen extends StatefulWidget {
  const Cessna172ChecklistScreen({super.key});

  @override
  _Cessna172ChecklistScreenState createState() => _Cessna172ChecklistScreenState();
}

class _Cessna172ChecklistScreenState extends State<Cessna172ChecklistScreen> {
  late Map<String, Map<String, bool>> checklistSections;
  final TextEditingController _airportController = TextEditingController();

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
      "1️⃣ Cabin Checks": {
        "✅ Control Lock – REMOVE.": false,
        "✅ Ignition Switch – OFF.": false,
        "✅ Master Switch – ON.": false,
        "✅ Flaps – FULL (30°).": false,
        "✅ Fuel Quantity Indicators – CHECK.": false,
        "✅ Internal / Exterior Lights – ON/CHECK/OFF.": false,
        "✅ Pitot Tube Heat – ON/CHECK/OFF.": false,
        "✅ Master Switch – OFF.": false,
        "✅ Fuel Shutoff Valve – ON.": false,
        "✅ Fire Extinguisher / First Aid Kit – GREEN/IN PLACE.": false,
      },
      "2️⃣ Empennage": {
        "✅ Rudder Gust Lock – REMOVE.": false,
        "✅ Tail Tie-Down – DISCONNECT.": false,
        "✅ Control Surfaces – CHECK.": false,
      },
      "3️⃣ Right Wing": {
        "✅ Wing Tie-Down – DISCONNECT.": false,
        "✅ Main Wheel Tire – CHECK.": false,
        "✅ Fuel Drain, Quantity & Filler Cap – CHECK.": false,
      },
      "4️⃣ Right Wing Trailing Edge": {
        "✅ Aileron & Flap – CHECK.": false,
      },
      "5️⃣ Nose": {
        "✅ Engine Oil Level – CHECK (MIN. 4).": false,
        "✅ Fuel Drain – CHECK.": false,
        "✅ Propeller, Spinner, Air Filter – CHECK.": false,
        "✅ Nose Wheel Strut and Tire – CHECK.": false,
        "✅ Static Source – CHECK.": false,
      },
      "6️⃣ Left Wing": {
        "✅ Pitot Tube Cover – CONFIRM REMOVED.": false,
        "✅ Stall Warning, Fuel Tank and Vent Opening – CHECK.": false,
        "✅ Wing Tie-Down – DISCONNECT.": false,
        "✅ Main Wheel Tire – CHECK.": false,
        "✅ Fuel Drain, Quantity & Filler Cap – CHECK.": false,
      },
      "7️⃣ Left Wing Trailing Edge": {
        "✅ Aileron & Flap – CHECK.": false,
      },
      "8️⃣ Cockpit Preparation": {
        "✅ Preflight Inspection – COMPLETE.": false,
        "✅ Seats, Belts, Shoulder Harness – ADJUST & LOCK.": false,
        "✅ Fuel Shutoff Valve – ON (HORIZONTAL).": false,
        "✅ Radios & Electrical Equipment – OFF.": false,
        "✅ Brakes – CHECKED (PRESS).": false,
        "✅ Circuit Breakers – ALL IN.": false,
        "✅ Flight Controls – FREE & CORRECT.": false,
      },
      "9️⃣ Before Engine Start": {
        "✅ Battery Switch – ON.": false,
        "✅ ATC (Start-Up) – REQUEST/NOTIFY.": false,
        "✅ Radios – OFF.": false,
        "✅ Beacon – ON.": false,
        "✅ Mixture – RICH.": false,
        "✅ Throttle – OPEN ¼ INCH.": false,
        "✅ Carb Heat – OFF.": false,
        "✅ Prime (Up to 3 strokes) – AS REQUIRED.": false,
        "✅ Propeller Area – CLEAR.": false,
        "✅ Ignition Switch – START.": false,
        "✅ Throttle – 1000 RPM.": false,
      },
      "🔟 After Engine Start": {
        "✅ Oil Pressure – GREEN (<30s).": false,
        "✅ Alternator Switch – ON.": false,
        "✅ Ammeter / Low Voltage Light – CHECKED.": false,
        "✅ Navigation Lights – ON (NIGHT FLIGHT).": false,
        "✅ Radios / Transponder – ON / STBY.": false,
        "✅ Flaps – UP.": false,
        "✅ Flight Instruments (FLAGS) – CHECK FLAGS.": false,
        "✅ Heading Indicator – ALIGNED.": false,
        "✅ Altimeter – SET & CHECKED.": false,
        "✅ Navaids – CHECK (IF REQD).": false,
      },
      "🛫 Taxi": {
        "✅ ATC (Taxi) – REQUEST/NOTIFY.": false,
        "✅ Brake Check – PERFORM.": false,
        "✅ Flight Instruments – CHECK (Compass, Gyro, Turn Coordinator, AI).": false,
      },
      "🛫 Before Takeoff": {
        "✅ Cabin Doors – CLOSED.": false,
        "✅ Flight Instruments – CHECKED.": false,
        "✅ Pitot Cover – REMOVED.": false,
        "✅ Fuel Shutoff Valve – ON (HORIZONTAL).": false,
        "✅ Elevator Trim – TAKEOFF.": false,
        "✅ Oil Temperature – GREEN ARC.": false,
        "✅ Mixture – RICH.": false,
        "✅ Power Check @1700 RPM – PERFORM.": false,
        "✅ Magnetos – CHECK.": false,
        "✅ Elec & Eng Instruments – CHECK.": false,
        "✅ Suction Gauge – GREEN.": false,
        "✅ Carburetor Heat – CHECK OPERATION.": false,
        "✅ Navaids – SET FOR DEP.": false,
        "✅ Throttle Friction Lock – ADJUSTED.": false,
        "✅ Flaps – SET (UP / 10°).": false,
        "✅ T/O Briefing – CONFIRMED.": false,
        "✅ Landing & Strobe Lights – ON.": false,
        "✅ Transponder – ALT OR STBY.": false,
        "✅ QFU/Gyro – CONFIRM/ALIGN.": false,
      },
      "🛫 After Takeoff / Climb": {
        "✅ Flaps – UP.": false,
        "✅ Landing Light – OFF.": false,
        "✅ Altimeter – SET (Crossing Transition Altitude).": false,
      },
      "✈️ Cruise": {
        "✅ Throttle – AS REQUIRED.": false,
        "✅ Mixture – AS REQUIRED.": false,
      },
      "🛬 Descent / Approach": {
        "✅ Seats, Seat Belts & Harnesses – ADJUST & LOCK.": false,
        "✅ Mixture – RICH.": false,
        "✅ Carburetor Heat – ON.": false,
        "✅ Approach Briefing – CONFIRMED.": false,
        "✅ Altimeter – SET (Crossing Transition Level).": false,
      },
      "🛬 Before Landing": {
        "✅ Landing Light – ON.": false,
        "✅ Carburetor Heat – ON.": false,
        "✅ Flaps – 10° (ABEAM or CIRCUIT ENTRY).": false,
        "✅ Flaps – LDG CONFIG (ON FINAL <300' AGL).": false,
      },
      "🛬 After Landing": {
        "✅ Flaps – UP.": false,
        "✅ Carburetor Heat – OFF (IN).": false,
        "✅ Landing & Strobe Lights – OFF.": false,
        "✅ Transponder – STBY.": false,
      },
      "⛔ Shutdown": {
        "✅ Throttle – 1000 RPM.": false,
        "✅ Radios – OFF.": false,
        "✅ Transponder – 7000/OFF.": false,
        "✅ Navigation Lights – OFF.": false,
        "✅ Mixture – CUT OFF.": false,
        "✅ Ignition Switch – OFF.": false,
        "✅ Beacon – OFF.": false,
        "✅ Master Switch – OFF.": false,
        "✅ Time – NOTE.": false,
      },
      "🅿️ Parking": {
        "✅ Trim – RESET (T/O).": false,
        "✅ Control Lock – INSTALL.": false,
        "✅ Hobbs (Timer Counter) – RECORD.": false,
        "✅ Pitot Cover – INSTALL.": false,
        "✅ Chocks – INSTALL.": false,
        "✅ Fuel Remaining – CHECK.": false,
      },
    };
    loadChecklist();
  }

  Future<void> loadChecklist() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      checklistSections.forEach((section, items) {
        items.forEach((key, value) {
          bool? savedValue = prefs.getBool('$section - $key');
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
    prefs.setBool('$section - $key', value);
  }

  void resetChecklist() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      checklistSections.forEach((section, items) {
        items.forEach((key, _) {
          checklistSections[section]![key] = false;
          prefs.setBool('$section - $key', false);
        });
      });
    });
  }

  void applyWeatherCondition(String key) {
    final items = _weatherChecklistItems[key];
    if (items == null) return;

    setState(() {
      items.forEach((section, additions) {
        if (!checklistSections.containsKey(section)) {
          checklistSections[section] = {};
        }
        for (var item in additions) {
          if (!checklistSections[section]!.containsKey(item)) {
            checklistSections[section]![item] = false;
          }
        }
      });
    });
  }

  Future<void> fetchWeatherAndApply(String airportCode) async {
    String exampleCondition = 'cold';
    applyWeatherCondition(exampleCondition);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Applied "\$exampleCondition" checklist for \$airportCode')),
    );
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
      final fontData = await rootBundle.load("assets/fonts/NotoSans-Regular.ttf");
      final pdfFont = pdfWidgets.Font.ttf(fontData);

      pdf.addPage(
        pdfWidgets.MultiPage(
          pageFormat: PdfPageFormat.a4,
          theme: pdfWidgets.ThemeData.withFont(base: pdfFont),
          build: (context) => [
            pdfWidgets.Text("Cessna 172 Checklist", style: pdfWidgets.TextStyle(fontSize: 24, fontWeight: pdfWidgets.FontWeight.bold)),
            pdfWidgets.SizedBox(height: 10),
            ...checklistSections.entries.map((entry) => pdfWidgets.Column(children: [
              pdfWidgets.Text(entry.key, style: pdfWidgets.TextStyle(fontSize: 18, fontWeight: pdfWidgets.FontWeight.bold)),
              pdfWidgets.SizedBox(height: 5),
              ...entry.value.entries.map((item) => pdfWidgets.Text(
                "\${item.value ? '[x]' : '[ ]'} \${item.key}",
                style: pdfWidgets.TextStyle(fontSize: 14),
              )),
              pdfWidgets.SizedBox(height: 10),
            ])),
          ],
        ),
      );

      final output = await getTemporaryDirectory();
      final file = File("\${output.path}/Cessna_172_Checklist.pdf");
      await file.writeAsBytes(await pdf.save());
      OpenFile.open(file.path);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("PDF error occurred.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: Text("Cessna 172 - Pre-Flight Checklist"),
        backgroundColor: Colors.red,
      ),
      body: ListView(
        padding: EdgeInsets.all(10),
        children: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => Cessna172EmergencyScreen())),
            child: Text("🚨 Emergency Procedures"),
          ),
          SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _airportController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Enter ICAO (e.g. EGLL)',
                  hintStyle: TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey[800],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.cloud, color: Colors.white),
              onPressed: () => fetchWeatherAndApply(_airportController.text.trim()),
            )
          ]),
          SizedBox(height: 10),
          Wrap(spacing: 10, children: [
            _weatherButton('Cold', Icons.ac_unit, 'cold'),
            _weatherButton('Hot', Icons.wb_sunny, 'hot'),
            _weatherButton('Rain', Icons.grain, 'rain'),
            _weatherButton('IFR', Icons.cloud, 'ifrc'),
            _weatherButton('Windy', Icons.air, 'windy'),
            _weatherButton('Storm', Icons.flash_on, 'storm'),
          ]),
          SizedBox(height: 20),
          ...checklistSections.entries.map((entry) => ChecklistExpansionTile(
            title: entry.key,
            items: entry.value,
            updateChecklist: (key, value) => updateChecklist(entry.key, key, value),
          )),
          SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _iconButton(Icons.refresh, 'Reset', Colors.red, resetChecklist),
              _iconButton(Icons.picture_as_pdf, 'PDF', Colors.blue, generatePDF),
              _iconButton(Icons.info_outline, 'Details', Colors.orange, () => Navigator.push(context, MaterialPageRoute(builder: (_) => Cessna172Screen()))),
            ],
          )
        ],
      ),
    );
  }

  Widget _weatherButton(String label, IconData icon, String conditionKey) {
    return InkWell(
      onTap: () => applyWeatherCondition(conditionKey),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(color: Colors.blueGrey, shape: BoxShape.circle),
            padding: EdgeInsets.all(14),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          SizedBox(height: 4),
          Text(label, style: TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _iconButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            padding: EdgeInsets.all(18),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
        ),
        SizedBox(height: 8),
        Text(label, style: TextStyle(color: Colors.white)),
      ],
    );
  }
}

class ChecklistExpansionTile extends StatelessWidget {
  final String title;
  final Map<String, bool> items;
  final Function(String, bool) updateChecklist;

  const ChecklistExpansionTile({super.key, required this.title, required this.items, required this.updateChecklist});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[850],
      margin: EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ExpansionTile(
        title: Text(title, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        children: items.keys.map((item) {
          return CheckboxListTile(
            title: Text(item, style: TextStyle(color: Colors.white)),
            value: items[item],
            onChanged: (bool? value) => updateChecklist(item, value ?? false),
            activeColor: Colors.red,
          );
        }).toList(),
      ),
    );
  }
}
