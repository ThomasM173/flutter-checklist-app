import 'package:flutter/material.dart';
import '../../utils/storage_helper.dart';
import '../../widget/checklist_expansion_title.dart';

class PiperPA28ChecklistScreen extends StatefulWidget {
  const PiperPA28ChecklistScreen({super.key});

  @override
  _PiperPA28ChecklistScreenState createState() => _PiperPA28ChecklistScreenState();
}

class _PiperPA28ChecklistScreenState extends State<PiperPA28ChecklistScreen> {
  Map<String, bool> checklistItems = {
    "✅ Control Lock Removed": false,
    "✅ Master Switch - ON": false,
    "✅ Fuel Quantity - CHECKED": false,
    "✅ Avionics - ON": false,
  };

  @override
  void initState() {
    super.initState();
    loadChecklist();
  }

  void loadChecklist() async {
    Map<String, bool> savedChecklist = await StorageHelper.loadChecklist("PiperPA28");
    setState(() {
      checklistItems = savedChecklist.isNotEmpty ? savedChecklist : checklistItems;
    });
  }

  void updateChecklist(String key, bool value) {
    setState(() {
      checklistItems[key] = value;
    });
    StorageHelper.saveChecklist("PiperPA28", checklistItems);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Piper PA-28 - Pre-Flight Checklist"), backgroundColor: Colors.red),
      body: ListView(
        children: [
          ChecklistExpansionTile(title: "Pre-Flight Checks", checklistItems: checklistItems, updateChecklist: updateChecklist),
        ],
      ),
    );
  }
}
