import 'package:shared_preferences/shared_preferences.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'dart:convert';

class UserAccount {
  final String email;
  final String password; // Only used for local admin account
  final String? fullName;
  final String? licenseNumber;
  final String? homeBase;
  final bool isPremium;
  final String? cognitoUserId;

  UserAccount({
    required this.email,
    this.password = '',
    this.fullName,
    this.licenseNumber,
    this.homeBase,
    this.isPremium = false,
    this.cognitoUserId,
  });

  Map<String, dynamic> toJson() => {
    'email': email,
    'password': password,
    'fullName': fullName,
    'licenseNumber': licenseNumber,
    'homeBase': homeBase,
    'isPremium': isPremium,
    'cognitoUserId': cognitoUserId,
  };

  factory UserAccount.fromJson(Map<String, dynamic> json) => UserAccount(
    email: json['email'],
    password: json['password'] ?? '',
    fullName: json['fullName'],
    licenseNumber: json['licenseNumber'],
    homeBase: json['homeBase'],
    isPremium: json['isPremium'] ?? false,
    cognitoUserId: json['cognitoUserId'],
  );

  UserAccount copyWith({
    String? email,
    String? password,
    String? fullName,
    String? licenseNumber,
    String? homeBase,
    bool? isPremium,
    String? cognitoUserId,
  }) {
    return UserAccount(
      email: email ?? this.email,
      password: password ?? this.password,
      fullName: fullName ?? this.fullName,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      homeBase: homeBase ?? this.homeBase,
      isPremium: isPremium ?? this.isPremium,
      cognitoUserId: cognitoUserId ?? this.cognitoUserId,
    );
  }
}

class AuthService {
  static const String _currentUserKey = 'currentUser';
  static const String _isAdminKey = 'isAdmin';
  
  UserAccount? _currentUser;

  UserAccount? get currentUser => _currentUser;

  // Initialize the auth service
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isAdmin = prefs.getBool(_isAdminKey) ?? false;
      
      if (isAdmin) {
        // Load admin account
        _currentUser = UserAccount(
          email: 'admin@clearedtogo.dev',
          password: 'David',
          fullName: 'Tom (Admin)',
          isPremium: true,
        );
        return;
      }
      
