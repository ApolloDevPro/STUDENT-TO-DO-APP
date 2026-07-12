import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../providers/subject_provider.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  String _filter = 'All';
  String? _subjectFilter;

  @override
  Widget build(BuildContext context) {
    return Consumer2<TaskProvider, SubjectProvider>(
      builder: (context, taskProvider, subjectProvider, child) {
        List<Task> filteredTasks = taskProvider.tasksForFilter(_filter);

        // Apply subject filter
        if (_subjectFilter != null) {
          filteredTasks = filteredTasks.where((t) => t.subjectId == _subjectFilter).toList();
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('My Tasks'),
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.filter_list),
                onSelected: (value) => setState(() => _filter = value),
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'All', child: Text('All')),
                  const PopupMenuItem(value: 'Pending', child: Text('Pending')),
                  const PopupMenuItem(value: 'Completed', child: Text('Completed')),
                  const PopupMenuItem(value: 'Assignments', child: Text('Assignments')),
                  const PopupMenuItem(value: 'Today', child: Text('Due Today')),
                  const PopupMenuItem(value: 'Upcoming', child: Text('Upcoming')),
                ],
              ),
            ],
          ),
          body: Column(
            children: [
              // Subject filter chips
              if (subjectProvider.subjects.isNotEmpty)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('All Subjects'),
                        selected: _subjectFilter == null,
                        onSelected: (selected) {
                          setState(() => _subjectFilter = null);
                        },
                      ),
                      const SizedBox(width: 8),
                      ...subjectProvider.subjects.map((subject) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            avatar: CircleAvatar(
                              backgroundColor: subject.color,
                              radius: 8,
                            ),
                            label: Text(subject.name),
                            selected: _subjectFilter == subject.id,
                            onSelected: (selected) {
                              setState(() {
                                _subjectFilter = selected ? subject.id : null;
                              });
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),

              // Task list
              Expanded(
                child: filteredTasks.isEmpty
                    ? const Center(
                        child: Text('No tasks found'),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredTasks.length,
                        itemBuilder: (context, index) {
                          final task = filteredTasks[index];
                          final subject = subjectProvider.getSubjectById(task.subjectId ?? '');
                          return _buildTaskCard(context, task, subject, taskProvider);
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            heroTag: 'tasksScreenFAB',
            onPressed: () => _showTaskDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('New Task'),
          ),
        );
      },
    );
  }

  Widget _buildTaskCard(
    BuildContext context,
    Task task,
    dynamic subject,
    TaskProvider taskProvider,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: Key(task.id),
        direction: DismissDirection.endToStart,
        background: Container(
          color: Colors.red,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        onDismissed: (_) {
          taskProvider.deleteTask(task.id);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Task deleted')),
          );
        },
        child: ListTile(
          leading: Checkbox(
            value: task.status == TaskStatus.completed,
            onChanged: (_) => taskProvider.toggleTaskStatus(task),
          ),
          title: Text(
            task.title,
            style: TextStyle(
              decoration: task.status == TaskStatus.completed
                  ? TextDecoration.lineThrough
                  : null,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (subject != null)
                Text(
                  subject.name,
                  style: TextStyle(color: subject.color),
                ),
              if (task.isAssignment)
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Assignment',
                    style: TextStyle(fontSize: 11, color: Colors.deepPurple),
                  ),
                ),
              if (task.dueDate != null)
                Text(
                  'Due: ${task.dueDate!.day}/${task.dueDate!.month}/${task.dueDate!.year}',
                  style: TextStyle(
                    fontSize: 12,
                    color: task.dueDate!.isBefore(DateTime.now()) ? Colors.red : null,
                  ),
                ),
            ],
          ),
          trailing: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: _getPriorityColor(task.priority),
              shape: BoxShape.circle,
            ),
          ),
          onTap: () => _showTaskDialog(context, task: task),
        ),
      ),
    );
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return Colors.red;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.low:
        return Colors.green;
    }
  }

  void _showTaskDialog(BuildContext context, {Task? task}) {
    final titleController = TextEditingController(text: task?.title);
    final descController = TextEditingController(text: task?.description);
    DateTime? selectedDate = task?.dueDate;
    String? selectedSubjectId = task?.subjectId;
    TaskPriority selectedPriority = task?.priority ?? TaskPriority.medium;
    bool selectedIsAssignment = task?.isAssignment ?? false;

    showDialog(
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
                        const DropdownMenuItem(value: null, child: Text('No subject')),
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
                              color: _getPriorityColor(priority),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(priority.name[0].toUpperCase() + priority.name.substring(1)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() => selectedPriority = value!);
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
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate ?? DateTime.now(),
                      firstDate: DateTime.now(),
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

                final taskProvider = Provider.of<TaskProvider>(context, listen: false);

                if (task == null) {
                  taskProvider.addTask(Task(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: titleController.text.trim(),
                    description: descController.text.trim().isEmpty
                        ? null
                        : descController.text.trim(),
                    subjectId: selectedSubjectId,
                    priority: selectedPriority,
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
}