import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:todo_list_app/core/services/foreground_service.dart';

import 'core/services/notification_service.dart';
import 'features/tasks/presentation/pages/todo_home_page.dart';
import 'features/tasks/presentation/providers/task_controller.dart';
import 'features/tasks/data/datasources/local_task_datasource.dart';
import 'features/tasks/domain/usecases/add_task.dart';
import 'features/tasks/domain/usecases/delete_task.dart';
import 'features/tasks/domain/usecases/get_tasks.dart';
import 'features/tasks/domain/usecases/toggle_task.dart';
import 'features/tasks/domain/entities/task.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Africa/Casablanca'));
  await NotificationService().init();
  await ForegroundService().initialize();
  await ForegroundService().startForegroundService();

  // Initialize clean architecture dependencies
  final datasource = LocalTaskDatasource();
  final controller = TaskController(
    getTasksUseCase: GetTasks(datasource),
    addTaskUseCase: AddTask(datasource),
    deleteTaskUseCase: DeleteTask(datasource),
    toggleTaskUseCase: ToggleTask(datasource),
  );

  /*  // 🔁 TEMP: Add dummy task to confirm it's working
  await controller.addTask(Task(
    title: '👋 Hello Clean Architecture!',
    done: false,
    timestamp: DateTime.now(),
    remind: false,
    reminderTime: null,
  )); */

  runApp(
    ChangeNotifierProvider(
      create: (_) => controller..loadTasks(),
      child: const ToDoApp(),
    ),
  );
}

class ToDoApp extends StatelessWidget {
  const ToDoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'To-Do List',
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const ToDoHomePage(),
    );
  }
}
