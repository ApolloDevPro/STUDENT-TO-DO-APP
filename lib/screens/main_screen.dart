import 'package:flutter/material.dart';
import '../theme/custom_theme.dart';
import 'dashboard_screen.dart';
import 'subjects_screen.dart';
import 'tasks_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = [
    DashboardScreen(),
    TasksScreen(),
    SubjectsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: CustomTheme.gradientBackground(isDark: isDark),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: IndexedStack(
          index: _selectedIndex,
          children: _screens,
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) =>
              setState(() => _selectedIndex = index),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.task_outlined),
              selectedIcon: Icon(Icons.task),
              label: 'Tasks',
            ),
            NavigationDestination(
              icon: Icon(Icons.school_outlined),
              selectedIcon: Icon(Icons.school),
              label: 'Subjects',
            ),
          ],
        ),
      ),
    );
  }
}
