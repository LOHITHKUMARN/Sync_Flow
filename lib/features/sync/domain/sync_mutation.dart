enum MutationStatus {
  pending,
  syncing,
  failed,
  synced,
}

class SyncMutation {
  final String id;
  final String entityType;
  final String action; // 'create' | 'update' | 'delete'
  final String targetId;
  final String projectId;
  final Map<String, dynamic> payload;
  final int clientVersion;
  final DateTime createdAt;
  final MutationStatus status;
  final int retryCount;
  final String? lastError;

  const SyncMutation({
    required this.id,
    required this.entityType,
    required this.action,
    required this.targetId,
    required this.projectId,
    required this.payload,
    this.clientVersion = 1,
    required this.createdAt,
    this.status = MutationStatus.pending,
    this.retryCount = 0,
    this.lastError,
  });

  SyncMutation copyWith({
    String? id,
    String? entityType,
    String? action,
    String? targetId,
    String? projectId,
    Map<String, dynamic>? payload,
    int? clientVersion,
    DateTime? createdAt,
    MutationStatus? status,
    int? retryCount,
    String? lastError,
  }) {
    return SyncMutation(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      action: action ?? this.action,
      targetId: targetId ?? this.targetId,
      projectId: projectId ?? this.projectId,
      payload: payload ?? this.payload,
      clientVersion: clientVersion ?? this.clientVersion,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      lastError: lastError ?? this.lastError,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'entity_type': entityType,
      'action': action,
      'target_id': targetId,
      'project_id': projectId,
      'payload': payload,
      'client_version': clientVersion,
      'created_at': createdAt.toIso8601String(),
      'status': status.name,
      'retry_count': retryCount,
      'last_error': lastError,
    };
  }

  factory SyncMutation.fromJson(Map<String, dynamic> json) {
    return SyncMutation(
      id: json['id'] as String,
      entityType: json['entity_type'] as String? ?? 'task',
      action: json['action'] as String,
      targetId: json['target_id'] as String,
      projectId: json['project_id'] as String? ?? '',
      payload: Map<String, dynamic>.from(json['payload'] as Map? ?? {}),
      clientVersion: json['client_version'] as int? ?? 1,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      status: MutationStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => MutationStatus.pending,
      ),
      retryCount: json['retry_count'] as int? ?? 0,
      lastError: json['last_error'] as String?,
    );
  }
}
