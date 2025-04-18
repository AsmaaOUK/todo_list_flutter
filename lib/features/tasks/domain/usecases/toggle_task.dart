import 'package:todo_list_app/features/tasks/data/models/task_mapper.dart';
import 'package:todo_list_app/features/tasks/domain/entities/task.dart';
import 'package:todo_list_app/features/tasks/data/datasources/local_task_datasource.dart';

class ToggleTask {
  final LocalTaskDatasource datasource;

  ToggleTask(this.datasource);

  Future<void> call(int index, List<Task> currentTasks) async {
    final updated = [...currentTasks];
    final task = updated[index];
    updated[index] = Task(
      title: task.title,
      done: !task.done,
      timestamp: task.timestamp,
      remind: task.remind,
      reminderTime: task.reminderTime,
    );

    await datasource.saveTasks(
      updated.map((t) => TaskMapper.toModel(t)).toList(),
    );
  }
}