      // Check if there's a Cognito session with timeout
      try {
        final session = await Amplify.Auth.fetchAuthSession()
            .timeout(const Duration(seconds: 3));
        if (session.isSignedIn) {
          // Load user from Cognito
          await _loadCognitoUser();
        }
      } catch (e) {
        safePrint('Error checking auth session (timeout or error): $e');
        // Continue without Cognito - user can still login
      }
    } catch (e) {
      safePrint('Error initializing auth service: $e');
      // Continue anyway - app should still be usable
    }
  }

  // Load current Cognito user and attributes
  Future<void> _loadCognitoUser() async {
    try {
      final user = await Amplify.Auth.getCurrentUser()
          .timeout(const Duration(seconds: 3));
      final attributes = await Amplify.Auth.fetchUserAttributes()
          .timeout(const Duration(seconds: 3));
      
      String? email;
      String? fullName;
      
      for (final attr in attributes) {
        if (attr.userAttributeKey == CognitoUserAttributeKey.email) {
          email = attr.value;
        } else if (attr.userAttributeKey == CognitoUserAttributeKey.name) {
          fullName = attr.value;
        }
      }
      
      // Load additional profile data from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_currentUserKey);
      
      if (userJson != null) {
        final userData = json.decode(userJson);
        _currentUser = UserAccount.fromJson(userData);
      } else {
        _currentUser = UserAccount(
          email: email ?? user.username,
          fullName: fullName,
          cognitoUserId: user.userId,
        );
        await _saveCurrentUser();
      }
    } catch (e) {
      safePrint('Error loading Cognito user (timeout or error): $e');
    }
  }

  // Save current user to SharedPreferences
  Future<void> _saveCurrentUser() async {
    if (_currentUser == null) return;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentUserKey, json.encode(_currentUser!.toJson()));
  }

  // Sign up with AWS Cognito
  Future<bool> signUpWithCognito(
    String email,
    String password,
    bool acceptedTerms,
  ) async {
    if (!acceptedTerms) {
      throw Exception('Must accept terms and conditions');
    }

    try {
      final normalizedEmail = email.toLowerCase().trim();
      
      final userAttributes = <AuthUserAttributeKey, String>{
        AuthUserAttributeKey.email: normalizedEmail,
      };

      final result = await Amplify.Auth.signUp(
        username: normalizedEmail,
        password: password,
        options: SignUpOptions(
          userAttributes: userAttributes,
        ),
      ).timeout(const Duration(seconds: 10));

      safePrint('Sign up result: ${result.nextStep.signUpStep}');

      // Check if email confirmation is required
      if (result.nextStep.signUpStep == AuthSignUpStep.confirmSignUp) {
        safePrint('Email confirmation required');
        throw Exception('Account created. Please check your email for a verification code, then login.');
      }

      // If signup is complete, auto-login
      if (result.isSignUpComplete) {
        await loginWithCognito(normalizedEmail, password);
        return true;
      }

      // Try to auto-login anyway
      try {
        await loginWithCognito(normalizedEmail, password);
        return true;
      } catch (e) {
        safePrint('Auto-login after signup failed: $e');
        throw Exception('Account created. Please check your email for verification code, then login.');
      }
    } on AuthException catch (e) {
      safePrint('Sign up error: ${e.message}');
      
      // Check for specific error messages
      final message = e.message.toLowerCase();
      if (message.contains('username') && message.contains('exists')) {
        throw Exception('An account with this email already exists');
      }
      
      throw Exception(e.message);
    } catch (e) {
      safePrint('Unexpected sign up error: $e');
      rethrow;
    }
  }

  // Login with AWS Cognito (with Tom/David admin override)
  Future<bool> loginWithCognito(String username, String password) async {
    // HARDCODED ADMIN LOGIN - ALWAYS CHECK FIRST
    if (username == 'Tom' && password == 'David') {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isAdminKey, true);
      
      _currentUser = UserAccount(
        email: 'admin@clearedtogo.dev',
        password: 'David',
        fullName: 'Tom (Admin)',
        isPremium: true,
      );
      
      await _saveCurrentUser();
      
      safePrint('Admin login successful');
      return true;
    }
    
    // Normal Cognito authentication
    try {
      final result = await Amplify.Auth.signIn(
        username: username.toLowerCase(), // Ensure lowercase for consistency
        password: password,
      ).timeout(const Duration(seconds: 10));

      safePrint('Sign in result: ${result.nextStep.signInStep}');

      if (result.isSignedIn) {
        // Load user data
        await _loadCognitoUser();
        safePrint('Login successful');
        return true;
      } else {
        // Handle additional steps (MFA, password change, etc.)
        safePrint('Login incomplete: ${result.nextStep.signInStep}');
        if (result.nextStep.signInStep == AuthSignInStep.confirmSignUp) {
          throw Exception('Please verify your email before logging in. Check your inbox for the verification code.');
        }
        return false;
      }
    } on AuthException catch (e) {
      safePrint('Auth error: ${e.message}');
      
      // Check specific error messages for better user feedback
      final message = e.message.toLowerCase();
      if (message.contains('not confirmed') || message.contains('not verified')) {
        throw Exception('Please verify your email before logging in. Check your inbox for the verification code.');
      } else if (message.contains('not found') || message.contains('incorrect') || message.contains('not authorized')) {
        throw Exception('Invalid username or password');
      }
      
      throw Exception(e.message);
    } catch (e) {
      safePrint('Unexpected login error: $e');
      throw Exception('Login failed: $e');
    }
  }

  // Logout from AWS Cognito
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isAdmin = prefs.getBool(_isAdminKey) ?? false;
      
      if (isAdmin) {
        // Admin logout - just clear local state
        await prefs.remove(_isAdminKey);
        await prefs.remove(_currentUserKey);
      } else {
        // Cognito logout
        await Amplify.Auth.signOut()
            .timeout(const Duration(seconds: 5));
        await prefs.remove(_currentUserKey);
      }
      
      _currentUser = null;
      safePrint('Logout successful');
    } catch (e) {
      safePrint('Logout error: $e');
      // Even if Cognito logout fails, clear local state
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_isAdminKey);
      await prefs.remove(_currentUserKey);
      _currentUser = null;
    }
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final isAdmin = prefs.getBool(_isAdminKey) ?? false;
    
    if (isAdmin) {
      return true;
    }
    
    try {
      final session = await Amplify.Auth.fetchAuthSession()
          .timeout(const Duration(seconds: 3));
      return session.isSignedIn;
    } catch (e) {
      return false;
    }
  }

  Future<String?> getCurrentUsername() async {
    return _currentUser?.email;
  }

  // Get Cognito User ID (for PDFs, subscriptions, etc.)
  Future<String?> getCognitoUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isAdmin = prefs.getBool(_isAdminKey) ?? false;
      
      if (isAdmin) {
        return 'admin-local';
      }
      
      final user = await Amplify.Auth.getCurrentUser()
          .timeout(const Duration(seconds: 3));
      return user.userId;
    } catch (e) {
      safePrint('Error getting Cognito user ID: $e');
      return null;
    }
  }

  // Update user profile
  Future<void> updateProfile({
    String? fullName,
    String? licenseNumber,
    String? homeBase,
  }) async {
    if (_currentUser == null) {
      throw Exception('No user logged in');
    }

    // Update current user
    _currentUser = _currentUser!.copyWith(
      fullName: fullName,
      licenseNumber: licenseNumber,
      homeBase: homeBase,
    );

    // Save to local storage
    await _saveCurrentUser();

    // Update Cognito attributes (skip for admin)
    final prefs = await SharedPreferences.getInstance();
    final isAdmin = prefs.getBool(_isAdminKey) ?? false;
    
    if (!isAdmin && fullName != null) {
      try {
        await Amplify.Auth.updateUserAttribute(
          userAttributeKey: CognitoUserAttributeKey.name,
          value: fullName,
        ).timeout(const Duration(seconds: 5));
        safePrint('Cognito attributes updated');
      } catch (e) {
        safePrint('Error updating Cognito attributes: $e');
        // Don't throw - local update already succeeded
      }
    }

    // Custom attributes such as license and home base should be stored in
    // a backend database once available.
  }

  // Update user's premium status
  Future<void> updatePremiumStatus(bool isPremium) async {
    if (_currentUser == null) {
      throw Exception('No user logged in');
    }

    // Update current user
    _currentUser = _currentUser!.copyWith(isPremium: isPremium);

    // Save to storage
    await _saveCurrentUser();

    // Premium entitlement checks should be validated against backend records
    // once billing integration is available.
  }
}
