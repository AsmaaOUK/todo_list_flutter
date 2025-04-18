import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../models/task_model.dart';

class LocalTaskDatasource {
  static const String key = 'tasks';

  Future<List<TaskModel>> getTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String? tasksString = prefs.getString(key);
    if (tasksString != null) {
      final decoded = json.decode(tasksString);
      return (decoded as List)
          .map((taskJson) => TaskModel.fromJson(taskJson))
          .toList();
    }
    return [];
  }

  Future<void> saveTasks(List<TaskModel> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(tasks.map((t) => t.toJson()).toList());
    await prefs.setString(key, encoded);
  }
}
