import 'package:flutter/material.dart';
import 'screens/auth/auth_gate.dart';
import 'screens/home_screen.dart';
import 'screens/contact_us.dart';
import 'screens/flight_conditions_screen.dart';
import 'screens/learning_game_screen.dart';
import 'screens/aircraft_screens/cessna_172_screen.dart';
import 'screens/aircraft_screens/cessna_152_screen.dart';
import 'screens/aircraft_screens/piper_pa28_screen.dart';
import 'screens/aircraft_screens/cessna_152_emergency_screen.dart';
import 'screens/aircraft_screens/cessna_152_emergency_game.dart';
import 'screens/aircraft_screens/cessna_172_emergency_screen.dart';
import 'screens/aircraft_screens/cessna_172_emergency_game.dart';
import 'screens/aircraft_screens/piper_pa28_emergency_screen.dart';
import 'screens/aircraft_screens/piper_pa28_emergency_game.dart';
import 'screens/checklist_screens/piper_pa28_checklist.dart';
import 'screens/checklist_screens/cessna_172_checklist.dart';
import 'screens/checklist_screens/cessna_152_checklist.dart';
import 'screens/flight_school/flight_school_dashboard.dart';
import 'screens/flight_school/pdf_library_screen.dart';
import 'screens/flight_school/checklist_editor_screen.dart';
import 'screens/auth/login_screen.dart';


final Map<String, WidgetBuilder> appRoutes = {
  '/': (context) => const AuthGate(),
  '/login': (context) => const LoginScreen(),
  '/home': (context) => const HomeScreen(),
  '/map': (context) => const ContactUs(),
  '/flight_conditions': (context) => const FlightConditionsScreen(),
  '/learning_game': (context) => const LearningGameScreen(), 
  '/cessna_172': (context) => const Cessna172Screen(),
  '/cessna_152': (context) => const Cessna152Screen(),
  '/piper_pa28': (context) => const PiperPA28Screen(),
  '/piper_pa28_checklist': (context) => const PiperPA28ChecklistScreen(),
  '/cessna_172_checklist': (context) => const Cessna172ChecklistScreen(),
  '/cessna_152_checklist': (context) => const Cessna152ChecklistScreen(),
  '/cessna_152_emergency_screen': (context) => const Cessna152EmergencyScreen(),
  '/cessna_152_emergency_game': (context) => const Cessna152EmergencyGame(),
  '/cessna_172_emergency_screen': (context) => const Cessna172EmergencyScreen(),
  '/cessna_172_emergency_game': (context) => const Cessna172EmergencyGame(),
  '/piper_pa28_emergency_screen': (context) => const PiperPA28EmergencyScreen(),
  '/piper_pa28_emergency_game': (context) => const PiperPA28EmergencyGame(),
  // Flight School Admin routes
  '/flight-school/dashboard': (context) => const FlightSchoolDashboard(),
  '/flight-school/pdfs': (context) => const PdfLibraryScreen(),
  '/flight-school/checklists': (context) => const ChecklistEditorScreen(),
};

