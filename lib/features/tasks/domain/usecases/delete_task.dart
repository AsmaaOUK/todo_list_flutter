import 'package:todo_list_app/features/tasks/data/models/task_mapper.dart';
import 'package:todo_list_app/features/tasks/domain/entities/task.dart';
import 'package:todo_list_app/features/tasks/data/datasources/local_task_datasource.dart';

class DeleteTask {
  final LocalTaskDatasource datasource;

  DeleteTask(this.datasource);

  Future<void> call(int index, List<Task> currentTasks) async {
    final updated = [...currentTasks]..removeAt(index);
    await datasource.saveTasks(
      updated.map((t) => TaskMapper.toModel(t)).toList(),
    );
  }
}
