import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../models/checklist_completion.dart';
import '../../services/supabase_auth_service.dart';
import '../../services/supabase_pdf_service.dart';
import '../../utils/completion_pdf_builder.dart';

/// Shows one stored completion's data, with an on-demand "View as PDF"
/// action built fresh from that data (CompletionPdfBuilder) - replaces
/// opening a pre-generated file as the primary way to review a completion.
/// Falls back to opening the original stored PDF for completions created
/// before the data-first migration (no `data`, only `pdf_storage_path`).
class CompletionDetailScreen extends StatefulWidget {
  final ChecklistCompletion completion;
  const CompletionDetailScreen({super.key, required this.completion});

  @override
  State<CompletionDetailScreen> createState() =>
      _CompletionDetailScreenState();
}

class _CompletionDetailScreenState extends State<CompletionDetailScreen> {
  final _dateFmt = DateFormat('d MMM yyyy · HH:mm');
  bool _busy = false;

  Future<void> _viewAsPdf() async {
    setState(() => _busy = true);
    try {
      final fontData =
          await rootBundle.load("assets/fonts/NotoSans-Regular.ttf");
      final pdfFont = pw.Font.ttf(fontData);
      final user = SupabaseAuthService().currentUser;

      final pdfBytes = await CompletionPdfBuilder.build(
        font: pdfFont,
        title: widget.completion.checklistName,
        aircraftType: widget.completion.aircraftType,
        completedAt: widget.completion.completedAt,
        pilotName: widget.completion.pilotName ?? user?.fullName,
        licenseNumber: user?.licenseNumber,
        homeBase: user?.homeBase,
        data: widget.completion.data!,
      );

      final output = await getTemporaryDirectory();
      final file = File(
          "${output.path}/Completion_${widget.completion.id}.pdf");
      await file.writeAsBytes(pdfBytes);
      await OpenFile.open(file.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not generate PDF: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openStoredPdf() async {
    setState(() => _busy = true);
    try {
      final path =
          await SupabasePdfService().downloadPdfToTemp(widget.completion);
      final res = await OpenFile.open(path);
      if (res.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open PDF: ${res.message}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open PDF: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.completion;
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text(c.checklistName, style: const TextStyle(color: Colors.black)),
        iconTheme: const IconThemeData(color: Colors.black),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFADD8E6), Color(0xFF87CEEB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 4,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                elevation: 1,
                shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${c.completionTypeLabel} · ${c.aircraftType}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _dateFmt.format(c.completedAt),
                        style: TextStyle(color: Colors.grey[700], fontSize: 13),
                      ),
                      if (c.pilotName != null) ...[
                        const SizedBox(height: 4),
                        Text('Pilot: ${c.pilotName}',
                            style:
                                TextStyle(color: Colors.grey[700], fontSize: 13)),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: c.hasStructuredData
                  ? _DataList(data: c.data!)
                  : _legacyNotice(),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _busy
                      ? null
                      : (c.hasStructuredData
                          ? _viewAsPdf
                          : (c.hasPdf ? _openStoredPdf : null)),
                  icon: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.black))
                      : const Icon(Icons.picture_as_pdf, color: Colors.black),
                  label: Text(
                    c.hasStructuredData ? 'View as PDF' : 'Open Stored PDF',
                    style: const TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF87CEEB),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legacyNotice() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, size: 56, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              widget.completion.hasPdf
                  ? 'This completion was saved before structured data was '
                      'tracked - its original PDF is still available below.'
                  : 'No data or PDF is available for this completion.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }
}

/// Renders a completion's data map the same way CompletionPdfBuilder does -
/// flat fields as label/value rows, nested maps as their own labeled
/// section, lists as bullet lists - just as Flutter widgets instead of PDF
/// widgets, so the two stay visually consistent.
class _DataList extends StatelessWidget {
  final Map<String, dynamic> data;
  const _DataList({required this.data});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: data.entries.map((e) => _entry(e.key, e.value)).toList(),
    );
  }

  Widget _entry(String label, dynamic value) {
    if (value is Map) {
      final map = Map<String, dynamic>.from(value);
      return Card(
        margin: const EdgeInsets.only(bottom: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 6),
              ...map.entries.map((e) => _kv(e.key, e.value)),
            ],
          ),
        ),
      );
    }
    if (value is List) {
      return Card(
        margin: const EdgeInsets.only(bottom: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 6),
              ...value.map((v) => Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text('•  $v', style: const TextStyle(fontSize: 13)),
                  )),
            ],
          ),
        ),
      );
    }
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: _kv(label, value),
      ),
    );
  }

  Widget _kv(String label, dynamic value) {
    final isBool = value is bool;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 13)),
          ),
          if (isBool)
            Icon(
              value ? Icons.check_circle : Icons.remove_circle_outline,
              size: 18,
              color: value ? Colors.green : Colors.grey,
            )
          else
            Flexible(
              child: Text(
                '$value',
                textAlign: TextAlign.end,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }
}
