import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/checklist_models.dart';
import '../repositories/checklist_repository.dart';

/// Local implementation of ChecklistRepository
/// TODO: Replace with backend API when ready
class LocalChecklistRepository implements ChecklistRepository {
  static const String _customChecklistsKey = 'custom_checklists';

  @override
  Future<void> init() async {
    // Initialize default checklists if needed
    // Defaults are hardcoded and don't need storage
  }

  @override
  Future<ChecklistTemplate?> getChecklistTemplate({
    required String aircraftType,
    String? flightSchoolId,
  }) async {
    // If flight school is provided, check for custom checklist first
    if (flightSchoolId != null) {
      final customChecklists = await getCustomChecklistsBySchool(flightSchoolId);
      try {
        return customChecklists.firstWhere(
          (c) => c.aircraftType == aircraftType,
        );
      } catch (e) {
        // No custom checklist found, fall through to default
      }
    }
    
    // Return default checklist
    return _getDefaultChecklistByType(aircraftType);
  }

  @override
  Future<List<ChecklistTemplate>> getDefaultChecklists() async {
    // Return all default checklists (built-in)
    return [
      _getDefaultChecklistByType('C152')!,
      _getDefaultChecklistByType('C172')!,
      _getDefaultChecklistByType('PA28')!,
    ];
  }

  ChecklistTemplate? _getDefaultChecklistByType(String aircraftType) {
    // These are simplified defaults - in practice, you'd load from your existing screens
    // TODO: Extract actual checklist data from existing checklist screens
    
    switch (aircraftType) {
      case 'C152':
        return ChecklistTemplate(
          id: 'default-c152',
          aircraftType: 'C152',
          sections: [
            ChecklistSection(
              id: 'c152-preflight',
              title: 'Pre-Flight Inspection',
              order: 1,
              items: [
                ChecklistItem(id: '1', text: 'Documents - Check', order: 1),
                ChecklistItem(id: '2', text: 'Fuel Quantity - Check', order: 2),
                ChecklistItem(id: '3', text: 'Oil Level - Check', order: 3),
              ],
            ),
            ChecklistSection(
              id: 'c152-startup',
              title: 'Engine Start',
              order: 2,
              items: [
                ChecklistItem(id: '4', text: 'Parking Brake - Set', order: 1),
                ChecklistItem(id: '5', text: 'Master Switch - ON', order: 2),
                ChecklistItem(id: '6', text: 'Fuel Pump - ON', order: 3),
              ],
            ),
          ],
        );
      
      case 'C172':
        return ChecklistTemplate(
          id: 'default-c172',
          aircraftType: 'C172',
          sections: [
            ChecklistSection(
              id: 'c172-preflight',
              title: 'Pre-Flight Inspection',
              order: 1,
              items: [
                ChecklistItem(id: '1', text: 'Documents - Check', order: 1),
                ChecklistItem(id: '2', text: 'Fuel Quantity - Check', order: 2),
                ChecklistItem(id: '3', text: 'Oil Level - Check (6-8 qts)', order: 3),
              ],
            ),
          ],
        );
      
      case 'PA28':
        return ChecklistTemplate(
          id: 'default-pa28',
          aircraftType: 'PA28',
          sections: [
            ChecklistSection(
              id: 'pa28-preflight',
              title: 'Pre-Flight Inspection',
              order: 1,
              items: [
                ChecklistItem(id: '1', text: 'Documents - Check', order: 1),
                ChecklistItem(id: '2', text: 'Fuel Quantity - Check', order: 2),
                ChecklistItem(id: '3', text: 'Oil Level - Check', order: 3),
              ],
            ),
          ],
        );
      
      default:
        return null;
    }
  }

  @override
  Future<List<ChecklistTemplate>> getCustomChecklistsBySchool(String flightSchoolId) async {
    final prefs = await SharedPreferences.getInstance();
    final checklistsJson = prefs.getString(_customChecklistsKey);
    
    if (checklistsJson == null) {
      return [];
    }
    
    final allChecklists = List<Map<String, dynamic>>.from(json.decode(checklistsJson));
    return allChecklists
        .map((c) => ChecklistTemplate.fromJson(c))
        .where((c) => c.flightSchoolId == flightSchoolId)
        .toList();
  }

  @override
  Future<void> saveChecklistTemplate(ChecklistTemplate template) async {
    final prefs = await SharedPreferences.getInstance();
    final checklistsJson = prefs.getString(_customChecklistsKey);
    
    List<Map<String, dynamic>> checklists = [];
    if (checklistsJson != null) {
      checklists = List<Map<String, dynamic>>.from(json.decode(checklistsJson));
    }
    
    // Remove existing template with same ID if exists
    checklists.removeWhere((c) => c['id'] == template.id);
    
    // Add updated template
    final updatedTemplate = template.copyWith(
      updatedAt: DateTime.now(),
    );
    checklists.add(updatedTemplate.toJson());
    
    await prefs.setString(_customChecklistsKey, json.encode(checklists));
  }

  @override
  Future<void> deleteChecklistTemplate(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final checklistsJson = prefs.getString(_customChecklistsKey);
    
    if (checklistsJson != null) {
      var checklists = List<Map<String, dynamic>>.from(json.decode(checklistsJson));
      checklists.removeWhere((c) => c['id'] == id);
      await prefs.setString(_customChecklistsKey, json.encode(checklists));
    }
  }

  @override
  Future<bool> hasCustomChecklist({
    required String aircraftType,
    required String flightSchoolId,
  }) async {
    final customChecklists = await getCustomChecklistsBySchool(flightSchoolId);
    return customChecklists.any((c) => c.aircraftType == aircraftType);
  }
}
