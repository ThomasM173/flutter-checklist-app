import 'package:flutter/material.dart';
import 'package:clearedtogo/services/supabase_auth_service.dart';
import 'package:clearedtogo/models/profile.dart';
import 'package:clearedtogo/screens/home_screen.dart';
import 'package:clearedtogo/screens/flight_school/flight_school_dashboard.dart';

/// Decides the first screen. Sign-in is OPTIONAL — checklists, weather and the
/// training game work without an account — so a guest goes straight to
/// [HomeScreen]. Only a signed-in flight school admin is routed to their
/// dedicated dashboard.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _auth = SupabaseAuthService();
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _auth.init();
    if (mounted) setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.red)),
      );
    }

    final profile = _auth.currentUser;
    if (profile != null && profile.role == UserRole.flightSchoolAdmin) {
      return const FlightSchoolDashboard();
    }
    return const HomeScreen();
  }
}
