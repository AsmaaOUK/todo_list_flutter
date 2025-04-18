import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones(); // <-- THIS MUST BE HERE and called early
  tz.setLocalLocation(
      tz.getLocation('Africa/Casablanca')); // <-- Use your timezone
  await NotificationService().init();
  runApp(const ToDoApp());
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

class ToDoHomePage extends StatefulWidget {
  const ToDoHomePage({super.key});

  @override
  State<ToDoHomePage> createState() => _ToDoHomePageState();
}

class _ToDoHomePageState extends State<ToDoHomePage> {
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  List<Map<String, dynamic>> _tasks = [];
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  void _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String? tasksString = prefs.getString('tasks');
    if (tasksString != null) {
      setState(() {
        _tasks = List<Map<String, dynamic>>.from(json.decode(tasksString));
      });
    }
  }

  void _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tasks', json.encode(_tasks));
  }

  void _addTask(String title, bool remind, TimeOfDay? time) async {
    if (title.isEmpty) return;
    DateTime now = DateTime.now();
    DateTime? scheduled;
    if (remind && time != null) {
      scheduled =
          DateTime(now.year, now.month, now.day, time.hour, time.minute);
      if (scheduled.isBefore(now))
        scheduled = scheduled.add(const Duration(days: 1));
      await _scheduleNotification(title, scheduled);
    }
    setState(() {
      _tasks.add({
        'title': title,
        'done': false,
        'timestamp': now.toIso8601String(),
        'remind': remind,
        'reminderTime': scheduled?.toIso8601String(),
      });
    });
    _saveTasks();
  }

  void _toggleTask(int index) {
    setState(() {
      _tasks[index]['done'] = !_tasks[index]['done'];
    });
    _saveTasks();
  }

  void _deleteTask(int index) {
    setState(() {
      _tasks.removeAt(index);
    });
    _saveTasks();
  }

  List<Map<String, dynamic>> get _filteredTasks {
    if (_filter == 'Completed') {
      return _tasks.where((task) => task['done']).toList();
    } else if (_filter == 'Pending') {
      return _tasks.where((task) => !task['done']).toList();
    }
    return _tasks;
  }

  Future<void> _scheduleNotification(String title, DateTime time) async {
    final scheduledDate = tz.TZDateTime.from(time, tz.local);

    final android = AndroidNotificationDetails(
      'todo_channel',
      'To-Do Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    final details = NotificationDetails(android: android);

    await _notifications.zonedSchedule(
      scheduledDate.hashCode,
      'Reminder',
      title,
      scheduledDate,
      details,
      matchDateTimeComponents: DateTimeComponents.time,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  void _showAddTaskDialog() {
    String title = '';
    bool remind = false;
    TimeOfDay? selectedTime;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Task'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Task title'),
                onChanged: (value) => title = value,
              ),
              SwitchListTile(
                value: remind,
                title: const Text('Remind me'),
                onChanged: (val) => setState(() => remind = val),
              ),
              if (remind)
                TextButton.icon(
                  icon: const Icon(Icons.access_time),
                  label: Text(selectedTime == null
                      ? 'Pick time'
                      : selectedTime?.format(context) ?? 'Pick time'),
                  onPressed: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (picked != null) setState(() => selectedTime = picked);
                  },
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _addTask(title, remind, selectedTime);
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My To-Do List')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['All', 'Completed', 'Pending'].map((f) {
                return ChoiceChip(
                  label: Text(f),
                  selected: _filter == f,
                  onSelected: (_) => setState(() => _filter = f),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredTasks.length,
                itemBuilder: (context, index) {
                  final task = _filteredTasks[index];
                  final realIndex = _tasks.indexOf(task);
                  return Card(
                    child: ListTile(
                      title: Text(
                        task['title'],
                        style: TextStyle(
                          decoration:
                              task['done'] ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      subtitle: task['remind'] == true &&
                              task['reminderTime'] != null
                          ? Text(
                              '⏰ Reminder: ${DateTime.parse(task['reminderTime']).hour.toString().padLeft(2, '0')}:${DateTime.parse(task['reminderTime']).minute.toString().padLeft(2, '0')}')
                          : null,
                      leading: Checkbox(
                        value: task['done'],
                        onChanged: (_) => _toggleTask(realIndex),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteTask(realIndex),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings =
        InitializationSettings(android: androidInit);
    await flutterLocalNotificationsPlugin.initialize(initSettings);
  }
}
