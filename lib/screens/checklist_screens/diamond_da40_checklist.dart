import 'package:flutter/material.dart';
import '../../utils/storage_helper.dart';
import '../../widget/checklist_expansion_title.dart';

class DiamondDA40ChecklistScreen extends StatefulWidget {
  const DiamondDA40ChecklistScreen({super.key});

  @override
  _DiamondDA40ChecklistScreenState createState() => _DiamondDA40ChecklistScreenState();
}

class _DiamondDA40ChecklistScreenState extends State<DiamondDA40ChecklistScreen> {
  Map<String, bool> checklistItems = {
    "✅ Documents Verified": false,
    "✅ Master Switch - ON": false,
    "✅ Fuel Selector - BOTH": false,
    "✅ Flaps - CHECK": false,
  };

  @override
  void initState() {
    super.initState();
    loadChecklist();
  }

  void loadChecklist() async {
    Map<String, bool> savedChecklist = await StorageHelper.loadChecklist("DiamondDA40");
    setState(() {
      checklistItems = savedChecklist.isNotEmpty ? savedChecklist : checklistItems;
    });
  }

  void updateChecklist(String key, bool value) {
    setState(() {
      checklistItems[key] = value;
    });
    StorageHelper.saveChecklist("DiamondDA40", checklistItems);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Diamond DA40 - Pre-Flight Checklist"), backgroundColor: Colors.red),
      body: ListView(
        children: [
          ChecklistExpansionTile(title: "Pre-Flight Checks", checklistItems: checklistItems, updateChecklist: updateChecklist),
        ],
      ),
    );
  }
}
