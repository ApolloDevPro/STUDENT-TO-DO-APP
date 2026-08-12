import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/task_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/fade_in.dart';
import '../widgets/responsive_scaffold.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final taskProvider = Provider.of<TaskProvider>(context);

    final user = authProvider.currentUser;
    final displayName = user?.displayName ?? 'No name';
    final email = user?.email ?? 'No email';

    return ResponsiveScaffold(
      title: 'Profile',
      builder: (context, _) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FadeIn(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 34, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  displayName,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  email,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FadeIn(
            delay: const Duration(milliseconds: 80),
            child: GlassCard(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.edit),
                    title: const Text('Edit display name'),
                    onTap: () => _showEditNameDialog(context, displayName),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.verified_user),
                    title: const Text('Change password'),
                    onTap: () => _showChangePasswordDialog(context),
                  ),
                  if (!authProvider.isEmailVerified) ...[
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.mark_email_read),
                      title: const Text('Verify email'),
                      subtitle: const Text('Send a verification link'),
                      onTap: () async {
                        final error =
                            await authProvider.sendEmailVerification();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              error ?? 'Verification email sent. Check your inbox.',
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                  const Divider(),
                  SwitchListTile(
                    secondary: const Icon(Icons.notifications),
                    title: const Text('Due-date reminders'),
                    value: taskProvider.remindersEnabled,
                    onChanged: (value) => taskProvider.setRemindersEnabled(value),
                  ),
                  ListTile(
                    leading: const Icon(Icons.alarm),
                    title: const Text('Reminder lead time'),
                    subtitle: Text(_leadTimeLabel(taskProvider.reminderLeadMinutes)),
                    onTap: () =>
                        _showLeadTimeDialog(context, taskProvider.reminderLeadMinutes),
                  ),
                  const Divider(),
                  SwitchListTile(
                    secondary: const Icon(Icons.dark_mode),
                    title: const Text('Dark theme'),
                    value: themeProvider.themeMode == ThemeMode.dark,
                    onChanged: (value) => themeProvider.setThemeMode(
                      value ? ThemeMode.dark : ThemeMode.light,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          FadeIn(
            delay: const Duration(milliseconds: 160),
            child: FilledButton.icon(
              onPressed: () async {
                await authProvider.signOut();
              },
              icon: const Icon(Icons.logout),
              label: const Text('Log Out'),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditNameDialog(BuildContext context, String currentName) {
    final controller = TextEditingController(text: currentName);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Display Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Display name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(ctx);
              await authProvider.updateDisplayName(name);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Display name updated')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final newPasswordController = TextEditingController();
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm new password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final newPassword = newPasswordController.text;
              if (newPassword.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('Password must be at least 6 characters'),
                  ),
                );
                return;
              }
              if (newPassword != confirmController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Passwords do not match')),
                );
                return;
              }
              Navigator.pop(ctx);
              final authProvider =
                  Provider.of<AuthProvider>(context, listen: false);
              final error = await authProvider.changePassword(newPassword);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(error ?? 'Password updated successfully'),
                ),
              );
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  String _leadTimeLabel(int minutes) {
    switch (minutes) {
      case 15:
        return '15 minutes before';
      case 60:
        return '1 hour before';
      case 180:
        return '3 hours before';
      case 1440:
        return '1 day before';
      case 10080:
        return '1 week before';
      default:
        return 'At the due time';
    }
  }

  void _showLeadTimeDialog(BuildContext context, int currentMinutes) {
    const options = <int>[0, 15, 60, 180, 1440, 10080];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reminder Lead Time'),
        content: RadioGroup<int>(
          groupValue: currentMinutes,
          onChanged: (value) {
            Navigator.pop(ctx);
            if (value != null) {
              Provider.of<TaskProvider>(context, listen: false)
                  .setReminderLeadMinutes(value);
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: options.map((minutes) {
              return RadioListTile<int>(
                title: Text(_leadTimeLabel(minutes)),
                value: minutes,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
