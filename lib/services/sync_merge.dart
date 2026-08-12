import '../models/subject.dart';
import '../models/task.dart';

class TaskMergeResult {
  final List<Task> merged;
  final List<Task> toPush;
  TaskMergeResult({required this.merged, required this.toPush});
}

class SubjectMergeResult {
  final List<Subject> merged;
  final List<Subject> toPush;
  SubjectMergeResult({required this.merged, required this.toPush});
}

/// Last-write-wins merge between the local task list and the remote (cloud)
/// task list, using each task's `updatedAt` timestamp.
///
/// Returns the merged list plus the subset that should be pushed back to the
/// cloud (items that are newer locally or missing remotely).
TaskMergeResult mergeTaskLists(List<Task> local, List<Task> remote) {
  final merged = List<Task>.of(local);
  final remoteById = {for (final t in remote) t.id: t};

  for (final remoteTask in remote) {
    final i = merged.indexWhere((t) => t.id == remoteTask.id);
    if (i == -1) {
      merged.add(remoteTask);
    } else if (remoteTask.updatedAt.isAfter(merged[i].updatedAt)) {
      merged[i] = remoteTask;
    }
  }

  final toPush = <Task>[];
  for (final localTask in merged) {
    final r = remoteById[localTask.id];
    if (r == null || localTask.updatedAt.isAfter(r.updatedAt)) {
      toPush.add(localTask);
    }
  }

  return TaskMergeResult(merged: merged, toPush: toPush);
}

/// Same last-write-wins merge for subjects.
SubjectMergeResult mergeSubjectLists(
  List<Subject> local,
  List<Subject> remote,
) {
  final merged = List<Subject>.of(local);
  final remoteById = {for (final s in remote) s.id: s};

  for (final remoteSubject in remote) {
    final i = merged.indexWhere((s) => s.id == remoteSubject.id);
    if (i == -1) {
      merged.add(remoteSubject);
    } else if (remoteSubject.updatedAt.isAfter(merged[i].updatedAt)) {
      merged[i] = remoteSubject;
    }
  }

  final toPush = <Subject>[];
  for (final localSubject in merged) {
    final r = remoteById[localSubject.id];
    if (r == null || localSubject.updatedAt.isAfter(r.updatedAt)) {
      toPush.add(localSubject);
    }
  }

  return SubjectMergeResult(merged: merged, toPush: toPush);
}
