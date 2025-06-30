import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/aircraft_screens/piper_pa28_emergency_game.dart';

class PiperPA28EmergencyScreen extends StatelessWidget {
  static const Map<String, List<String>> emergencyProcedures = {
  "🛑 Engine Failure During Takeoff Roll": [
    "Throttle                   – IDLE",
    "Brakes                     – APPLY",
    "Mixture                    – CUT OFF",
    "Fuel Pump                  – OFF",
    "Fuel Selector              – OFF",
    "Magnetos                   – OFF",
    "Master Switch              – OFF"
  ],
  "🛬 Engine Failure After Takeoff (RWY Available)": [
    "Pitch                      – NOSE DOWN, 73 KTS",
    "Land on remaining runway",
    "Mixture                    – CUT OFF",
    "Fuel Pump                  – OFF",
    "Fuel Selector              – OFF",
    "Magnetos                   – OFF",
    "Master Switch              – OFF"
  ],
  "🛫 Engine Failure in Flight": [
    "Airspeed                   – 73 KTS (BEST GLIDE)",
    "Best Field                 – SELECT",
    "Fuel Selector              – SWITCH TANKS",
    "Fuel Pump                  – ON",
    "Mixture                    – RICH",
    "Carburetor Heat            – ON",
    "Primer                     – LOCKED",
    "Magnetos                   – CHECK L / R / BOTH / START"
  ],
  "⛔ If Restart Unsuccessful": [
    "Throttle                   – IDLE",
    "Mixture                    – CUT OFF",
    "Fuel Pump                  – OFF",
    "Fuel Selector              – OFF",
    "Magnetos                   – OFF",
    "Harnesses                  – TIGHT",
    "Flaps                      – AS REQUIRED",
    "Doors                      – UNLATCH",
    "Radio (MAYDAY)             – TRANSMIT",
    "Master Switch              – OFF"
  ],
  "🔥 Engine Fire During Start": [
    "Starter                    – CONTINUE TO CRANK",
    "If Engine Starts: Throttle – OPEN SLIGHTLY → RUN 1700 RPM → SHUTDOWN",
    "If Engine doesn’t Start:",
    "  Throttle                 – FULL OPEN",
    "  Mixture                  – CUT OFF",
    "  Fuel Pump                – OFF",
    "  Fuel Selector            – OFF",
    "  Magnetos                 – OFF",
    "  Master Switch            – OFF",
    "  Fire Extinguisher        – OBTAIN",
    "  Vacate Aircraft          – TO SAFE DISTANCE UPWIND"
  ],
  "🔥 Engine Fire In Flight": [
    "Mixture                    – CUT OFF",
    "Fuel Pump                  – OFF",
    "Fuel Selector              – OFF",
    "Magnetos                   – OFF",
    "Throttle                   – CLOSED",
    "Master Switch              – OFF",
    "Cabin Vents                – OPEN",
    "Attempt to Increase Airflow Over Engine",
    "⚠️ EXECUTE EMERGENCY LANDING WITHOUT ENGINE POWER"
  ],
  "⚡ Electrical Fire In Flight": [
    "Master Switch              – OFF",
    "Cabin Heat                 – OFF",
    "Vents                      – OPEN",
    "Fire Extinguisher          – ACTIVATE",
    "⚠️ LAND AS SOON AS PRACTICAL"
  ],
  "🔥 Cabin Fire": [
    "Master Switch              – OFF",
    "Cabin Heat & Vents         – CLOSED",
    "Fire Extinguisher          – ACTIVATE"
  ],
  "🔥 Wing Fire": [
    "Navigation Light           – OFF",
    "Strobe Light               – OFF",
    "Pitot Heat                 – OFF"
  ],
  "🟡 Precautionary Landing With Engine Power": [
    "Airspeed                   – 60 KTS",
    "Landing Area               – SELECT",
    "Radios & Electrical Equip  – OFF",
    "Flaps                      – AS REQUIRED",
    "Final Approach Speed       – 55 KTS",
    "Harnesses                  – SECURE",
    "Doors                      – UNLATCH",
    "Ignition Switch (Post TD)  – OFF",
    "Master Switch              – OFF"
  ],
  "🌊 Ditching": [
    "Radio                      – MAYDAY",
    "Passengers                 – BRIEF",
    "Heavy Objects              – SECURE",
    "Approach                   – INTO WIND / PARALLEL TO SWELLS",
    "Flaps                      – FULL",
    "Descent Rate               – 300 FT/MIN",
    "Doors                      – UNLATCH",
    "Touchdown                  – LEVEL ATTITUDE",
    "Life Vests                 – INFLATE AFTER EXIT"
  ],
  "🔋 Electrical Malfunction": [
    "If Ammeter Shows Discharge or Voltage Light ON:",
    "  Radios                  – OFF",
    "  Master Switch           – OFF for 2 sec → ON",
    "  Alternator              – CHECK OUTPUT",
    "  Circuit Breakers        – CHECK / RESET ONCE ONLY",
    "If No Output:",
    "  Alternator              – OFF",
    "  Reduce Electrical Load",
    "  Use Only Essential Systems",
    "  ⚠️ LAND ASAP"
  ],
};
  const PiperPA28EmergencyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text("Piper PA28 – Emergency Procedures"),
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
                MaterialPageRoute(builder: (context) => const PiperPA28EmergencyGame()),
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
