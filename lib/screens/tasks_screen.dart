import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../providers/subject_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/fade_in.dart';
import '../widgets/glass_card.dart';
import '../widgets/responsive_scaffold.dart';
import '../widgets/task_dialog.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  String _filter = 'All';
  String? _subjectFilter;
  TaskSortMode _sortMode = TaskSortMode.manual;

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: 'My Tasks',
      actions: [
        PopupMenuButton<TaskSortMode>(
          icon: const Icon(Icons.sort),
          tooltip: 'Sort tasks',
          onSelected: (value) => setState(() => _sortMode = value),
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: TaskSortMode.manual,
              child: Text('Default order'),
            ),
            const PopupMenuItem(
              value: TaskSortMode.dueDate,
              child: Text('Due date (soonest first)'),
            ),
            const PopupMenuItem(
              value: TaskSortMode.priority,
              child: Text('Priority (highest first)'),
            ),
            const PopupMenuItem(
              value: TaskSortMode.createdAt,
              child: Text('Newest first'),
            ),
          ],
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.filter_list),
          onSelected: (value) => setState(() => _filter = value),
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'All', child: Text('All')),
            const PopupMenuItem(value: 'Pending', child: Text('Pending')),
            const PopupMenuItem(
                value: 'In Progress', child: Text('In Progress')),
            const PopupMenuItem(value: 'Completed', child: Text('Completed')),
            const PopupMenuItem(value: 'Assignments', child: Text('Assignments')),
            const PopupMenuItem(value: 'Today', child: Text('Due Today')),
            const PopupMenuItem(value: 'Upcoming', child: Text('Upcoming')),
          ],
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'tasksScreenFAB',
        onPressed: () => showTaskDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('New Task'),
      ),
      builder: (context, deviceType) => Consumer2<TaskProvider, SubjectProvider>(
        builder: (context, taskProvider, subjectProvider, child) {
          List<Task> filteredTasks =
              taskProvider.tasksForFilter(_filter);
          if (_subjectFilter != null) {
            filteredTasks =
                filteredTasks.where((t) => t.subjectId == _subjectFilter).toList();
          }
          filteredTasks = Task.sortBy(filteredTasks, _sortMode);

          return Column(
            children: [
              if (subjectProvider.subjects.isNotEmpty)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('All Subjects'),
                        selected: _subjectFilter == null,
                        onSelected: (_) => setState(() => _subjectFilter = null),
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
              Expanded(
                child: filteredTasks.isEmpty
                    ? const EmptyState(
                        icon: Icons.task_alt,
                        title: 'No tasks yet',
                        message:
                            'Your tasks will appear here. Tap "New Task" to add your first one.',
                      )
                    : _buildTaskList(filteredTasks, subjectProvider, deviceType),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTaskList(
    List<Task> tasks,
    SubjectProvider subjectProvider,
    DeviceType deviceType,
  ) {
    if (deviceType.isDesktop) {
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.6,
        ),
        itemCount: tasks.length,
        itemBuilder: (context, index) =>
            _buildTaskCard(tasks[index], subjectProvider, index),
      );
    }
    if (deviceType.isTablet) {
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.8,
        ),
        itemCount: tasks.length,
        itemBuilder: (context, index) =>
            _buildTaskCard(tasks[index], subjectProvider, index),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      itemBuilder: (context, index) =>
          _buildTaskCard(tasks[index], subjectProvider, index),
    );
  }

  Widget _buildTaskCard(Task task, SubjectProvider subjectProvider, int index) {
    final subject = subjectProvider.getSubjectById(task.subjectId ?? '');
    return FadeIn(
      delay: Duration(milliseconds: 40 * index),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: GlassCard(
          padding: EdgeInsets.zero,
          child: Dismissible(
            key: Key(task.id),
            direction: DismissDirection.endToStart,
            background: Container(
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (_) {
              final taskProvider =
                  Provider.of<TaskProvider>(context, listen: false);
              taskProvider.deleteTask(task.id);
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: const Text('Task deleted'),
                    action: SnackBarAction(
                      label: 'Undo',
                      onPressed: () => taskProvider.restoreTask(task),
                    ),
                  ),
                );
            },
            child: ListTile(
              leading: Checkbox(
                value: task.status == TaskStatus.completed,
                onChanged: (_) {
                  Provider.of<TaskProvider>(context, listen: false)
                      .toggleTaskStatus(task);
                },
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
                  if (task.status == TaskStatus.inProgress)
                    const Text(
                      'In progress',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  if (task.isAssignment)
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Assignment',
                        style:
                            TextStyle(fontSize: 11, color: Colors.deepPurple),
                      ),
                    ),
                  if (task.dueDate != null)
                    Text(
                      'Due: ${task.dueDate!.day}/${task.dueDate!.month}/${task.dueDate!.year}',
                      style: TextStyle(
                        fontSize: 12,
                        color: task.dueDate!.isBefore(DateTime.now())
                            ? Colors.red
                            : null,
                      ),
                    ),
                ],
              ),
              trailing: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: priorityColor(task.priority),
                  shape: BoxShape.circle,
                ),
              ),
              onTap: () => showTaskDialog(context, task: task),
            ),
          ),
        ),
      ),
    );
  }
}
