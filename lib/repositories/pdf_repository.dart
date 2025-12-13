import '../models/pdf_record.dart';

/// Abstract PDF repository
/// TODO: Replace with S3 + database implementation when ready
abstract class PdfRepository {
  /// Initialize the repository
  Future<void> init();
  
  /// Save a PDF and its metadata
  /// Returns the created PdfRecord with storage paths
  Future<PdfRecord> savePdf({
    required String localPath,
    required String title,
    required String pdfType,
    String? pilotName,
    String? pilotId,
    String? aircraftType,
    String? aircraftRegistration,
    String? flightSchoolId,
  });
  
  /// Get all PDFs for a specific flight school
  Future<List<PdfRecord>> getPdfsByFlightSchool(String flightSchoolId);
  
  /// Get all PDFs for a specific pilot
  Future<List<PdfRecord>> getPdfsByPilot(String pilotId);
  
  /// Search PDFs by various criteria
  Future<List<PdfRecord>> searchPdfs({
    String? flightSchoolId,
    String? pilotName,
    String? aircraftType,
    String? pdfType,
    DateTime? startDate,
    DateTime? endDate,
  });
  
  /// Get a single PDF by ID
  Future<PdfRecord?> getPdfById(String id);
  
  /// Update PDF metadata
  Future<void> updatePdf(PdfRecord pdf);
  
  /// Delete a PDF
  Future<void> deletePdf(String id);
  
  /// Upload PDF to cloud storage (when available)
  /// TODO: Implement S3 upload
  Future<String?> uploadToCloud(String localPath);
}
