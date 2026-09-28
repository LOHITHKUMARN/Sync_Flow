class TaskActivity {
  final String id;
  final String taskId;
  final String? projectId;
  final String actorId;
  final String actorName;
  final String? actorAvatar;
  final String actionType; // 'created', 'status_changed', 'assigned', 'commented', etc.
  final String summary;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  const TaskActivity({
    required this.id,
    required this.taskId,
    this.projectId,
    required this.actorId,
    required this.actorName,
    this.actorAvatar,
    required this.actionType,
    required this.summary,
    this.metadata = const {},
    required this.createdAt,
  });

  factory TaskActivity.fromJson(Map<String, dynamic> json) {
    return TaskActivity(
      id: json['id'] as String? ?? '',
      taskId: json['task_id'] as String? ?? '',
      projectId: json['project_id'] as String?,
      actorId: json['actor_id'] as String? ?? '',
      actorName: json['actor_name'] as String? ??
          (json['profiles'] != null ? json['profiles']['full_name'] as String? : null) ??
          'Team Member',
      actorAvatar: json['actor_avatar'] as String? ??
          (json['profiles'] != null ? json['profiles']['avatar_url'] as String? : null),
      actionType: json['action_type'] as String? ?? 'updated',
      summary: json['summary'] as String? ?? '',
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_id': taskId,
      'project_id': projectId,
      'actor_id': actorId,
      'actor_name': actorName,
      'actor_avatar': actorAvatar,
      'action_type': actionType,
      'summary': summary,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
