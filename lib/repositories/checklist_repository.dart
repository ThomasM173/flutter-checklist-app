import '../models/checklist_models.dart';

/// Abstract checklist repository
/// TODO: Replace with backend API when ready
abstract class ChecklistRepository {
  /// Initialize the repository
  Future<void> init();
  
  /// Get checklist template for an aircraft type
  /// Returns custom template if exists for the flight school, otherwise default
  Future<ChecklistTemplate?> getChecklistTemplate({
    required String aircraftType,
    String? flightSchoolId,
  });
  
  /// Get all default (built-in) checklists
  Future<List<ChecklistTemplate>> getDefaultChecklists();
  
  /// Get all custom checklists for a flight school
  Future<List<ChecklistTemplate>> getCustomChecklistsBySchool(String flightSchoolId);
  
  /// Save or update a custom checklist template
  Future<void> saveChecklistTemplate(ChecklistTemplate template);
  
  /// Delete a custom checklist template
  Future<void> deleteChecklistTemplate(String id);
  
  /// Check if a custom checklist exists for an aircraft type and flight school
  Future<bool> hasCustomChecklist({
    required String aircraftType,
    required String flightSchoolId,
  });
}
