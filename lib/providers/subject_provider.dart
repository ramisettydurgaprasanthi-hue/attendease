import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/subject.dart';
import '../services/notification_service.dart';

class SubjectProvider extends ChangeNotifier {
  final List<Subject> _subjects = [];
  double _target = 75;
  bool _dark = false;

  List<Subject> get subjects => List.unmodifiable(_subjects);
  double get target => _target;
  bool get isDark => _dark;

  // ---------- overall statistics ----------

  int get overallAttended =>
      _subjects.fold<int>(0, (sum, s) => sum + s.attended);

  int get overallTotal => _subjects.fold<int>(0, (sum, s) => sum + s.total);

  double get overallPercentage =>
      overallTotal == 0 ? 0 : overallAttended / overallTotal * 100;

  /// Classes that can still be missed overall while staying at the target.
  int get overallCanMiss {
    final t = _target / 100;
    final v = (overallAttended / t - overallTotal + 1e-9).floor();
    return v < 0 ? 0 : v;
  }

  /// Classes that must be attended in a row to reach the target overall.
  int get overallNeeded {
    if (overallTotal == 0 || overallPercentage >= _target) return 0;
    final t = _target / 100;
    return ((t * overallTotal - overallAttended) / (1 - t) - 1e-9).ceil();
  }

  /// Average number of classes per teaching day, from the timetable.
  double? get classesPerDay {
    final slots = _subjects.fold<int>(0, (sum, s) => sum + s.days.length);
    final activeDays = _subjects.expand((s) => s.days).toSet().length;
    if (activeDays == 0) return null;
    return slots / activeDays;
  }

  /// Converts a number of classes into teaching days using the timetable.
  int? daysFor(int classes, {required bool roundUp}) {
    final perDay = classesPerDay;
    if (perDay == null || perDay == 0) return null;
    final d = classes / perDay;
    return roundUp ? d.ceil() : d.floor();
  }

  /// Subjects scheduled today that have not been marked yet.
  List<String> get pendingToday {
    final today = DateTime.now();
    return _subjects
        .where((s) => s.isScheduledOn(today) && s.statusOn(today) == null)
        .map((s) => s.name)
        .toList();
  }

  // ---------- loading and saving ----------

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('subjects');
    if (raw != null) {
      final list = jsonDecode(raw) as List;
      _subjects
        ..clear()
        ..addAll(list
            .map((e) => Subject.fromJson(Map<String, dynamic>.from(e as Map))));
    }
    _target = prefs.getDouble('target') ?? 75;
    _dark = prefs.getBool('dark') ?? false;
    notifyListeners();
    _updateReminders();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'subjects', jsonEncode(_subjects.map((s) => s.toJson()).toList()));
    await prefs.setDouble('target', _target);
    await prefs.setBool('dark', _dark);
  }

  void _changed() {
    notifyListeners();
    _save();
    _updateReminders();
  }

  /// Plans an attendance reminder for each of the next 7 days. A day only
  /// gets one if it has subjects scheduled that are not marked yet.
  void _updateReminders() {
    final now = DateTime.now();
    final bodies = <int, String>{};

    for (var i = 0; i < 7; i++) {
      final day = DateTime(now.year, now.month, now.day + i);
      final pending = _subjects
          .where((s) => s.isScheduledOn(day) && s.statusOn(day) == null)
          .map((s) => s.name)
          .toList();
      if (pending.isEmpty) continue;
      bodies[i] =
      'Attendance not marked yet for today: ${pending.join(', ')}';
    }
    NotificationService.instance.scheduleAttendanceReminders(bodies);
  }

  // ---------- actions ----------

  void addSubject(String name, List<int> days) {
    _subjects.add(Subject(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      days: days,
    ));
    _changed();
  }

  void editSubject(String id, String name, List<int> days) {
    final s = _subjects.firstWhere((s) => s.id == id);
    s.name = name;
    s.days = days;
    _changed();
  }

  void deleteSubject(String id) {
    _subjects.removeWhere((s) => s.id == id);
    _changed();
  }

  void resetSubject(String id) {
    final s = _subjects.firstWhere((s) => s.id == id);
    s.baseAttended = 0;
    s.baseTotal = 0;
    s.records.clear();
    _changed();
  }

  /// Marks attendance for one day (default: today). Marking the same day
  /// again replaces the earlier mark. Future dates are rejected.
  bool mark(String id, {required bool present, DateTime? date}) {
    final now = DateTime.now();
    final day = date ?? now;
    final dayOnly = DateTime(day.year, day.month, day.day);
    final todayOnly = DateTime(now.year, now.month, now.day);
    if (dayOnly.isAfter(todayOnly)) return false;

    final s = _subjects.firstWhere((s) => s.id == id);
    s.records[Subject.keyFor(dayOnly)] = present;
    _changed();
    return true;
  }

  /// Removes the mark for one day (used to undo a wrong tap).
  void clearMark(String id, DateTime date) {
    final s = _subjects.firstWhere((s) => s.id == id);
    s.records.remove(Subject.keyFor(date));
    _changed();
  }

  void setTarget(double value) {
    _target = value;
    _changed();
  }

  void toggleTheme() {
    _dark = !_dark;
    _changed();
  }
}