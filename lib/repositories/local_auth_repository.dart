import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_role.dart';
import '../repositories/auth_repository.dart';

/// Local authentication repository implemented with SharedPreferences.
/// This local implementation is intended for development and fallback scenarios.
class LocalAuthRepository implements AuthRepository {
  static const String _currentUserKey = 'current_user_v2';
  static const String _usersKey = 'users_database';
  
  User? _currentUser;
  final _authStateController = StreamController<User?>.broadcast();

  // Seeded demo admin account for testing
  static final User _demoAdmin = User(
    id: 'demo-admin-001',
    email: 'school@demo.com',
    password: 'Demo123!', // Only stored for local auth
    fullName: 'Demo Flight School',
    role: UserRole.flightSchoolAdmin,
    flightSchoolId: 'demo-school-001',
    isPremium: true,
  );

  @override
  Future<void> init() async {
    // Load current user from storage
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_currentUserKey);
    
    if (userJson != null) {
      try {
        _currentUser = User.fromJson(json.decode(userJson));
        _authStateController.add(_currentUser);
      } catch (e) {
        debugPrint('Error loading user: $e');
        await prefs.remove(_currentUserKey);
      }
    }
    
    // Seed demo admin if not exists
    await _seedDemoAdmin();
  }

  Future<void> _seedDemoAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersKey);
    
    Map<String, dynamic> usersDb = {};
    if (usersJson != null) {
      usersDb = json.decode(usersJson);
    }
    
    // Add demo admin if not exists
    if (!usersDb.containsKey(_demoAdmin.email)) {
      usersDb[_demoAdmin.email] = _demoAdmin.toJson();
      await prefs.setString(_usersKey, json.encode(usersDb));
    }
  }

  @override
  User? get currentUser => _currentUser;

  @override
  bool get isSignedIn => _currentUser != null;

  @override
  Stream<User?> get authStateChanges => _authStateController.stream;

  @override
  Future<User> signIn(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersKey);
    
    if (usersJson == null) {
      throw Exception('No users found');
    }
    
    final usersDb = json.decode(usersJson) as Map<String, dynamic>;
    final userJson = usersDb[email];
    
    if (userJson == null) {
      throw Exception('User not found');
    }
    
    final user = User.fromJson(userJson);
    
    // Verify password (in production, this would be hashed)
    if (user.password != password) {
      throw Exception('Invalid password');
    }
    
    // Store current user
    _currentUser = user;
    await prefs.setString(_currentUserKey, json.encode(user.toJson()));
    _authStateController.add(_currentUser);
    
    return user;
  }

  @override
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
    _currentUser = null;
    _authStateController.add(null);
  }

  @override
  Future<void> updateUser(User user) async {
    if (_currentUser?.id != user.id) {
      throw Exception('Can only update current user');
    }
    
    final prefs = await SharedPreferences.getInstance();
    
    // Update in users database
    final usersJson = prefs.getString(_usersKey);
    if (usersJson != null) {
      final usersDb = json.decode(usersJson) as Map<String, dynamic>;
      usersDb[user.email] = user.toJson();
      await prefs.setString(_usersKey, json.encode(usersDb));
    }
    
    // Update current user
    _currentUser = user;
    await prefs.setString(_currentUserKey, json.encode(user.toJson()));
    _authStateController.add(_currentUser);
  }

  void dispose() {
    _authStateController.close();
  }
}
