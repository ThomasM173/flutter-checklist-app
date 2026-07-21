import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'amplifyconfiguration.dart';
import 'routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set up global error handlers
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    safePrint('Flutter Error: ${details.exception}');
    safePrint('Stack: ${details.stack}');
  };
  
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    safePrint('Platform Error: $error');
    safePrint('Stack: $stack');
    return true;
  };
  
  // Configure Amplify but don't let it crash or hang the app
  try {
    await _configureAmplify()
        .timeout(const Duration(seconds: 5));
  } catch (e) {
    safePrint('Failed to configure Amplify, continuing anyway: $e');
  }
  
  runApp(const MyApp());
}

Future<void> _configureAmplify() async {
  try {
    // Check if Amplify is already configured
    if (Amplify.isConfigured) {
      safePrint('Amplify already configured');
      return;
    }
    
    final auth = AmplifyAuthCognito();
    await Amplify.addPlugin(auth);
    await Amplify.configure(amplifyconfig);
    safePrint('Amplify configured successfully');
  } on Exception catch (e) {
    safePrint('Error configuring Amplify: $e');
    // Don't rethrow - let the app continue without Amplify if needed
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ClearedToGo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'NotoSans',
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF87CEEB),
        scaffoldBackgroundColor: Colors.black,
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const Color(0xFF87CEEB);
            }
            return Colors.white;
          }),
          checkColor: WidgetStateProperty.resolveWith((states) => Colors.white),
          side: const BorderSide(color: Color(0xFF87CEEB), width: 1.5),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            return const Color(0xFF87CEEB).withValues(alpha: 0.15);
          }),
        ),
        radioTheme: RadioThemeData(
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const Color(0xFF87CEEB);
            }
            return Colors.white;
          }),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            return const Color(0xFF87CEEB).withValues(alpha: 0.15);
          }),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Color(0xFF87CEEB), width: 2),
          ),
        ),
      ),
      initialRoute: '/',
      routes: appRoutes,
    );
  }
}

