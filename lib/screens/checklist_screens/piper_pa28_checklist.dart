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
import '../aircraft_screens/piper_pa28_emergency_screen.dart';
import '../aircraft_screens/piper_pa28_emergency_game.dart';
import '../aircraft_screens/piper_pa28_screen.dart';

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
        "Tie down and chocks            – REMOVE.": false,
        "Control locks and covers       – REMOVE AND STOW.": false,
        "Avionics                       – OFF.": false,
        "Park Brake                     – ON.": false,
        "Ignition                       – OFF / KEY OUT.": false,
        "Master switch                  – ON.": false,
        "Annunciator panel              – CHECK.": false,
        "Fuel quantity gauges           – Check, on tank with lowest content.": false,
        "External electrical switches   – ALL ON.": false,
        "Navigation lights              – CHECK.": false,
        "Strobes                        – CHECK.": false,
        "Landing light                  – CHECK.": false,
        "Stall Warner                   – CHECK.": false,
        "Pitot heat                     – CHECK.": false,
        "Anti-collision beacon          – CHECK.": false,
        "External electrical switches   – ALL OFF.": false,
        "Master switch                  – OFF.": false,
        "First aid kit                  – In position, secure.": false,
        "Fire extinguisher              – In position, secure.": false,
        "Cockpit                        – Check & remove/stow any loose items.": false,
        "Flaps                          – SET 25°.": false,
      },
      "2️⃣ Empennage": {
        "Rudder Gust Lock               – REMOVE.": false,
        "Tail Tie-Down                  – DISCONNECT.": false,
        "Control Surfaces               – CHECK.": false,
      },
      "3️⃣ Left Wing": {
        "Tyre                           – Condition, inflation, creep marks aligned.": false,
        "Hydraulic lines                – Condition, leaks.": false,
        "Disc brake block               – Condition.": false,
        "Oleo/Strut                     – Normal extension (~4.5 inches).": false,
        "Torque link                    – Nuts and split pins secure.": false,
        "Flap                           – Linkages, hinges, condition (free of mud).": false,
        "Aileron                        – Linkages, hinges, full & free movement.": false,
        "Wing tip                       – Condition, security, navigation light.": false,
        "Wing surface                   – Condition, upper & lower surfaces.": false,
        "Leading edge                   – Check for dents.": false,
        "Fuel tank                      – Contents visually checked, fuel cap secure.": false,
        "Fuel drain                     – Examine sample, check fully closed.": false,
        "Fuel vent                      – Open.": false,
        "Windows                        – Clean.": false,
        "Skin                           – Examine condition.": false,
      },
      "4️⃣ Nose": {
        "Starboard cowling              – Check oil level (6 qts.).": false,
        "Engine compartment             – Check for leaks, contamination, loose connections.": false,
        "Secure cowling.": false,
        "Windscreen                     – CLEAN, OAT probe secure.": false,
        "Nose leg                       – Oleo/strut extension (3.25 inch), torque link, nuts & split pins.": false,
        "Nosewheel                      – Condition, inflation, creep marks aligned.": false,
        "Front cowling                  – Condition & security, air intakes clear.": false,
        "Propeller                      – Check condition, especially leading edge.": false,
        "Port cowling                   – Check brake fluid level.": false,
        "Engine compartment (port side) – Check for leaks, contamination, loose leads.": false,
        "Secure cowling (port side).": false,
        "Fuel drain                     – Examine sample, check fully closed.": false,
      },
      "5️⃣ Right Wing": {
        "Check all exterior and surfaces for damage, ice, snow, frost.": false,
        "Flap                           – Linkages, hinges, condition (free of mud).": false,
        "Aileron                        – Linkages, hinges, full & free movement.": false,
        "Wing tip                       – Condition, security, navigation light.": false,
        "Wing surface                   – Condition, upper & lower surfaces.": false,
        "Leading edge                   – Check for dents.": false,
        "Fuel tank                      – Contents visually checked, fuel cap secure.": false,
        "Fuel drain                     – Examine sample, check fully closed.": false,
        "Fuel vent                      – Open.": false,
        "Tyre                           – Condition, inflation, creep marks aligned.": false,
        "Hydraulic lines                – Condition, leaks.": false,
        "Disc brake block               – Condition.": false,
        "Oleo/Strut                     – Normal extension (~4.5 inches).": false,
        "Torque link                    – Nuts and split pins secure.": false,
      },
      "6️⃣ Internal": {
        "Passenger brief                – If required.": false,
        "Seats, Belts, Shoulder Harness – ADJUST & LOCK.": false,
        "Circuit Breakers               – ALL IN.": false,
        "Parking Brake                  – ON.": false,
        "Radios                         – OFF.": false,
        "Instruments                    – Legible, serviceable, readings within limits.": false,
        "Flying Controls                – Full & free movement, correct sense.": false,
        "Trimmers                       – Full & free movement, set for take-off.": false,
        "Flaps                          – Check in stages, select up.": false,
        "Cabin air controls             – Closed (Off).": false,
        "Fuel                           – On, select tank with lowest contents.": false,
      },
      "7️⃣ Engine Start": {
        "Throttle                       – Operate full & free movement, set ½ inch open.": false,
        "Mixture                        – Full & free movement, set rich.": false,
        "Throttle friction              – Operate and check loose.": false,
        "Carburettor heat               – Full & free movement, set cold.": false,
        "Master switch                  – ON.": false,
        "Circuit breakers/fuses         – In / secure.": false,
        "Beacon                         – Confirm ON.": false,
        "Fuel pump                      – ON, check fuel pressure, then OFF.": false,
        "Primer                         – Prime (2-6 strokes*) & LOCK.": false,
        "Lookout                        – Good look around, call “CLEAR PROP”.": false,
        "Starter                        – Engage.": false,
        "RPM on start-up                – Avoid high revs, set 1200 rpm.": false,
      },
      "8️⃣ After Engine Start": {
        "RPM                            – Set to 1200 rpm.": false,
        "Brakes                         – Check holding.": false,
        "Starter warning light          – Out*.": false,
        "Oil Pressure                   – Rising to green arc within 30 secs*.": false,
        "Ammeter                        – Charging.": false,
        "Suction                        – Registering.": false,
        "Magnetos                       – Check.": false,
        "Flight Instruments             – Set as required.": false,
        "Radios                         – Tuned / checked / airfield info.": false,
        "Taxi clearance                 – If required.": false,
      },
      "🛫 Taxi": {
        "ATC (Taxi)                     – REQUEST/NOTIFY.": false,
        "Brake Check                    – PERFORM.": false,
        "Flight Instruments             – CHECK (Compass, Gyro, Turn Coordinator, AI).": false,
      },
      "🛫 Power Checks": {
        "Position                       – Into wind, check clear all round, esp. behind.": false,
        "Parking brake                  – ON.": false,
        "Throttle                       – 1200 rpm set.": false,
        "Fuel                           – Note time and change tanks.": false,
        "Engine temp & press            – Within limits.": false,
        "Throttle                       – SET 2000 rpm, check brakes holding.": false,
        "Carb. heat                     – ON for 15 secs, drop ~75 rpm, steady, set cold.": false,
        "Magnetos                       – Check left & right & back to BOTH (max drop 175 rpm, max difference 50 rpm).": false,
        "Engine temp & pressures        – Within limits.": false,
        "Ammeter                        – Charging.": false,
        "Suction                        – 3”–5”.": false,
        "Throttle fully closed          – 500–700 rpm.": false,
        "Throttle                       – Reset 1200 rpm.": false,
      },
      "🛫 Pre Take Off Checks": {
        "T Trimmers                     – Set for take-off.": false,
        "T Throttle Friction            – Set finger tight.": false,
        "M Mixture                      – RICH.": false,
        "M Magnetos                     – ON BOTH.": false,
        "M Master switch                – ON.": false,
        "P Pitot Heater (if flight temp <5° in visible moisture) – ON.": false,
        "P Primer                       – Locked.": false,
        "F Fuel                         – Sufficient and on correct tank.": false,
        "F Fuel pump                    – ON.": false,
        "F Flaps                        – As required (25° short field).": false,
        "G Gauges (Instruments)         – HI, AI, altimeter: Checked and set.": false,
        "H Hatches                      – Doors and windows secure.": false,
        "H Harnesses                    – Secure.": false,
        "C Carburettor heat             – Re-check if necessary, set COLD.": false,
        "C Controls                     – Full and free movement.": false,
        "Transponder                    – ON ALT.": false,
        "Strobes                        – ON.": false,
        "Landing light                  – ON.": false,
      },
      "🛫 After Takeoff / Climb": {
        "Flaps                          – UP.": false,
        "T's and P's                    – Green.": false,
        "Trim                           – As Required.": false,
      },
      "✈️ Cruise": {
        "Throttle                       – AS REQUIRED.": false,
        "Mixture                        – AS REQUIRED.": false,
      },
      "🛬 Descent / Approach": {
        "Throttle                       – Reduce by 250 RPM.": false,
        "Airspeed                       – 100 KIAS maintained.": false,
        "Mixture                        – RICH.": false,
        "Carburettor heat               – ON if required.": false,
      },
      "🛬 Before Landing": {
        "BUMPFICH                       – Check.": false,
      },
      "🛬 After Landing": {
        "Flaps                          – UP.": false,
        "Carburetor Heat                – OFF (IN).": false,
        "Landing & Strobe Lights        – OFF.": false,
        "Transponder                    – STBY.": false,
      },
      "⛔ Shutdown": {
        "Park Brake                     – ON.": false,
        "Throttle                       – 1200 RPM.": false,
        "Time Hobbs                     – Record.": false,
        "Magnetos                       – Dead Cut Check.": false,
        "Radios                         – OFF.": false,
        "Throttle                       – Close.": false,
        "Mixture                        – CUT OFF.": false,
        "Magneto Switch                 – When Eng Off Key Out.": false,
        "Master Switch                  – OFF.": false,
      },
      "🅿️ Parking": {
        "Control Lock                   – INSTALL.": false,
        "Pitot Cover                    – INSTALL.": false,
        "Chocks                         – INSTALL.": false,
        "Fuel Remaining                 – CHECK.": false,
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
            pdfWidgets.Text("Piper PA28 Checklist",
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
      final file = File("${output.path}/piper_pa28_checklist.pdf");
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
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text("Piper PA28 - Pre-Flight Checklist"),
        backgroundColor: Colors.purple,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => PiperPA28EmergencyScreen())),
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
                    fillColor: Colors.grey,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none),
                  ),
                ),
              ),
              Column(
                children: [
                 IconButton(
  icon: Icon(Icons.cloud, color: Colors.grey[700]),
  onPressed: () {
    // Optionally show a message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Auto weather fetch not implemented')),
    );
  },
),

                  SizedBox(height: 2),
                  Text("Search",
                      style: TextStyle(color: Colors.black, fontSize: 12)),
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
                style: TextStyle(color: Colors.black, fontSize: 14)),
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
            color: isActive ? Colors.amber.shade700 : Colors.blueGrey.shade700,
            shape: BoxShape.circle,
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
        color: Colors.grey[600],
        margin: EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 3,
        shadowColor: Colors.grey[600],
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
                  activeColor: Colors.green,
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