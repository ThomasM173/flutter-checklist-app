import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../repositories/local_pdf_repository.dart';
import '../services/auth_service_manager.dart';
import '../models/pdf_record.dart';

/// Helper for managing PDF storage with flight school integration
/// Wraps the PDF repository to provide a simple interface for screens
class PdfStorageHelper {
  static final PdfStorageHelper _instance = PdfStorageHelper._internal();
  factory PdfStorageHelper() => _instance;
  PdfStorageHelper._internal();

  final _pdfRepo = LocalPdfRepository();
  final _authService = AuthServiceManager();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    await _pdfRepo.init();
    _initialized = true;
  }

  /// Save a PDF and register it in the repository
  /// Returns the file path for opening/sharing
  /// 
  /// [pdfBytes] - The PDF file content
  /// [title] - Display title for the PDF
  /// [pdfType] - Type of PDF (weight_balance, tech_log, etc.)
  /// [aircraftType] - Optional aircraft type (C152, C172, etc.)
  /// [aircraftRegistration] - Optional aircraft registration
  Future<String> savePdf({
    required List<int> pdfBytes,
    required String title,
    required String pdfType,
    String? aircraftType,
    String? aircraftRegistration,
  }) async {
    if (!_initialized) await init();
    
    // Save PDF to temporary location first
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final tempPath = '${tempDir.path}/$timestamp\_$pdfType.pdf';
    final tempFile = File(tempPath);
    await tempFile.writeAsBytes(pdfBytes);
    
    // Get current user info
    final user = _authService.currentUser;
    final pilotName = user?.fullName;
    final pilotId = user?.id;
    final flightSchoolId = user?.flightSchoolId;
    
    // Register PDF in repository (this will copy it to managed location)
    final pdfRecord = await _pdfRepo.savePdf(
      localPath: tempPath,
      title: title,
      pdfType: pdfType,
      pilotName: pilotName,
      pilotId: pilotId,
      aircraftType: aircraftType,
      aircraftRegistration: aircraftRegistration,
      flightSchoolId: flightSchoolId,
    );
    
    // Delete temp file
    try {
      await tempFile.delete();
    } catch (e) {
      // Ignore deletion errors
    }
    
    // Return the managed file path for opening/sharing
    return pdfRecord.localPath;
  }

  /// Get all PDFs for the current flight school (admin only)
  Future<List<PdfRecord>> getFlightSchoolPdfs() async {
    if (!_initialized) await init();
    
    final flightSchoolId = _authService.flightSchoolId;
    if (flightSchoolId == null) {
      throw Exception('No flight school ID found');
    }
    
    return await _pdfRepo.getPdfsByFlightSchool(flightSchoolId);
  }

  /// Get all PDFs for the current pilot
  Future<List<PdfRecord>> getMyPdfs() async {
    if (!_initialized) await init();
    
    final pilotId = _authService.currentUser?.id;
    if (pilotId == null) {
      throw Exception('Not logged in');
    }
    
    return await _pdfRepo.getPdfsByPilot(pilotId);
  }
}
