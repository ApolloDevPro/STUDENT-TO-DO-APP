import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import '../services/cloud_sync_service.dart';
import '../services/notification_service.dart';
import '../services/sync_merge.dart';

class TaskProvider extends ChangeNotifier {
  final String? userId;
  List<Task> _tasks = [];
  List<Task> get tasks => List.unmodifiable(_tasks);

  bool _remindersEnabled = true;
  bool get remindersEnabled => _remindersEnabled;

  int _reminderLeadMinutes = 0;
  int get reminderLeadMinutes => _reminderLeadMinutes;

  bool _disposed = false;

  TaskProvider({this.userId}) {
    _loadRemindersEnabled();
    _loadLeadMinutes();
    loadTasks();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  String get _storageKey =>
      userId == null ? 'tasks_guest' : 'tasks_$userId';

  Future<void> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String? tasksJson = prefs.getString(_storageKey);

    if (tasksJson != null) {
      final List<dynamic> decoded = jsonDecode(tasksJson);
      _tasks = decoded.map((t) => Task.fromJson(t)).toList();
      _notify();
    }
    _rescheduleAll();
    _pullAndMerge();
  }

  /// Fetches the remote list and reconciles it with the local list using a
  /// last-write-wins merge.
  Future<void> _pullAndMerge() async {
    if (_disposed) return;
    final remoteJson = await CloudSyncService.instance.fetchTasks();
    if (_disposed) return;

    final remote = remoteJson.map((m) => Task.fromJson(m)).toList();
    final result = mergeTaskLists(_tasks, remote);

    final changed = result.merged.length != _tasks.length ||
        List<bool>.generate(
          result.merged.length,
          (i) => result.merged[i] != _tasks[i],
        ).contains(true);

    _tasks = result.merged;
    for (final task in result.toPush) {
      CloudSyncService.instance.pushTask(task);
    }

    if (changed) {
      _notify();
      await _saveTasks();
    }
  }

  Future<void> _loadRemindersEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    _remindersEnabled = prefs.getBool('remindersEnabled') ?? true;
  }

  Future<void> _loadLeadMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    _reminderLeadMinutes = prefs.getInt('reminderLeadMinutes') ?? 0;
  }

  Future<void> setRemindersEnabled(bool value) async {
    _remindersEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('remindersEnabled', value);
    _notify();
    _rescheduleAll();
  }

  Future<void> setReminderLeadMinutes(int minutes) async {
    _reminderLeadMinutes = minutes;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('reminderLeadMinutes', minutes);
    _notify();
    _rescheduleAll();
  }

  void _rescheduleAll() {
    NotificationService.instance.cancelAll();
    if (!_remindersEnabled) return;
    for (final task in _tasks) {
      NotificationService.instance
          .scheduleForTask(task, leadMinutes: _reminderLeadMinutes);
    }
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String tasksJson = jsonEncode(_tasks.map((t) => t.toJson()).toList());
    await prefs.setString(_storageKey, tasksJson);
  }

  void addTask(Task task) {
    task.updatedAt = DateTime.now();
    _tasks.add(task);
    _saveTasks();
    CloudSyncService.instance.pushTask(task);
    if (_remindersEnabled) {
      NotificationService.instance
          .scheduleForTask(task, leadMinutes: _reminderLeadMinutes);
    }
    _notify();
  }

  void updateTask(Task task) {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      task.updatedAt = DateTime.now();
      _tasks[index] = task;
      _saveTasks();
      CloudSyncService.instance.pushTask(task);
      NotificationService.instance.cancelForTask(task.id);
      if (_remindersEnabled) {
        NotificationService.instance
            .scheduleForTask(task, leadMinutes: _reminderLeadMinutes);
      }
      _notify();
    }
  }

  void deleteTask(String taskId) {
    _tasks.removeWhere((t) => t.id == taskId);
    _saveTasks();
    CloudSyncService.instance.deleteRemoteTask(taskId);
    NotificationService.instance.cancelForTask(taskId);
    _notify();
  }

  /// Re-inserts a previously deleted task (used by the swipe-to-delete undo).
  void restoreTask(Task task) {
    if (_tasks.any((t) => t.id == task.id)) return;
    task.updatedAt = DateTime.now();
    _tasks.add(task);
    _saveTasks();
    CloudSyncService.instance.pushTask(task);
    if (_remindersEnabled) {
      NotificationService.instance
          .scheduleForTask(task, leadMinutes: _reminderLeadMinutes);
    }
    _notify();
  }

  void toggleTaskStatus(Task task) {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      final updated = _tasks[index];
      updated.status = updated.status == TaskStatus.completed
          ? TaskStatus.pending
          : TaskStatus.completed;
      updated.updatedAt = DateTime.now();
      _saveTasks();
      CloudSyncService.instance.pushTask(updated);
      NotificationService.instance.cancelForTask(updated.id);
      if (_remindersEnabled) {
        NotificationService.instance
            .scheduleForTask(updated, leadMinutes: _reminderLeadMinutes);
      }
      _notify();
    }
  }

  // Statistics
  int get totalTasks => _tasks.length;
  int get completedTasks =>
      _tasks.where((t) => t.status == TaskStatus.completed).length;
  int get pendingTasks =>
      _tasks.where((t) => t.status == TaskStatus.pending).length;
  int get inProgressTasks =>
      _tasks.where((t) => t.status == TaskStatus.inProgress).length;
  int get overdueTasks => _tasks.where((t) {
        if (t.dueDate == null || t.status == TaskStatus.completed) return false;
        return t.dueDate!.isBefore(DateTime.now());
      }).length;

  double get completionPercentage {
    if (_tasks.isEmpty) return 0;
    return completedTasks / _tasks.length;
  }

  Task? getTaskById(String id) {
    try {
      return _tasks.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  List<Task> getTasksBySubject(String subjectId) {
    return _tasks.where((t) => t.subjectId == subjectId).toList();
  }

  List<Task> searchTasks(String query) {
    if (query.isEmpty) return _tasks;
    return _tasks.where((t) {
      return t.title.toLowerCase().contains(query.toLowerCase()) ||
          (t.description?.toLowerCase().contains(query.toLowerCase()) ??
              false);
    }).toList();
  }

  List<Task> get assignmentTasks =>
      _tasks.where((t) => t.isAssignment).toList();

  bool _isDueToday(Task t) {
    if (t.dueDate == null) return false;
    final now = DateTime.now();
    return t.dueDate!.year == now.year &&
        t.dueDate!.month == now.month &&
        t.dueDate!.day == now.day;
  }

  bool _isUpcoming(Task t) {
    if (t.dueDate == null) return false;
    final now = DateTime.now();
    return t.dueDate!.isAfter(now) && !_isDueToday(t);
  }

  List<Task> tasksForFilter(String filter) {
    switch (filter) {
      case 'Assignments':
        return _tasks.where((t) => t.isAssignment).toList();
      case 'Today':
        return _tasks.where(_isDueToday).toList();
      case 'Upcoming':
        return _tasks.where(_isUpcoming).toList();
      case 'In Progress':
        return _tasks.where((t) => t.status == TaskStatus.inProgress).toList();
      case 'Completed':
        return _tasks.where((t) => t.status == TaskStatus.completed).toList();
      case 'Pending':
        return _tasks.where((t) => t.status == TaskStatus.pending).toList();
      default:
        return _tasks;
    }
  }
}
