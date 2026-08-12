import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/subject_provider.dart';
import '../providers/task_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/glass_card.dart';
import '../widgets/responsive_scaffold.dart';
import '../widgets/task_dialog.dart';

class TaskDetailScreen extends StatelessWidget {
  final String taskId;
  const TaskDetailScreen({super.key, required this.taskId});

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, _) {
        final task = taskProvider.getTaskById(taskId);
        return ResponsiveScaffold(
          title: task?.title ?? 'Task',
          builder: (context, deviceType) {
            if (task == null) {
              return const EmptyState(
                icon: Icons.task_alt,
                title: 'Task not found',
                message: 'This task may have been deleted on another device.',
              );
            }
            return _TaskDetails(task: task);
          },
        );
      },
    );
  }
}

class _TaskDetails extends StatelessWidget {
  final Task task;
  const _TaskDetails({required this.task});

  @override
  Widget build(BuildContext context) {
    final subjectProvider = Provider.of<SubjectProvider>(context);
    final subject = subjectProvider.getSubjectById(task.subjectId ?? '');
    final overdue = task.dueDate != null &&
        task.dueDate!.isBefore(DateTime.now()) &&
        task.status != TaskStatus.completed;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              if (task.description != null &&
                  task.description!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(task.description!),
              ],
              const SizedBox(height: 20),
              _InfoRow(label: 'Subject', value: subject?.name ?? 'No subject'),
              _InfoRow(
                label: 'Status',
                value: taskStatusLabel(task.status),
              ),
              _InfoRow(
                label: 'Priority',
                value: task.priority.name[0].toUpperCase() +
                    task.priority.name.substring(1),
              ),
              _InfoRow(
                label: 'Due',
                value: task.dueDate == null
                    ? 'No due date'
                    : '${task.dueDate!.day}/${task.dueDate!.month}/${task.dueDate!.year}',
                valueColor: overdue ? Colors.red : null,
              ),
              if (task.isAssignment) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Assignment',
                    style: TextStyle(color: Colors.deepPurple),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          icon: const Icon(Icons.edit),
          label: const Text('Edit Task'),
          onPressed: () => showTaskDialog(context, task: task),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.delete),
          label: const Text('Delete Task'),
          style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
          onPressed: () {
            Provider.of<TaskProvider>(context, listen: false)
                .deleteTask(task.id);
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _InfoRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.hintColor),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(color: valueColor),
            ),
          ),
        ],
      ),
    );
  }
}
