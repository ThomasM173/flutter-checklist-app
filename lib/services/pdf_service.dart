import 'dart:typed_data';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clearedtogo/models/pdf_item.dart';
import 'package:clearedtogo/services/auth_service.dart';

/// Service for managing PDF documents
///
/// Currently implements local storage using SharedPreferences.
/// Ready for backend integration with AWS S3 and REST API.
class PdfService {
  static const String _pdfsKey = 'user_pdfs';
  final AuthService _authService;

  PdfService(this._authService);

  /// Upload a PDF document
  ///
  /// For now, stores PDF metadata locally in SharedPreferences.
  /// PDF bytes are not persisted (would exceed SharedPreferences size limits).
  ///
  /// Backend integration is pending.
  /// In a production implementation, this would upload PDF bytes,
  /// persist metadata, and return a record with a permanent storage URL.
  ///
  /// Example backend integration:
  /// ```dart
  /// // 1. Get pre-signed upload URL from backend
  /// final response = await http.post(
  ///   Uri.parse('$baseUrl/api/pdfs/upload-url'),
  ///   headers: {'Authorization': 'Bearer $accessToken'},
  ///   body: json.encode({'fileName': title, 'fileSize': pdfBytes.length}),
  /// );
  /// final uploadUrl = json.decode(response.body)['uploadUrl'];
  ///
  /// // 2. Upload to S3
  /// await http.put(
  ///   Uri.parse(uploadUrl),
  ///   body: pdfBytes,
  ///   headers: {'Content-Type': 'application/pdf'},
  /// );
  ///
  /// // 3. Confirm upload to backend
  /// final confirmResponse = await http.post(
  ///   Uri.parse('$baseUrl/api/pdfs'),
  ///   headers: {'Authorization': 'Bearer $accessToken'},
  ///   body: json.encode({
  ///     'title': title,
  ///     'sizeBytes': pdfBytes.length,
  ///     's3Key': s3Key,
  ///   }),
  /// );
  ///
  /// return PdfItem.fromJson(json.decode(confirmResponse.body));
  /// ```
  Future<PdfItem> uploadPdf(Uint8List pdfBytes, String title) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      throw Exception('User must be logged in to upload PDFs');
    }

    // Generate dummy ID (in production, this comes from backend)
    final id = 'pdf_${DateTime.now().millisecondsSinceEpoch}';

    // Create PDF item with local metadata
    final pdfItem = PdfItem(
      id: id,
      title: title,
      createdAt: DateTime.now(),
      localPath: null, // Could store to device storage later
      url: null, // Will be S3 URL in production
      sizeBytes: pdfBytes.length,
    );

    // Store to local cache
    await _savePdfToLocal(pdfItem);

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    return pdfItem;
  }

  /// List all PDFs for the current user
  ///
  /// For now, retrieves from local SharedPreferences.
  ///
  /// Backend integration is pending.
  /// In a production implementation, this would request the user's PDF list
  /// from the backend and return a strongly typed collection.
  ///
  /// Example backend integration:
  /// ```dart
  /// final response = await http.get(
  ///   Uri.parse('$baseUrl/api/pdfs?page=1&limit=20'),
  ///   headers: {'Authorization': 'Bearer $accessToken'},
  /// );
  ///
  /// if (response.statusCode == 200) {
  ///   final data = json.decode(response.body);
  ///   return (data['pdfs'] as List)
  ///     .map((json) => PdfItem.fromJson(json))
  ///     .toList();
  /// }
  /// ```
  Future<List<PdfItem>> listPdfs() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      return [];
    }

    // Retrieve from local storage
    final pdfs = await _loadPdfsFromLocal();

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Sort by created date (newest first)
    pdfs.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return pdfs;
  }

  /// Delete a PDF document
  ///
  /// Backend integration is pending.
  /// In production, this would call the backend to remove the PDF record
  /// and delete the associated object from cloud storage.
  ///
  /// Example backend integration:
  /// ```dart
  /// final response = await http.delete(
  ///   Uri.parse('$baseUrl/api/pdfs/$pdfId'),
  ///   headers: {'Authorization': 'Bearer $accessToken'},
  /// );
  /// ```
  Future<void> deletePdf(String pdfId) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      throw Exception('User must be logged in to delete PDFs');
    }

    final pdfs = await _loadPdfsFromLocal();
    pdfs.removeWhere((pdf) => pdf.id == pdfId);
    await _savePdfsToLocal(pdfs);

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
  }

  /// Get a download/view URL for a PDF
  ///
  /// Backend integration is pending.
  /// In production, this would request a signed download URL from the backend.
  ///
  /// Example backend integration:
  /// ```dart
  /// final response = await http.get(
  ///   Uri.parse('$baseUrl/api/pdfs/$pdfId/download-url'),
  ///   headers: {'Authorization': 'Bearer $accessToken'},
  /// );
  ///
  /// if (response.statusCode == 200) {
  ///   final data = json.decode(response.body);
  ///   return data['url']; // Signed S3 URL valid for 1 hour
  /// }
  /// ```
  Future<String?> getDownloadUrl(String pdfId) async {
    final pdfs = await _loadPdfsFromLocal();
    final pdf = pdfs.firstWhere(
      (p) => p.id == pdfId,
      orElse: () => throw Exception('PDF not found'),
    );

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    // Return placeholder URL (in production, this is signed S3 URL)
    return pdf.url ?? pdf.localPath;
  }

  // Internal methods for local storage

  Future<void> _savePdfToLocal(PdfItem pdfItem) async {
    final pdfs = await _loadPdfsFromLocal();
    pdfs.add(pdfItem);
    await _savePdfsToLocal(pdfs);
  }

  Future<List<PdfItem>> _loadPdfsFromLocal() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      return [];
    }

    final prefs = await SharedPreferences.getInstance();
    final key = '${_pdfsKey}_${currentUser.email}';
    final pdfsJson = prefs.getString(key);

    if (pdfsJson == null) {
      return [];
    }

    try {
      final List<dynamic> decoded = json.decode(pdfsJson);
      return decoded.map((json) => PdfItem.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> _savePdfsToLocal(List<PdfItem> pdfs) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final key = '${_pdfsKey}_${currentUser.email}';
    final pdfsJson = json.encode(pdfs.map((p) => p.toJson()).toList());
    await prefs.setString(key, pdfsJson);
  }

  /// Clear all local PDF data (for testing/logout)
  Future<void> clearLocalPdfs() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final key = '${_pdfsKey}_${currentUser.email}';
    await prefs.remove(key);
  }
}
