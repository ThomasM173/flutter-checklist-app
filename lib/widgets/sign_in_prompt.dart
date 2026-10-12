import 'package:flutter/material.dart';
import '../services/supabase_auth_service.dart';
import '../screens/auth/login_screen.dart';

/// Guard for anything that writes data (the Finish action on every
/// completion flow). A guest's save would otherwise either silently no-op
/// (SupabasePdfService returns null when signed out) or, worse, let the
/// caller show a false "saved" message — this stops that before the save
/// call runs.
///
/// Returns true if the caller should proceed (already signed in). Returns
/// false if a guest was shown the prompt — the caller must not attempt the
/// save in that case, regardless of which button they tapped.
Future<bool> requireSignInToSave(BuildContext context) async {
  if (SupabaseAuthService().isSignedIn) return true;

  final shouldSignIn = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Sign in to save your work'),
      content: const Text(
        'Create a free account or sign in to save this to your checklist history.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Sign In'),
        ),
      ],
    ),
  );

  if (shouldSignIn == true && context.mounted) {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }
  return false;
}
