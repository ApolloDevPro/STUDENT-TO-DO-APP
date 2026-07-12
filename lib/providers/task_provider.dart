import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import '../services/notification_service.dart';

class TaskProvider with ChangeNotifier {
  final String? userId;
  List<Task> _tasks = [];
  List<Task> get tasks => _tasks;

  bool _remindersEnabled = true;
  bool get remindersEnabled => _remindersEnabled;

  TaskProvider({this.userId}) {
    _loadRemindersEnabled();
    loadTasks();
  }

  String get _storageKey =>
      userId == null ? 'tasks_guest' : 'tasks_$userId';

  Future<void> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String? tasksJson = prefs.getString(_storageKey);

    if (tasksJson != null) {
      final List<dynamic> decoded = jsonDecode(tasksJson);
      _tasks = decoded.map((t) => Task.fromJson(t)).toList();
      notifyListeners();
    }
    _rescheduleAll();
  }

  Future<void> _loadRemindersEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    _remindersEnabled = prefs.getBool('remindersEnabled') ?? true;
  }

  Future<void> setRemindersEnabled(bool value) async {
    _remindersEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('remindersEnabled', value);
    notifyListeners();
    _rescheduleAll();
  }

  void _rescheduleAll() {
    if (!_remindersEnabled) {
      NotificationService.instance.cancelAll();
      return;
    }
    for (final task in _tasks) {
      NotificationService.instance.scheduleForTask(task);
    }
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String tasksJson = jsonEncode(_tasks.map((t) => t.toJson()).toList());
    await prefs.setString(_storageKey, tasksJson);
  }

  void addTask(Task task) {
    _tasks.add(task);
    _saveTasks();
    if (_remindersEnabled) NotificationService.instance.scheduleForTask(task);
    notifyListeners();
  }

  void updateTask(Task task) {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task;
      _saveTasks();
      NotificationService.instance.cancelForTask(task.id);
      if (_remindersEnabled) NotificationService.instance.scheduleForTask(task);
      notifyListeners();
    }
  }

  void deleteTask(String taskId) {
    _tasks.removeWhere((t) => t.id == taskId);
    _saveTasks();
    NotificationService.instance.cancelForTask(taskId);
    notifyListeners();
  }

  void toggleTaskStatus(Task task) {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index].status = _tasks[index].status == TaskStatus.completed
          ? TaskStatus.pending
          : TaskStatus.completed;
      _saveTasks();
      NotificationService.instance.cancelForTask(task.id);
      if (_remindersEnabled) NotificationService.instance.scheduleForTask(task);
      notifyListeners();
    }
  }

  // Statistics
  int get totalTasks => _tasks.length;
  int get completedTasks => _tasks.where((t) => t.status == TaskStatus.completed).length;
  int get pendingTasks => _tasks.where((t) => t.status == TaskStatus.pending).length;
  int get overdueTasks => _tasks.where((t) {
    if (t.dueDate == null || t.status == TaskStatus.completed) return false;
    return t.dueDate!.isBefore(DateTime.now());
  }).length;

  double get completionPercentage {
    if (_tasks.isEmpty) return 0;
    return completedTasks / _tasks.length;
  }

  List<Task> getTasksBySubject(String subjectId) {
    return _tasks.where((t) => t.subjectId == subjectId).toList();
  }

  List<Task> searchTasks(String query) {
    if (query.isEmpty) return _tasks;
    return _tasks.where((t) {
      return t.title.toLowerCase().contains(query.toLowerCase()) ||
          (t.description?.toLowerCase().contains(query.toLowerCase()) ?? false);
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
      default:
        return _tasks;
    }
  }
}