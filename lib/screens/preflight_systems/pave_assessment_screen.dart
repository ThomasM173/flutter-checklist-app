import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:clearedtogo/services/supabase_pdf_service.dart';
import 'package:clearedtogo/utils/completion_pdf_builder.dart';
import 'dart:convert';

class PaveAssessmentScreen extends StatefulWidget {
  const PaveAssessmentScreen({super.key});

  @override
  State<PaveAssessmentScreen> createState() => _PaveAssessmentScreenState();
}

class _PaveAssessmentScreenState extends State<PaveAssessmentScreen> {
  final _formKey = GlobalKey<FormState>();

  // PAVE Fields
  final _pilotNameController = TextEditingController();
  final _dateController = TextEditingController();
  final _flightNumberController = TextEditingController();

  // Pilot Assessment
  String _imsafeIllness = '';
  String _imsafeMedication = '';
  String _imsafeStress = '';
  String _imsafeAlcohol = '';
  String _imsafeFatigue = '';
  String _imsafeEating = '';
  final _pilotNotesController = TextEditingController();

  // Aircraft Assessment
  final _aircraftRegistrationController = TextEditingController();
  String _aircraftServiceability = 'Serviceable';
  final _aircraftDefectsController = TextEditingController();
  final _aircraftNotesController = TextEditingController();

  // enVironment Assessment
  final _departureAirportController = TextEditingController();
  final _destinationAirportController = TextEditingController();
  final _weatherConditionsController = TextEditingController();
  String _vfrIfrConditions = 'VFR';
  final _environmentNotesController = TextEditingController();

  // External Pressures
  String _timeConstraints = 'No';
  String _passengerPressure = 'No';
  final _externalPressuresController = TextEditingController();

  // 5P Assessment
  String _fivePPlan = 'Satisfactory';
  String _fivePPlane = 'Satisfactory';
  String _fivePPilot = 'Satisfactory';
  String _fivePPassengers = 'Satisfactory';
  String _fivePProgramming = 'Satisfactory';

  String _overallRiskLevel = 'Low';

  @override
  void initState() {
    super.initState();
    _loadLastEntry();
    _dateController.text = DateTime.now().toString().split(' ')[0];
  }

