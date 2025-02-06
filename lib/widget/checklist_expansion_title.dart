import 'package:flutter/material.dart';

class ChecklistExpansionTile extends StatelessWidget {
  final String title;
  final Map<String, bool> checklistItems;
  final Function(String, bool) updateChecklist;

  const ChecklistExpansionTile({super.key, required this.title, required this.checklistItems, required this.updateChecklist});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(title, style: TextStyle(color: Colors.white)),
      children: checklistItems.keys.map((item) {
        return CheckboxListTile(
          title: Text(item, style: TextStyle(color: Colors.white)),
          value: checklistItems[item],
          onChanged: (bool? value) {
            updateChecklist(item, value ?? false);
          },
        );
      }).toList(),
    );
  }
}
