import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  /// Attendance reminder time (24-hour clock). 20:00 = 8 PM.
  static const int reminderHour = 20;
  static const int reminderMinute = 0;

  final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  static const NotificationDetails _attendanceDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'attendance_reminders_v2',
      'Attendance reminders',
      channelDescription: 'Daily reminder to mark your attendance',
      importance: Importance.max,
      priority: Priority.high,
    ),
  );

  static const NotificationDetails _taskDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'task_reminders_v2',
      'Task reminders',
      channelDescription: 'Reminders for your to-do tasks',
      importance: Importance.max,
      priority: Priority.high,
    ),
  );

  Future<void> init() async {
    if (kIsWeb) return;
    tzdata.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(const InitializationSettings(android: android));

    // Android 13+ needs the user to allow notifications.
    await _plugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// Schedules one notification. Tries exact timing first and falls back to
  /// inexact timing if Android does not allow exact alarms.
  Future<void> _schedule({
    required int id,
    required String title,
    required String body,
    required DateTime when,
    required NotificationDetails details,
  }) async {
    if (!when.isAfter(DateTime.now())) return;
    final date = tz.TZDateTime.from(when, tz.UTC);

    Future<void> go(AndroidScheduleMode mode) => _plugin.zonedSchedule(
      id,
      title,
      body,
      date,
      details,
      androidScheduleMode: mode,
    );

    try {
      await go(AndroidScheduleMode.exactAllowWhileIdle);
    } catch (e) {
      debugPrint('Exact scheduling failed, trying inexact: $e');
      try {
        await go(AndroidScheduleMode.inexactAllowWhileIdle);
      } catch (e2) {
        debugPrint('Scheduling failed: $e2');
      }
    }
  }

  /// [bodies] maps a day offset (0 = today ... 6) to the message for that
  /// day. Days that are not in the map get no reminder. Attendance
  /// reminders use ids 0-6; task reminders use ids from 1000 upwards.
  Future<void> scheduleAttendanceReminders(Map<int, String> bodies) async {
    for (var i = 0; i < 7; i++) {
      await _plugin.cancel(i);
    }
    final now = DateTime.now();

    for (final entry in bodies.entries) {
      final i = entry.key;
      final when = DateTime(
        now.year,
        now.month,
        now.day + i,
        reminderHour,
        reminderMinute,
      );
      await _schedule(
        id: i,
        title: 'Mark your attendance',
        body: entry.value,
        when: when,
        details: _attendanceDetails,
      );
    }
  }

  Future<void> scheduleTaskReminder({
    required int id,
    required String title,
    required DateTime when,
  }) {
    return _schedule(
      id: id,
      title: 'Task reminder',
      body: title,
      when: when,
      details: _taskDetails,
    );
  }

  Future<void> cancel(int id) async {
    if (kIsWeb) return;
    await _plugin.cancel(id);
  }

  /// Sends one notification right now and schedules another in 1 minute.
  Future<void> sendTestNotifications() async {
    await _plugin.show(
      9001,
      'Test notification',
      'If you can read this, notifications are allowed.',
      _attendanceDetails,
    );
    await _schedule(
      id: 9002,
      title: 'Scheduled test',
      body: 'This was scheduled about 1 minute ago.',
      when: DateTime.now().add(const Duration(minutes: 1)),
      details: _attendanceDetails,
    );
  }
}