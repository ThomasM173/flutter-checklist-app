import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Builds a compact PDF from a completion's stored structured data.
///
/// Every completion flow previously built its own bespoke, heavily-spaced
/// PDF (one row per item, large fonts, section headers eating whole pages -
/// commonly 7 pages for a single checklist). This is the single shared
/// renderer used by every flow's "View as PDF" instead: same underlying
/// data, a tight 2-column grid for nested sections and a label/value row
/// for flat fields, small fonts throughout. Typically 1-2 pages.
class CompletionPdfBuilder {
  /// [font] — callers already load this the same way their old bespoke PDF
  /// generator did (`rootBundle.load('assets/fonts/NotoSans-Regular.ttf')`
  /// then `pw.Font.ttf(...)`). Kept as a parameter rather than loaded
  /// in here so this file stays plain Dart (no `flutter/services.dart`,
  /// which pulls in `dart:ui` and can't run outside a Flutter binding) -
  /// that's what makes tool/test_completion_pdf.dart able to exercise this
  /// directly via `dart run`, loading the same TTF straight off disk.
  static Future<Uint8List> build({
    required pw.Font font,
    required String title,
    required String aircraftType,
    required DateTime completedAt,
    String? pilotName,
    String? licenseNumber,
    String? homeBase,
    required Map<String, dynamic> data,
  }) async {
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(22, 18, 22, 18),
        theme: pw.ThemeData.withFont(base: font),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title,
              style:
                  pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 1),
            pw.Text(
              [
                aircraftType,
                if (pilotName != null && pilotName.isNotEmpty)
                  'Pilot: $pilotName',
                if (licenseNumber != null && licenseNumber.isNotEmpty)
                  'License: $licenseNumber',
                if (homeBase != null && homeBase.isNotEmpty)
                  'Base: $homeBase',
                _formatDateTime(completedAt),
              ].join('   •   '),
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 4),
            pw.Divider(thickness: 1, height: 1),
            pw.SizedBox(height: 5),
          ],
        ),
        build: (context) => _renderData(data),
      ),
    );
    return doc.save();
  }

  static List<pw.Widget> _renderData(Map<String, dynamic> data) {
    return data.entries
        .where((e) => !e.key.startsWith('_internal_'))
        .map((e) => _renderEntry(_humanize(e.key), e.value))
        .toList();
  }

  static pw.Widget _renderEntry(String label, dynamic value) {
    if (value is Map) {
      final mapVal = Map<String, dynamic>.from(value);
      if (mapVal.isEmpty) return pw.SizedBox();
      return pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 4),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label,
              style:
                  pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 1),
            _renderGrid(mapVal),
          ],
        ),
      );
    }
    if (value is List) {
      if (value.isEmpty) return pw.SizedBox();
      return pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 8),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label,
              style:
                  pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 2),
            ...value.map((item) => pw.Text(
                  '-  ${_formatValue(item)}',
                  style: const pw.TextStyle(fontSize: 9),
                )),
          ],
        ),
      );
    }
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 150,
            child: pw.Text(
              label,
              style:
                  pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(
            child: pw.Text(_formatValue(value),
                style: const pw.TextStyle(fontSize: 9.5)),
          ),
        ],
      ),
    );
  }

  /// Nested maps (e.g. a checklist section's {item: checked} pairs) render
  /// as a tight 2-up grid rather than one row per item.
  static pw.Widget _renderGrid(Map<String, dynamic> map) {
    return pw.Wrap(
      spacing: 10,
      runSpacing: 0.5,
      children: map.entries.map((e) {
        final v = e.value;
        final display = v is bool ? (v ? 'Y' : '-') : _formatValue(v);
        return pw.Container(
          width: 220,
          child: pw.Row(
            children: [
              pw.Expanded(
                child: pw.Text(e.key, style: const pw.TextStyle(fontSize: 7.5)),
              ),
              pw.SizedBox(width: 3),
              pw.Text(
                display,
                style:
                    pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  static String _formatValue(dynamic v) {
    if (v == null) return '-';
    if (v is bool) return v ? 'Yes' : 'No';
    if (v is double) {
      return v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();
    }
    return v.toString();
  }

  static String _humanize(String key) {
    final spaced = key.replaceAll('_', ' ');
    if (spaced.isEmpty) return spaced;
    return spaced[0].toUpperCase() + spaced.substring(1);
  }

  static String _formatDateTime(DateTime d) {
    final l = d.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(l.day)}/${two(l.month)}/${l.year} ${two(l.hour)}:${two(l.minute)}';
  }
}
