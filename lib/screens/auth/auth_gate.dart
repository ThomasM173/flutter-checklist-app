import 'package:flutter/material.dart';
import 'package:clearedtogo/services/auth_service.dart';
import 'package:clearedtogo/services/auth_service_manager.dart';
import 'package:clearedtogo/screens/auth/login_screen.dart';
import 'package:clearedtogo/screens/home_screen.dart';
import 'package:clearedtogo/screens/flight_school/flight_school_dashboard.dart';
import 'package:clearedtogo/models/user_role.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _authService = AuthService();
  final _authServiceManager = AuthServiceManager();
  bool _isInitialized = false;
  bool _isLoggedIn = false;
  UserRole? _userRole;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // Initialize both auth services
    await _authService.init();
    await _authServiceManager.init();
    
    // Check for new repository-based auth first
    final newAuthUser = _authServiceManager.currentUser;
    if (newAuthUser != null) {
      setState(() {
        _isInitialized = true;
        _isLoggedIn = true;
        _userRole = newAuthUser.role;
      });
      return;
    }
    
    // Fall back to old Cognito auth check
    final loggedIn = await _authService.isLoggedIn();
    
    if (mounted) {
      setState(() {
        _isInitialized = true;
        _isLoggedIn = loggedIn;
        _userRole = UserRole.pilot; // Legacy users are pilots
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.red),
        ),
      );
    }

    if (!_isLoggedIn) {
      return const LoginScreen();
    }
    
    // Route based on user role
    if (_userRole == UserRole.flightSchoolAdmin) {
      return const FlightSchoolDashboard();
    } else {
      return const HomeScreen();
    }
  }
}

