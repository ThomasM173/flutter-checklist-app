import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clearedtogo/services/auth_service.dart';
import 'package:clearedtogo/services/pdf_storage_helper.dart';

class WeightBalanceScreen extends StatefulWidget {
  const WeightBalanceScreen({super.key});

  @override
  State<WeightBalanceScreen> createState() => _WeightBalanceScreenState();
}

class _WeightBalanceScreenState extends State<WeightBalanceScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Aircraft Selection
  String _selectedAircraft = 'Cessna 152';
  
  // Flight Details
  final _pilotNameController = TextEditingController();
  final _dateController = TextEditingController();
  final _aircraftRegistrationController = TextEditingController();
  final _departureController = TextEditingController();
  final _destinationController = TextEditingController();
  
  // Weight & Balance Data
  final _basicEmptyWeightController = TextEditingController();
  final _basicEmptyMomentController = TextEditingController();
  
  // Pilot & Front Seat
  final _frontSeatWeightController = TextEditingController();
  final _frontSeatArmController = TextEditingController();
  
  // Rear Seat
  final _rearSeatWeightController = TextEditingController();
  final _rearSeatArmController = TextEditingController();
  
  // Baggage Area 1
  final _baggage1WeightController = TextEditingController();
  final _baggage1ArmController = TextEditingController();
  
  // Baggage Area 2 (if applicable)
  final _baggage2WeightController = TextEditingController();
  final _baggage2ArmController = TextEditingController();
  
  // Fuel
  final _fuelWeightController = TextEditingController();
  final _fuelArmController = TextEditingController();
  
  // Aircraft Templates
  final Map<String, Map<String, dynamic>> _aircraftTemplates = {
    'Cessna 152': {
      'maxWeight': 1670.0,
      'frontSeatArm': 33.0,
      'rearSeatArm': 0.0, // No rear seats
      'baggage1Arm': 63.0,
      'baggage2Arm': 0.0,
      'fuelArm': 32.0,
      'cgLimits': {
        'forwardAt1500': 31.0,
        'forwardAt1670': 32.5,
        'aftAt1500': 36.5,
        'aftAt1670': 36.5,
      },
    },
    'Cessna 172': {
      'maxWeight': 2550.0,
      'frontSeatArm': 37.0,
      'rearSeatArm': 73.0,
      'baggage1Arm': 95.0,
      'baggage2Arm': 123.0,
      'fuelArm': 48.0,
      'cgLimits': {
        'forwardAt2100': 35.0,
        'forwardAt2550': 37.5,
        'aftAt2100': 43.0,
        'aftAt2550': 47.3,
      },
    },
    'Piper PA-28': {
      'maxWeight': 2440.0,
      'frontSeatArm': 85.5,
      'rearSeatArm': 118.1,
      'baggage1Arm': 142.8,
      'baggage2Arm': 0.0,
      'fuelArm': 95.0,
      'cgLimits': {
        'forwardAt2000': 86.0,
        'forwardAt2440': 88.0,
        'aftAt2000': 94.2,
        'aftAt2440': 94.2,
      },
    },
  };

  @override
  void initState() {
    super.initState();
    _dateController.text = DateTime.now().toString().split(' ')[0];
    _loadTemplate();
    _loadLastEntry();
  }

  void _loadTemplate() {
    final template = _aircraftTemplates[_selectedAircraft]!;
    _frontSeatArmController.text = template['frontSeatArm'].toString();
    _rearSeatArmController.text = template['rearSeatArm'].toString();
    _baggage1ArmController.text = template['baggage1Arm'].toString();
    _baggage2ArmController.text = template['baggage2Arm'].toString();
    _fuelArmController.text = template['fuelArm'].toString();
  }

  Future<void> _loadLastEntry() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pilotNameController.text = prefs.getString('wb_pilotName') ?? '';
      _aircraftRegistrationController.text = prefs.getString('wb_registration') ?? '';
    });
  }

  Future<void> _saveEntry() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('wb_pilotName', _pilotNameController.text);
    await prefs.setString('wb_registration', _aircraftRegistrationController.text);
  }

  double _calculateMoment(String weightStr, String armStr) {
    final weight = double.tryParse(weightStr) ?? 0.0;
    final arm = double.tryParse(armStr) ?? 0.0;
    return weight * arm / 1000; // Moment in thousands
  }

  Map<String, double> _calculateTotals() {
    final basicWeight = double.tryParse(_basicEmptyWeightController.text) ?? 0.0;
    final basicMoment = double.tryParse(_basicEmptyMomentController.text) ?? 0.0;
    
    final frontWeight = double.tryParse(_frontSeatWeightController.text) ?? 0.0;
    final frontMoment = _calculateMoment(_frontSeatWeightController.text, _frontSeatArmController.text);
    
    final rearWeight = double.tryParse(_rearSeatWeightController.text) ?? 0.0;
    final rearMoment = _calculateMoment(_rearSeatWeightController.text, _rearSeatArmController.text);
    
    final baggage1Weight = double.tryParse(_baggage1WeightController.text) ?? 0.0;
    final baggage1Moment = _calculateMoment(_baggage1WeightController.text, _baggage1ArmController.text);
    
    final baggage2Weight = double.tryParse(_baggage2WeightController.text) ?? 0.0;
    final baggage2Moment = _calculateMoment(_baggage2WeightController.text, _baggage2ArmController.text);
    
    final fuelWeight = double.tryParse(_fuelWeightController.text) ?? 0.0;
    final fuelMoment = _calculateMoment(_fuelWeightController.text, _fuelArmController.text);
    
    final totalWeight = basicWeight + frontWeight + rearWeight + baggage1Weight + baggage2Weight + fuelWeight;
    final totalMoment = basicMoment + frontMoment + rearMoment + baggage1Moment + baggage2Moment + fuelMoment;
    final cg = totalWeight > 0 ? (totalMoment * 1000) / totalWeight : 0.0;
    
    return {
      'totalWeight': totalWeight,
      'totalMoment': totalMoment,
      'cg': cg,
    };
  }

  String _checkCGLimits() {
    final totals = _calculateTotals();
    final weight = totals['totalWeight']!;
    final cg = totals['cg']!;
    final template = _aircraftTemplates[_selectedAircraft]!;
    final maxWeight = template['maxWeight'];
    final cgLimits = template['cgLimits'] as Map<String, dynamic>;
    
    if (weight > maxWeight) {
      return '❌ OVERWEIGHT - Reduce weight by ${(weight - maxWeight).toStringAsFixed(1)} lbs';
    }
    
    // Simplified CG check (you may need to interpolate for exact limits)
    final forwardLimit = cgLimits.values.toList()[0] as double;
    final aftLimit = cgLimits.values.toList()[2] as double;
    
    if (cg < forwardLimit) {
      return '❌ CG TOO FORWARD - ${cg.toStringAsFixed(2)}" (limit: ${forwardLimit.toStringAsFixed(2)}")';
    }
    
    if (cg > aftLimit) {
      return '❌ CG TOO AFT - ${cg.toStringAsFixed(2)}" (limit: ${aftLimit.toStringAsFixed(2)}")';
    }
    
    return '✅ WITHIN LIMITS';
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
      final totals = _calculateTotals();
      final cgStatus = _checkCGLimits();
      
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
                "WEIGHT & BALANCE LOADSHEET",
                style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
              ),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 10),
              
              if (user?.fullName != null) pw.Text("Pilot: ${user!.fullName}", style: pw.TextStyle(fontSize: 11)),
              if (user?.licenseNumber != null) pw.Text("License: ${user!.licenseNumber}", style: pw.TextStyle(fontSize: 11)),
              if (user?.homeBase != null) pw.Text("Home Base: ${user!.homeBase}", style: pw.TextStyle(fontSize: 11)),
              pw.SizedBox(height: 10),
              
              // Flight Details
              _pdfRow("Aircraft Type:", _selectedAircraft),
              _pdfRow("Registration:", _aircraftRegistrationController.text),
              _pdfRow("Date:", _dateController.text),
              _pdfRow("Departure:", _departureController.text),
              _pdfRow("Destination:", _destinationController.text),
              pw.SizedBox(height: 15),
              
              // Weight & Balance Table
              pw.Text(
                "WEIGHT & BALANCE CALCULATION",
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 8),
              
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: pw.FlexColumnWidth(3),
                  1: pw.FlexColumnWidth(2),
                  2: pw.FlexColumnWidth(2),
                  3: pw.FlexColumnWidth(2),
                },
                children: [
                  _pdfTableHeader(),
                  _pdfTableRow("Basic Empty Weight", _basicEmptyWeightController.text, "-", _basicEmptyMomentController.text),
                  _pdfTableRow("Front Seat", _frontSeatWeightController.text, _frontSeatArmController.text, 
                      _calculateMoment(_frontSeatWeightController.text, _frontSeatArmController.text).toStringAsFixed(2)),
                  if ((double.tryParse(_rearSeatWeightController.text) ?? 0) > 0)
                    _pdfTableRow("Rear Seat", _rearSeatWeightController.text, _rearSeatArmController.text,
                        _calculateMoment(_rearSeatWeightController.text, _rearSeatArmController.text).toStringAsFixed(2)),
                  if ((double.tryParse(_baggage1WeightController.text) ?? 0) > 0)
                    _pdfTableRow("Baggage 1", _baggage1WeightController.text, _baggage1ArmController.text,
                        _calculateMoment(_baggage1WeightController.text, _baggage1ArmController.text).toStringAsFixed(2)),
                  if ((double.tryParse(_baggage2WeightController.text) ?? 0) > 0)
                    _pdfTableRow("Baggage 2", _baggage2WeightController.text, _baggage2ArmController.text,
                        _calculateMoment(_baggage2WeightController.text, _baggage2ArmController.text).toStringAsFixed(2)),
                  _pdfTableRow("Fuel", _fuelWeightController.text, _fuelArmController.text,
                      _calculateMoment(_fuelWeightController.text, _fuelArmController.text).toStringAsFixed(2)),
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      _pdfCell("TOTAL", bold: true),
                      _pdfCell("${totals['totalWeight']!.toStringAsFixed(1)} lbs", bold: true),
                      _pdfCell("-", bold: true),
                      _pdfCell(totals['totalMoment']!.toStringAsFixed(2), bold: true),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      _pdfCell("CENTER OF GRAVITY", bold: true),
                      _pdfCell(""),
                      _pdfCell("${totals['cg']!.toStringAsFixed(2)}\"", bold: true, colSpan: 2),
                      _pdfCell(""),
                    ],
                  ),
                ],
              ),
              
              pw.SizedBox(height: 15),
              
              // CG Status
              pw.Container(
                padding: pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: cgStatus.contains('✅') ? PdfColors.green50 : PdfColors.red50,
                  border: pw.Border.all(
                    color: cgStatus.contains('✅') ? PdfColors.green : PdfColors.red,
                    width: 2,
                  ),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  cgStatus,
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                    color: cgStatus.contains('✅') ? PdfColors.green900 : PdfColors.red900,
                  ),
                ),
              ),
              
              pw.Spacer(),
              
              // Signature
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
                        decoration: pw.BoxDecoration(
                          border: pw.Border(bottom: pw.BorderSide()),
                        ),
                        child: pw.Text(
                          _pilotNameController.text,
                          style: pw.TextStyle(fontSize: 12, fontStyle: pw.FontStyle.italic),
                        ),
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
                        decoration: pw.BoxDecoration(
                          border: pw.Border(bottom: pw.BorderSide()),
                        ),
                        child: pw.Text(
                          _dateController.text,
                          style: pw.TextStyle(fontSize: 12),
                        ),
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

      final pdfBytes = await pdf.save();
      
      // Save PDF using new storage helper (uploads to repository & cloud)
      try {
        final filePath = await PdfStorageHelper().savePdf(
          pdfBytes: pdfBytes,
          title: 'Weight & Balance - ${_selectedAircraft} - ${_dateController.text}',
          pdfType: 'weight_balance',
          aircraftType: _selectedAircraft,
          aircraftRegistration: _aircraftRegistrationController.text.isNotEmpty 
              ? _aircraftRegistrationController.text 
              : null,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PDF generated and saved successfully!'), backgroundColor: Colors.green),
          );
        }
        
        OpenFile.open(filePath);
      } catch (e) {
        debugPrint('Failed to save PDF: $e');
        
        // Fallback: save to temp and open
        final output = await getTemporaryDirectory();
        final fileName = "W&B_${_selectedAircraft.replaceAll(' ', '_')}_${_dateController.text}.pdf";
        final file = File("${output.path}/$fileName");
        await file.writeAsBytes(pdfBytes);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PDF generated (not uploaded)'), backgroundColor: Colors.orange),
          );
        }
        
        OpenFile.open(file.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error generating PDF: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  pw.TableRow _pdfTableHeader() {
    return pw.TableRow(
      decoration: pw.BoxDecoration(color: PdfColors.blue900),
      children: [
        _pdfCell("Item", bold: true, color: PdfColors.white),
        _pdfCell("Weight (lbs)", bold: true, color: PdfColors.white),
        _pdfCell("Arm (in)", bold: true, color: PdfColors.white),
        _pdfCell("Moment (/1000)", bold: true, color: PdfColors.white),
      ],
    );
  }

  pw.TableRow _pdfTableRow(String item, String weight, String arm, String moment) {
    return pw.TableRow(
      children: [
        _pdfCell(item),
        _pdfCell(weight),
        _pdfCell(arm),
        _pdfCell(moment),
      ],
    );
  }

  pw.Widget _pdfCell(String text, {bool bold = false, PdfColor? color, int colSpan = 1}) {
    return pw.Padding(
      padding: pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color,
        ),
      ),
    );
  }

  pw.Widget _pdfRow(String label, String value) {
    return pw.Padding(
      padding: pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        children: [
          pw.Container(
            width: 120,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Text(value, style: pw.TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totals = _calculateTotals();
    final cgStatus = _checkCGLimits();
    final template = _aircraftTemplates[_selectedAircraft]!;
    
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text(
          "Weight & Balance Loadsheet",
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
            // Aircraft Selection Card
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.airplanemode_active, color: Color(0xFF87CEEB)),
                        SizedBox(width: 8),
                        Text(
                          'Aircraft Type',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedAircraft,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: _aircraftTemplates.keys
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedAircraft = val!;
                          _loadTemplate();
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Max Weight: ${template['maxWeight']} lbs',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Flight Details
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: ExpansionTile(
                initiallyExpanded: false,
                leading: const Icon(Icons.flight, color: Colors.purple),
                title: const Text('Flight Details', style: TextStyle(fontWeight: FontWeight.bold)),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildTextField(_pilotNameController, 'Pilot Name *', Icons.person, required: true),
                        _buildTextField(_dateController, 'Date *', Icons.calendar_today, required: true),
                        _buildTextField(_aircraftRegistrationController, 'Registration *', Icons.tag, required: true),
                        _buildTextField(_departureController, 'Departure', Icons.flight_takeoff),
                        _buildTextField(_destinationController, 'Destination', Icons.flight_land),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Basic Empty Weight
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: ExpansionTile(
                initiallyExpanded: false,
                leading: const Icon(Icons.construction, color: Colors.orange),
                title: const Text('Basic Empty Weight', style: TextStyle(fontWeight: FontWeight.bold)),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildTextField(_basicEmptyWeightController, 'Weight (lbs) *', Icons.scale, 
                            required: true, keyboardType: TextInputType.number),
                        _buildTextField(_basicEmptyMomentController, 'Moment (/1000) *', Icons.architecture,
                            required: true, keyboardType: TextInputType.number),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Front Seat
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: ExpansionTile(
                initiallyExpanded: false,
                leading: const Icon(Icons.event_seat, color: Colors.blue),
                title: const Text('Front Seat', style: TextStyle(fontWeight: FontWeight.bold)),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildTextField(_frontSeatWeightController, 'Weight (lbs)', Icons.person,
                            keyboardType: TextInputType.number),
                        _buildTextField(_frontSeatArmController, 'Arm (in)', Icons.straighten,
                            keyboardType: TextInputType.number, enabled: false),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Rear Seat (if applicable)
            if (template['rearSeatArm'] > 0) ...[
              const SizedBox(height: 16),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: ExpansionTile(
                  initiallyExpanded: false,
                  leading: const Icon(Icons.event_seat, color: Colors.blue),
                  title: const Text('Rear Seat', style: TextStyle(fontWeight: FontWeight.bold)),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildTextField(_rearSeatWeightController, 'Weight (lbs)', Icons.person,
                              keyboardType: TextInputType.number),
                          _buildTextField(_rearSeatArmController, 'Arm (in)', Icons.straighten,
                              keyboardType: TextInputType.number, enabled: false),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // Baggage
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: ExpansionTile(
                initiallyExpanded: false,
                leading: const Icon(Icons.luggage, color: Colors.brown),
                title: const Text('Baggage', style: TextStyle(fontWeight: FontWeight.bold)),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildTextField(_baggage1WeightController, 'Baggage 1 Weight (lbs)', Icons.work,
                            keyboardType: TextInputType.number),
                        _buildTextField(_baggage1ArmController, 'Arm (in)', Icons.straighten,
                            keyboardType: TextInputType.number, enabled: false),
                        if (template['baggage2Arm'] > 0) ...[
                          const SizedBox(height: 12),
                          _buildTextField(_baggage2WeightController, 'Baggage 2 Weight (lbs)', Icons.work,
                              keyboardType: TextInputType.number),
                          _buildTextField(_baggage2ArmController, 'Arm (in)', Icons.straighten,
                              keyboardType: TextInputType.number, enabled: false),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Fuel
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: ExpansionTile(
                initiallyExpanded: false,
                leading: const Icon(Icons.local_gas_station, color: Colors.red),
                title: const Text('Fuel', style: TextStyle(fontWeight: FontWeight.bold)),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildTextField(_fuelWeightController, 'Weight (lbs) *', Icons.opacity,
                            required: true, keyboardType: TextInputType.number),
                        _buildTextField(_fuelArmController, 'Arm (in)', Icons.straighten,
                            keyboardType: TextInputType.number, enabled: false),
                        const SizedBox(height: 8),
                        Text(
                          'Note: 1 US Gallon AvGas ≈ 6 lbs',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Results Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              color: cgStatus.contains('✅') ? Colors.green[50] : Colors.red[50],
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calculate,
                          color: cgStatus.contains('✅') ? Colors.green[700] : Colors.red[700],
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Weight & Balance Results',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _buildResultRow('Total Weight:', '${totals['totalWeight']!.toStringAsFixed(1)} lbs'),
                    _buildResultRow('Max Weight:', '${template['maxWeight']} lbs'),
                    const SizedBox(height: 8),
                    _buildResultRow('Total Moment:', totals['totalMoment']!.toStringAsFixed(2)),
                    _buildResultRow('Center of Gravity:', '${totals['cg']!.toStringAsFixed(2)}"'),
                    const Divider(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cgStatus.contains('✅') ? Colors.green : Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        cgStatus,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Generate PDF Button
            ElevatedButton.icon(
              onPressed: _generatePDF,
              icon: const Icon(Icons.picture_as_pdf, color: Colors.black),
              label: const Text(
                'Generate PDF Loadsheet',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
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
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: enabled ? Colors.white : Colors.grey[100],
        ),
        validator: required
            ? (val) => val == null || val.isEmpty ? 'Required field' : null
            : null,
        onChanged: (_) => setState(() {}), // Recalculate on change
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pilotNameController.dispose();
    _dateController.dispose();
    _aircraftRegistrationController.dispose();
    _departureController.dispose();
    _destinationController.dispose();
    _basicEmptyWeightController.dispose();
    _basicEmptyMomentController.dispose();
    _frontSeatWeightController.dispose();
    _frontSeatArmController.dispose();
    _rearSeatWeightController.dispose();
    _rearSeatArmController.dispose();
    _baggage1WeightController.dispose();
    _baggage1ArmController.dispose();
    _baggage2WeightController.dispose();
    _baggage2ArmController.dispose();
    _fuelWeightController.dispose();
    _fuelArmController.dispose();
    super.dispose();
  }
}
