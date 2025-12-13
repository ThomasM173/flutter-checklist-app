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

class PassengerBriefScreen extends StatefulWidget {
  const PassengerBriefScreen({super.key});

  @override
  State<PassengerBriefScreen> createState() => _PassengerBriefScreenState();
}

class _PassengerBriefScreenState extends State<PassengerBriefScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _aircraftRegistrationController = TextEditingController();
  final _dateController = TextEditingController();
  final _pilotNameController = TextEditingController();
  final _departureController = TextEditingController();
  final _destinationController = TextEditingController();
  
  final List<PassengerEntry> _passengers = [];
  
  // Safety brief checklist
  bool _seatBelts = false;
  bool _doorOperation = false;
  bool _emergencyExit = false;
  bool _fireExtinguisher = false;
  bool _lifejackets = false;
  bool _smokingProhibited = false;
  bool _electronicDevices = false;
  bool _briefingQuestions = false;
  
  @override
  void initState() {
    super.initState();
    _dateController.text = DateTime.now().toString().split(' ')[0];
    _loadLastEntry();
  }

  Future<void> _loadLastEntry() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pilotNameController.text = prefs.getString('pax_pilotName') ?? '';
      _aircraftRegistrationController.text = prefs.getString('pax_registration') ?? '';
    });
  }

  Future<void> _saveEntry() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pax_pilotName', _pilotNameController.text);
    await prefs.setString('pax_registration', _aircraftRegistrationController.text);
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
              pw.Text("PASSENGER SAFETY BRIEFING RECORD", style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
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
            _pdfRow("Pilot:", _pilotNameController.text),
            _pdfRow("Departure:", _departureController.text),
            _pdfRow("Destination:", _destinationController.text),
            _pdfRow("Number of Passengers:", "${_passengers.length}"),
            
            pw.SizedBox(height: 15),
            
            pw.Text("PASSENGER LIST", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            
            if (_passengers.isEmpty)
              pw.Text("No passengers recorded", style: pw.TextStyle(fontSize: 11, fontStyle: pw.FontStyle.italic))
            else
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.blue900),
                    children: [
                      _pdfCell("Name", bold: true, color: PdfColors.white),
                      _pdfCell("Age", bold: true, color: PdfColors.white),
                      _pdfCell("Weight (kg)", bold: true, color: PdfColors.white),
                      _pdfCell("Emergency Contact", bold: true, color: PdfColors.white),
                    ],
                  ),
                  ...List.generate(_passengers.length, (i) {
                    final p = _passengers[i];
                    return pw.TableRow(
                      children: [
                        _pdfCell(p.name),
                        _pdfCell(p.age),
                        _pdfCell(p.weight),
                        _pdfCell(p.emergencyContact),
                      ],
                    );
                  }),
                ],
              ),
            
            pw.SizedBox(height: 15),
            
            pw.Text("SAFETY BRIEFING COMPLETED", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            
            _pdfCheckbox("Seat belts operation demonstrated", _seatBelts),
            _pdfCheckbox("Door operation and emergency exit explained", _doorOperation),
            _pdfCheckbox("Emergency exit location pointed out", _emergencyExit),
            _pdfCheckbox("Fire extinguisher location shown", _fireExtinguisher),
            _pdfCheckbox("Lifejackets location shown (if required)", _lifejackets),
            _pdfCheckbox("Smoking prohibited", _smokingProhibited),
            _pdfCheckbox("Electronic devices policy explained", _electronicDevices),
            _pdfCheckbox("Passengers given opportunity to ask questions", _briefingQuestions),
            
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
      final fileName = "PassengerBrief_${_dateController.text}.pdf";
      final file = File("${output.path}/$fileName");
      final pdfBytes = await pdf.save();
      await file.writeAsBytes(pdfBytes);
      
      try {
        await PdfUploadService().uploadPdf(
          pdfBytes,
          title: 'Passenger Brief - ${_dateController.text}',
          aircraftId: _aircraftRegistrationController.text,
          type: 'passenger_brief',
        );
      } catch (e) {
        debugPrint('Failed to upload PDF: $e');
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passenger Brief PDF generated!'), backgroundColor: Colors.green),
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

  pw.Widget _pdfCheckbox(String label, bool checked) {
    return pw.Padding(
      padding: pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        children: [
          pw.Container(
            width: 12,
            height: 12,
            decoration: pw.BoxDecoration(border: pw.Border.all(), color: checked ? PdfColors.green : null),
            child: checked ? pw.Center(child: pw.Text("✓", style: pw.TextStyle(fontSize: 10, color: PdfColors.white))) : pw.SizedBox(),
          ),
          pw.SizedBox(width: 8),
          pw.Text(label, style: pw.TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  pw.Widget _pdfCell(String text, {bool bold = false, PdfColor? color}) {
    return pw.Padding(
      padding: pw.EdgeInsets.all(6),
      child: pw.Text(text, style: pw.TextStyle(fontSize: 10, fontWeight: bold ? pw.FontWeight.bold : null, color: color)),
    );
  }

  pw.Widget _pdfRow(String label, String value) {
    return pw.Padding(
      padding: pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        children: [
          pw.Container(width: 140, child: pw.Text(label, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold))),
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
        title: const Text("Passenger Safety Brief", style: TextStyle(color: Colors.black)),
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
                leading: const Icon(Icons.flight, color: Colors.blue),
                title: const Text('Flight Details', style: TextStyle(fontWeight: FontWeight.bold)),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildTextField(_aircraftRegistrationController, 'Aircraft *', Icons.local_airport, required: true),
                        _buildTextField(_pilotNameController, 'Pilot Name *', Icons.person, required: true),
                        _buildTextField(_dateController, 'Date *', Icons.calendar_today, required: true),
                        _buildTextField(_departureController, 'Departure *', Icons.flight_takeoff, required: true),
                        _buildTextField(_destinationController, 'Destination *', Icons.flight_land, required: true),
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
                    Row(
                      children: [
                        const Icon(Icons.people, color: Colors.blue, size: 28),
                        const SizedBox(width: 12),
                        const Text('Passenger List', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        Text('${_passengers.length} PAX', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    if (_passengers.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                        child: const Center(child: Text('No passengers added', style: TextStyle(fontStyle: FontStyle.italic))),
                      )
                    else
                      ...List.generate(_passengers.length, (index) {
                        final p = _passengers[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(child: Text('${index + 1}')),
                            title: Text(p.name),
                            subtitle: Text('Age: ${p.age}, Weight: ${p.weight}kg\nEmergency: ${p.emergencyContact}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => setState(() => _passengers.removeAt(index)),
                            ),
                            isThreeLine: true,
                          ),
                        );
                      }),
                    
                    const SizedBox(height: 12),
                    
                    ElevatedButton.icon(
                      onPressed: () async {
                        final result = await showDialog<PassengerEntry>(
                          context: context,
                          builder: (context) => const AddPassengerDialog(),
                        );
                        if (result != null) {
                          setState(() => _passengers.add(result));
                        }
                      },
                      icon: const Icon(Icons.person_add, color: Colors.white),
                      label: const Text('Add Passenger', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
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
                    const Row(
                      children: [
                        Icon(Icons.health_and_safety, color: Colors.green, size: 28),
                        SizedBox(width: 12),
                        Text('Safety Briefing Checklist', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(value: _seatBelts, onChanged: (v) => setState(() => _seatBelts = v!), title: const Text('Seat belts operation')),
                    CheckboxListTile(value: _doorOperation, onChanged: (v) => setState(() => _doorOperation = v!), title: const Text('Door operation & emergency exit')),
                    CheckboxListTile(value: _emergencyExit, onChanged: (v) => setState(() => _emergencyExit = v!), title: const Text('Emergency exit location')),
                    CheckboxListTile(value: _fireExtinguisher, onChanged: (v) => setState(() => _fireExtinguisher = v!), title: const Text('Fire extinguisher location')),
                    CheckboxListTile(value: _lifejackets, onChanged: (v) => setState(() => _lifejackets = v!), title: const Text('Lifejackets (if required)')),
                    CheckboxListTile(value: _smokingProhibited, onChanged: (v) => setState(() => _smokingProhibited = v!), title: const Text('Smoking prohibited')),
                    CheckboxListTile(value: _electronicDevices, onChanged: (v) => setState(() => _electronicDevices = v!), title: const Text('Electronic devices policy')),
                    CheckboxListTile(value: _briefingQuestions, onChanged: (v) => setState(() => _briefingQuestions = v!), title: const Text('Opportunity for questions')),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            ElevatedButton.icon(
              onPressed: _generatePDF,
              icon: const Icon(Icons.picture_as_pdf, color: Colors.black),
              label: const Text('Generate Passenger Brief PDF', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
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
    _departureController.dispose();
    _destinationController.dispose();
    super.dispose();
  }
}

class PassengerEntry {
  String name;
  String age;
  String weight;
  String emergencyContact;

  PassengerEntry({
    this.name = '',
    this.age = '',
    this.weight = '',
    this.emergencyContact = '',
  });
}

class AddPassengerDialog extends StatefulWidget {
  const AddPassengerDialog({super.key});

  @override
  State<AddPassengerDialog> createState() => _AddPassengerDialogState();
}

class _AddPassengerDialogState extends State<AddPassengerDialog> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _emergencyController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Passenger'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Name', prefixIcon: Icon(Icons.person))),
            const SizedBox(height: 12),
            TextField(controller: _ageController, decoration: const InputDecoration(labelText: 'Age', prefixIcon: Icon(Icons.cake)), keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            TextField(controller: _weightController, decoration: const InputDecoration(labelText: 'Weight (kg)', prefixIcon: Icon(Icons.scale)), keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            TextField(controller: _emergencyController, decoration: const InputDecoration(labelText: 'Emergency Contact', prefixIcon: Icon(Icons.phone))),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            if (_nameController.text.isNotEmpty) {
              Navigator.pop(context, PassengerEntry(
                name: _nameController.text,
                age: _ageController.text,
                weight: _weightController.text,
                emergencyContact: _emergencyController.text,
              ));
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _emergencyController.dispose();
    super.dispose();
  }
}

