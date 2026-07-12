enum TaskPriority { low, medium, high }
enum TaskStatus { pending, inProgress, completed }

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
  });

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
  };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id: json['id'],
    title: json['title'],
    description: json['description'],
    subjectId: json['subjectId'],
    priority: TaskPriority.values[json['priority']],
    status: TaskStatus.values[json['status']],
    createdAt: DateTime.parse(json['createdAt']),
    dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
    isAssignment: json['isAssignment'] ?? false,
  );
}