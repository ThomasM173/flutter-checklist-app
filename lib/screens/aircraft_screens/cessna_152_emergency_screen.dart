import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/screens/aircraft_screens/cessna_152_emergency_game.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:pdf/widgets.dart' as pdfWidgets;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class Cessna152EmergencyScreen extends StatefulWidget {
  const Cessna152EmergencyScreen({super.key});

  @override
  State<Cessna152EmergencyScreen> createState() => _Cessna152EmergencyScreenState();
}

class _Cessna152EmergencyScreenState extends State<Cessna152EmergencyScreen> {
  late Map<String, Map<String, bool>> checklistSections;
  static const Map<String, List<String>> emergencyProcedures = {
  "ENGINE FAILURE DURING TAKE-OFF ROLL": [
    "Throttle                   – IDLE",
    "Flaps                      – UP",
    "Mixture                    – CUT OFF",
    "Ignition Switch            – OFF",
    "Master Switch              – OFF",
    "Fuel Shutoff Valve         – OFF",
  ],
  "ENGINE FAILURE AFTER TAKE-OFF (RWY Available)": [
    "Land on remaining runway",
    "Mixture                    – CUT OFF",
    "Ignition Switch            – OFF",
    "Master Switch              – OFF",
    "Fuel Shutoff Valve         – OFF",
  ],
  "ENGINE FAILURE AFTER TAKE-OFF (RWY NOT Available)": [
    "Airspeed                   – 70 KTS",
    "Best Field                 – 30° OFF NOSE",
    "Throttle                   – IDLE",
    "Mixture                    – CUT OFF",
    "Fuel Shutoff Valve         – OFF",
    "Ignition Switch            – OFF",
    "Master Switch              – OFF",
  ],
  "ENGINE FAILURE (RESTART)": [
    "Best Field                 – CHOOSE",
    "Airspeed                   – 70 KTS",
    "Pattern                    – ESTABLISH",
    "Fuel Shutoff Valve         – ON",
    "Mixture                    – RICH",
    "Carburetor Heat            – ON",
    "Primer                     – IN & LOCKED",
    "Ignition Switch            – BOTH / START",
  ],
  "IF RESTART UNSUCCESSFUL": [
    "MAYDAY CALL & TRANSPONDER  – TRANSMIT & 7700",
    "Throttle                   – IDLE",
    "Mixture                    – CUT OFF",
    "Fuel Shutoff Valve         – OFF",
    "Ignition Switch            – OFF",
    "Flaps                      – AS REQUIRED - 65KTS",
    "Doors                      – UNLATCH",
  ],
  "ENGINE FAILURE DURING START": [
    "Starter                    – CONTINUE TO CRANK",
    "If Engine Starts: Power    – 1700 RPM FOR FEW MINUTES",
    "Mixture                    – IDLE CUT OFF",
    "If Engine doesn't Start: Throttle – FULL OPEN",
    "Starter                    – CONTINUE TO CRANK",
    "Mixture                    – IDLE CUT OFF",
    "Master Switch              – OFF",
    "Ignition Switch            – OFF",
    "Fuel Selector              – OFF",
    "Fire Extinguisher          – OBTAIN",
    "Fire                       – EXTINGUISH",
  ],
  "ENGINE FIRE IN FLIGHT": [
    "Mixture                    – IDLE CUT OFF",
    "Fuel Selector              – OFF",
    "Master Switch              – OFF",
    "Cabin Heat & Air           – OFF",
    "Airspeed                   – 70 KTS",
    "⚠️ EXECUTE EMERGENCY LANDING WITHOUT ENGINE POWER",
  ],
  "ELECTRICAL FIRE IN FLIGHT": [
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
  "DITCHING": [
    "Radio                      – MAYDAY",
    "Heavy Objects              – SECURE",
    "Approach                   – INTO WIND / PARALLEL TO SWELLS",
    "Flaps                      – FULL",
    "Descent                    – 300 FT/MIN",
    "Doors                      – UNLATCH",
    "Touchdown                  – LEVEL ATTITUDE",
    "Life Vests                 – INFLATE",
  ],
  "ELECTRICAL FAILURE": [
    "If Ammeter Shows Discharge:",
    "  Alternator              – OFF",
    "  Nonessential Electrical – OFF",
    "  ⚠️ LAND ASAP",
    "If Low Voltage Light illuminates:",
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
            pdfWidgets.Text("Cessna 152 Emergency Checklist",
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
    final file = File("${output.path}/Cessna_152_Emergency_Procedures.pdf");
    await file.writeAsBytes(await pdf.save());
    OpenFile.open(file.path);
  } catch (_) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("PDF error occurred.")),
      );
    }
  }
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

Widget _iconButton(IconData icon, String label, Color color, VoidCallback onPressed) {
  return Expanded(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ElevatedButton.icon(
        icon: Icon(icon, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          minimumSize: const Size.fromHeight(60),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: onPressed,
      ),
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Colors.redAccent,
        title: const Text(
          "Cessna 152 – Emergency Procedures",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.restart_alt),
            tooltip: "Reset All",
            onPressed: _resetChecklist,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.menu_book_rounded, color: Colors.white),
            label: const Text(
              "Play Emergency Learning Game",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[400],
              minimumSize: const Size.fromHeight(60), // height 60
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const Cessna152EmergencyGame()),
              );
            },
          ),
          const SizedBox(height: 10),

          // Your checklist expansion tiles
          ...emergencyProcedures.entries.map((entry) {
            final title = entry.key;
            final steps = entry.value;
            final checkedIndices = _checkedItems[title] ?? <int>{};
            final isSectionComplete = checkedIndices.length == steps.length;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: Card(
                color: Colors.white,
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: isSectionComplete ? Colors.green : Colors.black,
                    width: 2,
                  ),
                ),
                elevation: 3,
                shadowColor: Colors.white,
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    iconColor: Colors.black,
                    collapsedIconColor: Colors.black,
                    title: Row(
                      children: [
                        if (isSectionComplete)
                          const Padding(
                            padding: EdgeInsets.only(right: 6.0),
                            child: Icon(Icons.check_circle,
                                color: Colors.green, size: 20),
                          ),
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    childrenPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    children: steps.asMap().entries.map((entryMap) {
                      final index = entryMap.key;
                      final stepText = entryMap.value;
                      final isChecked = checkedIndices.contains(index);

                      return CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          stepText,
                          style:
                              const TextStyle(color: Colors.black, fontSize: 14),
                        ),
                        value: isChecked,
                        onChanged: (bool? value) =>
                            _toggleItem(title, index, value),
                        activeColor: Colors.green,
                        controlAffinity: ListTileControlAffinity.leading,
                      );
                    }).toList(),
                  ),
                ),
              ),
            );
          }).toList(),

          const SizedBox(height: 30),

          Row(
            children: [
              _iconButton(Icons.refresh, 'Reset', Colors.red, _resetChecklist),
              _iconButton(Icons.picture_as_pdf, 'PDF', Colors.blue, generatePDF),
              _iconButton(
                Icons.info_outline,
                'Details',
                Colors.orange,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const Cessna152EmergencyScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

}