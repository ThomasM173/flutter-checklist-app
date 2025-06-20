import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/map_screen.dart';
import 'screens/flight_conditions_screen.dart';
import 'screens/learning_game_screen.dart';
import 'screens/aircraft_screens/cessna_172_screen.dart';
import 'screens/aircraft_screens/cessna_152_screen.dart';
import 'screens/aircraft_screens/piper_pa28_screen.dart';
import 'screens/checklist_screens/piper_pa28_checklist.dart';
import 'screens/checklist_screens/cessna_172_checklist.dart';
import 'screens/checklist_screens/cessna_152_checklist.dart';


final Map<String, WidgetBuilder> appRoutes = {
  '/': (context) => HomeScreen(),
  '/map': (context) => MapScreen(),
  '/flight_conditions': (context) => FlightConditionsScreen(),
  '/learning_game': (context) => LearningGameScreen(), 
  '/cessna_172': (context) => Cessna172Screen(),
  '/cessna_152': (context) => Cessna152Screen(),
  '/piper_pa28': (context) => PiperPA28Screen(),
  '/piper_pa28_checklist': (context) => PiperPA28ChecklistScreen(),
  '/cessna_172_checklist': (context) => Cessna172ChecklistScreen(),
  '/cessna_152_checklist': (context) => Cessna152ChecklistScreen(),
};
