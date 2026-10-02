import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/env.dart';
import 'services/supabase_auth_service.dart';
import 'routes.dart';
import 'theme/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Global error handlers (kept from the pre-Supabase setup).
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter Error: ${details.exception}');
  };
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    debugPrint('Platform Error: $error');
    return true;
  };

  // Client env (gitignored .env, bundled as an asset). See .env.example.
  await dotenv.load(fileName: '.env');

  // Initialise Supabase (replaces Amplify.configure). Deliberately not
  // wrapped in a swallow-all try/catch: a missing/invalid URL or key is a
  // build-config error we want to see immediately, not a silent degrade.
  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
    debug: false,
  );

  await SupabaseAuthService.instance.init();

  runApp(const MyApp());
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
        brightness: Brightness.light,
        useMaterial3: true,
        primaryColor: AppColors.navy,
        scaffoldBackgroundColor: AppColors.pageBackground,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.navy,
          brightness: Brightness.light,
          primary: AppColors.navy,
          secondary: AppColors.skyBlue,
          tertiary: AppColors.orange,
          surface: AppColors.cardBackground,
        ),
        cardTheme: const CardThemeData(
          color: AppColors.cardBackground,
          surfaceTintColor: Colors.transparent,
        ),
        dialogTheme: const DialogThemeData(
          backgroundColor: AppColors.cardBackground,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.cardBackground,
          foregroundColor: AppColors.bodyText,
          iconTheme: IconThemeData(color: AppColors.bodyText),
        ),
        textTheme: ThemeData.light().textTheme.apply(
              bodyColor: AppColors.bodyText,
              displayColor: AppColors.bodyText,
            ),
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.skyBlue;
            }
            return Colors.white;
          }),
          checkColor: WidgetStateProperty.resolveWith((states) => Colors.white),
          side: const BorderSide(color: AppColors.skyBlue, width: 1.5),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            return AppColors.skyBlue.withValues(alpha: 0.15);
          }),
        ),
        radioTheme: RadioThemeData(
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.skyBlue;
            }
            return Colors.white;
          }),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            return AppColors.skyBlue.withValues(alpha: 0.15);
          }),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: AppColors.skyBlue, width: 2),
          ),
        ),
      ),
      initialRoute: '/',
      routes: appRoutes,
    );
  }
}