  Future<void> _loadLastEntry() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pilotNameController.text = prefs.getString('pave_pilotName') ?? '';
      _aircraftRegistrationController.text =
          prefs.getString('pave_aircraftReg') ?? '';
    });
  }

  Future<void> _saveEntry() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    final entryData = {
      'timestamp': timestamp,
      'pilotName': _pilotNameController.text,
      'date': _dateController.text,
      'flightNumber': _flightNumberController.text,
      'imsafeIllness': _imsafeIllness,
      'imsafeMedication': _imsafeMedication,
      'imsafeStress': _imsafeStress,
      'imsafeAlcohol': _imsafeAlcohol,
      'imsafeFatigue': _imsafeFatigue,
      'imsafeEating': _imsafeEating,
      'pilotNotes': _pilotNotesController.text,
      'aircraftRegistration': _aircraftRegistrationController.text,
      'aircraftServiceability': _aircraftServiceability,
      'aircraftDefects': _aircraftDefectsController.text,
      'aircraftNotes': _aircraftNotesController.text,
      'departureAirport': _departureAirportController.text,
      'destinationAirport': _destinationAirportController.text,
      'weatherConditions': _weatherConditionsController.text,
      'vfrIfrConditions': _vfrIfrConditions,
      'environmentNotes': _environmentNotesController.text,
      'timeConstraints': _timeConstraints,
      'passengerPressure': _passengerPressure,
      'externalPressures': _externalPressuresController.text,
      'fivePPlan': _fivePPlan,
      'fivePPlane': _fivePPlane,
      'fivePPilot': _fivePPilot,
      'fivePPassengers': _fivePPassengers,
      'fivePProgramming': _fivePProgramming,
      'overallRiskLevel': _overallRiskLevel,
    };

    // Save to history (last 7 days)
    final historyKey = 'pave_history';
    final historyJson = prefs.getString(historyKey) ?? '[]';
    final List<dynamic> history = jsonDecode(historyJson);

    // Remove entries older than 7 days
    final sevenDaysAgo =
        DateTime.now().subtract(const Duration(days: 7)).millisecondsSinceEpoch;
    history.removeWhere((entry) => entry['timestamp'] < sevenDaysAgo);

    history.add(entryData);
    await prefs.setString(historyKey, jsonEncode(history));

    // Save current values for next time
    await prefs.setString('pave_pilotName', _pilotNameController.text);
    await prefs.setString(
        'pave_aircraftReg', _aircraftRegistrationController.text);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Assessment saved successfully')),
      );
    }
  }

  /// Structured snapshot shared by [_finishChecklist] and [_viewAsPdf].
  Map<String, dynamic> _buildCompletionData() {
    return {
      'Pilot Name': _pilotNameController.text,
      'Date': _dateController.text,
      if (_flightNumberController.text.isNotEmpty)
        'Flight Number': _flightNumberController.text,
      'Pilot (IMSAFE)': {
        'Illness': _imsafeIllness,
        'Medication': _imsafeMedication,
        'Stress': _imsafeStress,
        'Alcohol': _imsafeAlcohol,
        'Fatigue': _imsafeFatigue,
        'Eating': _imsafeEating,
      },
      if (_pilotNotesController.text.isNotEmpty)
        'Pilot Notes': _pilotNotesController.text,
      'Aircraft': {
        'Registration': _aircraftRegistrationController.text,
        'Serviceability': _aircraftServiceability,
        if (_aircraftDefectsController.text.isNotEmpty)
          'Defects': _aircraftDefectsController.text,
      },
      if (_aircraftNotesController.text.isNotEmpty)
        'Aircraft Notes': _aircraftNotesController.text,
      'enVironment': {
        'Departure Airport': _departureAirportController.text,
        'Destination Airport': _destinationAirportController.text,
        'Weather Conditions': _weatherConditionsController.text,
        'VFR/IFR': _vfrIfrConditions,
      },
      if (_environmentNotesController.text.isNotEmpty)
        'Environment Notes': _environmentNotesController.text,
      'External Pressures': {
        'Time Constraints': _timeConstraints,
        'Passenger Pressure': _passengerPressure,
      },
      if (_externalPressuresController.text.isNotEmpty)
        'External Pressures Notes': _externalPressuresController.text,
      '5P Assessment': {
        'Plan': _fivePPlan,
        'Plane': _fivePPlane,
        'Pilot': _fivePPilot,
        'Passengers': _fivePPassengers,
        'Programming': _fivePProgramming,
      },
      'Overall Risk Level': _overallRiskLevel,
    };
  }

  /// Writes straight to checklist_completions - no PDF generated or
  /// uploaded. A PDF (see [_viewAsPdf]) is always available on demand
  /// afterwards, built fresh from this same stored data. Also keeps the
  /// existing local 7-day history in SharedPreferences via _saveEntry()
  /// (unrelated to the Supabase record - a separate, pre-existing
  /// mechanism, left as-is).
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
        checklistName: 'PAVE Assessment',
        completionType: 'pave_assessment',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PAVE assessment saved.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Failed to save PAVE assessment completion: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save assessment.')),
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

      final pdfBytes = await CompletionPdfBuilder.build(
        font: pdfFont,
        title: 'PAVE & IMSAFE Risk Assessment',
        aircraftType: _aircraftRegistrationController.text.isNotEmpty
            ? _aircraftRegistrationController.text
            : 'UNKNOWN',
        completedAt: DateTime.now(),
        pilotName: _pilotNameController.text,
        data: _buildCompletionData(),
      );

      final output = await getTemporaryDirectory();
      final fileName = "PAVE_Assessment_${_dateController.text}.pdf";
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
          "PAVE & IMSAFE Risk Assessment",
          style: TextStyle(color: Colors.black, fontSize: 18),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _showHistory(),
            tooltip: 'View History',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSection(
              "Flight Information",
              Icons.flight,
              Colors.purple,
              [
                _buildTextField(
                  controller: _pilotNameController,
                  label: "Pilot Name *",
                  icon: Icons.person,
                  required: true,
                ),
                _buildTextField(
                  controller: _dateController,
                  label: "Date *",
                  icon: Icons.calendar_today,
                  required: true,
                ),
                _buildTextField(
                  controller: _flightNumberController,
                  label: "Flight Number",
                  icon: Icons.confirmation_number,
                ),
              ],
            ),
            _buildSection(
              "I.M.S.A.F.E. Check (Pilot)",
              Icons.health_and_safety,
              Colors.purple,
              [
                _buildRadioGroup("Illness", _imsafeIllness,
                    (val) => setState(() => _imsafeIllness = val!)),
                _buildRadioGroup("Medication", _imsafeMedication,
                    (val) => setState(() => _imsafeMedication = val!)),
                _buildRadioGroup("Stress", _imsafeStress,
                    (val) => setState(() => _imsafeStress = val!)),
                _buildRadioGroup("Alcohol (8hr rule)", _imsafeAlcohol,
                    (val) => setState(() => _imsafeAlcohol = val!)),
                _buildRadioGroup("Fatigue", _imsafeFatigue,
                    (val) => setState(() => _imsafeFatigue = val!)),
                _buildRadioGroup("Eating/Hydration", _imsafeEating,
                    (val) => setState(() => _imsafeEating = val!)),
                _buildTextField(
                  controller: _pilotNotesController,
                  label: "Additional Notes",
                  icon: Icons.notes,
                  maxLines: 2,
                ),
              ],
            ),
            _buildSection(
              "Aircraft (PAVE: A)",
              Icons.airplanemode_active,
              Colors.orange,
              [
                _buildTextField(
                  controller: _aircraftRegistrationController,
                  label: "Aircraft Registration *",
                  icon: Icons.tag,
                  required: true,
                ),
                _buildDropdown(
                  label: "Serviceability",
                  value: _aircraftServiceability,
                  items: ['Serviceable', 'Unserviceable'],
                  onChanged: (val) =>
                      setState(() => _aircraftServiceability = val!),
                ),
                _buildTextField(
                  controller: _aircraftDefectsController,
                  label: "Known Defects",
                  icon: Icons.warning,
                  maxLines: 2,
                ),
                _buildTextField(
                  controller: _aircraftNotesController,
                  label: "Additional Notes",
                  icon: Icons.notes,
                  maxLines: 2,
                ),
              ],
            ),
            _buildSection(
              "enVironment (PAVE: V)",
              Icons.cloud,
              Colors.blue,
              [
                _buildTextField(
                  controller: _departureAirportController,
                  label: "Departure Airport *",
                  icon: Icons.flight_takeoff,
                  required: true,
                ),
                _buildTextField(
                  controller: _destinationAirportController,
                  label: "Destination Airport *",
                  icon: Icons.flight_land,
                  required: true,
                ),
                _buildTextField(
                  controller: _weatherConditionsController,
                  label: "Weather Conditions *",
                  icon: Icons.wb_sunny,
                  required: true,
                  maxLines: 2,
                ),
                _buildDropdown(
                  label: "Flight Rules",
                  value: _vfrIfrConditions,
                  items: ['VFR', 'IFR', 'SVFR'],
                  onChanged: (val) => setState(() => _vfrIfrConditions = val!),
                ),
                _buildTextField(
                  controller: _environmentNotesController,
                  label: "Additional Notes",
                  icon: Icons.notes,
                  maxLines: 2,
                ),
              ],
            ),
            _buildSection(
              "External Pressures (PAVE: E)",
              Icons.timer,
              Colors.red,
              [
                _buildDropdown(
                  label: "Time Constraints",
                  value: _timeConstraints,
                  items: ['No', 'Minor', 'Significant'],
                  onChanged: (val) => setState(() => _timeConstraints = val!),
                ),
                _buildDropdown(
                  label: "Passenger Pressure",
                  value: _passengerPressure,
                  items: ['No', 'Minor', 'Significant'],
                  onChanged: (val) => setState(() => _passengerPressure = val!),
                ),
                _buildTextField(
                  controller: _externalPressuresController,
                  label: "Additional Pressures",
                  icon: Icons.notes,
                  maxLines: 2,
                ),
              ],
            ),
            _buildSection(
              "5P Assessment",
              Icons.checklist,
              Colors.green,
              [
                _buildDropdown(
                  label: "Plan (Flight planning)",
                  value: _fivePPlan,
                  items: ['Satisfactory', 'Marginal', 'Unsatisfactory'],
                  onChanged: (val) => setState(() => _fivePPlan = val!),
                ),
                _buildDropdown(
                  label: "Plane (Aircraft condition)",
                  value: _fivePPlane,
                  items: ['Satisfactory', 'Marginal', 'Unsatisfactory'],
                  onChanged: (val) => setState(() => _fivePPlane = val!),
                ),
                _buildDropdown(
                  label: "Pilot (Capability)",
                  value: _fivePPilot,
                  items: ['Satisfactory', 'Marginal', 'Unsatisfactory'],
                  onChanged: (val) => setState(() => _fivePPilot = val!),
                ),
                _buildDropdown(
                  label: "Passengers (Needs)",
                  value: _fivePPassengers,
                  items: ['Satisfactory', 'Marginal', 'Unsatisfactory'],
                  onChanged: (val) => setState(() => _fivePPassengers = val!),
                ),
                _buildDropdown(
                  label: "Programming (Automation)",
                  value: _fivePProgramming,
                  items: ['Satisfactory', 'Marginal', 'Unsatisfactory'],
                  onChanged: (val) => setState(() => _fivePProgramming = val!),
                ),
              ],
            ),
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              color: _overallRiskLevel == 'Low'
                  ? Colors.green[50]
                  : _overallRiskLevel == 'Medium'
                      ? Colors.orange[50]
                      : Colors.red[50],
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.assessment,
                          color: _overallRiskLevel == 'Low'
                              ? Colors.green[700]
                              : _overallRiskLevel == 'Medium'
                                  ? Colors.orange[700]
                                  : Colors.red[700],
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "Overall Risk Level",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _overallRiskLevel,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      items: ['Low', 'Medium', 'High']
                          .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _overallRiskLevel = val!),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _finishChecklist,
              icon: const Icon(Icons.check_circle, color: Colors.white),
              label: const Text(
                "Finish",
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 3,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _viewAsPdf,
              icon: const Icon(Icons.picture_as_pdf, color: Colors.black),
              label: const Text(
                "View as PDF",
                style:
                    TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                side: const BorderSide(color: Color(0xFF87CEEB)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
      String title, IconData icon, Color color, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: ExpansionTile(
        initiallyExpanded: false,
        leading: Icon(icon, color: color, size: 28),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool required = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
        ),
        validator: required
            ? (val) => val == null || val.isEmpty ? 'Required field' : null
            : null,
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
        ),
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildRadioGroup(
      String label, String value, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                  fontSize: 14,
                ),
              ),
            ),
            const Divider(height: 1),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text("OK",
                        style: TextStyle(fontSize: 12, color: Colors.black87)),
                    value: "OK",
                    groupValue: value,
                    onChanged: onChanged,
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    activeColor: const Color(0xFF87CEEB),
                    fillColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return const Color(0xFF87CEEB);
                      }
                      return Colors.white;
                    }),
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text("Concern",
                        style: TextStyle(fontSize: 12, color: Colors.black87)),
                    value: "Concern",
                    groupValue: value,
                    onChanged: onChanged,
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    activeColor: const Color(0xFF87CEEB),
                    fillColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return const Color(0xFF87CEEB);
                      }
                      return Colors.white;
                    }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString('pave_history') ?? '[]';
    final List<dynamic> history = jsonDecode(historyJson);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Recent Assessments (7 days)"),
        content: SizedBox(
          width: double.maxFinite,
          child: history.isEmpty
              ? const Text("No recent assessments")
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final entry = history[history.length - 1 - index];
                    final date =
                        DateTime.fromMillisecondsSinceEpoch(entry['timestamp']);
                    return ListTile(
                      title: Text(
                          "${entry['pilotName']} - ${entry['flightNumber']}"),
                      subtitle: Text(date.toString().split('.')[0]),
                      trailing: Text(entry['overallRiskLevel']),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pilotNameController.dispose();
    _dateController.dispose();
    _flightNumberController.dispose();
    _pilotNotesController.dispose();
    _aircraftRegistrationController.dispose();
    _aircraftDefectsController.dispose();
    _aircraftNotesController.dispose();
    _departureAirportController.dispose();
    _destinationAirportController.dispose();
    _weatherConditionsController.dispose();
    _environmentNotesController.dispose();
    _externalPressuresController.dispose();
    super.dispose();
  }
}
