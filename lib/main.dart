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
        primaryColor: Colors.red,
        scaffoldBackgroundColor: Colors.black,
      ),
      initialRoute: '/',
      routes: appRoutes,
    );
  }
}

