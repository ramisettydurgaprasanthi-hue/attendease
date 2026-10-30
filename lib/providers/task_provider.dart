import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/task.dart';
import '../services/notification_service.dart';

class TaskProvider extends ChangeNotifier {
  final List<Task> _tasks = [];

  List<Task> get tasks => List.unmodifiable(_tasks);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('tasks');
    if (raw != null) {
      final list = jsonDecode(raw) as List;
      _tasks
        ..clear()
        ..addAll(list
            .map((e) => Task.fromJson(Map<String, dynamic>.from(e as Map))));
    }
    notifyListeners();
    // Make sure upcoming reminders are scheduled (safe to repeat).
    for (final t in _tasks) {
      _scheduleIfNeeded(t);
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'tasks', jsonEncode(_tasks.map((t) => t.toJson()).toList()));
  }

  void _changed() {
    notifyListeners();
    _save();
  }

  void _scheduleIfNeeded(Task t) {
    final when = t.remindAt;
    if (!t.done && when != null && when.isAfter(DateTime.now())) {
      NotificationService.instance
          .scheduleTaskReminder(id: t.notifId, title: t.title, when: when);
    }
  }

  void addTask(String title, {DateTime? remindAt}) {
    final now = DateTime.now();
    final task = Task(
      id: now.microsecondsSinceEpoch.toString(),
      notifId: 1000 + (now.millisecondsSinceEpoch % 100000000),
      title: title,
      remindAt: remindAt,
    );
    _tasks.insert(0, task);
    _scheduleIfNeeded(task);
    _changed();
  }

  void toggleDone(String id) {
    final t = _tasks.firstWhere((t) => t.id == id);
    t.done = !t.done;
    if (t.done) {
      NotificationService.instance.cancel(t.notifId);
    } else {
      _scheduleIfNeeded(t);
    }
    _changed();
  }

  void deleteTask(String id) {
    final t = _tasks.firstWhere((t) => t.id == id);
    NotificationService.instance.cancel(t.notifId);
    _tasks.remove(t);
    _changed();
  }
}