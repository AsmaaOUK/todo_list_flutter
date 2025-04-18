import 'package:todo_list_app/features/tasks/data/models/task_mapper.dart';

import '../entities/task.dart';
import '../../data/datasources/local_task_datasource.dart';

class AddTask {
  final LocalTaskDatasource datasource;

  AddTask(this.datasource);

  Future<void> call(Task task, List<Task> currentTasks) async {
    final updated = [...currentTasks, task];
    await datasource.saveTasks(
      updated.map((t) => TaskMapper.toModel(t)).toList(),
    );
  }
}
