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
  _Cessna172ChecklistScreenState createState() =>
      _Cessna172ChecklistScreenState();
}

class _Cessna172ChecklistScreenState extends State<Cessna172ChecklistScreen> {
  final Set<String> _activeWeatherConditions = {};
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
        "✅ Aileron & Flap – CHECK.": false,
      },
      "4️⃣ Nose": {
        "✅ Engine Oil Level – CHECK (MIN. 4).": false,
        "✅ Fuel Drain – CHECK.": false,
        "✅ Propeller, Spinner, Air Filter – CHECK.": false,
        "✅ Nose Wheel Strut and Tire – CHECK.": false,
        "✅ Static Source – CHECK.": false,
      },
      "5️⃣ Left Wing": {
        "✅ Pitot Tube Cover – CONFIRM REMOVED.": false,
        "✅ Stall Warning, Fuel Tank and Vent Opening – CHECK.": false,
        "✅ Wing Tie-Down – DISCONNECT.": false,
        "✅ Main Wheel Tire – CHECK.": false,
        "✅ Fuel Drain, Quantity & Filler Cap – CHECK.": false,
        "✅ Aileron & Flap – CHECK.": false,
      },
      "6️⃣ Cockpit Preparation": {
        "✅ Preflight Inspection – COMPLETE.": false,
        "✅ Seats, Belts, Shoulder Harness – ADJUST & LOCK.": false,
        "✅ Fuel Shutoff Valve – ON (HORIZONTAL).": false,
        "✅ Radios & Electrical Equipment – OFF.": false,
        "✅ Brakes – CHECKED (PRESS).": false,
        "✅ Circuit Breakers – ALL IN.": false,
        "✅ Flight Controls – FREE & CORRECT.": false,
      },
      "7️⃣ Before Engine Start": {
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
      "8️⃣ After Engine Start": {
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
        "✅ Flight Instruments – CHECK (Compass, Gyro, Turn Coordinator, AI).":
            false,
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
        "✅ Transponder – ALT.": false,
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

void toggleWeatherCondition(String key) {
  final items = _weatherChecklistItems[key];
  if (items == null) return;

  setState(() {
    if (_activeWeatherConditions.contains(key)) {
      // REMOVE weather checklist items
      items.forEach((section, checklistItems) {
        checklistItems.forEach((item) {
          checklistSections[section]?.remove(item);
        });
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
          theme: pdfWidgets.ThemeData.withFont(base: pdfFont),
          build: (context) => [
            pdfWidgets.Text("Cessna 172 Checklist",
                style: pdfWidgets.TextStyle(
                    fontSize: 24, fontWeight: pdfWidgets.FontWeight.bold)),
            pdfWidgets.SizedBox(height: 10),
            ...checklistSections.entries.map((entry) => pdfWidgets.Column(
                  children: [
                    pdfWidgets.Text(entry.key,
                        style: pdfWidgets.TextStyle(
                            fontSize: 18,
                            fontWeight: pdfWidgets.FontWeight.bold)),
                    pdfWidgets.SizedBox(height: 5),
                    ...entry.value.entries.map((item) => pdfWidgets.Text(
                          "${item.value ? '[x]' : '[ ]'} ${item.key}",
                          style: pdfWidgets.TextStyle(fontSize: 14),
                        )),
                    pdfWidgets.SizedBox(height: 10),
                  ],
                )),
          ],
        ),
      );

      final output = await getTemporaryDirectory();
      final file = File("${output.path}/Cessna_172_Checklist.pdf");
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

  String getCompletionProgress() {
    int total = 0;
    int completed = 0;
    checklistSections.forEach((section, items) {
      items.forEach((key, value) {
        total++;
        if (value) completed++;
      });
    });
    return "$completed of $total items completed";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: Text("Cessna 172 - Pre-Flight Checklist"),
        backgroundColor: Colors.red,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => Cessna172EmergencyScreen())),
                child: Text("🚨 Emergency Procedures"),
              ),
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
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none),
                  ),
                ),
              ),
              Column(
                children: [
                 IconButton(
  icon: Icon(Icons.cloud, color: Colors.white),
  onPressed: () {
    // Optionally show a message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Auto weather fetch not implemented')),
    );
  },
),

                  SizedBox(height: 2),
                  Text("Search",
                      style: TextStyle(color: Colors.white, fontSize: 12)),
                ],
              )
            ]),
            SizedBox(height: 10),
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _weatherButton('Cold', Icons.ac_unit, 'cold'),
                    _weatherButton('Hot', Icons.wb_sunny, 'hot'),
                    _weatherButton('Rain', Icons.grain, 'rain'),
                    _weatherButton('IFR', Icons.cloud, 'ifrc'),
                    _weatherButton('Windy', Icons.air, 'windy'),
                    _weatherButton('Storm', Icons.flash_on, 'storm'),
                  ],
                ),
              ),
            ),
            SizedBox(height: 14),
            Text(getCompletionProgress(),
                style: TextStyle(color: Colors.white70, fontSize: 14)),
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
                        MaterialPageRoute(builder: (_) => Cessna172Screen()))),
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
            color: isActive ? Colors.amber.shade700 : Colors.blueGrey.shade700,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black45,
                blurRadius: 4,
                offset: Offset(1, 2),
              ),
            ],
          ),
          padding: EdgeInsets.all(14),
          child: Icon(icon, color: Colors.white, size: 26),
        ),
        SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.white, fontSize: 12)),
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
        Text(label, style: TextStyle(color: Colors.white)),
      ],
    );
  }
}

class ChecklistExpansionTile extends StatelessWidget {
  final String title;
  final Map<String, bool> items;
  final Function(String, bool) updateChecklist;

  const ChecklistExpansionTile(
      {super.key,
      required this.title,
      required this.items,
      required this.updateChecklist});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Card(
        color: Colors.grey[850],
        margin: EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 3,
        shadowColor: Colors.black54,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (items.containsKey('__weather__'))
                  Container(
                    margin: EdgeInsets.only(left: 6),
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.yellowAccent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.yellowAccent.withOpacity(0.6)),
                    ),
                    child: Text('WX',
                        style: TextStyle(
                            color: Colors.yellowAccent, fontSize: 12)),
                  ),
              ],
            ),
            childrenPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            children:
                items.entries.where((e) => e.key != '__weather__').map((entry) {
              final isWeatherAdded = items.containsKey('__weather__');
              final Color highlightColor = isWeatherAdded
                  ? Colors.yellowAccent.withOpacity(0.1)
                  : Colors.transparent;
              return Container(
                color: highlightColor,
                child: CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(entry.key,
                      style: TextStyle(color: Colors.white, fontSize: 14)),
                  value: entry.value,
                  onChanged: (bool? value) =>
                      updateChecklist(entry.key, value ?? false),
                  activeColor: Colors.red,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}