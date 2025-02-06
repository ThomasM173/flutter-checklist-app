import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/map_screen.dart';
import 'screens/flight_conditions_screen.dart';
import 'screens/learning_game_screen.dart';
import 'screens/aircraft_screens/cessna_172_screen.dart';
import 'screens/aircraft_screens/diamond_da40_screen.dart';
import 'screens/aircraft_screens/piper_pa28_screen.dart';
import 'screens/checklist_screens/cessna_172_checklist.dart';

final Map<String, WidgetBuilder> appRoutes = {
  '/': (context) => HomeScreen(),
  '/map': (context) => MapScreen(),
  '/flight_conditions': (context) => FlightConditionsScreen(),
  '/learning_game': (context) => LearningGameScreen(), // ✅ Added new route
  '/cessna_172': (context) => Cessna172Screen(),
  '/diamond_da40': (context) => DiamondDA40Screen(),
  '/piper_pa28': (context) => PiperPA28Screen(),
  '/cessna_172_checklist': (context) => Cessna172ChecklistScreen(),
};
