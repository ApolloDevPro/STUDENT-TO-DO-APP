import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../models/task.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  void Function(String taskId)? _onTaskTap;

  Future<void> init({void Function(String taskId)? onTaskTap}) async {
    if (_initialized) return;
    _onTaskTap = onTaskTap;
    if (kIsWeb) {
      // Local notifications are not supported on web; skip init silently.
      _initialized = true;
      return;
    }
    tz_data.initializeTimeZones();

    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) _onTaskTap?.call(payload);
      },
    );
    _initialized = true;
    await _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    if (kIsWeb) return;
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  int _idFor(String taskId) => taskId.hashCode & 0x7FFFFFFF;

  /// Returns the moment the reminder for [task] should fire, or null if the
  /// task has no due date, is completed, or the reminder time has already
  /// passed. [leadMinutes] is how early the reminder should arrive.
  static DateTime? reminderDateTime(Task task, int leadMinutes) {
    if (task.dueDate == null) return null;
    if (task.status == TaskStatus.completed) return null;
    final reminder = task.dueDate!.subtract(Duration(minutes: leadMinutes));
    return reminder.isAfter(DateTime.now()) ? reminder : null;
  }

  Future<void> scheduleForTask(Task task, {int leadMinutes = 0}) async {
    if (kIsWeb || !_initialized) return;
    final reminder = reminderDateTime(task, leadMinutes);
    if (reminder == null) return;

    final scheduled = tz.TZDateTime.from(reminder, tz.local);

    await _plugin.zonedSchedule(
      id: _idFor(task.id),
      title: 'Task due: ${task.title}',
      body: 'Your task "${task.title}" is due.',
      scheduledDate: scheduled,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'task_reminders',
          'Task Reminders',
          channelDescription: 'Reminders for tasks that are due',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexact,
      payload: task.id,
    );
  }

  Future<void> cancelForTask(String taskId) async {
    if (kIsWeb || !_initialized) return;
    await _plugin.cancel(id: _idFor(taskId));
  }

  Future<void> cancelAll() async {
    if (kIsWeb || !_initialized) return;
    await _plugin.cancelAll();
  }
}
