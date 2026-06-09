import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/alarm.dart';
import 'firebase_service.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static final StreamController<void> _localChangeStreamController =
      StreamController<void>.broadcast();

  String _cacheKey(String uid) => 'alarms_cache_$uid';
  String _pendingWritesKey(String uid) => 'pending_writes_$uid';
  String _pendingDeletesKey(String uid) => 'pending_deletes_$uid';

  Future<List<Alarm>> getCachedAlarms(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? alarmsJson = prefs.getString(_cacheKey(uid));
      if (alarmsJson == null) return [];
      final List<dynamic> decoded = jsonDecode(alarmsJson);
      return decoded.map((item) => Alarm.fromMap(item)).toList();
    } catch (e) {
      debugPrint("Error fetching cached alarms: $e");
      return [];
    }
  }

  Future<void> saveAlarmsToCache(String uid, List<Alarm> alarms) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encoded = jsonEncode(alarms.map((e) => e.toMap()).toList());
      await prefs.setString(_cacheKey(uid), encoded);
    } catch (e) {
      debugPrint("Error saving alarms to cache: $e");
    }
  }

  Stream<List<Alarm>> getAlarmsStream(String uid) {
    final controller = StreamController<List<Alarm>>.broadcast();

    getCachedAlarms(uid).then((cached) {
      if (!controller.isClosed) {
        controller.add(cached);
      }
    });

    if (FirebaseService.isInitialized) {
      _syncPendingOperations(uid);

      final firestoreStream = _firestore
          .collection('users')
          .doc(uid)
          .collection('alarms')
          .snapshots();

      final subscription = firestoreStream.listen((snapshot) {
        final alarms = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return Alarm.fromMap(data);
        }).toList();

        alarms.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        saveAlarmsToCache(uid, alarms);

        if (!controller.isClosed) {
          controller.add(alarms);
        }
      }, onError: (error) {
        debugPrint("Firestore stream error: $error");
      });

      controller.onCancel = () {
        subscription.cancel();
        controller.close();
      };
    } else {
      final localSubscription = _localChangeStreamController.stream.listen((_) async {
        final cached = await getCachedAlarms(uid);
        if (!controller.isClosed) {
          controller.add(cached);
        }
      });

      controller.onCancel = () {
        localSubscription.cancel();
        controller.close();
      };
    }

    return controller.stream;
  }

  Future<void> saveAlarm(String uid, Alarm alarm) async {
    final cached = await getCachedAlarms(uid);
    final index = cached.indexWhere((element) => element.id == alarm.id);
    if (index >= 0) {
      cached[index] = alarm;
    } else {
      cached.add(alarm);
    }
    cached.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    await saveAlarmsToCache(uid, cached);

    _localChangeStreamController.add(null);

    if (FirebaseService.isInitialized) {
      try {
        await _firestore
            .collection('users')
            .doc(uid)
            .collection('alarms')
            .doc(alarm.id)
            .set(alarm.toMap());
      } catch (e) {
        debugPrint("Firestore write failed, queuing for offline sync: $e");
        await _queuePendingWrite(uid, alarm);
      }
    }
  }

  Future<void> deleteAlarm(String uid, String alarmId) async {
    final cached = await getCachedAlarms(uid);
    cached.removeWhere((element) => element.id == alarmId);
    await saveAlarmsToCache(uid, cached);

    _localChangeStreamController.add(null);

    if (FirebaseService.isInitialized) {
      try {
        await _firestore
            .collection('users')
            .doc(uid)
            .collection('alarms')
            .doc(alarmId)
            .delete();
      } catch (e) {
        debugPrint("Firestore delete failed, queuing for offline sync: $e");
        await _queuePendingDelete(uid, alarmId);
      }
    }
  }

  Future<void> migrateOfflineAlarms(String offlineUid, String firebaseUid) async {
    final offlineAlarms = await getCachedAlarms(offlineUid);
    if (offlineAlarms.isEmpty) return;

    debugPrint("Migrating ${offlineAlarms.length} offline alarms to Firestore user $firebaseUid");

    for (final alarm in offlineAlarms) {
      await saveAlarm(firebaseUid, alarm);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey(offlineUid));
  }

  Future<void> _queuePendingWrite(String uid, Alarm alarm) async {
    final prefs = await SharedPreferences.getInstance();
    final String key = _pendingWritesKey(uid);
    final String? writesJson = prefs.getString(key);
    final List<dynamic> decoded = writesJson != null ? jsonDecode(writesJson) : [];
    
    decoded.removeWhere((item) => item['id'] == alarm.id);
    decoded.add(alarm.toMap());
    
    await prefs.setString(key, jsonEncode(decoded));
  }

  Future<void> _queuePendingDelete(String uid, String alarmId) async {
    final prefs = await SharedPreferences.getInstance();
    final String key = _pendingDeletesKey(uid);
    final String? deletesJson = prefs.getString(key);
    final List<String> decoded = deletesJson != null ? List<String>.from(jsonDecode(deletesJson)) : [];
    
    if (!decoded.contains(alarmId)) {
      decoded.add(alarmId);
    }
    
    await prefs.setString(key, jsonEncode(decoded));
  }

  Future<void> _syncPendingOperations(String uid) async {
    if (!FirebaseService.isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      
      final deleteKey = _pendingDeletesKey(uid);
      final String? deletesJson = prefs.getString(deleteKey);
      if (deletesJson != null) {
        final List<String> pendingDeletes = List<String>.from(jsonDecode(deletesJson));
        if (pendingDeletes.isNotEmpty) {
          debugPrint("Offline Sync: Processing ${pendingDeletes.length} pending deletes");
          for (final id in pendingDeletes) {
            await _firestore
                .collection('users')
                .doc(uid)
                .collection('alarms')
                .doc(id)
                .delete();
          }
          await prefs.remove(deleteKey);
        }
      }

      final writeKey = _pendingWritesKey(uid);
      final String? writesJson = prefs.getString(writeKey);
      if (writesJson != null) {
        final List<dynamic> pendingWrites = jsonDecode(writesJson);
        if (pendingWrites.isNotEmpty) {
          debugPrint("Offline Sync: Processing ${pendingWrites.length} pending writes");
          for (final item in pendingWrites) {
            final alarm = Alarm.fromMap(item);
            await _firestore
                .collection('users')
                .doc(uid)
                .collection('alarms')
                .doc(alarm.id)
                .set(alarm.toMap());
          }
          await prefs.remove(writeKey);
        }
      }
    } catch (e) {
      debugPrint("Offline Sync: Synchronization failed (device might still be offline): $e");
    }
  }
}
