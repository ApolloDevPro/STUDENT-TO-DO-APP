import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/subject.dart';
import '../models/task.dart';

/// Best-effort cloud sync layer backed by Cloud Firestore.
///
/// Data is still stored locally in `shared_preferences` (so the app works
/// offline), and this service mirrors changes to Firestore under
/// `users/{uid}/tasks` and `users/{uid}/subjects`. A merge on startup (see
/// `sync_merge.dart`) reconciles the two sides using each document's
/// `updatedAt` timestamp.
class CloudSyncService {
  CloudSyncService._();
  static final CloudSyncService instance = CloudSyncService._();

  String? _uid;
  bool get isEnabled => _uid != null;

  /// Point the service at the signed-in user. Pass `null` when signed out.
  void bindUser(String? uid) => _uid = uid;

  CollectionReference<Map<String, dynamic>> get _tasks =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(_uid!)
          .collection('tasks');

  CollectionReference<Map<String, dynamic>> get _subjects =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(_uid!)
          .collection('subjects');

  Future<void> pushTask(Task task) async {
    if (!isEnabled) return;
    try {
      await _tasks.doc(task.id).set(task.toJson());
    } catch (_) {
      // Offline or rules error: local copy remains the source of truth.
    }
  }

  Future<void> deleteRemoteTask(String taskId) async {
    if (!isEnabled) return;
    try {
      await _tasks.doc(taskId).delete();
    } catch (_) {}
  }

  Future<void> pushSubject(Subject subject) async {
    if (!isEnabled) return;
    try {
      await _subjects.doc(subject.id).set(subject.toJson());
    } catch (_) {}
  }

  Future<void> deleteRemoteSubject(String subjectId) async {
    if (!isEnabled) return;
    try {
      await _subjects.doc(subjectId).delete();
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> fetchTasks() async {
    if (!isEnabled) return [];
    try {
      final snap = await _tasks.get();
      return snap.docs.map((d) => d.data()).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchSubjects() async {
    if (!isEnabled) return [];
    try {
      final snap = await _subjects.get();
      return snap.docs.map((d) => d.data()).toList();
    } catch (_) {
      return [];
    }
  }
}
