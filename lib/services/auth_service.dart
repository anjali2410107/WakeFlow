import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_user.dart';
import 'firebase_service.dart';

class AuthService {
  FirebaseAuth get _firebaseAuth => FirebaseAuth.instance;

  static final StreamController<AppUser?> _mockAuthStreamController =
      StreamController<AppUser?>.broadcast();

  static const String _prefCurrentUserKey = 'mock_current_user';
  static const String _prefUsersListKey = 'mock_registered_users';

  Future<void> init() async {
    if (!FirebaseService.isInitialized) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final userJson = prefs.getString(_prefCurrentUserKey);
        if (userJson != null) {
          final userMap = jsonDecode(userJson);
          final user = AppUser.fromMap(userMap);
          _mockAuthStreamController.add(user);
          debugPrint("Mock Auth: Restored session for ${user.email}");
        } else {
          _mockAuthStreamController.add(null);
        }
      } catch (e) {
        debugPrint("Mock Auth initialization failed: $e");
        _mockAuthStreamController.add(null);
      }
    }
  }

  Stream<AppUser?> get authStateChanges {
    if (FirebaseService.isInitialized) {
      return _firebaseAuth.authStateChanges().map((firebaseUser) {
        if (firebaseUser == null) return null;
        return AppUser(uid: firebaseUser.uid, email: firebaseUser.email ?? '');
      });
    } else {
      return _mockAuthStreamController.stream;
    }
  }

  Future<AppUser?> getCurrentUser() async {
    if (FirebaseService.isInitialized) {
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser == null) return null;
      return AppUser(uid: firebaseUser.uid, email: firebaseUser.email ?? '');
    } else {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_prefCurrentUserKey);
      if (userJson == null) return null;
      return AppUser.fromMap(jsonDecode(userJson));
    }
  }

  Future<AppUser> register(String email, String password) async {
    if (FirebaseService.isInitialized) {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final firebaseUser = credential.user!;
      return AppUser(uid: firebaseUser.uid, email: firebaseUser.email ?? '');
    } else {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString(_prefUsersListKey) ?? '{}';
      final Map<String, dynamic> users = jsonDecode(usersJson);

      if (users.containsKey(email)) {
        throw FirebaseAuthException(
          code: 'email-already-in-use',
          message: 'The email address is already in use by another account.',
        );
      }

      final uid = 'mock_uid_${DateTime.now().millisecondsSinceEpoch}';
      users[email] = {
        'uid': uid,
        'email': email,
        'password': password,
      };

      await prefs.setString(_prefUsersListKey, jsonEncode(users));

      final newUser = AppUser(uid: uid, email: email);
      await prefs.setString(_prefCurrentUserKey, jsonEncode(newUser.toMap()));
      _mockAuthStreamController.add(newUser);
      return newUser;
    }
  }

  Future<AppUser> login(String email, String password) async {
    if (FirebaseService.isInitialized) {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final firebaseUser = credential.user!;
      return AppUser(uid: firebaseUser.uid, email: firebaseUser.email ?? '');
    } else {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString(_prefUsersListKey) ?? '{}';
      final Map<String, dynamic> users = jsonDecode(usersJson);

      if (!users.containsKey(email) || users[email]['password'] != password) {
        throw FirebaseAuthException(
          code: 'invalid-credential',
          message: 'Invalid email or password.',
        );
      }

      final userData = users[email];
      final user = AppUser(uid: userData['uid'], email: userData['email']);
      await prefs.setString(_prefCurrentUserKey, jsonEncode(user.toMap()));
      _mockAuthStreamController.add(user);
      return user;
    }
  }

  Future<void> logout() async {
    if (FirebaseService.isInitialized) {
      await _firebaseAuth.signOut();
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefCurrentUserKey);
      _mockAuthStreamController.add(null);
    }
  }
}
