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

class DepartureBriefingScreen extends StatefulWidget {
  const DepartureBriefingScreen({super.key});

  @override
  State<DepartureBriefingScreen> createState() => _DepartureBriefingScreenState();
}

class _DepartureBriefingScreenState extends State<DepartureBriefingScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _aircraftRegistrationController = TextEditingController();
  final _dateController = TextEditingController();
  final _pilotNameController = TextEditingController();
  final _departureAirportController = TextEditingController();
  final _destinationAirportController = TextEditingController();
  final _runwayController = TextEditingController();
  final _runwayLengthController = TextEditingController();
  final _windController = TextEditingController();
  final _abortPointController = TextEditingController();
  final _engineFailureActionController = TextEditingController();
  
  // TEM (Threat and Error Management)
  final List<String> _threats = [];
  final List<String> _errors = [];
  final List<String> _mitigations = [];
  
  @override
  void initState() {
    super.initState();
    _dateController.text = DateTime.now().toString().split(' ')[0];
    _loadLastEntry();
  }

  Future<void> _loadLastEntry() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pilotNameController.text = prefs.getString('brief_pilotName') ?? '';
      _aircraftRegistrationController.text = prefs.getString('brief_registration') ?? '';
    });
  }

  Future<void> _saveEntry() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('brief_pilotName', _pilotNameController.text);
    await prefs.setString('brief_registration', _aircraftRegistrationController.text);
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
              pw.Text("DEPARTURE BRIEFING / TEM", style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 5),
            ],
          ),
          build: (context) => [
            if (user?.fullName != null) pw.Text("Pilot: ${user!.fullName}", style: pw.TextStyle(fontSize: 11)),
            if (user?.licenseNumber != null) pw.Text("License: ${user!.licenseNumber}", style: pw.TextStyle(fontSize: 11)),
            pw.SizedBox(height: 10),
            
            _pdfRow("Aircraft:", _aircraftRegistrationController.text),
            _pdfRow("Date:", _dateController.text),
            _pdfRow("Departure:", _departureAirportController.text),
            _pdfRow("Destination:", _destinationAirportController.text),
            _pdfRow("Runway:", _runwayController.text),
            _pdfRow("Runway Length:", "${_runwayLengthController.text}m"),
            _pdfRow("Wind:", _windController.text),
            
            pw.SizedBox(height: 15),
            
            _pdfSection("DEPARTURE BRIEF", [
              _pdfRow("Abort Point:", _abortPointController.text),
              _pdfRow("Engine Failure Action:", _engineFailureActionController.text),
            ]),
            
            if (_threats.isNotEmpty) _pdfSection("THREATS IDENTIFIED", _threats.map((t) => pw.Text("• $t", style: pw.TextStyle(fontSize: 11))).toList()),
            if (_errors.isNotEmpty) _pdfSection("POTENTIAL ERRORS", _errors.map((e) => pw.Text("• $e", style: pw.TextStyle(fontSize: 11))).toList()),
            if (_mitigations.isNotEmpty) _pdfSection("MITIGATIONS", _mitigations.map((m) => pw.Text("• $m", style: pw.TextStyle(fontSize: 11))).toList()),
            
            pw.Spacer(),
            
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
      final fileName = "DepartureBrief_${_dateController.text}.pdf";
      final file = File("${output.path}/$fileName");
      final pdfBytes = await pdf.save();
      await file.writeAsBytes(pdfBytes);
      
      try {
        await PdfUploadService().uploadPdf(
          pdfBytes,
          title: 'Departure Briefing - ${_departureAirportController.text} - ${_dateController.text}',
          aircraftId: _aircraftRegistrationController.text,
          type: 'departure_brief',
        );
      } catch (e) {
        debugPrint('Failed to upload PDF: $e');
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Departure Briefing PDF generated!'), backgroundColor: Colors.green),
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

  pw.Widget _pdfSection(String title, List<pw.Widget> children) {
    return pw.Container(
      margin: pw.EdgeInsets.only(bottom: 12, top: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: double.infinity,
            padding: pw.EdgeInsets.symmetric(vertical: 6, horizontal: 10),
            decoration: pw.BoxDecoration(color: PdfColors.blue900, borderRadius: pw.BorderRadius.circular(4)),
            child: pw.Text(title, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
          ),
          pw.SizedBox(height: 6),
          ...children,
        ],
      ),
    );
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
        title: const Text("Departure Briefing / TEM", style: TextStyle(color: Colors.black)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFFADD8E6), Color(0xFF87CEEB)], begin: Alignment.topLeft, end: Alignment.bottomRight),
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
              child: ExpansionTile(
                initiallyExpanded: false,
                leading: const Icon(Icons.flight_takeoff, color: Colors.blue),
                title: const Text('Flight Details', style: TextStyle(fontWeight: FontWeight.bold)),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildTextField(_aircraftRegistrationController, 'Aircraft *', Icons.local_airport, required: true),
                        _buildTextField(_pilotNameController, 'Pilot Name *', Icons.person, required: true),
                        _buildTextField(_dateController, 'Date *', Icons.calendar_today, required: true),
                        _buildTextField(_departureAirportController, 'Departure *', Icons.flight_takeoff, required: true),
                        _buildTextField(_destinationAirportController, 'Destination *', Icons.flight_land, required: true),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            Card(
              elevation: 2,
              child: ExpansionTile(
                initiallyExpanded: false,
                leading: const Icon(Icons.airport_shuttle, color: Colors.orange),
                title: const Text('Runway & Performance', style: TextStyle(fontWeight: FontWeight.bold)),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildTextField(_runwayController, 'Runway *', Icons.route, required: true),
                        _buildTextField(_runwayLengthController, 'Length (m) *', Icons.straighten, required: true, keyboardType: TextInputType.number),
                        _buildTextField(_windController, 'Wind *', Icons.air, required: true),
                        _buildTextField(_abortPointController, 'Abort Point *', Icons.stop_circle, required: true),
                        _buildTextField(_engineFailureActionController, 'Engine Failure Action *', Icons.build, required: true, maxLines: 2),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('TEM - Threat & Error Management', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _buildListSection('Threats', _threats, Colors.red),
                    const SizedBox(height: 12),
                    _buildListSection('Errors', _errors, Colors.orange),
                    const SizedBox(height: 12),
                    _buildListSection('Mitigations', _mitigations, Colors.green),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            ElevatedButton.icon(
              onPressed: _generatePDF,
              icon: const Icon(Icons.picture_as_pdf, color: Colors.black),
              label: const Text('Generate Briefing PDF', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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

  Widget _buildListSection(String title, List<String> items, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.label, color: color, size: 20),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(left: 28, bottom: 4),
          child: Row(
            children: [
              Expanded(child: Text('• $item')),
              IconButton(
                icon: const Icon(Icons.delete, size: 20),
                onPressed: () => setState(() => items.remove(item)),
              ),
            ],
          ),
        )),
        TextButton.icon(
          onPressed: () async {
            final controller = TextEditingController();
            final result = await showDialog<String>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Add $title'),
                content: TextField(controller: controller, autofocus: true, maxLines: 2),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                  TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Add')),
                ],
              ),
            );
            if (result != null && result.isNotEmpty) {
              setState(() => items.add(result));
            }
          },
          icon: Icon(Icons.add, color: color),
          label: Text('Add $title', style: TextStyle(color: color)),
        ),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool required = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
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
    _departureAirportController.dispose();
    _destinationAirportController.dispose();
    _runwayController.dispose();
    _runwayLengthController.dispose();
    _windController.dispose();
    _abortPointController.dispose();
    _engineFailureActionController.dispose();
    super.dispose();
  }
}
