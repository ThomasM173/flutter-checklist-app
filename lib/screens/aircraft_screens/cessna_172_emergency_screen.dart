import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/aircraft_screens/cessna_172_emergency_game.dart';

class Cessna172EmergencyScreen extends StatelessWidget {
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
    "Airspeed                   – 80 KTS",
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
    "Starter                    – CONTINUE TO CRANK",
    "If Engine Starts: Power    – 1700 RPM → Engine – SHUTDOWN",
    "If Engine doesn't Start: Throttle – FULL OPEN",
    "Mixture                    – CUT OFF",
    "Fuel Selector              – CHANGE TANKS",
    "Fire Extinguisher          – OBTAIN",
    "Engine                     – SECURE (Ignition, Master, Fuel OFF)",
    "Fire                       – EXTINGUISH",
  ],
  "🔥 Engine Fire In Flight": [
    "Mixture                    – CUT OFF",
    "Fuel Shutoff Valve         – OFF",
    "Master Switch              – OFF",
    "Cabin Heat & Air           – OFF",
    "Airspeed                   – 80 KTS",
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


  const Cessna172EmergencyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text("Cessna 172 – Emergency Procedures"),
        backgroundColor: Colors.redAccent,
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
              color: Colors.grey[600],
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
