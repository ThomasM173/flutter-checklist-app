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
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.red,
        scaffoldBackgroundColor: Colors.black,
      ),
      initialRoute: '/',
      routes: appRoutes,  // ✅ Uses a centralized routes file
    );
  }
}

