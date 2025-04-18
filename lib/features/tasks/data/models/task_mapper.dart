import '../../domain/entities/task.dart';
import 'task_model.dart';

class TaskMapper {
  static Task fromModel(TaskModel model) {
    return Task(
      title: model.title,
      done: model.done,
      timestamp: DateTime.parse(model.timestamp),
      remind: model.remind,
      reminderTime: model.reminderTime != null
          ? DateTime.parse(model.reminderTime!)
          : null,
    );
  }

  static TaskModel toModel(Task task) {
    return TaskModel(
      title: task.title,
      done: task.done,
      timestamp: task.timestamp.toIso8601String(),
      remind: task.remind,
      reminderTime: task.reminderTime?.toIso8601String(),
    );
  }
}
