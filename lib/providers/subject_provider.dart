import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/subject.dart';
import '../services/cloud_sync_service.dart';
import '../services/sync_merge.dart';

class SubjectProvider extends ChangeNotifier {
  final String? userId;
  List<Subject> _subjects = [];
  List<Subject> get subjects => List.unmodifiable(_subjects);

  bool _disposed = false;

  SubjectProvider({this.userId}) {
    loadSubjects();
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
      userId == null ? 'subjects_guest' : 'subjects_$userId';

  Future<void> loadSubjects() async {
    final prefs = await SharedPreferences.getInstance();
    final String? subjectsJson = prefs.getString(_storageKey);

    if (subjectsJson != null) {
      final List<dynamic> decoded = jsonDecode(subjectsJson);
      _subjects = decoded.map((s) => Subject.fromJson(s)).toList();
      _notify();
    }
    _pullAndMerge();
  }

  Future<void> _pullAndMerge() async {
    if (_disposed) return;
    final remoteJson = await CloudSyncService.instance.fetchSubjects();
    if (_disposed) return;

    final remote = remoteJson.map((m) => Subject.fromJson(m)).toList();
    final result = mergeSubjectLists(_subjects, remote);

    final changed = result.merged.length != _subjects.length ||
        List<bool>.generate(
          result.merged.length,
          (i) => result.merged[i] != _subjects[i],
        ).contains(true);

    _subjects = result.merged;
    for (final subject in result.toPush) {
      CloudSyncService.instance.pushSubject(subject);
    }

    if (changed) {
      _notify();
      await _saveSubjects();
    }
  }

  Future<void> _saveSubjects() async {
    final prefs = await SharedPreferences.getInstance();
    final String subjectsJson =
        jsonEncode(_subjects.map((s) => s.toJson()).toList());
    await prefs.setString(_storageKey, subjectsJson);
  }

  void addSubject(Subject subject) {
    subject.updatedAt = DateTime.now();
    _subjects.add(subject);
    _saveSubjects();
    CloudSyncService.instance.pushSubject(subject);
    _notify();
  }

  void updateSubject(Subject subject) {
    final index = _subjects.indexWhere((s) => s.id == subject.id);
    if (index != -1) {
      subject.updatedAt = DateTime.now();
      _subjects[index] = subject;
      _saveSubjects();
      CloudSyncService.instance.pushSubject(subject);
      _notify();
    }
  }

  void deleteSubject(String subjectId) {
    _subjects.removeWhere((s) => s.id == subjectId);
    _saveSubjects();
    CloudSyncService.instance.deleteRemoteSubject(subjectId);
    _notify();
  }

  Subject? getSubjectById(String id) {
    try {
      return _subjects.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }
}
