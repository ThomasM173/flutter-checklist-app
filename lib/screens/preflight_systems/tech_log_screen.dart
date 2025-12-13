import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clearedtogo/services/pdf_upload_service.dart';
import 'package:clearedtogo/services/auth_service.dart';
import 'dart:convert';

class TechLogScreen extends StatefulWidget {
  const TechLogScreen({super.key});

  @override
  State<TechLogScreen> createState() => _TechLogScreenState();
}

class _TechLogScreenState extends State<TechLogScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _aircraftRegistrationController = TextEditingController();
  final _dateController = TextEditingController();
  final _pilotNameController = TextEditingController();
  final _flightNumberController = TextEditingController();
  final _hobbsStartController = TextEditingController();
  final _hobbsEndController = TextEditingController();
  
  final List<DefectEntry> _defects = [];
  
  @override
  void initState() {
    super.initState();
    _dateController.text = DateTime.now().toString().split(' ')[0];
    _loadLastEntry();
  }

  Future<void> _loadLastEntry() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pilotNameController.text = prefs.getString('techlog_pilotName') ?? '';
      _aircraftRegistrationController.text = prefs.getString('techlog_registration') ?? '';
    });
  }

  Future<void> _saveEntry() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('techlog_pilotName', _pilotNameController.text);
    await prefs.setString('techlog_registration', _aircraftRegistrationController.text);
    
    // Save defect history
    final history = prefs.getStringList('techlog_history') ?? [];
    final entry = jsonEncode({
      'date': _dateController.text,
      'registration': _aircraftRegistrationController.text,
      'pilot': _pilotNameController.text,
      'defectCount': _defects.length,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    history.add(entry);
    // Keep last 10 entries
    if (history.length > 10) history.removeAt(0);
    await prefs.setStringList('techlog_history', history);
  }

  void _addDefect() {
    setState(() {
      _defects.add(DefectEntry());
    });
  }

  void _removeDefect(int index) {
    setState(() {
      _defects.removeAt(index);
    });
  }

  Future<void> _generatePDF() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    if (!(Platform.isAndroid || Platform.isIOS)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF generation only works on Android/iOS')),
        );
      }
      return;
    }

    try {
      final pdf = pw.Document();
      final fontData = await rootBundle.load("assets/fonts/NotoSans-Regular.ttf");
      final pdfFont = pw.Font.ttf(fontData);
      
      final authService = AuthService();
      final user = authService.currentUser;

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(30),
          theme: pw.ThemeData.withFont(base: pdfFont),
          header: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                "AIRCRAFT TECHNICAL LOG",
                style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
              ),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 5),
            ],
          ),
          footer: (context) => pw.Column(
            children: [
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Generated: ${DateTime.now().toString().split('.')[0]}", 
                      style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                  pw.Text("Page ${context.pageNumber}/${context.pagesCount}",
                      style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                ],
              ),
            ],
          ),
          build: (context) => [
            if (user?.fullName != null) pw.Text("Pilot: ${user!.fullName}", style: pw.TextStyle(fontSize: 11)),
            if (user?.licenseNumber != null) pw.Text("License: ${user!.licenseNumber}", style: pw.TextStyle(fontSize: 11)),
            pw.SizedBox(height: 10),
            
            _pdfRow("Aircraft Registration:", _aircraftRegistrationController.text),
            _pdfRow("Date:", _dateController.text),
            _pdfRow("Pilot Name:", _pilotNameController.text),
            _pdfRow("Flight Number:", _flightNumberController.text),
            _pdfRow("Hobbs Start:", _hobbsStartController.text),
            _pdfRow("Hobbs End:", _hobbsEndController.text),
            if (_hobbsStartController.text.isNotEmpty && _hobbsEndController.text.isNotEmpty)
              _pdfRow("Flight Time:", 
                  "${(double.tryParse(_hobbsEndController.text) ?? 0.0) - (double.tryParse(_hobbsStartController.text) ?? 0.0)} hours"),
            
            pw.SizedBox(height: 20),
            
            pw.Text(
              "DEFECTS & SNAGS (${_defects.length})",
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            
            if (_defects.isEmpty)
              pw.Container(
                padding: pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.green50,
                  border: pw.Border.all(color: PdfColors.green),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  "✅ NO DEFECTS REPORTED - AIRCRAFT SERVICEABLE",
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.green900),
                ),
              )
            else
              ...List.generate(_defects.length, (index) {
                final defect = _defects[index];
                return pw.Container(
                  margin: pw.EdgeInsets.only(bottom: 12),
                  padding: pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: defect.status == 'Unserviceable' ? PdfColors.red50 : PdfColors.orange50,
                    border: pw.Border.all(
                      color: defect.status == 'Unserviceable' ? PdfColors.red : PdfColors.orange,
                    ),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text("Defect #${index + 1}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          pw.Container(
                            padding: pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: pw.BoxDecoration(
                              color: defect.status == 'Unserviceable' ? PdfColors.red : PdfColors.orange,
                              borderRadius: pw.BorderRadius.circular(4),
                            ),
                            child: pw.Text(
                              defect.status,
                              style: pw.TextStyle(fontSize: 10, color: PdfColors.white, fontWeight: pw.FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text("System: ${defect.system}", style: pw.TextStyle(fontSize: 11)),
                      pw.SizedBox(height: 4),
                      pw.Text("Description:", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.Text(defect.description, style: pw.TextStyle(fontSize: 10)),
                      if (defect.actionTaken.isNotEmpty) ...[
                        pw.SizedBox(height: 4),
                        pw.Text("Action Taken:", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                        pw.Text(defect.actionTaken, style: pw.TextStyle(fontSize: 10)),
                      ],
                      pw.SizedBox(height: 4),
                      pw.Text("Reported by: ${defect.reportedBy}", style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic)),
                    ],
                  ),
                );
              }),
            
            pw.SizedBox(height: 30),
            
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("Pilot Signature:", style: pw.TextStyle(fontSize: 10)),
                    pw.SizedBox(height: 5),
                    pw.Container(
                      width: 200,
                      padding: pw.EdgeInsets.symmetric(vertical: 8),
                      decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide())),
                      child: pw.Text(_pilotNameController.text, style: pw.TextStyle(fontSize: 12, fontStyle: pw.FontStyle.italic)),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("Date:", style: pw.TextStyle(fontSize: 10)),
                    pw.SizedBox(height: 5),
                    pw.Container(
                      width: 120,
                      padding: pw.EdgeInsets.symmetric(vertical: 8),
                      decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide())),
                      child: pw.Text(_dateController.text, style: pw.TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );

      await _saveEntry();

      final output = await getTemporaryDirectory();
      final fileName = "TechLog_${_aircraftRegistrationController.text}_${_dateController.text}.pdf";
      final file = File("${output.path}/$fileName");
      final pdfBytes = await pdf.save();
      await file.writeAsBytes(pdfBytes);
      
      try {
        await PdfUploadService().uploadPdf(
          pdfBytes,
          title: 'Tech Log - ${_aircraftRegistrationController.text} - ${_dateController.text}',
          aircraftId: _aircraftRegistrationController.text,
          type: 'tech_log',
        );
      } catch (e) {
        debugPrint('Failed to upload PDF: $e');
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tech Log PDF generated!'), backgroundColor: Colors.green),
        );
      }
      
      OpenFile.open(file.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  pw.Widget _pdfRow(String label, String value) {
    return pw.Padding(
      padding: pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        children: [
          pw.Container(
            width: 140,
            child: pw.Text(label, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
          ),
          pw.Text(value, style: pw.TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text(
          "Aircraft Tech Log / Defects",
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
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
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: ExpansionTile(
                initiallyExpanded: false,
                leading: const Icon(Icons.flight, color: Colors.blue),
                title: const Text('Flight Details', style: TextStyle(fontWeight: FontWeight.bold)),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildTextField(_aircraftRegistrationController, 'Aircraft Registration *', Icons.local_airport, required: true),
                        _buildTextField(_dateController, 'Date *', Icons.calendar_today, required: true),
                        _buildTextField(_pilotNameController, 'Pilot Name *', Icons.person, required: true),
                        _buildTextField(_flightNumberController, 'Flight Number', Icons.confirmation_number),
                        _buildTextField(_hobbsStartController, 'Hobbs Start', Icons.speed, keyboardType: TextInputType.number),
                        _buildTextField(_hobbsEndController, 'Hobbs End', Icons.speed, keyboardType: TextInputType.number),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_amber, color: Colors.orange, size: 28),
                        const SizedBox(width: 12),
                        const Text(
                          'Defects & Snags',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _defects.isEmpty ? Colors.green : Colors.orange,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _defects.isEmpty ? 'Serviceable' : '${_defects.length} Defect(s)',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    if (_defects.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green),
                        ),
                        child: const Center(
                          child: Text(
                            '✅ No defects reported - Aircraft serviceable',
                            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                          ),
                        ),
                      )
                    else
                      ...List.generate(_defects.length, (index) {
                        return DefectCard(
                          defect: _defects[index],
                          index: index,
                          onRemove: () => _removeDefect(index),
                          onUpdate: () => setState(() {}),
                        );
                      }),
                    
                    const SizedBox(height: 12),
                    
                    ElevatedButton.icon(
                      onPressed: _addDefect,
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text('Add Defect', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            ElevatedButton.icon(
              onPressed: _generatePDF,
              icon: const Icon(Icons.picture_as_pdf, color: Colors.black),
              label: const Text('Generate Tech Log PDF', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF87CEEB),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 3,
              ),
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool required = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
        ),
        validator: required ? (val) => val == null || val.isEmpty ? 'Required' : null : null,
      ),
    );
  }

  @override
  void dispose() {
    _aircraftRegistrationController.dispose();
    _dateController.dispose();
    _pilotNameController.dispose();
    _flightNumberController.dispose();
    _hobbsStartController.dispose();
    _hobbsEndController.dispose();
    super.dispose();
  }
}

class DefectEntry {
  String system = 'Engine';
  String description = '';
  String actionTaken = '';
  String status = 'Deferred';
  String reportedBy = '';
}

class DefectCard extends StatelessWidget {
  final DefectEntry defect;
  final int index;
  final VoidCallback onRemove;
  final VoidCallback onUpdate;

  const DefectCard({
    super.key,
    required this.defect,
    required this.index,
    required this.onRemove,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: defect.status == 'Unserviceable' ? Colors.red[50] : Colors.orange[50],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Defect #${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: onRemove,
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            DropdownButtonFormField<String>(
              value: defect.system,
              decoration: const InputDecoration(
                labelText: 'System',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: ['Engine', 'Electrical', 'Instruments', 'Avionics', 'Hydraulics', 'Flight Controls', 'Landing Gear', 'Fuel System', 'Other']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) {
                defect.system = val!;
                onUpdate();
              },
            ),
            
            const SizedBox(height: 8),
            
            TextFormField(
              initialValue: defect.description,
              decoration: const InputDecoration(
                labelText: 'Description *',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              maxLines: 2,
              onChanged: (val) => defect.description = val,
            ),
            
            const SizedBox(height: 8),
            
            TextFormField(
              initialValue: defect.actionTaken,
              decoration: const InputDecoration(
                labelText: 'Action Taken',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              maxLines: 2,
              onChanged: (val) => defect.actionTaken = val,
            ),
            
            const SizedBox(height: 8),
            
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: defect.status,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: ['Deferred', 'Rectified', 'Unserviceable']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) {
                      defect.status = val!;
                      onUpdate();
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            TextFormField(
              initialValue: defect.reportedBy,
              decoration: const InputDecoration(
                labelText: 'Reported By',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (val) => defect.reportedBy = val,
            ),
          ],
        ),
      ),
    );
  }
}
