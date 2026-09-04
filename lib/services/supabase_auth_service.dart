import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../models/profile.dart';
import '../models/flight_school.dart';

/// Single source of truth for authentication + the app-level profile.
///
/// Replaces BOTH old systems:
///   * `AuthService`        (AWS Cognito + hardcoded Tom/David bypass)
///   * `AuthServiceManager` (SharedPreferences-only flight-school/demo store)
///
/// Everything now goes through Supabase Auth + the `profiles` table. Flight
/// school admins are just Supabase accounts whose `profiles.role` is
/// `flight_school_admin` (set by the seed script / service role).
///
/// Guest access is unchanged: nothing here is required to use checklists,
/// weather or the training game — screens only touch this when the user opts
/// into an account.
class SupabaseAuthService {
  SupabaseAuthService._();
  static final SupabaseAuthService instance = SupabaseAuthService._();
  factory SupabaseAuthService() => instance;

  sb.SupabaseClient get _client => sb.Supabase.instance.client;

  Profile? _profile;

  /// The signed-in app user, or null for a guest. Named `currentUser` for
  /// drop-in compatibility with the old services.
  Profile? get currentUser => _profile;
  Profile? get currentProfile => _profile;

  bool get isSignedIn => _client.auth.currentUser != null;

  final _controller = StreamController<Profile?>.broadcast();

  /// Emits whenever the profile is (re)loaded or cleared.
  Stream<Profile?> get authStateChanges => _controller.stream;

  UserRole get role => _profile?.role ?? UserRole.pilot;
  bool get isAdmin => _profile?.isAdmin ?? false;
  bool get isPilot => _profile?.isPilot ?? true;
  String? get flightSchoolId => _profile?.flightSchoolId;
  bool get isPremium => _profile?.isPremium ?? false;

  bool _initialized = false;
  StreamSubscription<sb.AuthState>? _sub;

  /// Safe to call repeatedly (many screens call it in initState).
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    _sub = _client.auth.onAuthStateChange.listen((state) async {
      switch (state.event) {
        case sb.AuthChangeEvent.signedOut:
          _profile = null;
          _controller.add(null);
          break;
        case sb.AuthChangeEvent.signedIn:
        case sb.AuthChangeEvent.tokenRefreshed:
        case sb.AuthChangeEvent.userUpdated:
          if (_client.auth.currentUser != null) await _loadProfile();
          break;
        default:
          break;
      }
    });

