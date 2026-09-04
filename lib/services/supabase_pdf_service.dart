import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../models/checklist_completion.dart';
import 'supabase_auth_service.dart';

/// Replaces the retired AWS Lambda `POST /pdf` path (`PdfUploadService`).
///
/// Per completed pre-boarding checklist:
///   1. insert a `checklist_completions` row (RLS: user_id must be auth.uid())
///   2. upload the PDF to the private `checklist-pdfs` bucket at
///      `{user_id}/{completion_id}.pdf`
///   3. write that path back onto the row
///
/// Retrieval:
///   * [listMyCompletions]     — the signed-in pilot's own history
///   * [listSchoolCompletions] — every completion for the admin's school
///     (RLS does the scoping; we just embed the pilot's name)
///   * [openPdf] — downloads the private object to a temp file and opens it
class SupabasePdfService {
  SupabasePdfService._();
  static final SupabasePdfService instance = SupabasePdfService._();
  factory SupabasePdfService() => instance;

  static const bucket = 'checklist-pdfs';

  sb.SupabaseClient get _client => sb.Supabase.instance.client;

  /// Records a completion + uploads its PDF. Returns null (and logs) if the
  /// user isn't signed in — callers treat this as best-effort, exactly like
  /// the old upload path.
  Future<ChecklistCompletion?> recordCompletion({
    required Uint8List pdfBytes,
    required String aircraftType,
    required String checklistName,
    DateTime? completedAt,
    String completionType = 'checklist',
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      debugPrint('SupabasePdfService: not signed in — completion not recorded.');
      return null;
    }

    // flight_school_id is denormalised from the current profile at completion
    // time (see table comment). Read it from the cached profile.
    final schoolId = SupabaseAuthService.instance.flightSchoolId;
    final when = (completedAt ?? DateTime.now()).toUtc();

    // 1. insert the row
    final inserted = await _client
        .from('checklist_completions')
        .insert({
          'user_id': user.id,
          'flight_school_id': schoolId,
          'aircraft_type': aircraftType,
          'checklist_name': checklistName,
          'completed_at': when.toIso8601String(),
          'completion_type': completionType,
        })
        .select()
        .single();

    final completionId = inserted['id'] as String;
    final path = '${user.id}/$completionId.pdf';

    // 2. upload the PDF
    try {
      await _client.storage.from(bucket).uploadBinary(
            path,
            pdfBytes,
            fileOptions: const sb.FileOptions(
              contentType: 'application/pdf',
              upsert: true,
            ),
          );

      // 3. write the path back
      final updated = await _client
          .from('checklist_completions')
          .update({'pdf_storage_path': path})
          .eq('id', completionId)
          .select()
          .single();
      return ChecklistCompletion.fromMap(updated);
    } catch (e) {
      // Row is kept even if the upload fails — it's still a valid record that
      // the checklist was completed; the PDF is just missing.
      debugPrint('SupabasePdfService: PDF upload failed for $path: $e');
      return ChecklistCompletion.fromMap(inserted);
    }
  }

  Future<List<ChecklistCompletion>> listMyCompletions({
    String? completionType,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return [];
    var query = _client
        .from('checklist_completions')
        .select()
        .eq('user_id', user.id);
    if (completionType != null && completionType.isNotEmpty) {
      query = query.eq('completion_type', completionType);
    }
    final rows = await query.order('completed_at', ascending: false);
    return (rows as List)
        .map((r) => ChecklistCompletion.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  /// For a flight_school_admin. RLS restricts rows to the admin's own school;
  /// the `profiles(full_name)` embed resolves each pilot's name (also allowed
  /// by the "admin reads own-school pilots" profile policy).
  Future<List<ChecklistCompletion>> listSchoolCompletions({
    String? aircraftType,
    String? completionType,
    DateTime? from,
    DateTime? to,
  }) async {
    var query = _client
        .from('checklist_completions')
        .select('*, profiles!checklist_completions_user_id_fkey(full_name)');

    if (aircraftType != null && aircraftType.isNotEmpty) {
      query = query.eq('aircraft_type', aircraftType);
    }
    if (completionType != null && completionType.isNotEmpty) {
      query = query.eq('completion_type', completionType);
    }
    if (from != null) {
      query = query.gte('completed_at', from.toUtc().toIso8601String());
    }
    if (to != null) {
      query = query.lte('completed_at', to.toUtc().toIso8601String());
    }

    final rows = await query.order('completed_at', ascending: false);
    return (rows as List)
        .map((r) => ChecklistCompletion.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  /// Downloads the private PDF to a temp file and returns its local path.
  Future<String> downloadPdfToTemp(ChecklistCompletion completion) async {
    final path = completion.pdfStoragePath;
    if (path == null || path.isEmpty) {
      throw Exception('This completion has no stored PDF.');
    }
    final bytes = await _client.storage.from(bucket).download(path);
    final dir = await getTemporaryDirectory();
    final safeName = path.replaceAll('/', '_');
    final file = File('${dir.path}/$safeName');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  /// A time-limited signed URL for the private object (e.g. to share/open in a
  /// browser). Default 1 hour.
  Future<String> signedUrl(ChecklistCompletion completion,
      {int expiresInSeconds = 3600}) async {
    final path = completion.pdfStoragePath;
    if (path == null || path.isEmpty) {
      throw Exception('This completion has no stored PDF.');
    }
    return _client.storage.from(bucket).createSignedUrl(path, expiresInSeconds);
  }
}
