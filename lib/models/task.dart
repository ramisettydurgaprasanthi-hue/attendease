class Task {
  final String id;
  final int notifId; // id used for this task's notification
  String title;
  bool done;
  DateTime? remindAt;

  Task({
    required this.id,
    required this.notifId,
    required this.title,
    this.done = false,
    this.remindAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'notifId': notifId,
    'title': title,
    'done': done,
    'remindAt': remindAt?.toIso8601String(),
  };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id: json['id'] as String,
    notifId: json['notifId'] as int,
    title: json['title'] as String,
    done: (json['done'] as bool?) ?? false,
    remindAt: json['remindAt'] == null
        ? null
        : DateTime.parse(json['remindAt'] as String),
  );
}