/// User role enumeration for role-based access control
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
}

/// Extended user model with role-based access
class User {
  final String id;
  final String email;
  final String? password; // Only for local auth, not stored for Cognito users
  final String? fullName;
  final String? licenseNumber;
  final String? homeBase;
  final bool isPremium;
  final String? cognitoUserId;
  final UserRole role;
  final String? flightSchoolId; // Required for admins, optional for pilots
  
  User({
    required this.id,
    required this.email,
    this.password,
    this.fullName,
    this.licenseNumber,
    this.homeBase,
    this.isPremium = false,
    this.cognitoUserId,
    this.role = UserRole.pilot,
    this.flightSchoolId,
  }) {
    // Validation: Flight school admins must have a flightSchoolId
    if (role == UserRole.flightSchoolAdmin && flightSchoolId == null) {
      throw ArgumentError('Flight school admin must have a flightSchoolId');
    }
  }

  bool get isAdmin => role == UserRole.flightSchoolAdmin;
  bool get isPilot => role == UserRole.pilot;

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'password': password,
    'fullName': fullName,
    'licenseNumber': licenseNumber,
    'homeBase': homeBase,
    'isPremium': isPremium,
    'cognitoUserId': cognitoUserId,
    'role': role.name,
    'flightSchoolId': flightSchoolId,
  };

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'],
    email: json['email'],
    password: json['password'],
    fullName: json['fullName'],
    licenseNumber: json['licenseNumber'],
    homeBase: json['homeBase'],
    isPremium: json['isPremium'] ?? false,
    cognitoUserId: json['cognitoUserId'],
    role: UserRole.values.firstWhere(
      (r) => r.name == json['role'],
      orElse: () => UserRole.pilot,
    ),
    flightSchoolId: json['flightSchoolId'],
  );

  User copyWith({
    String? id,
    String? email,
    String? password,
    String? fullName,
    String? licenseNumber,
    String? homeBase,
    bool? isPremium,
    String? cognitoUserId,
    UserRole? role,
    String? flightSchoolId,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      password: password ?? this.password,
      fullName: fullName ?? this.fullName,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      homeBase: homeBase ?? this.homeBase,
      isPremium: isPremium ?? this.isPremium,
      cognitoUserId: cognitoUserId ?? this.cognitoUserId,
      role: role ?? this.role,
      flightSchoolId: flightSchoolId ?? this.flightSchoolId,
    );
  }
}
