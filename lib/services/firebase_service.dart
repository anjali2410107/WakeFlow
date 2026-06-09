import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  static bool _isInitialized = false;

  static bool get isInitialized => _isInitialized;

  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      _isInitialized = true;
      debugPrint("Firebase successfully initialized!");
    } catch (e) {
      debugPrint("Firebase initialization failed: $e");
      debugPrint("Wakeflow will run in local Offline Demo Mode.");
      _isInitialized = false;
    }
  }
}
