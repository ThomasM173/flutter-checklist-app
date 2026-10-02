import 'package:flutter/material.dart';
import 'package:clearedtogo/theme/app_colors.dart';
import 'package:clearedtogo/config/config.dart';
import 'package:clearedtogo/services/supabase_auth_service.dart';
import 'package:clearedtogo/models/profile.dart';
import 'package:clearedtogo/screens/home_screen.dart';
import 'package:clearedtogo/screens/flight_school/flight_school_dashboard.dart';
import 'package:clearedtogo/screens/business/business_admin_dashboard.dart';
import 'package:clearedtogo/screens/auth/login_screen.dart';

/// Decides the first screen.
///
/// When kRequireLoginForAllFeatures is true (current default — see
/// config.dart for why), a guest is routed to [LoginScreen] instead of
/// [HomeScreen]. When false, sign-in is optional and a guest goes straight
/// to [HomeScreen] (checklists, weather and the training game all work
/// without an account in that mode). A signed-in flight school admin or
/// business admin is always routed to their dedicated dashboard either way.
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
        backgroundColor: AppColors.pageBackground,
        body: Center(child: CircularProgressIndicator(color: Colors.red)),
      );
    }

    final profile = _auth.currentUser;
    if (profile != null && profile.role == UserRole.flightSchoolAdmin) {
      return const FlightSchoolDashboard();
    }
    if (profile != null && profile.role == UserRole.businessAdmin) {
      return const BusinessAdminDashboard();
    }
    if (profile == null && kRequireLoginForAllFeatures) {
      return const LoginScreen();
    }
    return const HomeScreen();
  }
}
