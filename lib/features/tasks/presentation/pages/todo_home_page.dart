import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/task_controller.dart';
import '../../domain/entities/task.dart';

import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import '/../../../core/services/notification_service.dart';

Future<void> requestExactAlarmPermissionIfNeeded() async {
  if (Platform.isAndroid) {
    final prefs = await SharedPreferences.getInstance();
    final alreadyRequested = prefs.getBool('exactAlarmRequested') ?? false;

    if (!alreadyRequested) {
      const intent = AndroidIntent(
        action: 'android.settings.REQUEST_SCHEDULE_EXACT_ALARM',
        flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
      );
      await intent.launch();
      await prefs.setBool('exactAlarmRequested', true);
    }
  }
}

class ToDoHomePage extends StatefulWidget {
  const ToDoHomePage({super.key});

  @override
  State<ToDoHomePage> createState() => _ToDoHomePageState();
}

class _ToDoHomePageState extends State<ToDoHomePage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      requestExactAlarmPermissionIfNeeded();
    });
  }

  // Inside _ToDoHomePageState class
  Future<void> _checkPendingNotifications() async {
    final pending = await NotificationService()
        .flutterLocalNotificationsPlugin
        .pendingNotificationRequests();

    debugPrint('📋 Found ${pending.length} pending notifications');
    for (var notification in pending) {
      debugPrint(
          '⏰ ID: ${notification.id} - Title: ${notification.title} - Scheduled for: ${notification.payload}');
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Found ${pending.length} pending notifications'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<TaskController>(context);

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
                  selected: controller.filter == f,
                  onSelected: (_) => controller.setFilter(f),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: controller.tasks.isEmpty
                  ? const Center(child: Text('No tasks yet ✨'))
                  : ListView.builder(
                      itemCount: controller.tasks.length,
                      itemBuilder: (context, index) {
                        final task = controller.tasks[index];
                        return Card(
                          child: ListTile(
                            title: Text(
                              task.title,
                              style: TextStyle(
                                decoration: task.done
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            subtitle: task.remind && task.reminderTime != null
                                ? Text(
                                    '⏰ Reminder: ${task.reminderTime!.hour.toString().padLeft(2, '0')}:${task.reminderTime!.minute.toString().padLeft(2, '0')}',
                                  )
                                : null,
                            leading: Checkbox(
                              value: task.done,
                              onChanged: (_) => controller.toggleTask(index),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => controller.deleteTask(index),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'add',
            onPressed: () => _showAddTaskDialog(context, controller),
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'notif',
            onPressed: () {
              NotificationService().showInstantNotification(
                '🚨 Test',
                'This is a manual notification test!',
              );
            },
            backgroundColor: Colors.red,
            child: const Icon(Icons.notifications_active),
          ),
          const SizedBox(height: 12), // Add this test button to your UI
          FloatingActionButton(
            onPressed: () async {
              final now = DateTime.now();
              await NotificationService().scheduleNotification(
                id: 999,
                title: 'Test Notification',
                body: 'Scheduled at ${now.add(Duration(minutes: 1))}',
                scheduledTime: now.add(Duration(minutes: 1)),
              );
            },
            child: Icon(Icons.notifications),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'pending',
            onPressed: _checkPendingNotifications,
            backgroundColor: Colors.deepPurple,
            mini: true,
            child: const Icon(Icons.list),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'debug',
            onPressed: () async {
              final pending = await NotificationService()
                  .flutterLocalNotificationsPlugin
                  .pendingNotificationRequests();
              debugPrint('📋 Pending notifications: ${pending.length}');
              for (var p in pending) {
                debugPrint('⏰ ${p.id}: ${p.title} - ${p.body}');
              }
              // Show a snackbar with the count of pending notifications
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Pending notifications: ${pending.length}'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            backgroundColor: Colors.blue,
            child: const Icon(Icons.bug_report),
          ),
        ],
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context, TaskController controller) {
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
                  label: Text(selectedTime?.format(context) ?? 'Pick time'),
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
              if (title.trim().isEmpty) return;

              final now = DateTime.now();
              final reminderDate = selectedTime != null
                  ? DateTime(now.year, now.month, now.day, selectedTime!.hour,
                      selectedTime!.minute)
                  : null;

              controller.addTask(Task(
                title: title,
                done: false,
                timestamp: now,
                remind: remind,
                reminderTime: reminderDate,
              ));
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
