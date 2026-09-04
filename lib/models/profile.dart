/// Role-based access control roles. Mirrors profiles.role in Supabase.
enum UserRole {
  pilot,
  flightSchoolAdmin;

  String get displayName {
    switch (this) {
      case UserRole.pilot:
        return 'Pilot';
      case UserRole.flightSchoolAdmin:
        return 'Flight School Admin';
    }
  }

  /// DB string <-> enum. DB stores 'pilot' | 'flight_school_admin'.
  String get dbValue =>
      this == UserRole.flightSchoolAdmin ? 'flight_school_admin' : 'pilot';

  static UserRole fromDb(String? value) => value == 'flight_school_admin'
      ? UserRole.flightSchoolAdmin
      : UserRole.pilot;
}

/// App-level user, backed by the Supabase `profiles` row joined with the
/// authenticated user's email. Replaces the old `UserAccount` (Cognito) and
/// `User` (LocalAuthRepository) models — there is now a single type.
class Profile {
  final String id; // == auth.users.id
  final String email;
  final String? fullName;
  final String? licenseNumber;
  final String? homeBase;
  final UserRole role;
  final String? flightSchoolId;
  final String subscriptionStatus; // 'free' | 'premium'
  final String? subscriptionProductId;
  final DateTime? subscriptionExpiresAt;
  final DateTime? trialStartedAt;
  final DateTime? trialEndsAt;
  final DateTime? createdAt;

  /// Real entitlement, resolved server-side by has_premium_access() (active
  /// trial, comped flight school, or a live paid subscription). NOT derived
  /// from subscriptionStatus locally — set by SupabaseAuthService whenever
  /// the profile is (re)loaded.
  final bool isPremium;

  const Profile({
    required this.id,
    required this.email,
    this.fullName,
    this.licenseNumber,
    this.homeBase,
    this.role = UserRole.pilot,
    this.flightSchoolId,
    this.subscriptionStatus = 'free',
    this.subscriptionProductId,
    this.subscriptionExpiresAt,
    this.trialStartedAt,
    this.trialEndsAt,
    this.createdAt,
    this.isPremium = false,
  });

  bool get isAdmin => role == UserRole.flightSchoolAdmin;
  bool get isPilot => role == UserRole.pilot;

  /// Builds from a `profiles` row map plus the auth email (email lives on
  /// auth.users, not profiles) and the caller's has_premium_access() result.
  factory Profile.fromMap(
    Map<String, dynamic> map, {
    required String email,
    bool isPremium = false,
  }) {
    return Profile(
      id: map['id'] as String,
      email: email,
      fullName: map['full_name'] as String?,
      licenseNumber: map['license_number'] as String?,
      homeBase: map['home_base'] as String?,
      role: UserRole.fromDb(map['role'] as String?),
      flightSchoolId: map['flight_school_id'] as String?,
      subscriptionStatus: (map['subscription_status'] as String?) ?? 'free',
      subscriptionProductId: map['subscription_product_id'] as String?,
      subscriptionExpiresAt: map['subscription_expires_at'] != null
          ? DateTime.tryParse(map['subscription_expires_at'].toString())
          : null,
      trialStartedAt: map['trial_started_at'] != null
          ? DateTime.tryParse(map['trial_started_at'].toString())
          : null,
      trialEndsAt: map['trial_ends_at'] != null
          ? DateTime.tryParse(map['trial_ends_at'].toString())
          : null,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
      isPremium: isPremium,
    );
  }

  Profile copyWith({
    String? fullName,
    String? licenseNumber,
    String? homeBase,
    UserRole? role,
    String? flightSchoolId,
    bool clearFlightSchoolId = false,
    String? subscriptionStatus,
    String? subscriptionProductId,
    DateTime? subscriptionExpiresAt,
    DateTime? trialStartedAt,
    DateTime? trialEndsAt,
    bool? isPremium,
  }) {
    return Profile(
      id: id,
      email: email,
      fullName: fullName ?? this.fullName,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      homeBase: homeBase ?? this.homeBase,
      role: role ?? this.role,
      flightSchoolId:
          clearFlightSchoolId ? null : (flightSchoolId ?? this.flightSchoolId),
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      subscriptionProductId:
          subscriptionProductId ?? this.subscriptionProductId,
      subscriptionExpiresAt:
          subscriptionExpiresAt ?? this.subscriptionExpiresAt,
      trialStartedAt: trialStartedAt ?? this.trialStartedAt,
      trialEndsAt: trialEndsAt ?? this.trialEndsAt,
      createdAt: createdAt,
      isPremium: isPremium ?? this.isPremium,
    );
  }
}
