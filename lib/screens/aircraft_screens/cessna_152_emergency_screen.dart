import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/aircraft_screens/cessna_152_emergency_game.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class Cessna152EmergencyScreen extends StatefulWidget {
  const Cessna152EmergencyScreen({super.key});

  @override
  State<Cessna152EmergencyScreen> createState() => _Cessna152EmergencyScreenState();
}

class _Cessna152EmergencyScreenState extends State<Cessna152EmergencyScreen> {
  static const Map<String, List<String>> emergencyProcedures = {
  "🛑 Engine Failure During Takeoff Roll": [
    "Throttle                   – IDLE",
    "Flaps                      – UP",
    "Mixture                    – CUT OFF",
    "Ignition Switch            – OFF",
    "Master Switch              – OFF",
    "Fuel Shutoff Valve         – OFF",
  ],
  "🛬 Engine Failure After Takeoff (RWY Available)": [
    "Land on remaining runway",
    "Mixture                    – CUT OFF",
    "Ignition Switch            – OFF",
    "Master Switch              – OFF",
    "Fuel Shutoff Valve         – OFF",
  ],
  "🛫 Engine Failure in Flight": [
    "Airspeed                   – 60 KTS",
    "Best Field                 – CHOOSE",
    "Fuel Shutoff Valve         – ON",
    "Mixture                    – RICH",
    "Carburetor Heat            – ON",
    "Primer                     – IN & LOCKED",
    "Ignition Switch            – BOTH / START",
  ],
  "⛔ If Restart Unsuccessful": [
    "Throttle                   – IDLE",
    "Mixture                    – CUT OFF",
    "Ignition Switch            – OFF",
    "Fuel Shutoff Valve         – OFF",
    "Radio (MAYDAY)             – TRANSMIT",
    "Flaps                      – AS REQUIRED",
    "Doors                      – UNLATCH",
  ],
  "🔥 Engine Fire During Start": [
    "Cranking                   – CONTINUE",
    "If Engine Starts: Power    – 1700 RPM → Engine – SHUTDOWN",
    "If Engine doesn't Start: Throttle – FULL OPEN",
    "Mixture                    – CUT OFF",
    "Cranking                   – CONTINUE",
    "Fire Extinguisher          – OBTAIN",
    "Engine                     – SECURE (Ignition, Master, Fuel OFF)",
    "Fire                       – EXTINGUISH",
  ],
  "🔥 Engine Fire In Flight": [
    "Mixture                    – CUT OFF",
    "Fuel Shutoff Valve         – OFF",
    "Master Switch              – OFF",
    "Cabin Heat & Air           – OFF",
    "Airspeed                   – 85 KTS",
    "⚠️ EXECUTE EMERGENCY LANDING WITHOUT ENGINE POWER",
  ],
  "⚡ Electrical Fire In Flight": [
    "Master Switch              – OFF",
    "All Switches (except ign)  – OFF",
    "Vents & Cabin Air/Heat     – CLOSED",
    "Fire Extinguisher          – ACTIVATE",
    "If Fire Out & Power Needed:",
    "Master Switch              – ON",
    "Circuit Breakers           – CHECK TRIPPED",
    "Radios                     – ON (ONE AT A TIME)",
    "Vents & Cabin Air/Heat     – OPEN",
  ],
  "🔥 Cabin Fire": [
    "Master Switch              – OFF",
    "Vents & Cabin Air/Heat     – CLOSED",
    "Fire Extinguisher          – ACTIVATE",
  ],
  "🔥 Wing Fire": [
    "Navigation Light           – OFF",
    "Strobe Light               – OFF",
    "Pitot Heat                 – OFF",
  ],
  "✈️ Emergency Landing Without Engine Power": [
    "Airspeed                   – 65 KTS (Flaps UP), 60 KTS (Flaps 30°)",
    "Mixture                    – CUT OFF",
    "Fuel Shutoff Valve         – OFF",
    "Ignition Switch            – OFF",
    "Flaps                      – AS REQUIRED",
    "Master Switch              – OFF",
    "Doors (Prior Touchdown)    – UNLATCH",
  ],
  "🟡 Precautionary Landing With Engine Power": [
    "Airspeed                   – 60 KTS",
    "Radios & Electrical Equip  – OFF",
    "Flaps                      – 30° (On final)",
    "Airspeed                   – 55 KTS",
    "Master Switch              – OFF",
    "Doors                      – UNLATCH",
    "Ignition Switch (Post TD)  – OFF",
  ],
  "🌊 Ditching": [
    "Radio                      – MAYDAY",
    "Heavy Objects              – SECURE",
    "Approach                   – INTO WIND / PARALLEL TO SWELLS",
    "Flaps                      – FULL",
    "Descent                    – 300 FT/MIN",
    "Doors                      – UNLATCH",
    "Touchdown                  – LEVEL ATTITUDE",
    "Life Vests                 – INFLATE",
  ],
  "🔋 Electrical Malfunction": [
    "If Ammeter Shows Discharge:",
    "  Alternator              – OFF",
    "  Nonessential Electrical – OFF",
    "  ⚠️ LAND ASAP",
    "If Low Voltage Light:",
    "  Radios                  – OFF",
    "  Alt Circuit Breaker     – CHECK IN",
    "  Master                  – OFF THEN ON",
    "If Light Remains:",
    "  Alternator              – OFF",
    "  Nonessential Electrical – OFF",
    "  ⚠️ LAND ASAP",
  ],
};

  Map<String, Set<int>> _checkedItems = {};

  @override
  void initState() {
    super.initState();
    _loadChecklistState();
  }

  Future<void> _loadChecklistState() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('checkedItems');
    if (data != null) {
      final decoded = json.decode(data) as Map<String, dynamic>;
      setState(() {
        _checkedItems = decoded.map((key, value) =>
            MapEntry(key, Set<int>.from(List<int>.from(value))));
      });
    }
  }

  Future<void> _saveChecklistState() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(
        _checkedItems.map((key, value) => MapEntry(key, value.toList())));
    await prefs.setString('checkedItems', encoded);
  }

  Future<void> _resetChecklist() async {
    setState(() {
      _checkedItems = {};
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('checkedItems');
  }

  void _toggleItem(String section, int index, bool? value) {
    setState(() {
      final set = _checkedItems.putIfAbsent(section, () => <int>{});
      if (value == true) {
        set.add(index);
      } else {
        set.remove(index);
      }
    });
    _saveChecklistState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text("Cessna 152 – Emergency Procedures"),
        backgroundColor: Colors.red,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Reset All",
            onPressed: _resetChecklist,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Cessna152EmergencyGame()),
              );
            },
            child: const Text(
              "🎮 Play Emergency Learning Game",
              style: TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(height: 10),
          ...emergencyProcedures.entries.map((entry) {
            final title = entry.key;
            final steps = entry.value;
            final checked = _checkedItems[title] ?? <int>{};

            return Card(
              color: Colors.grey[850],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ExpansionTile(
                title: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                children: List.generate(steps.length, (index) {
                  final isChecked = checked.contains(index);
                  return CheckboxListTile(
                    title: Text(steps[index], style: const TextStyle(color: Colors.white)),
                    value: isChecked,
                    onChanged: (value) => _toggleItem(title, index, value),
                    activeColor: Colors.green,
                    checkColor: Colors.black,
                    controlAffinity: ListTileControlAffinity.leading,
                  );
                }),
              ),
            );
          }),
        ],
      ),
    );
  }
}