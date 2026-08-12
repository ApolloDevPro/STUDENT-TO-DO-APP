import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo_app/models/subject.dart';
import 'package:todo_app/models/task.dart';
import 'package:todo_app/providers/subject_provider.dart';
import 'package:todo_app/providers/task_provider.dart';
import 'package:todo_app/services/notification_service.dart';
import 'package:todo_app/services/sync_merge.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('TaskProvider', () {
    test('addTask increases total and stores the task', () {
      final provider = TaskProvider(userId: 'u1');
      provider.addTask(Task(id: '1', title: 'Test', createdAt: DateTime.now()));

      expect(provider.totalTasks, 1);
      expect(provider.tasks.first.title, 'Test');
    });

    test('toggleTaskStatus flips completion state', () {
      final provider = TaskProvider(userId: 'u1');
      final task = Task(id: '1', title: 'Test', createdAt: DateTime.now());
      provider.addTask(task);

      provider.toggleTaskStatus(task);
      expect(provider.completedTasks, 1);

      provider.toggleTaskStatus(task);
      expect(provider.completedTasks, 0);
    });

    test('deleteTask removes the task', () {
      final provider = TaskProvider(userId: 'u1');
      provider.addTask(Task(id: '1', title: 'Test', createdAt: DateTime.now()));
      provider.deleteTask('1');

      expect(provider.totalTasks, 0);
    });

    test('restoreTask re-adds a deleted task', () {
      final provider = TaskProvider(userId: 'u1');
      final task = Task(id: '1', title: 'Test', createdAt: DateTime.now());
      provider.addTask(task);
      provider.deleteTask(task.id);

      expect(provider.totalTasks, 0);

      provider.restoreTask(task);
      expect(provider.totalTasks, 1);
      expect(provider.tasks.first.id, '1');
    });

    test('overdueTasks counts only incomplete past-due tasks', () {
      final provider = TaskProvider(userId: 'u1');
      provider.addTask(Task(
        id: '1',
        title: 'Overdue',
        createdAt: DateTime.now(),
        dueDate: DateTime.now().subtract(const Duration(days: 1)),
      ));
      provider.addTask(Task(
        id: '2',
        title: 'Done overdue',
        createdAt: DateTime.now(),
        dueDate: DateTime.now().subtract(const Duration(days: 1)),
        status: TaskStatus.completed,
      ));
      provider.addTask(Task(
        id: '3',
        title: 'Future',
        createdAt: DateTime.now(),
        dueDate: DateTime.now().add(const Duration(days: 1)),
      ));

      expect(provider.overdueTasks, 1);
    });

    test('scopes data per user', () {
      final alice = TaskProvider(userId: 'alice');
      final bob = TaskProvider(userId: 'bob');

      alice.addTask(Task(id: '1', title: 'Alice task', createdAt: DateTime.now()));

      expect(alice.totalTasks, 1);
      expect(bob.totalTasks, 0);
    });

    test('filters by In Progress status', () {
      final provider = TaskProvider(userId: 'u1');
      provider.addTask(Task(
        id: '1',
        title: 'Working',
        createdAt: DateTime.now(),
        status: TaskStatus.inProgress,
      ));
      provider.addTask(Task(id: '2', title: 'Pending', createdAt: DateTime.now()));

      final inProgress = provider.tasksForFilter('In Progress');
      expect(inProgress.length, 1);
      expect(inProgress.first.id, '1');
    });
  });

  group('SubjectProvider', () {
    test('addSubject adds and retrieves by id', () {
      final provider = SubjectProvider(userId: 'u1');
      provider.addSubject(Subject(
        id: '1',
        name: 'Math',
        code: 'M101',
        colorValue: 0xFF0000FF,
      ));

      expect(provider.subjects.length, 1);
      expect(provider.getSubjectById('1')?.name, 'Math');
    });

    test('deleteSubject removes the subject', () {
      final provider = SubjectProvider(userId: 'u1');
      provider.addSubject(Subject(
        id: '1',
        name: 'Math',
        code: 'M101',
        colorValue: 0xFF0000FF,
      ));
      provider.deleteSubject('1');

      expect(provider.subjects.length, 0);
    });
  });

  group('Model serialization', () {
    test('Task JSON round-trips including updatedAt', () {
      final task = Task(
        id: 'abc',
        title: 'Read chapter 5',
        description: 'Pages 120-150',
        subjectId: 's1',
        priority: TaskPriority.high,
        status: TaskStatus.inProgress,
        createdAt: DateTime(2026, 1, 1, 9),
        dueDate: DateTime(2026, 1, 15, 23, 59),
        isAssignment: true,
        updatedAt: DateTime(2026, 1, 2, 10, 30),
      );

      final restored = Task.fromJson(task.toJson());
      expect(restored.id, task.id);
      expect(restored.title, task.title);
      expect(restored.description, task.description);
      expect(restored.subjectId, task.subjectId);
      expect(restored.priority, TaskPriority.high);
      expect(restored.status, TaskStatus.inProgress);
      expect(restored.createdAt, task.createdAt);
      expect(restored.dueDate, task.dueDate);
      expect(restored.isAssignment, true);
      expect(restored.updatedAt, task.updatedAt);
    });

    test('Task JSON without updatedAt falls back to createdAt', () {
      final createdAt = DateTime(2026, 3, 1);
      final json = {
        'id': 'old',
        'title': 'Legacy',
        'description': null,
        'subjectId': null,
        'priority': 1,
        'status': 0,
        'createdAt': createdAt.toIso8601String(),
        'dueDate': null,
        'isAssignment': false,
      };
      final restored = Task.fromJson(json);
      expect(restored.updatedAt, createdAt);
    });

    test('Subject JSON round-trips including updatedAt', () {
      final subject = Subject(
        id: 's1',
        name: 'Physics',
        code: 'PH201',
        colorValue: 0xFF00FF00,
        updatedAt: DateTime(2026, 5, 5),
      );
      final restored = Subject.fromJson(subject.toJson());
      expect(restored.id, 's1');
      expect(restored.name, 'Physics');
      expect(restored.code, 'PH201');
      expect(restored.colorValue, 0xFF00FF00);
      expect(restored.updatedAt, subject.updatedAt);
    });
  });

  group('Sync merge', () {
    test('mergeTaskLists adds remote-only tasks', () {
      final local = [
        Task(id: 'a', title: 'Local', createdAt: DateTime(2026, 1, 1)),
      ];
      final remote = [
        Task(id: 'b', title: 'Remote', createdAt: DateTime(2026, 1, 1)),
      ];

      final result = mergeTaskLists(local, remote);
      expect(result.merged.length, 2);
      expect(result.toPush, contains(local.first));
    });

    test('mergeTaskLists keeps the newer version on conflict', () {
      final older = Task(
        id: 'a',
        title: 'Old title',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      final newer = Task(
        id: 'a',
        title: 'New title',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 2),
      );

      final localWins = mergeTaskLists([newer], [older]);
      expect(localWins.merged.first.title, 'New title');
      expect(localWins.toPush, [newer]);

      final remoteWins = mergeTaskLists([older], [newer]);
      expect(remoteWins.merged.first.title, 'New title');
      expect(remoteWins.toPush, isEmpty);
    });

    test('mergeSubjectLists reconciles remote subjects', () {
      final local = [
        Subject(
          id: 'a',
          name: 'Local sub',
          code: 'L',
          colorValue: 1,
          updatedAt: DateTime(2026, 1, 1),
        ),
      ];
      final remote = [
        Subject(
          id: 'b',
          name: 'Remote sub',
          code: 'R',
          colorValue: 2,
          updatedAt: DateTime(2026, 1, 2),
        ),
      ];

      final result = mergeSubjectLists(local, remote);
      expect(result.merged.length, 2);
      expect(result.toPush.length, 1);
      expect(result.toPush.first.id, 'a');
    });
  });

  group('Task sorting', () {
    test('sortBy due date puts nulls last', () {
      final tasks = [
        Task(id: '1', title: 'No due', createdAt: DateTime(2026, 1, 1)),
        Task(
          id: '2',
          title: 'Later',
          createdAt: DateTime(2026, 1, 1),
          dueDate: DateTime(2026, 3, 1),
        ),
        Task(
          id: '3',
          title: 'Sooner',
          createdAt: DateTime(2026, 1, 1),
          dueDate: DateTime(2026, 2, 1),
        ),
      ];

      final sorted = Task.sortBy(tasks, TaskSortMode.dueDate);
      expect(sorted.map((t) => t.id).toList(), ['3', '2', '1']);
    });

    test('sortBy priority puts high first', () {
      final tasks = [
        Task(
          id: '1',
          title: 'Low',
          createdAt: DateTime(2026, 1, 1),
          priority: TaskPriority.low,
        ),
        Task(
          id: '2',
          title: 'High',
          createdAt: DateTime(2026, 1, 1),
          priority: TaskPriority.high,
        ),
        Task(
          id: '3',
          title: 'Medium',
          createdAt: DateTime(2026, 1, 1),
          priority: TaskPriority.medium,
        ),
      ];

      final sorted = Task.sortBy(tasks, TaskSortMode.priority);
      expect(sorted.map((t) => t.id).toList(), ['2', '3', '1']);
    });

    test('sortBy createdAt puts newest first', () {
      final tasks = [
        Task(id: '1', title: 'Old', createdAt: DateTime(2026, 1, 1)),
        Task(id: '2', title: 'New', createdAt: DateTime(2026, 2, 1)),
      ];

      final sorted = Task.sortBy(tasks, TaskSortMode.createdAt);
      expect(sorted.map((t) => t.id).toList(), ['2', '1']);
    });

    test('sortBy manual preserves input order', () {
      final tasks = [
        Task(id: '2', title: 'Second', createdAt: DateTime(2026, 2, 1)),
        Task(id: '1', title: 'First', createdAt: DateTime(2026, 1, 1)),
      ];

      final sorted = Task.sortBy(tasks, TaskSortMode.manual);
      expect(sorted.map((t) => t.id).toList(), ['2', '1']);
    });
  });

  group('Reminder timing', () {
    test('reminder fires at due date minus lead time', () {
      final due = DateTime(2027, 6, 1, 10);
      final task = Task(
        id: '1',
        title: 'Exam',
        createdAt: DateTime.now(),
        dueDate: due,
      );

      final reminder = NotificationService.reminderDateTime(task, 60);
      expect(reminder, due.subtract(const Duration(minutes: 60)));
    });

    test('reminder is null for completed tasks', () {
      final task = Task(
        id: '1',
        title: 'Done',
        createdAt: DateTime.now(),
        dueDate: DateTime.now().add(const Duration(days: 1)),
        status: TaskStatus.completed,
      );

      expect(NotificationService.reminderDateTime(task, 0), isNull);
    });

    test('reminder is null when the time already passed', () {
      final task = Task(
        id: '1',
        title: 'Past',
        createdAt: DateTime.now(),
        dueDate: DateTime.now().subtract(const Duration(days: 1)),
      );

      expect(NotificationService.reminderDateTime(task, 0), isNull);
    });

    test('reminder is null when lead time overshoots into the past', () {
      final task = Task(
        id: '1',
        title: 'Soon',
        createdAt: DateTime.now(),
        dueDate: DateTime.now().add(const Duration(minutes: 10)),
      );

      expect(NotificationService.reminderDateTime(task, 60), isNull);
    });
  });
}
