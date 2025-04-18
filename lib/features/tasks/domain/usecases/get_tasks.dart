import 'package:todo_list_app/features/tasks/data/models/task_mapper.dart';
import 'package:todo_list_app/features/tasks/domain/entities/task.dart';
import 'package:todo_list_app/features/tasks/data/datasources/local_task_datasource.dart';

class GetTasks {
  final LocalTaskDatasource datasource;

  GetTasks(this.datasource);

  Future<List<Task>> call() async {
    final models = await datasource.getTasks();
    return models.map((m) => TaskMapper.fromModel(m)).toList();
  }
}
