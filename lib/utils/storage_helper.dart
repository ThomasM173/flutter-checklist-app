import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class StorageHelper {
  static Future<void> saveChecklist(String aircraft, Map<String, bool> checklist) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String encodedData = jsonEncode(checklist);
    prefs.setString('checklist_$aircraft', encodedData);
  }

  static Future<Map<String, bool>> loadChecklist(String aircraft) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? encodedData = prefs.getString('checklist_$aircraft');
    
    if (encodedData != null) {
      return Map<String, bool>.from(jsonDecode(encodedData));
    }
    return {}; // Return empty if nothing is saved
  }
}
