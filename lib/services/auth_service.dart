import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class UserAccount {
  final String email;
  final String password; // Plain text for dev only
  final String? fullName;
  final String? licenseNumber;
  final String? homeBase;
  final bool isPremium;

  UserAccount({
    required this.email,
    required this.password,
    this.fullName,
    this.licenseNumber,
    this.homeBase,
    this.isPremium = false,
  });

  Map<String, dynamic> toJson() => {
    'email': email,
    'password': password,
    'fullName': fullName,
    'licenseNumber': licenseNumber,
    'homeBase': homeBase,
    'isPremium': isPremium,
  };

  factory UserAccount.fromJson(Map<String, dynamic> json) => UserAccount(
    email: json['email'],
    password: json['password'],
    fullName: json['fullName'],
    licenseNumber: json['licenseNumber'],
    homeBase: json['homeBase'],
    isPremium: json['isPremium'] ?? false,
  );

  UserAccount copyWith({
    String? email,
    String? password,
    String? fullName,
    String? licenseNumber,
    String? homeBase,
    bool? isPremium,
  }) {
    return UserAccount(
      email: email ?? this.email,
      password: password ?? this.password,
      fullName: fullName ?? this.fullName,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      homeBase: homeBase ?? this.homeBase,
      isPremium: isPremium ?? this.isPremium,
    );
  }
}

class AuthService {
  static const String _isLoggedInKey = 'isLoggedIn';
  static const String _currentUserEmailKey = 'currentUserEmail';
  static const String _usersKey = 'users';
  
  UserAccount? _currentUser;

  UserAccount? get currentUser => _currentUser;

  // Initialize the auth service
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;
    
    if (isLoggedIn) {
      final currentEmail = prefs.getString(_currentUserEmailKey);
      if (currentEmail != null) {
        final users = await _loadUsers();
        _currentUser = users[currentEmail];
      }
    }
  }

  // Load all users from SharedPreferences
  Future<Map<String, UserAccount>> _loadUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersKey);
    
    if (usersJson == null) {
      return {};
    }
    
    try {
      final Map<String, dynamic> decoded = json.decode(usersJson);
      return decoded.map(
        (key, value) => MapEntry(key, UserAccount.fromJson(value)),
      );
    } catch (e) {
      return {};
    }
  }

  // Save all users to SharedPreferences
  Future<void> _saveUsers(Map<String, UserAccount> users) async {
    final prefs = await SharedPreferences.getInstance();
    final usersMap = users.map(
      (key, value) => MapEntry(key, value.toJson()),
    );
    await prefs.setString(_usersKey, json.encode(usersMap));
  }

  // Store current logged-in user
  Future<void> _setCurrentUser(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, true);
    await prefs.setString(_currentUserEmailKey, email);
    
    final users = await _loadUsers();
    _currentUser = users[email];
  }

  // TODO: integrate AWS Cognito here
  Future<bool> signUpWithCognito(
    String email,
    String password,
    bool acceptedTerms,
  ) async {
    // TODO: Replace with actual AWS Cognito signup call
    // Example:
    // final userPool = CognitoUserPool(userPoolId, clientId);
    // final user = CognitoUser(email, userPool);
    // await user.signUp(email, password, userAttributes: [...]);
    
    if (!acceptedTerms) {
      throw Exception('Must accept terms and conditions');
    }

    // Local registration
    final users = await _loadUsers();
    
    // Check if email already exists
    if (users.containsKey(email.toLowerCase())) {
      throw Exception('An account with this email already exists');
    }
    
    // Create new user account
    final newUser = UserAccount(
      email: email.toLowerCase(),
      password: password, // Plain text for dev only
      isPremium: false,
    );
    
    // Save new user
    users[email.toLowerCase()] = newUser;
    await _saveUsers(users);
    
    // Set as current user
    await _setCurrentUser(email.toLowerCase());
    
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    return true;
  }

  // TODO: integrate AWS Cognito here
  Future<bool> loginWithCognito(String username, String password) async {
    // TODO: Replace with actual AWS Cognito authentication
    // Example:
    // final userPool = CognitoUserPool(userPoolId, clientId);
    // final cognitoUser = CognitoUser(username, userPool);
    // final authDetails = AuthenticationDetails(username: username, password: password);
    // final session = await cognitoUser.authenticateUser(authDetails);
    
    // Hardcoded admin login
    if (username == 'Tom' && password == 'David') {
      // Create/use special admin account
      final users = await _loadUsers();
      final adminEmail = 'admin@clearedtogo.dev';
      
      if (!users.containsKey(adminEmail)) {
        users[adminEmail] = UserAccount(
          email: adminEmail,
          password: 'David',
          fullName: 'Tom (Admin)',
          isPremium: true,
        );
        await _saveUsers(users);
      }
      
      await _setCurrentUser(adminEmail);
      
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));
      
      return true;
    }
    
    // Normal user login - check local storage
    final users = await _loadUsers();
    final user = users[username.toLowerCase()];
    
    if (user != null && user.password == password) {
      await _setCurrentUser(username.toLowerCase());
      await Future.delayed(const Duration(seconds: 1));
      return true;
    }
    
    return false;
  }

  // TODO: integrate AWS Cognito here
  Future<void> logout() async {
    // TODO: Replace with actual AWS Cognito logout
    // Example:
    // final cognitoUser = await userPool.getCurrentUser();
    // await cognitoUser?.signOut();
    
    // Clear local login state
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_isLoggedInKey);
    await prefs.remove(_currentUserEmailKey);
    
    _currentUser = null;
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  Future<String?> getCurrentUsername() async {
    return _currentUser?.email;
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

    // Save to storage
    final users = await _loadUsers();
    users[_currentUser!.email] = _currentUser!;
    await _saveUsers(users);

    // TODO: integrate AWS Cognito here - update user attributes
    // Example:
    // final attributes = [
    //   CognitoUserAttribute(name: 'name', value: fullName),
    //   CognitoUserAttribute(name: 'custom:license', value: licenseNumber),
    //   CognitoUserAttribute(name: 'custom:homeBase', value: homeBase),
    // ];
    // await cognitoUser.updateAttributes(attributes);
  }

  // Update user's premium status
  Future<void> updatePremiumStatus(bool isPremium) async {
    if (_currentUser == null) {
      throw Exception('No user logged in');
    }

    // Update current user
    _currentUser = _currentUser!.copyWith(isPremium: isPremium);

    // Save to storage
    final users = await _loadUsers();
    users[_currentUser!.email] = _currentUser!;
    await _saveUsers(users);

    // TODO: integrate backend verification here
    // This should verify the premium status with your backend
    // which should verify the purchase with Google Play Billing
  }
}
