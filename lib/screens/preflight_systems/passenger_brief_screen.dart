import 'dart:io';
import 'package:flutter/material.dart';
import 'package:clearedtogo/theme/app_colors.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clearedtogo/services/supabase_pdf_service.dart';
import 'package:clearedtogo/services/supabase_auth_service.dart';
import 'package:clearedtogo/utils/completion_pdf_builder.dart';

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
      _aircraftRegistrationController.text =
          prefs.getString('pax_registration') ?? '';
    });
  }

  Future<void> _saveEntry() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pax_pilotName', _pilotNameController.text);
    await prefs.setString(
        'pax_registration', _aircraftRegistrationController.text);
  }

  /// Structured snapshot shared by [_finishChecklist] and [_viewAsPdf].
  Map<String, dynamic> _buildCompletionData() {
    return {
      'Aircraft Registration': _aircraftRegistrationController.text,
      'Date': _dateController.text,
      'Pilot Name': _pilotNameController.text,
      if (_departureController.text.isNotEmpty)
        'Departure': _departureController.text,
      if (_destinationController.text.isNotEmpty)
        'Destination': _destinationController.text,
      'Safety Brief Checklist': {
        'Seat Belts': _seatBelts,
        'Door Operation': _doorOperation,
        'Emergency Exit': _emergencyExit,
        'Fire Extinguisher': _fireExtinguisher,
        'Life Jackets': _lifejackets,
        'Smoking Prohibited': _smokingProhibited,
        'Electronic Devices': _electronicDevices,
        'Briefing Questions Answered': _briefingQuestions,
      },
      'Passengers': _passengers.isEmpty
          ? ['None recorded']
          : [
              for (final p in _passengers)
                '${p.name} (age ${p.age}, weight ${p.weight})'
                    '${p.emergencyContact.isNotEmpty ? " - emergency contact: ${p.emergencyContact}" : ""}',
            ],
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
        checklistName: 'Passenger Brief',
        completionType: 'passenger_brief',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Passenger brief saved.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Failed to save passenger brief completion: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save passenger brief.')),
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
        title: 'Passenger Safety Brief',
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
      final fileName = "PassengerBrief_${_dateController.text}.pdf";
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
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: const Text("Passenger Safety Brief",
            style: TextStyle(color: Colors.black)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
                colors: [Color(0xFFADD8E6), Color(0xFF87CEEB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
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
                title: const Text('Flight Details',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildTextField(_aircraftRegistrationController,
                            'Aircraft *', Icons.local_airport,
                            required: true),
                        _buildTextField(
                            _pilotNameController, 'Pilot Name *', Icons.person,
                            required: true),
                        _buildTextField(
                            _dateController, 'Date *', Icons.calendar_today,
                            required: true),
                        _buildTextField(_departureController, 'Departure *',
                            Icons.flight_takeoff,
                            required: true),
                        _buildTextField(_destinationController, 'Destination *',
                            Icons.flight_land,
                            required: true),
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
                        const Text('Passenger List',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        Text('${_passengers.length} PAX',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_passengers.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8)),
                        child: const Center(
                            child: Text('No passengers added',
                                style: TextStyle(fontStyle: FontStyle.italic))),
                      )
                    else
                      ...List.generate(_passengers.length, (index) {
                        final p = _passengers[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(child: Text('${index + 1}')),
                            title: Text(p.name),
                            subtitle: Text(
                                'Age: ${p.age}, Weight: ${p.weight}kg\nEmergency: ${p.emergencyContact}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () =>
                                  setState(() => _passengers.removeAt(index)),
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
                      label: const Text('Add Passenger',
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
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
                        Icon(Icons.health_and_safety,
                            color: Colors.green, size: 28),
                        SizedBox(width: 12),
                        Text('Safety Briefing Checklist',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                        value: _seatBelts,
                        onChanged: (v) => setState(() => _seatBelts = v!),
                        title: const Text('Seat belts operation')),
                    CheckboxListTile(
                        value: _doorOperation,
                        onChanged: (v) => setState(() => _doorOperation = v!),
                        title: const Text('Door operation & emergency exit')),
                    CheckboxListTile(
                        value: _emergencyExit,
                        onChanged: (v) => setState(() => _emergencyExit = v!),
                        title: const Text('Emergency exit location')),
                    CheckboxListTile(
                        value: _fireExtinguisher,
                        onChanged: (v) =>
                            setState(() => _fireExtinguisher = v!),
                        title: const Text('Fire extinguisher location')),
                    CheckboxListTile(
                        value: _lifejackets,
                        onChanged: (v) => setState(() => _lifejackets = v!),
                        title: const Text('Lifejackets (if required)')),
                    CheckboxListTile(
                        value: _smokingProhibited,
                        onChanged: (v) =>
                            setState(() => _smokingProhibited = v!),
                        title: const Text('Smoking prohibited')),
                    CheckboxListTile(
                        value: _electronicDevices,
                        onChanged: (v) =>
                            setState(() => _electronicDevices = v!),
                        title: const Text('Electronic devices policy')),
                    CheckboxListTile(
                        value: _briefingQuestions,
                        onChanged: (v) =>
                            setState(() => _briefingQuestions = v!),
                        title: const Text('Opportunity for questions')),
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
        validator: required
            ? (val) => val == null || val.isEmpty ? 'Required' : null
            : null,
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
            TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                    labelText: 'Name', prefixIcon: Icon(Icons.person))),
            const SizedBox(height: 12),
            TextField(
                controller: _ageController,
                decoration: const InputDecoration(
                    labelText: 'Age', prefixIcon: Icon(Icons.cake)),
                keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            TextField(
                controller: _weightController,
                decoration: const InputDecoration(
                    labelText: 'Weight (kg)', prefixIcon: Icon(Icons.scale)),
                keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            TextField(
                controller: _emergencyController,
                decoration: const InputDecoration(
                    labelText: 'Emergency Contact',
                    prefixIcon: Icon(Icons.phone))),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            if (_nameController.text.isNotEmpty) {
              Navigator.pop(
                  context,
                  PassengerEntry(
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
