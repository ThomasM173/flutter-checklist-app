import 'package:flutter/material.dart';
import 'routes.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Plane stuff',
      debugShowCheckedModeBanner: false,  // ✅ Hides debug banner
      theme: ThemeData(
        fontFamily: 'NotoSans', // Added NotoSans font family for consistent numbering font
        brightness: Brightness.dark,
        primaryColor: Colors.red,
        scaffoldBackgroundColor: Colors.black,
      ),
      initialRoute: '/',
      routes: appRoutes,  // ✅ Uses a centralized routes file
    );
  }
}

