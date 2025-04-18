class TaskModel {
  final String title;
  final bool done;
  final String timestamp;
  final bool remind;
  final String? reminderTime;

  TaskModel({
    required this.title,
    required this.done,
    required this.timestamp,
    required this.remind,
    this.reminderTime,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) => TaskModel(
        title: json['title'],
        done: json['done'],
        timestamp: json['timestamp'],
        remind: json['remind'],
        reminderTime: json['reminderTime'],
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'done': done,
        'timestamp': timestamp,
        'remind': remind,
        'reminderTime': reminderTime,
      };
}
