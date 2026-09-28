class Project {
  final String id;
  final String workspaceId;
  final String name;
  final String? description;
  final String color;
  final String status;
  final String? creatorId;
  final DateTime createdAt;
  final int taskCount;
  final int completedTaskCount;

  const Project({
    required this.id,
    required this.workspaceId,
    required this.name,
    this.description,
    this.color = '#6366F1',
    this.status = 'active',
    this.creatorId,
    required this.createdAt,
    this.taskCount = 0,
    this.completedTaskCount = 0,
  });

  double get progressPercentage {
    if (taskCount == 0) return 0.0;
    return (completedTaskCount / taskCount).clamp(0.0, 1.0);
  }

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as String,
      workspaceId: json['workspace_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      color: json['color'] as String? ?? '#6366F1',
      status: json['status'] as String? ?? 'active',
      creatorId: json['creator_id'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      taskCount: json['task_count'] as int? ?? 0,
      completedTaskCount: json['completed_task_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'workspace_id': workspaceId,
      'name': name,
      'description': description,
      'color': color,
      'status': status,
      'creator_id': creatorId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Project copyWith({
    String? id,
    String? workspaceId,
    String? name,
    String? description,
    String? color,
    String? status,
    String? creatorId,
    DateTime? createdAt,
    int? taskCount,
    int? completedTaskCount,
  }) {
    return Project(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      status: status ?? this.status,
      creatorId: creatorId ?? this.creatorId,
      createdAt: createdAt ?? this.createdAt,
      taskCount: taskCount ?? this.taskCount,
      completedTaskCount: completedTaskCount ?? this.completedTaskCount,
    );
  }
}
