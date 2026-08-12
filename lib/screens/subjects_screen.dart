import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/subject.dart';
import '../providers/subject_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/fade_in.dart';
import '../widgets/empty_state.dart';
import '../widgets/responsive_scaffold.dart';

class SubjectsScreen extends StatelessWidget {
  const SubjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: 'My Subjects',
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'subjectsScreenFAB',
        onPressed: () => _showSubjectDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('New Subject'),
      ),
      builder: (context, deviceType) => Consumer<SubjectProvider>(
        builder: (context, subjectProvider, child) {
          if (subjectProvider.subjects.isEmpty) {
            return const EmptyState(
              icon: Icons.school_outlined,
              title: 'No subjects yet',
              message:
                  'Add your courses to organize tasks by subject. Tap "New Subject" to begin.',
            );
          }

          final subjects = subjectProvider.subjects;
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: deviceType.isDesktop
                  ? 4
                  : deviceType.isTablet
                      ? 3
                      : 1,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: deviceType.isMobile ? 4.5 : 2.4,
            ),
            itemCount: subjects.length,
            itemBuilder: (context, index) =>
                _buildSubjectCard(context, subjects[index], index),
          );
        },
      ),
    );
  }

  Widget _buildSubjectCard(
    BuildContext context,
    Subject subject,
    int index,
  ) {
    return FadeIn(
      delay: Duration(milliseconds: 40 * index),
      child: GlassCard(
        padding: EdgeInsets.zero,
        child: ListTile(
          leading: Hero(
            tag: 'subject-${subject.id}',
            child: CircleAvatar(
              backgroundColor: subject.color,
              child: Text(
                subject.code.isNotEmpty
                    ? subject.code[0].toUpperCase()
                    : subject.name.isNotEmpty
                        ? subject.name[0].toUpperCase()
                        : '?',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
          title: Text(subject.name),
          subtitle: Text(subject.code),
          trailing: IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _confirmDelete(context, subject),
          ),
          onTap: () => _showSubjectDialog(context, subject: subject),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Subject subject) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${subject.name}?'),
        content: const Text(
          'This removes the subject. Tasks already linked to it will stay, '
          'but will no longer be grouped under this subject.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final provider =
                  Provider.of<SubjectProvider>(ctx, listen: false);
              provider.deleteSubject(subject.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Subject deleted')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showSubjectDialog(BuildContext context, {Subject? subject}) {
    final nameController = TextEditingController(text: subject?.name);
    final codeController = TextEditingController(text: subject?.code);
    Color selectedColor = subject?.color ?? Colors.blue;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(subject == null ? 'New Subject' : 'Edit Subject'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Subject Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: codeController,
                decoration: const InputDecoration(
                  labelText: 'Subject Code (e.g., CS101)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Choose a color:'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  Colors.red,
                  Colors.blue,
                  Colors.green,
                  Colors.purple,
                  Colors.orange,
                  Colors.teal,
                  Colors.pink,
                  Colors.indigo,
                ].map((color) {
                  return InkWell(
                    onTap: () {
                      setDialogState(() => selectedColor = color);
                    },
                    child: CircleAvatar(
                      backgroundColor: color,
                      radius: 16,
                      child: selectedColor == color
                          ? const Icon(Icons.check, color: Colors.white, size: 16)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty ||
                    codeController.text.trim().isEmpty) {
                  return;
                }

                final subjectProvider =
                    Provider.of<SubjectProvider>(context, listen: false);

                if (subject == null) {
                  subjectProvider.addSubject(Subject(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameController.text.trim(),
                    code: codeController.text.trim(),
                    colorValue: selectedColor.toARGB32(),
                  ));
                } else {
                  subject.name = nameController.text.trim();
                  subject.code = codeController.text.trim();
                  subject.colorValue = selectedColor.toARGB32();
                  subjectProvider.updateSubject(subject);
                }

                Navigator.pop(ctx);
              },
              child: Text(subject == null ? 'Add' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }
}
