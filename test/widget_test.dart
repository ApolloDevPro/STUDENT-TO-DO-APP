import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo_app/models/subject.dart';
import 'package:todo_app/models/task.dart';
import 'package:todo_app/providers/subject_provider.dart';
import 'package:todo_app/providers/task_provider.dart';

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
}
