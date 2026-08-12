import 'package:firebase_core/firebase_core.dart';
import 'theme/custom_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/task_provider.dart';
import 'providers/subject_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/task_detail_screen.dart';
import 'services/cloud_sync_service.dart';
import 'services/notification_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService.instance.init(onTaskTap: _openTaskFromNotification);
  runApp(const StudentTodoApp());
}

void _openTaskFromNotification(String taskId) {
  final context = navigatorKey.currentContext;
  if (context == null) return;
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => TaskDetailScreen(taskId: taskId)),
  );
}

class StudentTodoApp extends StatelessWidget {
  const StudentTodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProxyProvider<AuthProvider, TaskProvider>(
          create: (_) => TaskProvider(),
          update: (_, auth, _) {
            CloudSyncService.instance.bindUser(auth.currentUser?.uid);
            return TaskProvider(userId: auth.currentUser?.uid);
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, SubjectProvider>(
          create: (_) => SubjectProvider(),
          update: (_, auth, _) {
            CloudSyncService.instance.bindUser(auth.currentUser?.uid);
            return SubjectProvider(userId: auth.currentUser?.uid);
          },
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) => MaterialApp(
          title: 'Student To-Do App',
          debugShowCheckedModeBanner: false,
          navigatorKey: navigatorKey,
          themeMode: themeProvider.themeMode,
          theme: CustomTheme.lightTheme,
          darkTheme: CustomTheme.darkTheme,
          home: const AuthGate(),
        ),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return StreamBuilder(
      stream: authProvider.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          return const MainScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
