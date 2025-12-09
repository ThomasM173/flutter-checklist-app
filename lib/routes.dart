import 'package:flutter/material.dart';
import 'screens/auth/auth_gate.dart';
import 'screens/home_screen.dart';
import 'screens/contact_us.dart';
import 'screens/flight_conditions_screen.dart';
import 'screens/learning_game_screen.dart';
import 'screens/aircraft_screens/cessna_172_screen.dart';
import 'screens/aircraft_screens/cessna_152_screen.dart';
import 'screens/aircraft_screens/piper_pa28_screen.dart';
import 'screens/checklist_screens/piper_pa28_checklist.dart';
import 'screens/checklist_screens/cessna_172_checklist.dart';
import 'screens/checklist_screens/cessna_152_checklist.dart';


final Map<String, WidgetBuilder> appRoutes = {
  '/': (context) => const AuthGate(),
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
};
