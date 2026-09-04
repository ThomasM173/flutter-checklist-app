import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Typed access to the client environment loaded from the gitignored `.env`
/// file (see `.env.example`). Loaded once in `main()` before `runApp`.
///
/// Only client-safe values live here. The Supabase `service_role` key and the
/// AVWX token are NEVER read by the app — they live in Edge Function secrets
/// and the Node seed script environment only.
class Env {
  Env._();

  static String get supabaseUrl => _require('SUPABASE_URL');
  static String get supabaseAnonKey => _require('SUPABASE_ANON_KEY');

  static String _require(String key) {
    final value = dotenv.maybeGet(key);
    if (value == null || value.isEmpty) {
      throw StateError(
        'Missing "$key" in .env. Copy .env.example to .env and fill it in, '
        'or pass --dart-define-from-file.',
      );
    }
    return value;
  }
}
