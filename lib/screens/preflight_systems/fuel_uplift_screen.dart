import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clearedtogo/services/supabase_pdf_service.dart';
import 'package:clearedtogo/services/supabase_auth_service.dart';
import 'package:clearedtogo/utils/completion_pdf_builder.dart';

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
      _aircraftRegistrationController.text =
          prefs.getString('fuel_registration') ?? '';
    });
  }

  Future<void> _saveEntry() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fuel_pilotName', _pilotNameController.text);
    await prefs.setString(
        'fuel_registration', _aircraftRegistrationController.text);
  }

  double _getTotalPreFuel() {
    final left = double.tryParse(_preFuelLeftController.text) ?? 0.0;
    final right = double.tryParse(_preFuelRightController.text) ?? 0.0;
    return left + right;
  }

  double _getTotalPostFuel() {
    return _getTotalPreFuel() +
        (double.tryParse(_fuelUpliftController.text) ?? 0.0);
  }

  /// Structured snapshot shared by [_finishChecklist] and [_viewAsPdf].
  Map<String, dynamic> _buildCompletionData() {
    return {
      'Aircraft Registration': _aircraftRegistrationController.text,
      'Date': _dateController.text,
      'Location': _locationController.text,
      'Pilot Name': _pilotNameController.text,
      'Pre-Fueling Levels': {
        'Left Tank (USG)': _preFuelLeftController.text,
        'Right Tank (USG)': _preFuelRightController.text,
        'Total Pre-Fuel (USG)': _getTotalPreFuel().toStringAsFixed(1),
      },
      'Fuel Uplift': {
        'Fuel Grade': _fuelGradeController.text,
        'Supplier': _fuelSupplier,
        if (_bowserNumberController.text.isNotEmpty)
          'Bowser Number': _bowserNumberController.text,
        'Fuel Uplifted (USG)': _fuelUpliftController.text,
      },
      'Bowser Water Check': _bowserWaterCheckPassed ? 'PASSED' : 'FAILED',
      'Total Usable Fuel (USG)': _getTotalPostFuel().toStringAsFixed(1),
      'Total Usable Fuel (lbs, approx)':
          (_getTotalPostFuel() * 6).toStringAsFixed(0),
    };
  }

  /// Writes straight to checklist_completions - no PDF generated or
  /// uploaded. A PDF (see [_viewAsPdf]) is always available on demand
  /// afterwards, built fresh from this same stored data.
  Future<void> _finishChecklist() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }
    try {
      await _saveEntry();
      await SupabasePdfService().recordCompletionData(
        data: _buildCompletionData(),
        aircraftType: _aircraftRegistrationController.text.isNotEmpty
            ? _aircraftRegistrationController.text
            : 'UNKNOWN',
        checklistName: 'Fuel Uplift',
        completionType: 'fuel_uplift',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fuel uplift record saved.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Failed to save fuel uplift completion: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save fuel uplift record.')),
        );
      }
    }
  }

  /// On-demand PDF, generated fresh from the current form state via the
  /// shared compact renderer - not saved anywhere, just opened locally.
  Future<void> _viewAsPdf() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }
    if (!(Platform.isAndroid || Platform.isIOS)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('PDF generation only works on Android/iOS')),
        );
      }
      return;
    }
    try {
      final fontData =
          await rootBundle.load("assets/fonts/NotoSans-Regular.ttf");
      final pdfFont = pw.Font.ttf(fontData);
      final user = SupabaseAuthService().currentUser;

      final pdfBytes = await CompletionPdfBuilder.build(
        font: pdfFont,
        title: 'Fuel Uplift & Bowser Check Record',
        aircraftType: _aircraftRegistrationController.text.isNotEmpty
            ? _aircraftRegistrationController.text
            : 'UNKNOWN',
        completedAt: DateTime.now(),
        pilotName: user?.fullName,
        licenseNumber: user?.licenseNumber,
        homeBase: user?.homeBase,
        data: _buildCompletionData(),
      );

      final output = await getTemporaryDirectory();
      final fileName =
          "FuelUplift_${_aircraftRegistrationController.text}_${_dateController.text}.pdf";
      final file = File("${output.path}/$fileName");
      await file.writeAsBytes(pdfBytes);
      OpenFile.open(file.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              child: ExpansionTile(
                initiallyExpanded: false,
                leading: const Icon(Icons.flight, color: Colors.blue),
                title: const Text('Flight Details',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildTextField(_aircraftRegistrationController,
                            'Aircraft Registration *', Icons.local_airport,
                            required: true),
                        _buildTextField(
                            _dateController, 'Date *', Icons.calendar_today,
                            required: true),
                        _buildTextField(
                            _pilotNameController, 'Pilot Name *', Icons.person,
                            required: true),
                        _buildTextField(_locationController,
                            'Location/Airport *', Icons.location_on,
                            required: true),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              child: ExpansionTile(
                initiallyExpanded: false,
                leading: const Icon(Icons.speed, color: Colors.orange),
                title: const Text('Pre-Fueling Levels',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildTextField(_preFuelLeftController,
                            'Left Tank (USG) *', Icons.opacity,
                            required: true,
                            keyboardType: TextInputType.number,
                            onChanged: () => setState(() {})),
                        _buildTextField(_preFuelRightController,
                            'Right Tank (USG) *', Icons.opacity,
                            required: true,
                            keyboardType: TextInputType.number,
                            onChanged: () => setState(() {})),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Pre-Fuel:',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              Text(
                                  '${_getTotalPreFuel().toStringAsFixed(1)} USG',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              child: ExpansionTile(
                initiallyExpanded: false,
                leading:
                    const Icon(Icons.local_gas_station, color: Colors.green),
                title: const Text('Fuel Uplift',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildTextField(_fuelUpliftController,
                            'Fuel Uplifted (USG) *', Icons.add_circle,
                            required: true,
                            keyboardType: TextInputType.number,
                            onChanged: () => setState(() {})),
                        _buildTextField(_fuelGradeController, 'Fuel Grade *',
                            Icons.local_fire_department,
                            required: true),
                        DropdownButtonFormField<String>(
                          initialValue: _fuelSupplier,
                          decoration: const InputDecoration(
                            labelText: 'Fuel Supplier',
                            prefixIcon: Icon(Icons.store),
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          items: [
                            'Self-Service',
                            'Bowser',
                            'Fuel Truck',
                            'Fixed Installation'
                          ]
                              .map((e) =>
                                  DropdownMenuItem(value: e, child: Text(e)))
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _fuelSupplier = val!),
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(_bowserNumberController,
                            'Bowser/Pump Number', Icons.confirmation_number),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              color:
                  _bowserWaterCheckPassed ? Colors.green[50] : Colors.red[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.water_drop,
                            color: _bowserWaterCheckPassed
                                ? Colors.green
                                : Colors.red),
                        const SizedBox(width: 8),
                        const Text('Bowser Water Check',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: Text(
                          _bowserWaterCheckPassed
                              ? 'Water Check PASSED ✅'
                              : 'Water Check FAILED ❌',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _bowserWaterCheckPassed
                                  ? Colors.green[900]
                                  : Colors.red[900])),
                      subtitle: Text(_bowserWaterCheckPassed
                          ? 'Fuel is clear and free of water contamination'
                          : 'Do NOT use this fuel source!'),
                      value: _bowserWaterCheckPassed,
                      onChanged: (val) =>
                          setState(() => _bowserWaterCheckPassed = val),
                      activeThumbColor: Colors.green,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              color: Colors.orange[50],
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.local_gas_station,
                            color: Colors.orange, size: 28),
                        const SizedBox(width: 12),
                        const Text('Total Fuel On Board',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Usable Fuel:',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w500)),
                        Text('${_getTotalPostFuel().toStringAsFixed(1)} USG',
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                        '≈ ${(_getTotalPostFuel() * 6).toStringAsFixed(0)} lbs (at 6 lbs/USG)',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                            fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _finishChecklist,
              icon: const Icon(Icons.check_circle, color: Colors.white),
              label: const Text('Finish',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                elevation: 3,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _viewAsPdf,
              icon: const Icon(Icons.picture_as_pdf, color: Colors.black),
              label: const Text('View as PDF',
                  style: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                side: const BorderSide(color: Color(0xFF87CEEB)),
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
        validator: required
            ? (val) => val == null || val.isEmpty ? 'Required' : null
            : null,
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
