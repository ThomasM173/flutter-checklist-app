import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Typed access to the client environment, loaded from the gitignored `.env`
/// file when present (see `.env.example`), falling back to the constants
/// below otherwise — see `main()`, which now tolerates `.env` being entirely
/// absent (e.g. a fresh CI checkout) instead of crashing on load.
///
/// Only client-safe values live here. The Supabase `service_role` key and the
/// AVWX token are NEVER read by the app — they live in Edge Function secrets
/// and the Node seed script environment only.
class Env {
  Env._();

  /// Public values, safe to embed in client code: this is the Supabase
  /// project's URL and its anon/publishable key, not a secret — real access
  /// control happens via RLS policies in Postgres, not by hiding this key.
  /// Exists so CI builds (e.g. Codemagic with no UI env-var setup) still
  /// produce a working app without needing a bundled `.env` at all. Verified
  /// this is the publishable key, not service_role, by its `sb_publishable_`
  /// prefix before committing it here.
  static const String _fallbackSupabaseUrl =
      'https://lrwqszvgikgpjhacqscb.supabase.co';
  static const String _fallbackSupabaseAnonKey =
      'sb_publishable_4e4DM6PA7k1rWMKq8iZi7A_6j-Hc-Pv';

  static String get supabaseUrl =>
      _resolve('SUPABASE_URL', _fallbackSupabaseUrl);
  static String get supabaseAnonKey =>
      _resolve('SUPABASE_ANON_KEY', _fallbackSupabaseAnonKey);

  static String _resolve(String key, String fallback) {
    final value = dotenv.maybeGet(key);
    return (value == null || value.isEmpty) ? fallback : value;
  }
}
