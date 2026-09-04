/// One completed pre-boarding checklist. Mirrors `public.checklist_completions`.
class ChecklistCompletion {
  final String id;
  final String userId;
  final String? flightSchoolId;
  final String aircraftType;
  final String checklistName;
  final DateTime completedAt;
  final String? pdfStoragePath;
  final DateTime? createdAt;
  final String completionType;

  /// Populated only for the flight-school admin list (PostgREST embed of
  /// `profiles.full_name`). Null on the pilot's own list.
  final String? pilotName;

  const ChecklistCompletion({
    required this.id,
    required this.userId,
    required this.aircraftType,
    required this.checklistName,
    required this.completedAt,
    this.flightSchoolId,
    this.pdfStoragePath,
    this.createdAt,
    this.completionType = 'checklist',
    this.pilotName,
  });

  factory ChecklistCompletion.fromMap(Map<String, dynamic> map) {
    final profile = map['profiles'];
    return ChecklistCompletion(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      flightSchoolId: map['flight_school_id'] as String?,
      aircraftType: map['aircraft_type'] as String? ?? '',
      checklistName: map['checklist_name'] as String? ?? '',
      completedAt: DateTime.parse(map['completed_at'].toString()).toLocal(),
      pdfStoragePath: map['pdf_storage_path'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())?.toLocal()
          : null,
      completionType: map['completion_type'] as String? ?? 'checklist',
      pilotName: profile is Map ? profile['full_name'] as String? : null,
    );
  }

  bool get hasPdf => (pdfStoragePath ?? '').isNotEmpty;

  /// Human-readable label for [completionType], for filters/list rows.
  static const Map<String, String> typeLabels = {
    'checklist': 'Checklist',
    'tech_log': 'Tech Log',
    'fuel_uplift': 'Fuel Uplift',
    'departure_briefing': 'Departure Briefing',
    'passenger_brief': 'Passenger Brief',
    'weight_balance': 'Weight & Balance',
    'emergency_procedures': 'Emergency Procedures',
    'pave_assessment': 'PAVE Assessment',
  };

  String get completionTypeLabel =>
      typeLabels[completionType] ?? completionType;
}
