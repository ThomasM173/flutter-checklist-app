import 'dart:convert';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// Service for uploading PDFs to the backend API
/// Handles authentication and communication with AWS API Gateway + Lambda
class PdfUploadService {
  static const String _baseUrl = 'https://4cx5f0qdab.execute-api.eu-west-2.amazonaws.com';

  /// Upload a PDF to the backend
  /// 
  /// Parameters:
  /// - [pdfBytes]: The PDF file as bytes
  /// - [title]: Title/name for the PDF
  /// - [aircraftId]: Aircraft registration (e.g., "G-ABCD")
  /// - [type]: Type of PDF (default: "preflight_checklist")
  /// 
  /// Throws an exception if:
  /// - User is not authenticated
  /// - Network request fails
  /// - Backend returns an error
  Future<void> uploadPdf(
    Uint8List pdfBytes, {
    required String title,
    required String aircraftId,
    String type = 'preflight_checklist',
  }) async {
    try {
      // Get Cognito ID token (raw JWT string)
      final session = await Amplify.Auth.fetchAuthSession()
          .timeout(const Duration(seconds: 5)) as CognitoAuthSession;
      final idToken = session.userPoolTokensResult.value.idToken.raw;

      if (idToken.isEmpty) {
        throw Exception('Not authenticated - please log in');
      }

      // Base64 encode the PDF bytes
      final fileB64 = base64Encode(pdfBytes);

      // Build request body
      final body = jsonEncode({
        'fileBase64': fileB64,
        'title': title,
        'aircraftId': aircraftId,
        'type': type,
      });

      // Send HTTP POST request
      final uri = Uri.parse('$_baseUrl/pdf');
      
      debugPrint('📤 Uploading PDF to backend: $title (${pdfBytes.length} bytes)');
      debugPrint('📍 Aircraft ID: $aircraftId | Type: $type');
      
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': idToken,
        },
        body: body,
      );

      // Check response and log details
      debugPrint('📥 Upload response: ${response.statusCode}');
      debugPrint('📝 Response body: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ PDF uploaded successfully!');
      } else {
        final errorMsg = 'Upload failed (${response.statusCode}): ${response.body}';
        debugPrint('❌ $errorMsg');
        throw Exception(errorMsg);
      }
    } on AuthException catch (e) {
      debugPrint('🔐 Authentication error during PDF upload: ${e.message}');
      throw Exception('Authentication error: ${e.message}');
    } catch (e) {
      debugPrint('💥 Failed to upload PDF: $e');
      rethrow;
    }
  }
}
