import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/alarm.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    tz.initializeTimeZones();
    try {
      final String timeZoneName = (await FlutterTimezone.getLocalTimezone()).identifier;
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      debugPrint("NotificationService: Initialized timezone to $timeZoneName");
    } catch (e) {
      debugPrint("NotificationService: Failed to detect local timezone, using UTC: $e");
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        debugPrint("Notification clicked: ${details.payload}");
      },
    );

    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      try {
        await androidImplementation.requestNotificationsPermission();
        await androidImplementation.requestExactAlarmsPermission();
        debugPrint("NotificationService: Requested Android runtime permissions.");
      } catch (e) {
        debugPrint("NotificationService: Error requesting permissions: $e");
      }
    }
  }

  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  static tz.TZDateTime _nextInstanceOfWeekday(int dayOfWeek, int hour, int minute) {
    tz.TZDateTime scheduledDate = _nextInstanceOfTime(hour, minute);
    while (scheduledDate.weekday != dayOfWeek) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  static Future<void> scheduleAlarm(Alarm alarm) async {
    await cancelAlarm(alarm);

    if (!alarm.isEnabled) {
      debugPrint("NotificationService: Alarm ${alarm.id} is disabled. Skipping schedule.");
      return;
    }

    debugPrint("NotificationService: Scheduling alarm '${alarm.label}' at ${alarm.time} (Hour: ${alarm.hour}, Minute: ${alarm.minute})");
    debugPrint("NotificationService: Current timezone database location is: ${tz.local}");
    debugPrint("NotificationService: Current time in timezone database is: ${tz.TZDateTime.now(tz.local)}");
    debugPrint("NotificationService: Current local system time is: ${DateTime.now()}");

    final int baseId = alarm.id.hashCode & 0x7FFFFFFF;

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'alarm_channel_v4',
      'Wakeflow Alarms',
      channelDescription: 'Channel for wakeflow active alarms',
      importance: Importance.max,
      priority: Priority.high,
      sound: const UriAndroidNotificationSound("content://settings/system/alarm_alert"),
      playSound: true,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      category: AndroidNotificationCategory.alarm,
      additionalFlags: Int32List.fromList(<int>[4]), // Insistent (loops sound until dismissed)
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
      enableVibration: true,
    );

    final NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    if (alarm.repeatDays.isEmpty) {
      final tz.TZDateTime scheduledDate = _nextInstanceOfTime(alarm.hour, alarm.minute);
      await _notificationsPlugin.zonedSchedule(
        baseId,
        'Alarm Triggered',
        alarm.label.isNotEmpty ? alarm.label : 'Wake Up!',
        scheduledDate,
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      debugPrint("NotificationService: Scheduled single alarm ${alarm.id} for $scheduledDate");
    } else {
      for (final day in alarm.repeatDays) {
        final tz.TZDateTime scheduledDate =
            _nextInstanceOfWeekday(day, alarm.hour, alarm.minute);
        await _notificationsPlugin.zonedSchedule(
          baseId + day,
          'Alarm Triggered (${_dayName(day)})',
          alarm.label.isNotEmpty ? alarm.label : 'Wake Up!',
          scheduledDate,
          platformDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
        debugPrint("NotificationService: Scheduled repeating alarm ${alarm.id} for weekday $day ($scheduledDate)");
      }
    }
  }

  static Future<void> cancelAlarm(Alarm alarm) async {
    final int baseId = alarm.id.hashCode & 0x7FFFFFFF;
    
    await _notificationsPlugin.cancel(baseId);

    for (int i = 1; i <= 7; i++) {
      await _notificationsPlugin.cancel(baseId + i);
    }
    debugPrint("NotificationService: Cancelled notifications for alarm ${alarm.id}");
  }

  static String _dayName(int day) {
    switch (day) {
      case 1: return 'Monday';
      case 2: return 'Tuesday';
      case 3: return 'Wednesday';
      case 4: return 'Thursday';
      case 5: return 'Friday';
      case 6: return 'Saturday';
      case 7: return 'Sunday';
      default: return 'Day';
    }
  }
}
