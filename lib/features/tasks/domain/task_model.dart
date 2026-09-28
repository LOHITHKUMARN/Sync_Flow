import 'label_model.dart';
import 'subtask_model.dart';

enum TaskStatus {
  todo('TODO', 'To Do'),
  inProgress('IN_PROGRESS', 'In Progress'),
  inReview('IN_REVIEW', 'In Review'),
  done('DONE', 'Done');

  final String code;
  final String label;

  const TaskStatus(this.code, this.label);

  static TaskStatus fromCode(String code) {
    return TaskStatus.values.firstWhere(
      (e) => e.code.toUpperCase() == code.toUpperCase(),
      orElse: () => TaskStatus.todo,
    );
  }
}

enum TaskPriority {
  low('LOW', 'Low'),
  medium('MEDIUM', 'Medium'),
  high('HIGH', 'High'),
  urgent('URGENT', 'Urgent');

  final String code;
  final String label;

  const TaskPriority(this.code, this.label);

  static TaskPriority fromCode(String code) {
    return TaskPriority.values.firstWhere(
      (e) => e.code.toUpperCase() == code.toUpperCase(),
      orElse: () => TaskPriority.medium,
    );
  }
}

class TaskItem {
  final String id;
  final String projectId;
  final String title;
  final String description;
  final TaskStatus status;
  final TaskPriority priority;
  final String? assigneeId;
  final String? assigneeName;
  final String? assigneeAvatar;
  final String? creatorId;
  final DateTime? dueDate;
  final double position;
  final int version;
  final List<TaskLabel> labels;
  final List<TaskSubtask> subtasks;
  final int commentCount;
  final int attachmentCount;
  final int totalTimeSpentSeconds;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TaskItem({
    required this.id,
    required this.projectId,
    required this.title,
    this.description = '',
    this.status = TaskStatus.todo,
    this.priority = TaskPriority.medium,
    this.assigneeId,
    this.assigneeName,
    this.assigneeAvatar,
    this.creatorId,
    this.dueDate,
    this.position = 1000.0,
    this.version = 1,
    this.labels = const [],
    this.subtasks = const [],
    this.commentCount = 0,
    this.attachmentCount = 0,
    this.totalTimeSpentSeconds = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  int get completedSubtaskCount => subtasks.where((s) => s.isCompleted).length;
  double get subtaskProgress =>
      subtasks.isEmpty ? 0.0 : completedSubtaskCount / subtasks.length;

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    return TaskItem(
      id: json['id'] as String? ?? '',
      projectId: json['project_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      status: TaskStatus.fromCode(json['status'] as String? ?? 'TODO'),
      priority: TaskPriority.fromCode(json['priority'] as String? ?? 'MEDIUM'),
      assigneeId: json['assignee_id'] as String?,
      assigneeName: json['assignee_name'] as String? ??
          (json['profiles'] != null ? json['profiles']['full_name'] as String? : null),
      assigneeAvatar: json['assignee_avatar'] as String? ??
          (json['profiles'] != null ? json['profiles']['avatar_url'] as String? : null),
      creatorId: json['creator_id'] as String?,
      dueDate: json['due_date'] != null
          ? DateTime.tryParse(json['due_date'].toString())
          : null,
      position: (json['position'] as num?)?.toDouble() ?? 1000.0,
      version: json['version'] as int? ?? 1,
      labels: (json['labels'] as List<dynamic>?)
              ?.map((e) => TaskLabel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      subtasks: (json['subtasks'] as List<dynamic>?)
              ?.map((e) => TaskSubtask.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      commentCount: json['comment_count'] as int? ?? 0,
      attachmentCount: json['attachment_count'] as int? ?? 0,
      totalTimeSpentSeconds: json['total_time_spent_seconds'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'project_id': projectId,
      'title': title,
      'description': description,
      'status': status.code,
      'priority': priority.code,
      'assignee_id': assigneeId,
      'creator_id': creatorId,
      'due_date': dueDate?.toIso8601String(),
      'position': position,
      'version': version,
      'labels': labels.map((e) => e.toJson()).toList(),
      'subtasks': subtasks.map((e) => e.toJson()).toList(),
      'comment_count': commentCount,
      'attachment_count': attachmentCount,
      'total_time_spent_seconds': totalTimeSpentSeconds,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  TaskItem copyWith({
    String? id,
    String? projectId,
    String? title,
    String? description,
    TaskStatus? status,
    TaskPriority? priority,
    String? assigneeId,
    String? assigneeName,
    String? assigneeAvatar,
    String? creatorId,
    DateTime? dueDate,
    double? position,
    int? version,
    List<TaskLabel>? labels,
    List<TaskSubtask>? subtasks,
    int? commentCount,
    int? attachmentCount,
    int? totalTimeSpentSeconds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskItem(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      assigneeId: assigneeId ?? this.assigneeId,
      assigneeName: assigneeName ?? this.assigneeName,
      assigneeAvatar: assigneeAvatar ?? this.assigneeAvatar,
      creatorId: creatorId ?? this.creatorId,
      dueDate: dueDate ?? this.dueDate,
      position: position ?? this.position,
      version: version ?? this.version,
      labels: labels ?? this.labels,
      subtasks: subtasks ?? this.subtasks,
      commentCount: commentCount ?? this.commentCount,
      attachmentCount: attachmentCount ?? this.attachmentCount,
      totalTimeSpentSeconds: totalTimeSpentSeconds ?? this.totalTimeSpentSeconds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
