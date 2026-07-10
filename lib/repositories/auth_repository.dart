import '../models/user_role.dart';

/// Abstract authentication repository.
/// Implementations may use local storage or AWS Cognito as required.
abstract class AuthRepository {
  /// Initialize the repository
  Future<void> init();
  
  /// Get the currently authenticated user
  User? get currentUser;
  
  /// Sign in with email and password
  Future<User> signIn(String email, String password);
  
  /// Sign out the current user
  Future<void> signOut();
  
  /// Check if a user is currently signed in
  bool get isSignedIn;
  
  /// Update current user profile
  Future<void> updateUser(User user);
  
  /// Stream of authentication state changes
  Stream<User?> get authStateChanges;
}