    if (_client.auth.currentUser != null) {
      await _loadProfile();
    }
  }

  Future<Profile?> _loadProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      _profile = null;
      _controller.add(null);
      return null;
    }
    final premium = await _fetchHasPremiumAccess();
    try {
      final row = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      _profile = row == null
          ? Profile(id: user.id, email: user.email ?? '', isPremium: premium)
          : Profile.fromMap(row, email: user.email ?? '', isPremium: premium);
    } catch (e) {
      debugPrint('SupabaseAuthService: profile load failed: $e');
      _profile = Profile(id: user.id, email: user.email ?? '', isPremium: premium);
    }
    _controller.add(_profile);
    return _profile;
  }

  /// The single entitlement check for the whole app (trial, comped flight
  /// school, or a live paid subscription) — see has_premium_access() in the
  /// Supabase migrations. Never derive premium status from subscriptionStatus
  /// locally; always go through this.
  Future<bool> _fetchHasPremiumAccess() async {
    try {
      final res = await _client.rpc('has_premium_access');
      return res == true;
    } catch (e) {
      debugPrint('SupabaseAuthService: has_premium_access failed: $e');
      return false;
    }
  }

  Future<Profile?> refreshProfile() => _loadProfile();

  // --- Email / password ------------------------------------------------------

  Future<Profile> signIn(String email, String password) async {
    final res = await _client.auth.signInWithPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );
    if (res.user == null) throw Exception('Invalid email or password');
    final profile = await _loadProfile();
    return profile ?? Profile(id: res.user!.id, email: res.user!.email ?? '');
  }

  /// [acceptedTerms] keeps the old signature's guard. Email confirmation is
  /// disabled in Supabase config, so a session is returned immediately.
  Future<Profile> signUp(
    String email,
    String password, {
    String? fullName,
    bool acceptedTerms = true,
  }) async {
    if (!acceptedTerms) {
      throw Exception('You must accept the Terms & Conditions to continue');
    }
    final res = await _client.auth.signUp(
      email: email.trim().toLowerCase(),
      password: password,
      data: {
        if (fullName != null && fullName.trim().isNotEmpty)
          'full_name': fullName.trim(),
      },
    );
    final user = res.user;
    if (user == null) {
      throw Exception(
        'Account created. Please sign in.', // confirmations on -> no session
      );
    }

    var profile = await _loadProfile();
    // Belt-and-braces: if the trigger hadn't populated full_name from
    // metadata, write it explicitly.
    if (fullName != null &&
        fullName.trim().isNotEmpty &&
        (profile?.fullName == null || profile!.fullName!.isEmpty)) {
      try {
        await _client
            .from('profiles')
            .update({'full_name': fullName.trim()}).eq('id', user.id);
        profile = await _loadProfile();
      } catch (_) {/* non-fatal */}
    }
    return profile ?? Profile(id: user.id, email: user.email ?? '');
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
    _profile = null;
    _controller.add(null);
  }

  /// Legacy alias (app_drawer called `.logout()`).
  Future<void> logout() => signOut();

  Future<String?> getCurrentUsername() async =>
      _profile?.email ?? _client.auth.currentUser?.email;

  // --- Profile edits -------------------------------------------------------

  Future<void> updateProfile({
    String? fullName,
    String? licenseNumber,
    String? homeBase,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('No user signed in');
    final patch = <String, dynamic>{};
    if (fullName != null) patch['full_name'] = fullName;
    if (licenseNumber != null) patch['license_number'] = licenseNumber;
    if (homeBase != null) patch['home_base'] = homeBase;
    if (patch.isEmpty) return;
    await _client.from('profiles').update(patch).eq('id', user.id);
    await _loadProfile();
  }

  // --- Subscription entitlement (Phase 4) --------------------------------

  /// Writes verified entitlement to the caller's own profile row. RLS
  /// restricts profile updates to `id = auth.uid()`, so this is safe
  /// client-side for now. Server-side renewal/expiry tracking is a
  /// documented follow-up (App Store Server Notifications V2).
  Future<void> setSubscription({
    required bool premium,
    String? productId,
    DateTime? expiresAt,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('No user signed in');
    await _client.from('profiles').update({
      'subscription_status': premium ? 'premium' : 'free',
      'subscription_product_id': premium ? productId : null,
      'subscription_expires_at':
          premium ? expiresAt?.toUtc().toIso8601String() : null,
    }).eq('id', user.id);
    await _loadProfile();
  }

  /// Legacy shim used by EntitlementService.
  Future<void> updatePremiumStatus(bool isPremium) =>
      setSubscription(premium: isPremium);

  // --- Account deletion (Edge Function) ---------------------------------

  /// Client SDKs cannot self-delete, so this calls the `delete-account`
  /// Edge Function, which verifies the JWT then uses the service role to
  /// remove the auth user (profiles + completions cascade) and purge the
  /// user's PDFs from storage.
  Future<void> deleteAccount() async {
    if (_client.auth.currentSession == null) {
      throw Exception('No user signed in');
    }
    final res = await _client.functions.invoke(
      'delete-account',
      method: sb.HttpMethod.post,
    );
    if (res.status != 200) {
      final detail = res.data is Map ? res.data['error'] : res.data;
      throw Exception('Account deletion failed: ${detail ?? res.status}');
    }
    await _client.auth.signOut();
    _profile = null;
    _controller.add(null);
  }

  // --- Flight school membership (invite-code flow) ---------------------

  Future<Profile?> joinFlightSchool(String inviteCode) async {
    await _client.rpc(
      'join_flight_school',
      params: {'p_invite_code': inviteCode.trim()},
    );
    return _loadProfile();
  }

  Future<Profile?> leaveFlightSchool() async {
    await _client.rpc('leave_flight_school');
    return _loadProfile();
  }

  /// Admin-only. Returns the freshly issued code.
  Future<String> rotateInviteCode() async {
    final code = await _client.rpc('rotate_flight_school_invite_code');
    return code as String;
  }

  /// The school the current user belongs to (admin's own, or a pilot's
  /// joined school). Null if unaffiliated.
  Future<FlightSchool?> currentFlightSchool() async {
    final id = flightSchoolId;
    if (id == null) return null;
    final row = await _client
        .from('flight_schools')
        .select()
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : FlightSchool.fromJson(row);
  }

  void dispose() {
    _sub?.cancel();
    _controller.close();
  }
}
