enum NotificationType {
  taskAssigned('TASK_ASSIGNED', 'Task Assigned'),
  commentAdded('COMMENT_ADDED', 'New Comment'),
  mention('MENTION', 'Mentioned You'),
  dueDateSoon('DUE_DATE_SOON', 'Due Soon'),
  workspaceInvite('WORKSPACE_INVITE', 'Workspace Invite');

  final String code;
  final String label;

  const NotificationType(this.code, this.label);

  static NotificationType fromCode(String code) {
    return NotificationType.values.firstWhere(
      (t) => t.code.toUpperCase() == code.toUpperCase(),
      orElse: () => NotificationType.taskAssigned,
    );
  }
}

class NotificationItem {
  final String id;
  final String userId;
  final String actorId;
  final String actorName;
  final String? actorAvatar;
  final NotificationType type;
  final String title;
  final String body;
  final String? taskId;
  final String? projectId;
  final String? workspaceId;
  final bool isRead;
  final DateTime createdAt;

  const NotificationItem({
    required this.id,
    required this.userId,
    required this.actorId,
    required this.actorName,
    this.actorAvatar,
    required this.type,
    required this.title,
    required this.body,
    this.taskId,
    this.projectId,
    this.workspaceId,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      actorId: json['actor_id'] as String? ?? '',
      actorName: json['actor_name'] as String? ??
          (json['profiles'] != null ? json['profiles']['full_name'] as String? : null) ??
          'Team Member',
      actorAvatar: json['actor_avatar'] as String? ??
          (json['profiles'] != null ? json['profiles']['avatar_url'] as String? : null),
      type: NotificationType.fromCode(json['type'] as String? ?? ''),
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      taskId: json['task_id'] as String?,
      projectId: json['project_id'] as String?,
      workspaceId: json['workspace_id'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'actor_id': actorId,
      'actor_name': actorName,
      'actor_avatar': actorAvatar,
      'type': type.code,
      'title': title,
      'body': body,
      'task_id': taskId,
      'project_id': projectId,
      'workspace_id': workspaceId,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }

  NotificationItem copyWith({
    String? id,
    String? userId,
    String? actorId,
    String? actorName,
    String? actorAvatar,
    NotificationType? type,
    String? title,
    String? body,
    String? taskId,
    String? projectId,
    String? workspaceId,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      actorId: actorId ?? this.actorId,
      actorName: actorName ?? this.actorName,
      actorAvatar: actorAvatar ?? this.actorAvatar,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      taskId: taskId ?? this.taskId,
      projectId: projectId ?? this.projectId,
      workspaceId: workspaceId ?? this.workspaceId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
