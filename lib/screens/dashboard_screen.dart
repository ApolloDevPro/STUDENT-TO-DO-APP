import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../providers/subject_provider.dart';
import '../providers/auth_provider.dart';
import '../models/task.dart';
import 'tasks_screen.dart';
import 'subjects_screen.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final message = authProvider.successMessage;
    if (message != null) {
      authProvider.clearSuccessMessage();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📚 Student Dashboard'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: TaskSearchDelegate(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer2<TaskProvider, SubjectProvider>(
        builder: (context, taskProvider, subjectProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back!',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You have ${taskProvider.pendingTasks} pending tasks',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'Total',
                        taskProvider.totalTasks.toString(),
                        Icons.list_alt,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'Completed',
                        taskProvider.completedTasks.toString(),
                        Icons.check_circle,
                        Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'Pending',
                        taskProvider.pendingTasks.toString(),
                        Icons.pending,
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'Overdue',
                        taskProvider.overdueTasks.toString(),
                        Icons.warning,
                        Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Overall Progress',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: taskProvider.completionPercentage,
                          minHeight: 10,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${(taskProvider.completionPercentage * 100).toInt()}% Complete',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickAction(
                        context,
                        'My Tasks',
                        Icons.task,
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const TasksScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildQuickAction(
                        context,
                        'Subjects',
                        Icons.school,
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SubjectsScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (taskProvider.tasks.isNotEmpty) ...[
                  Text(
                    'Recent Tasks',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  ...taskProvider.tasks.take(3).map((task) {
                    final subject = subjectProvider.getSubjectById(task.subjectId ?? '');
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: subject?.color ?? Colors.grey,
                          child: Icon(
                            task.status == TaskStatus.completed
                                ? Icons.check
                                : Icons.pending,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(task.title),
                        subtitle: Text(subject?.name ?? 'No subject'),
                        trailing: task.dueDate != null
                            ? Text(
                                '${task.dueDate!.day}/${task.dueDate!.month}',
                                style: TextStyle(
                                  color: task.dueDate!.isBefore(DateTime.now())
                                      ? Colors.red
                                      : null,
                                ),
                              )
                            : null,
                      ),
                    );
                  }),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(icon, size: 40, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 8),
              Text(label, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      ),
    );
  }
}

class TaskSearchDelegate extends SearchDelegate {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) => _buildResults(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildResults(context);

  Widget _buildResults(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final subjectProvider = Provider.of<SubjectProvider>(context, listen: false);
    final results = taskProvider.searchTasks(query);

    if (results.isEmpty) {
      return const Center(child: Text('No tasks found'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final task = results[index];
        final subject = subjectProvider.getSubjectById(task.subjectId ?? '');
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: subject?.color ?? Colors.grey,
            child: Icon(
              task.status == TaskStatus.completed ? Icons.check : Icons.pending,
              color: Colors.white,
            ),
          ),
          title: Text(task.title),
          subtitle: Text(subject?.name ?? 'No subject'),
          trailing: task.dueDate != null
              ? Text(
                  '${task.dueDate!.day}/${task.dueDate!.month}',
                  style: TextStyle(
                    color: task.dueDate!.isBefore(DateTime.now())
                        ? Colors.red
                        : null,
                  ),
                )
              : null,
          onTap: () {
            close(context, null);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TasksScreen()),
            );
          },
        );
      },
    );
  }
}