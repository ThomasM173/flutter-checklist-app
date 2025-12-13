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

class FuelUpliftScreen extends StatefulWidget {
  const FuelUpliftScreen({super.key});

  @override
  State<FuelUpliftScreen> createState() => _FuelUpliftScreenState();
}

class _FuelUpliftScreenState extends State<FuelUpliftScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _aircraftRegistrationController = TextEditingController();
  final _dateController = TextEditingController();
  final _pilotNameController = TextEditingController();
  final _locationController = TextEditingController();
  
  // Fuel readings
  final _preFuelLeftController = TextEditingController();
  final _preFuelRightController = TextEditingController();
  final _fuelUpliftController = TextEditingController();
  
  // Bowser checks
  bool _bowserWaterCheckPassed = true;
  final _bowserNumberController = TextEditingController();
  final _fuelGradeController = TextEditingController(text: '100LL');
  
  // Calculated values
  String _fuelSupplier = 'Self-Service';
  
  @override
  void initState() {
    super.initState();
    _dateController.text = DateTime.now().toString().split(' ')[0];
    _loadLastEntry();
  }

  Future<void> _loadLastEntry() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pilotNameController.text = prefs.getString('fuel_pilotName') ?? '';
      _aircraftRegistrationController.text = prefs.getString('fuel_registration') ?? '';
    });
  }

  Future<void> _saveEntry() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fuel_pilotName', _pilotNameController.text);
    await prefs.setString('fuel_registration', _aircraftRegistrationController.text);
  }

  double _getTotalPreFuel() {
    final left = double.tryParse(_preFuelLeftController.text) ?? 0.0;
    final right = double.tryParse(_preFuelRightController.text) ?? 0.0;
    return left + right;
  }

  double _getTotalPostFuel() {
    return _getTotalPreFuel() + (double.tryParse(_fuelUpliftController.text) ?? 0.0);
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
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(30),
          theme: pw.ThemeData.withFont(base: pdfFont),
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                "FUEL UPLIFT & BOWSER CHECK RECORD",
                style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
              ),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 10),
              
              if (user?.fullName != null) pw.Text("Pilot: ${user!.fullName}", style: pw.TextStyle(fontSize: 11)),
              if (user?.licenseNumber != null) pw.Text("License: ${user!.licenseNumber}", style: pw.TextStyle(fontSize: 11)),
              if (user?.homeBase != null) pw.Text("Home Base: ${user!.homeBase}", style: pw.TextStyle(fontSize: 11)),
              pw.SizedBox(height: 10),
              
              _pdfRow("Aircraft Registration:", _aircraftRegistrationController.text),
              _pdfRow("Date:", _dateController.text),
              _pdfRow("Location:", _locationController.text),
              _pdfRow("Pilot Name:", _pilotNameController.text),
              
              pw.SizedBox(height: 15),
              
              pw.Container(
                padding: pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue50,
                  border: pw.Border.all(color: PdfColors.blue),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("PRE-FUELING LEVELS", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text("Left Tank:", style: pw.TextStyle(fontSize: 11)),
                        pw.Text("${_preFuelLeftController.text} USG", style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text("Right Tank:", style: pw.TextStyle(fontSize: 11)),
                        pw.Text("${_preFuelRightController.text} USG", style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                    pw.Divider(),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text("Total Pre-Fuel:", style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                        pw.Text("${_getTotalPreFuel().toStringAsFixed(1)} USG", 
                            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 12),
              
              pw.Container(
                padding: pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.green50,
                  border: pw.Border.all(color: PdfColors.green),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("FUEL UPLIFT", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text("Fuel Grade:", style: pw.TextStyle(fontSize: 11)),
                        pw.Text(_fuelGradeController.text, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text("Supplier:", style: pw.TextStyle(fontSize: 11)),
                        pw.Text(_fuelSupplier, style: pw.TextStyle(fontSize: 11)),
                      ],
                    ),
                    if (_bowserNumberController.text.isNotEmpty)
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text("Bowser Number:", style: pw.TextStyle(fontSize: 11)),
                          pw.Text(_bowserNumberController.text, style: pw.TextStyle(fontSize: 11)),
                        ],
                      ),
                    pw.Divider(),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text("Fuel Uplifted:", style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                        pw.Text("${_fuelUpliftController.text} USG", 
                            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.green900)),
                      ],
                    ),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 12),
              
              pw.Container(
                padding: pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: _bowserWaterCheckPassed ? PdfColors.green50 : PdfColors.red50,
                  border: pw.Border.all(color: _bowserWaterCheckPassed ? PdfColors.green : PdfColors.red),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("BOWSER WATER CHECK", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      children: [
                        pw.Text(
                          _bowserWaterCheckPassed ? "✅ PASSED" : "❌ FAILED",
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: _bowserWaterCheckPassed ? PdfColors.green900 : PdfColors.red900,
                          ),
                        ),
                      ],
                    ),
                    if (!_bowserWaterCheckPassed)
                      pw.Text(
                        "WARNING: Do not use this fuel source until water contamination is resolved!",
                        style: pw.TextStyle(fontSize: 10, color: PdfColors.red900, fontStyle: pw.FontStyle.italic),
                      ),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 12),
              
              pw.Container(
                padding: pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.orange50,
                  border: pw.Border.all(color: PdfColors.orange, width: 2),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("TOTAL FUEL ON BOARD", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text("Total Usable Fuel:", style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
                        pw.Text("${_getTotalPostFuel().toStringAsFixed(1)} USG", 
                            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.orange900)),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      "≈ ${(_getTotalPostFuel() * 6).toStringAsFixed(0)} lbs (at 6 lbs/USG)",
                      style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic),
                    ),
                  ],
                ),
              ),
              
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
                        child: pw.Text(_pilotNameController.text, 
                            style: pw.TextStyle(fontSize: 12, fontStyle: pw.FontStyle.italic)),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("Date/Time:", style: pw.TextStyle(fontSize: 10)),
                      pw.SizedBox(height: 5),
                      pw.Container(
                        width: 150,
                        padding: pw.EdgeInsets.symmetric(vertical: 8),
                        decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide())),
                        child: pw.Text("${_dateController.text} ${TimeOfDay.now().format(context as BuildContext)}", 
                            style: pw.TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      );

      await _saveEntry();

      final output = await getTemporaryDirectory();
      final fileName = "FuelUplift_${_aircraftRegistrationController.text}_${_dateController.text}.pdf";
      final file = File("${output.path}/$fileName");
      final pdfBytes = await pdf.save();
      await file.writeAsBytes(pdfBytes);
      
      try {
        await PdfUploadService().uploadPdf(
          pdfBytes,
          title: 'Fuel Uplift - ${_aircraftRegistrationController.text} - ${_dateController.text}',
          aircraftId: _aircraftRegistrationController.text,
          type: 'fuel_uplift',
        );
      } catch (e) {
        debugPrint('Failed to upload PDF: $e');
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fuel Uplift PDF generated!'), backgroundColor: Colors.green),
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
          "Fuel Uplift & Bowser Checks",
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
                        _buildTextField(_locationController, 'Location/Airport *', Icons.location_on, required: true),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: ExpansionTile(
                initiallyExpanded: false,
                leading: const Icon(Icons.speed, color: Colors.orange),
                title: const Text('Pre-Fueling Levels', style: TextStyle(fontWeight: FontWeight.bold)),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildTextField(_preFuelLeftController, 'Left Tank (USG) *', Icons.opacity, 
                            required: true, keyboardType: TextInputType.number, onChanged: () => setState(() {})),
                        _buildTextField(_preFuelRightController, 'Right Tank (USG) *', Icons.opacity,
                            required: true, keyboardType: TextInputType.number, onChanged: () => setState(() {})),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Pre-Fuel:', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text('${_getTotalPreFuel().toStringAsFixed(1)} USG',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: ExpansionTile(
                initiallyExpanded: false,
                leading: const Icon(Icons.local_gas_station, color: Colors.green),
                title: const Text('Fuel Uplift', style: TextStyle(fontWeight: FontWeight.bold)),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildTextField(_fuelUpliftController, 'Fuel Uplifted (USG) *', Icons.add_circle,
                            required: true, keyboardType: TextInputType.number, onChanged: () => setState(() {})),
                        _buildTextField(_fuelGradeController, 'Fuel Grade *', Icons.local_fire_department, required: true),
                        DropdownButtonFormField<String>(
                          value: _fuelSupplier,
                          decoration: const InputDecoration(
                            labelText: 'Fuel Supplier',
                            prefixIcon: Icon(Icons.store),
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          items: ['Self-Service', 'Bowser', 'Fuel Truck', 'Fixed Installation']
                              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                              .toList(),
                          onChanged: (val) => setState(() => _fuelSupplier = val!),
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(_bowserNumberController, 'Bowser/Pump Number', Icons.confirmation_number),
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
              color: _bowserWaterCheckPassed ? Colors.green[50] : Colors.red[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.water_drop, color: _bowserWaterCheckPassed ? Colors.green : Colors.red),
                        const SizedBox(width: 8),
                        const Text('Bowser Water Check', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: Text(_bowserWaterCheckPassed ? 'Water Check PASSED ✅' : 'Water Check FAILED ❌',
                          style: TextStyle(fontWeight: FontWeight.bold, 
                              color: _bowserWaterCheckPassed ? Colors.green[900] : Colors.red[900])),
                      subtitle: Text(_bowserWaterCheckPassed 
                          ? 'Fuel is clear and free of water contamination'
                          : 'Do NOT use this fuel source!'),
                      value: _bowserWaterCheckPassed,
                      onChanged: (val) => setState(() => _bowserWaterCheckPassed = val),
                      activeColor: Colors.green,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              color: Colors.orange[50],
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.local_gas_station, color: Colors.orange, size: 28),
                        const SizedBox(width: 12),
                        const Text('Total Fuel On Board', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Usable Fuel:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                        Text('${_getTotalPostFuel().toStringAsFixed(1)} USG',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('≈ ${(_getTotalPostFuel() * 6).toStringAsFixed(0)} lbs (at 6 lbs/USG)',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700], fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            ElevatedButton.icon(
              onPressed: _generatePDF,
              icon: const Icon(Icons.picture_as_pdf, color: Colors.black),
              label: const Text('Generate Fuel Record PDF', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
    VoidCallback? onChanged,
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
        onChanged: onChanged != null ? (_) => onChanged() : null,
      ),
    );
  }

  @override
  void dispose() {
    _aircraftRegistrationController.dispose();
    _dateController.dispose();
    _pilotNameController.dispose();
    _locationController.dispose();
    _preFuelLeftController.dispose();
    _preFuelRightController.dispose();
    _fuelUpliftController.dispose();
    _bowserNumberController.dispose();
    _fuelGradeController.dispose();
    super.dispose();
  }
}
