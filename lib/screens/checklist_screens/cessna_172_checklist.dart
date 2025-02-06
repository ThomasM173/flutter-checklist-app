import 'package:flutter/material.dart';
import '../../utils/storage_helper.dart';

class Cessna172ChecklistScreen extends StatefulWidget {
  const Cessna172ChecklistScreen({super.key});

  @override
  _Cessna172ChecklistScreenState createState() => _Cessna172ChecklistScreenState();
}

class _Cessna172ChecklistScreenState extends State<Cessna172ChecklistScreen> {
  Map<String, bool> checklistItems = {
    // ✅ Cabin Checks
    "Documents & Certification – Verify aircraft manual, registration, insurance, weight & balance.": false,
    "Control Lock – REMOVE.": false,
    "Ignition Key – INSERT (OFF position).": false,
    "Master Switch – ON, check battery voltage.": false,
    "Fuel Quantity – CHECK (visually confirm in both tanks).": false,
    "Flaps – EXTEND to full & check movement.": false,
    "Avionics Master – ON, check radios & transponder.": false,

    // ✅ External Walkaround
    "Check propeller & spinner for damage.": false,
    "Oil level – MIN 6 quarts.": false,
    "Carb heat intake – CHECK for blockages (icing risk).": false,
    "Inspect leading edges for ice build-up.": false,
    "Ailerons & flaps – Free & correct movement.": false,
    "Static port – Unblocked.": false,
    "Rudder & elevators – Free movement.": false,
    "Check for frost accumulation.": false,
    "Tyre pressure – CHECK (Cold weather: consider slight overinflation).": false,
    "Brakes – NO hydraulic leaks.": false,

    // ✅ Before Engine Start
    "Fuel Selector Valve – BOTH.": false,
    "Mixture – RICH.": false,
    "Throttle – OPEN 1/4 inch.": false,
    "Beacon Light – ON.": false,
    "Brakes – HOLD.": false,

    // ✅ Engine Start & Warm-Up
    "Prime (if cold start) – 2-4 strokes, then LOCK.": false,
    "Throttle – Set 1000 RPM after start.": false,
    "Oil Pressure – Green within 30 sec.": false,
    "Ammeter & Volts – CHECK charging.": false,
    "Avionics – ON after 1-minute warm-up.": false,

    // ✅ Before Takeoff
    "Throttle – 1800 RPM (Check Magnetos, Carb Heat, Suction, Ammeter & Volts).": false,
    "Flaps – SET for takeoff (as required).": false,
    "Trim – SET for takeoff.": false,
    "ATIS & Runway Info – CONFIRM.": false,

    // ✅ Takeoff Briefing
    "Runway Assigned: 24": false,
    "Wind Consideration: Left crosswind": false,
    "Departure Route: VFR to Southampton": false,

    // ✅ Emergency Considerations
    "🔥 Engine Failure on Takeoff Roll: Throttle idle, brakes apply.": false,
    "🔥 Engine Failure After Takeoff (<500 ft AGL): Land ahead, avoid turns.": false,
    "🔥 Engine Fire: Mixture cutoff, fuel selector OFF, master switch OFF.": false,
  };

  @override
  void initState() {
    super.initState();
    loadChecklist();
  }

  void loadChecklist() async {
    Map<String, bool> savedChecklist = await StorageHelper.loadChecklist("Cessna172");
    setState(() {
      checklistItems = savedChecklist.isNotEmpty ? savedChecklist : checklistItems;
    });
  }

  void updateChecklist(String key, bool value) {
    setState(() {
      checklistItems[key] = value;
    });
    StorageHelper.saveChecklist("Cessna172", checklistItems);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900], // Dark Theme
      appBar: AppBar(title: Text("Cessna 172 - Pre-Flight Checklist"), backgroundColor: Colors.red),
      body: ListView(
        padding: EdgeInsets.all(10),
        children: [
          // 🌡️ AI Insights
          AIInsightCard(
            title: "Cold Weather Detected",
            message: "Carb heat check essential. Ensure avionics warm-up period before startup.",
          ),
          AIInsightCard(
            title: "Gusty Crosswind Takeoff",
            message: "Be prepared for turbulence. Use appropriate aileron deflection for crosswind takeoff.",
          ),
          AIInsightCard(
            title: "Wet Runway Considerations",
            message: "Possible braking inefficiencies on landing. Plan for a longer takeoff roll.",
          ),

          // Checklist Sections
          ChecklistExpansionTile(title: "1️⃣ Cabin Checks", items: checklistItems, updateChecklist: updateChecklist),
          ChecklistExpansionTile(title: "2️⃣ External Walkaround", items: checklistItems, updateChecklist: updateChecklist),
          ChecklistExpansionTile(title: "3️⃣ Before Engine Start", items: checklistItems, updateChecklist: updateChecklist),
          ChecklistExpansionTile(title: "4️⃣ Engine Start & Warm-Up", items: checklistItems, updateChecklist: updateChecklist),
          ChecklistExpansionTile(title: "5️⃣ Before Takeoff", items: checklistItems, updateChecklist: updateChecklist),
          ChecklistExpansionTile(title: "6️⃣ Takeoff Briefing & Clearance", items: checklistItems, updateChecklist: updateChecklist),
          ChecklistExpansionTile(title: "7️⃣ Emergency Considerations", items: checklistItems, updateChecklist: updateChecklist),
        ],
      ),
    );
  }
}

// Expandable Checklist Section
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
            onChanged: (bool? value) {
              updateChecklist(item, value ?? false);
            },
            activeColor: Colors.red,
          );
        }).toList(),
      ),
    );
  }
}

// AI Insights Card
class AIInsightCard extends StatelessWidget {
  final String title;
  final String message;

  const AIInsightCard({super.key, required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.red[400],
      elevation: 3,
      margin: EdgeInsets.symmetric(vertical: 5),
      child: ListTile(
        title: Text(title, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(message, style: TextStyle(color: Colors.white70)),
        leading: Icon(Icons.lightbulb, color: Colors.white),
      ),
    );
  }
}
