import '../models/user_role.dart';
import '../repositories/auth_repository.dart';
import '../repositories/local_auth_repository.dart';

/// Singleton service for managing authentication
/// Uses repository pattern to allow easy swapping of auth providers
class AuthServiceManager {
  static final AuthServiceManager _instance = AuthServiceManager._internal();
  factory AuthServiceManager() => _instance;
  AuthServiceManager._internal();

  // TODO: Replace with CognitoAuthRepository when ready
  late AuthRepository _authRepository;
  bool _initialized = false;

  /// Initialize the auth service with a repository
  Future<void> init({AuthRepository? repository}) async {
    if (_initialized) return;
    
    _authRepository = repository ?? LocalAuthRepository();
    await _authRepository.init();
    _initialized = true;
  }

  /// Get the current authenticated user
  User? get currentUser => _authRepository.currentUser;

  /// Check if a user is signed in
  bool get isSignedIn => _authRepository.isSignedIn;

  /// Stream of authentication state changes
  Stream<User?> get authStateChanges => _authRepository.authStateChanges;

  /// Sign in with email and password
  Future<User> signIn(String email, String password) async {
    return await _authRepository.signIn(email, password);
  }

  /// Sign out
  Future<void> signOut() async {
    await _authRepository.signOut();
  }

  /// Update current user
  Future<void> updateUser(User user) async {
    await _authRepository.updateUser(user);
  }

  /// Check if current user is a flight school admin
  bool get isAdmin => currentUser?.isAdmin ?? false;

  /// Check if current user is a pilot
  bool get isPilot => currentUser?.isPilot ?? false;

  /// Get flight school ID of current user (if any)
  String? get flightSchoolId => currentUser?.flightSchoolId;
}
