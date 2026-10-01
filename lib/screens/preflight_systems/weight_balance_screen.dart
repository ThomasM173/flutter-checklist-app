import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clearedtogo/services/supabase_auth_service.dart';
import 'package:clearedtogo/services/supabase_pdf_service.dart';
import 'package:clearedtogo/utils/completion_pdf_builder.dart';

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
      _aircraftRegistrationController.text =
          prefs.getString('wb_registration') ?? '';
    });
  }

  Future<void> _saveEntry() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('wb_pilotName', _pilotNameController.text);
    await prefs.setString(
        'wb_registration', _aircraftRegistrationController.text);
  }

  double _calculateMoment(String weightStr, String armStr) {
    final weight = double.tryParse(weightStr) ?? 0.0;
    final arm = double.tryParse(armStr) ?? 0.0;
    return weight * arm / 1000; // Moment in thousands
  }

  Map<String, double> _calculateTotals() {
    final basicWeight =
        double.tryParse(_basicEmptyWeightController.text) ?? 0.0;
    final basicMoment =
        double.tryParse(_basicEmptyMomentController.text) ?? 0.0;

    final frontWeight = double.tryParse(_frontSeatWeightController.text) ?? 0.0;
    final frontMoment = _calculateMoment(
        _frontSeatWeightController.text, _frontSeatArmController.text);

    final rearWeight = double.tryParse(_rearSeatWeightController.text) ?? 0.0;
    final rearMoment = _calculateMoment(
        _rearSeatWeightController.text, _rearSeatArmController.text);

    final baggage1Weight =
        double.tryParse(_baggage1WeightController.text) ?? 0.0;
    final baggage1Moment = _calculateMoment(
        _baggage1WeightController.text, _baggage1ArmController.text);

    final baggage2Weight =
        double.tryParse(_baggage2WeightController.text) ?? 0.0;
    final baggage2Moment = _calculateMoment(
        _baggage2WeightController.text, _baggage2ArmController.text);

    final fuelWeight = double.tryParse(_fuelWeightController.text) ?? 0.0;
    final fuelMoment =
        _calculateMoment(_fuelWeightController.text, _fuelArmController.text);

    final totalWeight = basicWeight +
        frontWeight +
        rearWeight +
        baggage1Weight +
        baggage2Weight +
        fuelWeight;
    final totalMoment = basicMoment +
        frontMoment +
        rearMoment +
        baggage1Moment +
        baggage2Moment +
        fuelMoment;
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

  /// Structured snapshot shared by [_finishChecklist] and [_viewAsPdf].
  Map<String, dynamic> _buildCompletionData() {
    final totals = _calculateTotals();
    return {
      'Aircraft': _selectedAircraft,
      'Aircraft Registration': _aircraftRegistrationController.text,
      'Date': _dateController.text,
      'Pilot Name': _pilotNameController.text,
      if (_departureController.text.isNotEmpty)
        'Departure': _departureController.text,
      if (_destinationController.text.isNotEmpty)
        'Destination': _destinationController.text,
      'Weight & Moment': {
        'Basic Empty Weight (lbs)': _basicEmptyWeightController.text,
        'Basic Empty Moment (/1000)': _basicEmptyMomentController.text,
        'Front Seat Weight (lbs)': _frontSeatWeightController.text,
        'Front Seat Arm (in)': _frontSeatArmController.text,
        'Rear Seat Weight (lbs)': _rearSeatWeightController.text,
        'Rear Seat Arm (in)': _rearSeatArmController.text,
        'Baggage 1 Weight (lbs)': _baggage1WeightController.text,
        'Baggage 1 Arm (in)': _baggage1ArmController.text,
        'Baggage 2 Weight (lbs)': _baggage2WeightController.text,
        'Baggage 2 Arm (in)': _baggage2ArmController.text,
        'Fuel Weight (lbs)': _fuelWeightController.text,
        'Fuel Arm (in)': _fuelArmController.text,
      },
      'Total Weight (lbs)': totals['totalWeight']!.toStringAsFixed(1),
      'Total Moment (/1000)': totals['totalMoment']!.toStringAsFixed(2),
      'Centre of Gravity (in)': totals['cg']!.toStringAsFixed(2),
      'CG Status': _checkCGLimits(),
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
        aircraftType: _selectedAircraft,
        checklistName: 'Weight & Balance Loadsheet',
        completionType: 'weight_balance',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Weight & balance loadsheet saved.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Failed to save weight & balance completion: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save loadsheet.')),
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
        title: 'Weight & Balance Loadsheet',
        aircraftType: _selectedAircraft,
        completedAt: DateTime.now(),
        pilotName: user?.fullName,
        licenseNumber: user?.licenseNumber,
        homeBase: user?.homeBase,
        data: _buildCompletionData(),
      );

      final output = await getTemporaryDirectory();
      final fileName =
          "W&B_${_selectedAircraft.replaceAll(' ', '_')}_${_dateController.text}.pdf";
      final file = File("${output.path}/$fileName");
      await file.writeAsBytes(pdfBytes);
      OpenFile.open(file.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Error generating PDF: $e"),
              backgroundColor: Colors.red),
        );
      }
    }
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.airplanemode_active,
                            color: Color(0xFF87CEEB)),
                        SizedBox(width: 8),
                        Text(
                          'Aircraft Type',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedAircraft,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: _aircraftTemplates.keys
                          .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)))
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              child: ExpansionTile(
                initiallyExpanded: false,
                leading: const Icon(Icons.flight, color: Colors.purple),
                title: const Text('Flight Details',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildTextField(
                            _pilotNameController, 'Pilot Name *', Icons.person,
                            required: true),
                        _buildTextField(
                            _dateController, 'Date *', Icons.calendar_today,
                            required: true),
                        _buildTextField(_aircraftRegistrationController,
                            'Registration *', Icons.tag,
                            required: true),
                        _buildTextField(_departureController, 'Departure',
                            Icons.flight_takeoff),
                        _buildTextField(_destinationController, 'Destination',
                            Icons.flight_land),
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              child: ExpansionTile(
                initiallyExpanded: false,
                leading: const Icon(Icons.construction, color: Colors.orange),
                title: const Text('Basic Empty Weight',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildTextField(_basicEmptyWeightController,
                            'Weight (lbs) *', Icons.scale,
                            required: true, keyboardType: TextInputType.number),
                        _buildTextField(_basicEmptyMomentController,
                            'Moment (/1000) *', Icons.architecture,
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              child: ExpansionTile(
                initiallyExpanded: false,
                leading: const Icon(Icons.event_seat, color: Colors.blue),
                title: const Text('Front Seat',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildTextField(_frontSeatWeightController,
                            'Weight (lbs)', Icons.person,
                            keyboardType: TextInputType.number),
                        _buildTextField(_frontSeatArmController, 'Arm (in)',
                            Icons.straighten,
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
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                child: ExpansionTile(
                  initiallyExpanded: false,
                  leading: const Icon(Icons.event_seat, color: Colors.blue),
                  title: const Text('Rear Seat',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildTextField(_rearSeatWeightController,
                              'Weight (lbs)', Icons.person,
                              keyboardType: TextInputType.number),
                          _buildTextField(_rearSeatArmController, 'Arm (in)',
                              Icons.straighten,
                              keyboardType: TextInputType.number,
                              enabled: false),
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              child: ExpansionTile(
                initiallyExpanded: false,
                leading: const Icon(Icons.luggage, color: Colors.brown),
                title: const Text('Baggage',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildTextField(_baggage1WeightController,
                            'Baggage 1 Weight (lbs)', Icons.work,
                            keyboardType: TextInputType.number),
                        _buildTextField(_baggage1ArmController, 'Arm (in)',
                            Icons.straighten,
                            keyboardType: TextInputType.number, enabled: false),
                        if (template['baggage2Arm'] > 0) ...[
                          const SizedBox(height: 12),
                          _buildTextField(_baggage2WeightController,
                              'Baggage 2 Weight (lbs)', Icons.work,
                              keyboardType: TextInputType.number),
                          _buildTextField(_baggage2ArmController, 'Arm (in)',
                              Icons.straighten,
                              keyboardType: TextInputType.number,
                              enabled: false),
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              child: ExpansionTile(
                initiallyExpanded: false,
                leading: const Icon(Icons.local_gas_station, color: Colors.red),
                title: const Text('Fuel',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildTextField(_fuelWeightController, 'Weight (lbs) *',
                            Icons.opacity,
                            required: true, keyboardType: TextInputType.number),
                        _buildTextField(
                            _fuelArmController, 'Arm (in)', Icons.straighten,
                            keyboardType: TextInputType.number, enabled: false),
                        const SizedBox(height: 8),
                        Text(
                          'Note: 1 US Gallon AvGas ≈ 6 lbs',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic),
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              color: cgStatus.contains('✅') ? Colors.green[50] : Colors.red[50],
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calculate,
                          color: cgStatus.contains('✅')
                              ? Colors.green[700]
                              : Colors.red[700],
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Weight & Balance Results',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _buildResultRow('Total Weight:',
                        '${totals['totalWeight']!.toStringAsFixed(1)} lbs'),
                    _buildResultRow(
                        'Max Weight:', '${template['maxWeight']} lbs'),
                    const SizedBox(height: 8),
                    _buildResultRow('Total Moment:',
                        totals['totalMoment']!.toStringAsFixed(2)),
                    _buildResultRow('Center of Gravity:',
                        '${totals['cg']!.toStringAsFixed(2)}"'),
                    const Divider(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            cgStatus.contains('✅') ? Colors.green : Colors.red,
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

            // Finish Button
            ElevatedButton.icon(
              onPressed: _finishChecklist,
              icon: const Icon(Icons.check_circle, color: Colors.white),
              label: const Text(
                'Finish',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
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
              label: const Text(
                'View as PDF',
                style:
                    TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
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
