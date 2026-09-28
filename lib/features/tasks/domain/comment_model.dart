class TaskComment {
  final String id;
  final String taskId;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final String content;
  final String? replyToId;
  final DateTime createdAt;

  const TaskComment({
    required this.id,
    required this.taskId,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    required this.content,
    this.replyToId,
    required this.createdAt,
  });

  factory TaskComment.fromJson(Map<String, dynamic> json) {
    return TaskComment(
      id: json['id'] as String? ?? '',
      taskId: json['task_id'] as String? ?? '',
      authorId: json['author_id'] as String? ?? json['user_id'] as String? ?? '',
      authorName: json['author_name'] as String? ??
          (json['profiles'] != null ? json['profiles']['full_name'] as String? : null) ??
          'Team Member',
      authorAvatar: json['author_avatar'] as String? ??
          (json['profiles'] != null ? json['profiles']['avatar_url'] as String? : null),
      content: json['content'] as String? ?? '',
      replyToId: json['reply_to_id'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_id': taskId,
      'author_id': authorId,
      'author_name': authorName,
      'author_avatar': authorAvatar,
      'content': content,
      'reply_to_id': replyToId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  TaskComment copyWith({
    String? id,
    String? taskId,
    String? authorId,
    String? authorName,
    String? authorAvatar,
    String? content,
    String? replyToId,
    DateTime? createdAt,
  }) {
    return TaskComment(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      content: content ?? this.content,
      replyToId: replyToId ?? this.replyToId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
