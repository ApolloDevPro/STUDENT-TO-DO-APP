import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/subject.dart';
import '../providers/subject_provider.dart';

class SubjectsScreen extends StatelessWidget {
  const SubjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Subjects'),
      ),
      body: Consumer<SubjectProvider>(
        builder: (context, subjectProvider, child) {
          if (subjectProvider.subjects.isEmpty) {
            return const Center(
              child: Text('No subjects yet. Add one!'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: subjectProvider.subjects.length,
            itemBuilder: (context, index) {
              final subject = subjectProvider.subjects[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: subject.color,
                    child: Text(
                      subject.code[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(subject.name),
                  subtitle: Text(subject.code),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      subjectProvider.deleteSubject(subject.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Subject deleted')),
                      );
                    },
                  ),
                  onTap: () => _showSubjectDialog(context, subject: subject),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'subjectsScreenFAB',
        onPressed: () => _showSubjectDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('New Subject'),
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

                final subjectProvider = Provider.of<SubjectProvider>(context, listen: false);

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