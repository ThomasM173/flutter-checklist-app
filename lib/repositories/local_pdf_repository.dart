import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/pdf_record.dart';
import '../repositories/pdf_repository.dart';

/// Local PDF repository implementation that stores metadata in shared preferences.
/// This is suitable for local development and testing.
class LocalPdfRepository implements PdfRepository {
  static const String _pdfsKey = 'pdf_records';
  static const String _pdfsDirName = 'flight_pdfs';

  Directory? _pdfsDirectory;
  final _uuid = const Uuid();

  @override
  Future<void> init() async {
    // Create directory for storing PDFs
    final appDir = await getApplicationDocumentsDirectory();
    _pdfsDirectory = Directory('${appDir.path}/$_pdfsDirName');

    if (!await _pdfsDirectory!.exists()) {
      await _pdfsDirectory!.create(recursive: true);
    }
  }

  @override
  Future<PdfRecord> savePdf({
    required String localPath,
    required String title,
    required String pdfType,
    String? pilotName,
    String? pilotId,
    String? aircraftType,
    String? aircraftRegistration,
    String? flightSchoolId,
  }) async {
    if (_pdfsDirectory == null) {
      await init();
    }

    final id = _uuid.v4();
    final filename = '${DateTime.now().millisecondsSinceEpoch}_$pdfType.pdf';
    final targetPath = '${_pdfsDirectory!.path}/$filename';

    // Copy PDF to managed location
    final sourceFile = File(localPath);
    await sourceFile.copy(targetPath);

    // Create PDF record
    final record = PdfRecord(
      id: id,
      filename: filename,
      title: title,
      pilotName: pilotName,
      pilotId: pilotId,
      aircraftType: aircraftType,
      aircraftRegistration: aircraftRegistration,
      flightSchoolId: flightSchoolId,
      localPath: targetPath,
      pdfType: pdfType,
      status: 'uploaded',
    );

    // Save to storage
    await _savePdfRecord(record);

    // Cloud upload is pending. This record is stored locally for now.
    return record;
  }

  Future<void> _savePdfRecord(PdfRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final pdfsJson = prefs.getString(_pdfsKey);

    List<Map<String, dynamic>> pdfs = [];
    if (pdfsJson != null) {
      pdfs = List<Map<String, dynamic>>.from(json.decode(pdfsJson));
    }

    // Remove existing record with same ID if exists
    pdfs.removeWhere((p) => p['id'] == record.id);

    // Add new record
    pdfs.add(record.toJson());

    await prefs.setString(_pdfsKey, json.encode(pdfs));
  }

  Future<List<PdfRecord>> _getAllPdfs() async {
    final prefs = await SharedPreferences.getInstance();
    final pdfsJson = prefs.getString(_pdfsKey);

    if (pdfsJson == null) {
      return [];
    }

    final pdfs = List<Map<String, dynamic>>.from(json.decode(pdfsJson));
    return pdfs.map((p) => PdfRecord.fromJson(p)).toList();
  }

  @override
  Future<List<PdfRecord>> getPdfsByFlightSchool(String flightSchoolId) async {
    final allPdfs = await _getAllPdfs();
    return allPdfs.where((p) => p.flightSchoolId == flightSchoolId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Most recent first
  }

  @override
  Future<List<PdfRecord>> getPdfsByPilot(String pilotId) async {
    final allPdfs = await _getAllPdfs();
    return allPdfs.where((p) => p.pilotId == pilotId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<List<PdfRecord>> searchPdfs({
    String? flightSchoolId,
    String? pilotName,
    String? aircraftType,
    String? pdfType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var results = await _getAllPdfs();

    if (flightSchoolId != null) {
      results =
          results.where((p) => p.flightSchoolId == flightSchoolId).toList();
    }

    if (pilotName != null && pilotName.isNotEmpty) {
      final lowerQuery = pilotName.toLowerCase();
      results = results
          .where(
              (p) => p.pilotName?.toLowerCase().contains(lowerQuery) ?? false)
          .toList();
    }

    if (aircraftType != null && aircraftType.isNotEmpty) {
      final lowerQuery = aircraftType.toLowerCase();
      results = results
          .where((p) =>
              p.aircraftType?.toLowerCase().contains(lowerQuery) ?? false)
          .toList();
    }

    if (pdfType != null && pdfType.isNotEmpty) {
      results = results.where((p) => p.pdfType == pdfType).toList();
    }

    if (startDate != null) {
      results = results.where((p) => p.createdAt.isAfter(startDate)).toList();
    }

    if (endDate != null) {
      results = results.where((p) => p.createdAt.isBefore(endDate)).toList();
    }

    results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return results;
  }

  @override
  Future<PdfRecord?> getPdfById(String id) async {
    final allPdfs = await _getAllPdfs();
    try {
      return allPdfs.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> updatePdf(PdfRecord pdf) async {
    await _savePdfRecord(pdf);
  }

  @override
  Future<void> deletePdf(String id) async {
    final pdf = await getPdfById(id);
    if (pdf == null) return;

    // Delete file
    try {
      final file = File(pdf.localPath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Error deleting PDF file: $e');
    }

    // Remove from storage
    final prefs = await SharedPreferences.getInstance();
    final pdfsJson = prefs.getString(_pdfsKey);

    if (pdfsJson != null) {
      var pdfs = List<Map<String, dynamic>>.from(json.decode(pdfsJson));
      pdfs.removeWhere((p) => p['id'] == id);
      await prefs.setString(_pdfsKey, json.encode(pdfs));
    }
  }

  @override
  Future<String?> uploadToCloud(String localPath) async {
    // Cloud upload is not yet implemented.
    // This method should upload the file to S3 and return the public URL.
    return null;
  }
}
