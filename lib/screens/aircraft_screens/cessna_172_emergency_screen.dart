import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/aircraft_screens/cessna_172_emergency_game.dart';

class Cessna172EmergencyScreen extends StatelessWidget {
  static const Map<String, List<String>> emergencyProcedures = {
  "✈️ ENGINE FAILURE AFTER TAKEOFF": [
    "Airspeed                  – 65 KIAS",
    "Mixture                   – IDLE CUTOFF",
    "Fuel Valve                – OFF",
    "Ignition Switch           – OFF",
    "Doors                     – OPEN",
  ],
  "🛫 ENGINE FAILURE DURING FLIGHT": [
    "Airspeed                  – 65 KIAS [FLAPS UP], 60 KIAS [FLAPS DOWN]",
    "Carb Heat                 – ON",
    "Primer                    – IN & LOCKED",
    "Fuel Valve                – ON",
    "Mixture                   – RICH",
    "Ignition                  – BOTH / START",
    "🔍 Refer to POH for details",
  ],
  "🛬 EMERGENCY LANDING WITHOUT POWER": [
    "Airspeed                  – 65 KIAS [FLAPS UP], 60 KIAS [FLAPS DOWN]",
    "Mixture                   – IDLE CUTOFF",
    "Fuel Valve                – OFF",
    "Ignition Switch           – OFF",
    "Wing Flaps                – AS REQUIRED",
    "Master Switch             – OFF",
    "Doors                     – OPEN BEFORE TOUCHDOWN",
    "Touchdown                 – TAIL LOW",
    "Brakes                    – APPLY HEAVILY",
  ],
  "🔥 ENGINE FIRE ON GROUND": [
    "Cranking                  – CONTINUE TO START ENGINE",
    "If Engine Starts:         – POWER 1700 RPM (Few Min), then SHUT DOWN",
    "If Engine Fails to Start:",
    "  Throttle                – FULL OPEN",
    "  Mixture                 – IDLE CUTOFF",
    "  Cranking                – CONTINUE",
    "ENGINE SECURE:",
    "  Master Switch           – OFF",
    "  Ignition Switch         – OFF",
    "  Fuel Valve              – OFF",
    "  Fire                    – EXTINGUISH",
    "  Aircraft                – INSPECT FOR DAMAGE",
  ],
  "🔥 ENGINE FIRE IN FLIGHT": [
    "Mixture                   – IDLE CUTOFF",
    "Fuel Valve                – OFF",
    "Master Switch             – OFF",
    "Cabin Heat & Air          – OFF",
    "Airspeed                  – 100 KIAS or as required to extinguish fire",
    "Forced Landing            – EXECUTE",
  ],
  "⚡ ELECTRICAL FIRE IN FLIGHT": [
    "Master / Avionics Switch  – OFF",
    "All Other Switches (exc. Ignition) – OFF",
    "Vents / Cabin Air / Heat  – OFF",
    "Fire Extinguisher         – ACTIVATE",
    "When Fire Appears Out:",
    "  Master Switch           – ON",
    "  Circuit Breakers        – CHECK (DON'T RESET)",
    "  Avionics Switch         – ON",
    "  Radio & Electric        – ON, ONE AT A TIME",
    "  Ventilate               – CABIN",
  ],
  "🔋 OVER VOLTAGE LIGHT ON": [
    "Avionics Switch           – OFF",
    "Master Switch             – OFF",
    "Master Switch             – ON",
    "Light                     – CHECK (IF STILL ON)",
    "⚠️ TERMINATE FLIGHT",
  ],
  "⚠️ AMMETER DISCHARGE": [
    "Alternator                – OFF",
    "Electrical Load           – REDUCE",
    "⚠️ TERMINATE FLIGHT ASAP",
  ],
};


  const Cessna172EmergencyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text("Cessna 172 – Emergency Procedures"),
        backgroundColor: Colors.red,
      ),
      body: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Cessna172EmergencyGame()),
              );
            },
            child: const Text(
              "🎮 Play Emergency Learning Game",
              style: TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(height: 10),
          ...emergencyProcedures.entries.map((entry) {
            return Card(
              color: Colors.grey[850],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ExpansionTile(
                title: Text(
                  entry.key,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                children: entry.value
                    .map(
                      (item) => ListTile(
                        title: Text(item, style: const TextStyle(color: Colors.white)),
                        dense: true,
                      ),
                    )
                    .toList(),
              ),
            );
          }),
        ],
      ),
    );
  }
}
