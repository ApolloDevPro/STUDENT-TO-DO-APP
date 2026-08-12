import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/subject_provider.dart';
import '../providers/task_provider.dart';
import '../utils/ids.dart';

Color priorityColor(TaskPriority priority) {
  switch (priority) {
    case TaskPriority.high:
      return Colors.red;
    case TaskPriority.medium:
      return Colors.orange;
    case TaskPriority.low:
      return Colors.green;
  }
}

String taskStatusLabel(TaskStatus status) {
  switch (status) {
    case TaskStatus.pending:
      return 'Pending';
    case TaskStatus.inProgress:
      return 'In Progress';
    case TaskStatus.completed:
      return 'Completed';
  }
}

/// Shared create/edit task dialog, used from the Tasks screen, the dashboard
/// search results, and the task detail screen opened from a notification.
Future<void> showTaskDialog(BuildContext context, {Task? task}) async {
  final titleController = TextEditingController(text: task?.title);
  final descController = TextEditingController(text: task?.description);
  DateTime? selectedDate = task?.dueDate;
  String? selectedSubjectId = task?.subjectId;
  TaskPriority selectedPriority = task?.priority ?? TaskPriority.medium;
  TaskStatus selectedStatus = task?.status ?? TaskStatus.pending;
  bool selectedIsAssignment = task?.isAssignment ?? false;

  await showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Text(task == null ? 'New Task' : 'Edit Task'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              Consumer<SubjectProvider>(
                builder: (context, subjectProvider, child) {
                  return DropdownButtonFormField<String>(
                    initialValue: selectedSubjectId,
                    decoration: const InputDecoration(
                      labelText: 'Subject',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('No subject'),
                      ),
                      ...subjectProvider.subjects.map((subject) {
                        return DropdownMenuItem(
                          value: subject.id,
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: subject.color,
                                radius: 8,
                              ),
                              const SizedBox(width: 8),
                              Text(subject.name),
                            ],
                          ),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setDialogState(() => selectedSubjectId = value);
                    },
                  );
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<TaskPriority>(
                initialValue: selectedPriority,
                decoration: const InputDecoration(
                  labelText: 'Priority',
                  border: OutlineInputBorder(),
                ),
                items: TaskPriority.values.map((priority) {
                  return DropdownMenuItem(
                    value: priority,
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: priorityColor(priority),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          priority.name[0].toUpperCase() +
                              priority.name.substring(1),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setDialogState(() => selectedPriority = value!);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<TaskStatus>(
                initialValue: selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                items: TaskStatus.values.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(taskStatusLabel(status)),
                  );
                }).toList(),
                onChanged: (value) {
                  setDialogState(() => selectedStatus = value!);
                },
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Is an assignment'),
                value: selectedIsAssignment,
                onChanged: (value) {
                  setDialogState(() => selectedIsAssignment = value);
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setDialogState(() => selectedDate = picked);
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Due Date',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          selectedDate == null
                              ? 'No due date'
                              : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                        ),
                      ),
                    ),
                  ),
                  if (selectedDate != null)
                    TextButton(
                      onPressed: () =>
                          setDialogState(() => selectedDate = null),
                      child: const Text('Clear'),
                    ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (titleController.text.trim().isEmpty) return;

              final taskProvider =
                  Provider.of<TaskProvider>(context, listen: false);

              if (task == null) {
                taskProvider.addTask(Task(
                  id: generateId(),
                  title: titleController.text.trim(),
                  description: descController.text.trim().isEmpty
                      ? null
                      : descController.text.trim(),
                  subjectId: selectedSubjectId,
                  priority: selectedPriority,
                  status: selectedStatus,
                  createdAt: DateTime.now(),
                  dueDate: selectedDate,
                  isAssignment: selectedIsAssignment,
                ));
              } else {
                task.title = titleController.text.trim();
                task.description = descController.text.trim().isEmpty
                    ? null
                    : descController.text.trim();
                task.subjectId = selectedSubjectId;
                task.priority = selectedPriority;
                task.status = selectedStatus;
                task.dueDate = selectedDate;
                task.isAssignment = selectedIsAssignment;
                taskProvider.updateTask(task);
              }

              Navigator.pop(ctx);
            },
            child: Text(task == null ? 'Add' : 'Save'),
          ),
        ],
      ),
    ),
  );
}
