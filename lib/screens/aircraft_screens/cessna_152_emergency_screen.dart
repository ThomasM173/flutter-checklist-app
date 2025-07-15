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
    "Airspeed                   – 70 KTS",
    "Best Field                 – CHOOSE",
    "Fuel Shutoff Valve         – ON",
    "Mixture                    – RICH",
    "Carburetor Heat            – ON",
    "Primer                     – IN & LOCKED",
    "Ignition Switch            – BOTH / START",
  ],
  "⛔ If Restart Unsuccessful": [
    "MAYDAY CALL & TRANSPONDER  – TRANSMIT & 7700",
    "Throttle                   – IDLE",
    "Mixture                    – CUT OFF",
    "Fuel Shutoff Valve         – OFF",
    "Ignition Switch            – OFF",
    "Flaps                      – AS REQUIRED - 65KTS",
    "Doors                      – UNLATCH",
  ],
  "🔥 Engine Fire During Start": [
    "Starter                    – CONTINUE TO CRANK",
    "If Engine Starts: Power    – 1700 RPM → Engine – SHUTDOWN",
    "If Engine doesn't Start: Throttle – FULL OPEN",
    "Mixture                    – CUT OFF",
    "Fuel Selector              – OFF",
    "Fire Extinguisher          – OBTAIN",
    "Engine                     – SECURE (Ignition, Master, Fuel OFF)",
    "Fire                       – EXTINGUISH",
  ],
  "🔥 Engine Fire In Flight": [
    "Mixture                    – CUT OFF",
    "Fuel Shutoff Valve         – OFF",
    "Master Switch              – OFF",
    "Cabin Heat & Air           – OFF",
    "Airspeed                   – 70 KTS",
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
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Colors.redAccent, // Sky blue top bar
        title: const Text(
          "Cessna 152 – Emergency Procedures",
          style: TextStyle(color: Colors.white), // Black title text
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.restart_alt), // More formal reset icon
            tooltip: "Reset All",
            onPressed: _resetChecklist,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.menu_book_rounded),
            label: const Text(
              "Play Emergency Learning Game",
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Cessna152EmergencyGame()),
              );
            },
          ),
          const SizedBox(height: 10),
          ...emergencyProcedures.entries.map((entry) {
            final title = entry.key;
            final steps = entry.value;
            final checked = _checkedItems[title] ?? <int>{};

            return Card(
              color: Colors.white, // Drop-down background white
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: Colors.black), // Black border
              ),
              margin: const EdgeInsets.symmetric(vertical: 8),
              elevation: 4,
              shadowColor: Colors.grey[600],
              child: ExpansionTile(
                iconColor: Colors.black,
                collapsedIconColor: Colors.black,
                title: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.black, // Title text in black
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                children: List.generate(steps.length, (index) {
                  final isChecked = checked.contains(index);
                  return CheckboxListTile(
                    title: Text(
                      steps[index],
                      style: const TextStyle(color: Colors.black), // Checklist text black
                    ),
                    value: isChecked,
                    onChanged: (value) => _toggleItem(title, index, value),
                    activeColor: Colors.black, // Black checkbox
                    checkColor: Colors.white, // White tick
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