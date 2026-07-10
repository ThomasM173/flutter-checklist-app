/// Metadata record for a generated PDF
class PdfRecord {
  final String id;
  final String filename;
  final String title;
  final String? pilotName;
  final String? pilotId;
  final String? aircraftType;
  final String? aircraftRegistration;
  final String? flightSchoolId;
  final DateTime createdAt;
  final String localPath; // Local file system path
  final String? cloudUrl; // Cloud storage URL, if uploaded
  final String status; // draft, uploaded, archived
  final String pdfType; // weight_balance, tech_log, fuel_uplift, etc.
  
  PdfRecord({
    required this.id,
    required this.filename,
    required this.title,
    this.pilotName,
    this.pilotId,
    this.aircraftType,
    this.aircraftRegistration,
    this.flightSchoolId,
    DateTime? createdAt,
    required this.localPath,
    this.cloudUrl,
    this.status = 'uploaded',
    required this.pdfType,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'filename': filename,
    'title': title,
    'pilotName': pilotName,
    'pilotId': pilotId,
    'aircraftType': aircraftType,
    'aircraftRegistration': aircraftRegistration,
    'flightSchoolId': flightSchoolId,
    'createdAt': createdAt.toIso8601String(),
    'localPath': localPath,
    'cloudUrl': cloudUrl,
    'status': status,
    'pdfType': pdfType,
  };

  factory PdfRecord.fromJson(Map<String, dynamic> json) => PdfRecord(
    id: json['id'],
    filename: json['filename'],
    title: json['title'],
    pilotName: json['pilotName'],
    pilotId: json['pilotId'],
    aircraftType: json['aircraftType'],
    aircraftRegistration: json['aircraftRegistration'],
    flightSchoolId: json['flightSchoolId'],
    createdAt: DateTime.parse(json['createdAt']),
    localPath: json['localPath'],
    cloudUrl: json['cloudUrl'],
    status: json['status'] ?? 'uploaded',
    pdfType: json['pdfType'],
  );

  PdfRecord copyWith({
    String? id,
    String? filename,
    String? title,
    String? pilotName,
    String? pilotId,
    String? aircraftType,
    String? aircraftRegistration,
    String? flightSchoolId,
    DateTime? createdAt,
    String? localPath,
    String? cloudUrl,
    String? status,
    String? pdfType,
  }) {
    return PdfRecord(
      id: id ?? this.id,
      filename: filename ?? this.filename,
      title: title ?? this.title,
      pilotName: pilotName ?? this.pilotName,
      pilotId: pilotId ?? this.pilotId,
      aircraftType: aircraftType ?? this.aircraftType,
      aircraftRegistration: aircraftRegistration ?? this.aircraftRegistration,
      flightSchoolId: flightSchoolId ?? this.flightSchoolId,
      createdAt: createdAt ?? this.createdAt,
      localPath: localPath ?? this.localPath,
      cloudUrl: cloudUrl ?? this.cloudUrl,
      status: status ?? this.status,
      pdfType: pdfType ?? this.pdfType,
    );
  }
}
