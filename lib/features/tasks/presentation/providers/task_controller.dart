import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../../../core/services/notification_service.dart';
import '../../domain/entities/task.dart';
import '../../domain/usecases/add_task.dart';
import '../../domain/usecases/delete_task.dart';
import '../../domain/usecases/get_tasks.dart';
import '../../domain/usecases/toggle_task.dart';

class TaskController extends ChangeNotifier {
  final GetTasks getTasksUseCase;
  final AddTask addTaskUseCase;
  final DeleteTask deleteTaskUseCase;
  final ToggleTask toggleTaskUseCase;

  List<Task> _tasks = [];
  String _filter = 'All';

  TaskController({
    required this.getTasksUseCase,
    required this.addTaskUseCase,
    required this.deleteTaskUseCase,
    required this.toggleTaskUseCase,
  });

  List<Task> get tasks {
    if (_filter == 'Completed') return _tasks.where((t) => t.done).toList();
    if (_filter == 'Pending') return _tasks.where((t) => !t.done).toList();
    return _tasks;
  }

  String get filter => _filter;

  Future<void> loadTasks() async {
    _tasks = await getTasksUseCase();
    debugPrint("✅ Loaded ${_tasks.length} tasks");
    for (var t in _tasks) {
      debugPrint("📌 ${t.title} | ${t.done}");
    }
    notifyListeners();
  }

  void setFilter(String value) {
    _filter = value;
    notifyListeners();
  }

  Future<void> addTask(Task task) async {
    await addTaskUseCase(task, _tasks);

    if (task.remind && task.reminderTime != null) {
      try {
        await NotificationService().scheduleNotification(
          id: task.hashCode,
          title: 'Task Reminder',
          body: task.title,
          scheduledTime: task.reminderTime!,
        );
      } catch (e) {
        debugPrint('⚠️ Error scheduling notification: $e');
      }
    }

    await loadTasks();
  }

  Future<void> toggleTask(int index) async {
    await toggleTaskUseCase(index, _tasks);
    await loadTasks();
  }

  Future<void> deleteTask(int index) async {
    await deleteTaskUseCase(index, _tasks);
    await loadTasks();
  }
}
