class TaskSubtask {
  final String id;
  final String taskId;
  final String title;
  final bool isCompleted;
  final double position;
  final DateTime createdAt;

  const TaskSubtask({
    required this.id,
    required this.taskId,
    required this.title,
    this.isCompleted = false,
    this.position = 1000.0,
    required this.createdAt,
  });

  factory TaskSubtask.fromJson(Map<String, dynamic> json) {
    return TaskSubtask(
      id: json['id'] as String? ?? '',
      taskId: json['task_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      isCompleted: json['is_completed'] as bool? ?? false,
      position: (json['position'] as num?)?.toDouble() ?? 1000.0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_id': taskId,
      'title': title,
      'is_completed': isCompleted,
      'position': position,
      'created_at': createdAt.toIso8601String(),
    };
  }

  TaskSubtask copyWith({
    String? id,
    String? taskId,
    String? title,
    bool? isCompleted,
    double? position,
    DateTime? createdAt,
  }) {
    return TaskSubtask(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      position: position ?? this.position,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
