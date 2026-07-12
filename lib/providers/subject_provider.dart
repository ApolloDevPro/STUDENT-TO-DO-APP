import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/subject.dart';

class SubjectProvider with ChangeNotifier {
  final String? userId;
  List<Subject> _subjects = [];
  List<Subject> get subjects => _subjects;

  SubjectProvider({this.userId}) {
    loadSubjects();
  }

  String get _storageKey =>
      userId == null ? 'subjects_guest' : 'subjects_$userId';

  Future<void> loadSubjects() async {
    final prefs = await SharedPreferences.getInstance();
    final String? subjectsJson = prefs.getString(_storageKey);

    if (subjectsJson != null) {
      final List<dynamic> decoded = jsonDecode(subjectsJson);
      _subjects = decoded.map((s) => Subject.fromJson(s)).toList();
      notifyListeners();
    }
  }

  Future<void> _saveSubjects() async {
    final prefs = await SharedPreferences.getInstance();
    final String subjectsJson = jsonEncode(_subjects.map((s) => s.toJson()).toList());
    await prefs.setString(_storageKey, subjectsJson);
  }

  void addSubject(Subject subject) {
    _subjects.add(subject);
    _saveSubjects();
    notifyListeners();
  }

  void updateSubject(Subject subject) {
    final index = _subjects.indexWhere((s) => s.id == subject.id);
    if (index != -1) {
      _subjects[index] = subject;
      _saveSubjects();
      notifyListeners();
    }
  }

  void deleteSubject(String subjectId) {
    _subjects.removeWhere((s) => s.id == subjectId);
    _saveSubjects();
    notifyListeners();
  }

  Subject? getSubjectById(String id) {
    try {
      return _subjects.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }
}