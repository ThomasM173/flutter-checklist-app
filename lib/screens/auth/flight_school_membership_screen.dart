import 'package:flutter/material.dart';
import 'package:clearedtogo/theme/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'package:clearedtogo/models/flight_school.dart';
import 'package:clearedtogo/services/supabase_auth_service.dart';
import 'package:clearedtogo/screens/auth/login_screen.dart';

/// Lets a signed-in pilot join a flight school by invite code, see the school
/// they're currently in, and leave it. Reached from Account Details.
class FlightSchoolMembershipScreen extends StatefulWidget {
  const FlightSchoolMembershipScreen({super.key});

  @override
  State<FlightSchoolMembershipScreen> createState() =>
      _FlightSchoolMembershipScreenState();
}

class _FlightSchoolMembershipScreenState
    extends State<FlightSchoolMembershipScreen> {
  final _authService = SupabaseAuthService();
  final _codeController = TextEditingController();

  bool _loading = true;
  bool _busy = false;
  FlightSchool? _school;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    await _authService.init();
    final school = await _authService.currentFlightSchool();
    if (!mounted) return;
    setState(() {
      _school = school;
      _loading = false;
    });
  }

  String _friendlyError(Object e) {
    if (e is sb.PostgrestException) {
      switch (e.code) {
        case 'P0002':
          return 'Invalid invite code. Double-check it with your flight school and try again.';
        case '42501':
          return 'Flight school admins can\'t join another school.';
        case '28000':
          return 'Please sign in again and retry.';
      }
      if (e.message.isNotEmpty) return e.message;
    }
    return 'Something went wrong: $e';
  }

  Future<void> _join() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter an invite code first')),
      );
      return;
    }

    if (_school != null) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Switch flight school?'),
          content: Text(
            'You\'re already a member of "${_school!.name}". Joining a new '
            'school with this code will replace it.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Switch'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    setState(() => _busy = true);
    try {
      await _authService.joinFlightSchool(code);
      _codeController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Joined successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(_friendlyError(e)), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _leave() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave flight school'),
        content: Text(
          'Leave "${_school?.name}"? Your past checklist completions stay '
          'visible to them, but new ones won\'t be.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busy = true);
    try {
      await _authService.leaveFlightSchool();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You have left the flight school')),
        );
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(_friendlyError(e)), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title:
            const Text('Flight School', style: TextStyle(color: Colors.black)),
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
        elevation: 4,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : !_authService.isSignedIn
              ? _buildSignInPrompt(context)
              : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_school != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF87CEEB)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.school,
                                  color: Color(0xFF3A7CA5)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _school!.name,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const Text(
                                      'Your current flight school',
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.black54),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _busy ? null : _leave,
                              icon: const Icon(Icons.logout, color: Colors.red),
                              label: const Text('Leave school',
                                  style: TextStyle(color: Colors.red)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.red),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Join a different flight school',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black),
                    ),
                  ] else ...[
                    const Text(
                      'Join a flight school',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Ask your flight school for their invite code to link '
                      'your account. Your flight school can then see your '
                      'completed checklists.',
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextField(
                    controller: _codeController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: 'Invite code',
                      prefixIcon:
                          const Icon(Icons.confirmation_number_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      hintText: 'e.g. A1B2C3D4',
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _busy ? null : _join,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF87CEEB),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _busy
                          ? const CircularProgressIndicator(color: Colors.black)
                          : Text(
                              _school != null ? 'Switch school' : 'Join',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSignInPrompt(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.school_outlined,
                size: 72, color: AppColors.subtleText),
            const SizedBox(height: 16),
            const Text(
              'Sign in to manage your flight school',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.bodyText),
            ),
            const SizedBox(height: 8),
            const Text(
              'Joining a flight school links your completed checklists to '
              'it so your instructors can review them.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.subtleText),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
                if (mounted) _load();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.skyBlue,
                foregroundColor: AppColors.bodyText,
              ),
              child: const Text('Login / Sign Up'),
            ),
          ],
        ),
      ),
    );
  }
}
