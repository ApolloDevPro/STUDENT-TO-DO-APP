enum TaskPriority { low, medium, high }
enum TaskStatus { pending, inProgress, completed }

enum TaskSortMode { manual, dueDate, priority, createdAt }

class Task {
  final String id;
  String title;
  String? description;
  String? subjectId;
  TaskPriority priority;
  TaskStatus status;
  DateTime createdAt;
  DateTime? dueDate;
  bool isAssignment;
  DateTime updatedAt;

  Task({
    required this.id,
    required this.title,
    this.description,
    this.subjectId,
    this.priority = TaskPriority.medium,
    this.status = TaskStatus.pending,
    required this.createdAt,
    this.dueDate,
    this.isAssignment = false,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'subjectId': subjectId,
    'priority': priority.index,
    'status': status.index,
    'createdAt': createdAt.toIso8601String(),
    'dueDate': dueDate?.toIso8601String(),
    'isAssignment': isAssignment,
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Task.fromJson(Map<String, dynamic> json) {
    final createdAt = DateTime.parse(json['createdAt'] as String);
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      subjectId: json['subjectId'] as String?,
      priority: TaskPriority.values[json['priority'] as int],
      status: TaskStatus.values[json['status'] as int],
      createdAt: createdAt,
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'] as String)
          : null,
      isAssignment: json['isAssignment'] as bool? ?? false,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : createdAt,
    );
  }

  /// Sorts a copy of [input] according to [mode]. Tasks without a due date are
  /// placed last when sorting by due date.
  static List<Task> sortBy(List<Task> input, TaskSortMode mode) {
    final list = List<Task>.of(input);
    switch (mode) {
      case TaskSortMode.manual:
        break;
      case TaskSortMode.dueDate:
        list.sort((a, b) {
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return a.dueDate!.compareTo(b.dueDate!);
        });
      case TaskSortMode.priority:
        list.sort((a, b) => b.priority.index.compareTo(a.priority.index));
      case TaskSortMode.createdAt:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return list;
  }
}
