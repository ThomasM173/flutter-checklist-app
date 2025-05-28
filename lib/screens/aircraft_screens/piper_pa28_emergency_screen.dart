import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/aircraft_screens/piper_pa28_emergency_game.dart';

class PiperPA28EmergencyScreen extends StatelessWidget {
  static const Map<String, List<String>> emergencyProcedures = {
  "🚒 ENGINE FIRE DURING START-UP": [
    "Starter                          – Crank engine",
    "Mixture                          – Idle cut-off",
    "Throttle                         – OPEN",
    "Electrical Fuel Pump             – OFF",
    "Fuel Selector                    – OFF",
    "If fire continues                – Abandon, brake OFF, take extinguisher, alert ground crew",
  ],

  "✈️ ENGINE POWER LOSS DURING TAKE-OFF": [
    "If runway remains               – Land straight ahead",
    "If insufficient runway"
      "Maintain safe airspeed        – Lower nose",
      "Turn                          – Shallow only to avoid obstructions",
      "Flaps                         – As situation requires",
      "Do not turn back              – On initial climb-out",
    "If altitude for restart"
      "Maintain safe airspeed        – True",
      "Fuel Selector                 – Change tanks",
      "Electric Pump                 – Check ON",
      "Mixture                       – Check RICH",
      "Carburettor Heat              – ON",
      "Primer                        – LOCKED",
    "If no restart                   – Proceed power-off landing",
    "After landing                   – Master OFF / Fuel OFF / MAYDAY if time permits",
  ],

  "🛫 ENGINE POWER LOSS IN FLIGHT": [
    "Turn down-wind                  – Increases glide range",
    "Establish glide attitude        – Trim for best glide",
    "Select field                    – Towards wing-tip if possible",
    "Plan approach                   – Constant aspect technique",
    "Then check cause of loss"
      "Fuel Selector                 – Switch tanks",
      "Electric Fuel Pump            – ON",
      "Mixture                       – RICH",
      "Carburettor Heat              – ON",
      "Engine Gauges                 – Check for cause indication",
      "Primer                        – Check LOCKED"
    "If no fuel pressure"
      "Fuel Selector                 – Ensure tank contains fuel",
    "If power restored"
      "Carburettor Heat              – OFF",
      "Electric Fuel Pump            – OFF",
    "If still no power               – Prepare power-off landing",
    "MAYDAY                          – Call and set 7700",
    "Landing touchdown               – Lowest airspeed, full flaps",
    "When committed"
      "Fuel                          – OFF",
      "Ignition                      – OFF",
      "Electrics (Master)            – ALL OFF",
      "Lap Strap                     – TIGHT",
      "Door                          – CRACKED OPEN",
    ],

  "🔥 FIRE IN FLIGHT": [
    "Electrical Fire (smoke):"
      "Master Switch                 – OFF",
      "Vents                         – OPEN",
      "Cabin Heat                    – OFF",
      "Fire Extinguisher             – Use only if absolutely necessary",
      "If source apparent            – Restore other services",
      "Land                          – As soon as practicable",
    ],
    "Engine Fire:": [
      "Fuel Selector                 – OFF",
      "Throttle                      – CLOSED",
      "Mixture                       – Idle cut-off",
      "Fuel Pump                     – Check OFF",
      "Heater                        – OFF",
      "Defroster                     – OFF",
      "Do not restart                – Proceed with power-off landing",
    ],

  "⚠️ LOSS OF OIL PRESSURE": [
    "Check oil temp gauge            – If normal, suspect gauge failure",
    "Land                            – As soon as possible",
    "Prepare                         – POWER-OFF LANDING",
  ],

  "🌡️ HIGH OIL TEMPERATURE": [
    "Check oil pressure              – If low/zero, prepare POWER-OFF LANDING",
    "If pressure normal:" 
      "Reduce power                  – Richen mixture",
      "Increase airspeed             – If in climb",
    "Land                            – Nearest airport, investigate",
    "Prepare                         – POWER-OFF LANDING",
  ],

  "🔋 ALTERNATOR FAILURE": [
    "ALT light on / low-volt flashing– Ammeter: verify alternator inoperative",
    "If ammeter zero                 – Check circuit breaker",
    "If breaker normal:"
      "ALT Switch                    – OFF, wait 5s, ON again",
    "If still no power"
      "ALT Switch                    – OFF",
      "Electrical loads              – Reduce to essential",
      "Land                          – As soon as practicable",
      "Advise ATC                    – 121.50 if required",
      "Anticipate                    – Complete electrical failure",
    ],
  

  "📻 RADIO FAILURE": [
    "Radio                           – Check freq, volume, squelch, switches, Radio Master",
    "Headset                         – Check plugs secure, try spare",
    "Ammeter/Master/Circuit Breakers – Check, reset once only",
    "Transponder                     – Set 7600",
    "Procedure                       – Speechless/transmit blind as appropriate",
  ],
};


  const PiperPA28EmergencyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
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
