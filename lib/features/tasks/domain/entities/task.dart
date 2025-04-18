class Task {
  final String title;
  final bool done;
  final DateTime timestamp;
  final bool remind;
  final DateTime? reminderTime;

  Task({
    required this.title,
    required this.done,
    required this.timestamp,
    required this.remind,
    this.reminderTime,
  });
}
