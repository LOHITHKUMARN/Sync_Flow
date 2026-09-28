class TimeEntry {
  final String id;
  final String taskId;
  final String userId;
  final String userName;
  final int durationSeconds;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String? note;

  const TimeEntry({
    required this.id,
    required this.taskId,
    required this.userId,
    required this.userName,
    required this.durationSeconds,
    required this.startedAt,
    this.endedAt,
    this.note,
  });

  factory TimeEntry.fromJson(Map<String, dynamic> json) {
    return TimeEntry(
      id: json['id'] as String? ?? '',
      taskId: json['task_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      userName: json['user_name'] as String? ?? 'Team Member',
      durationSeconds: json['duration_seconds'] as int? ?? 0,
      startedAt: json['started_at'] != null
          ? DateTime.tryParse(json['started_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      endedAt: json['ended_at'] != null
          ? DateTime.tryParse(json['ended_at'].toString())
          : null,
      note: json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_id': taskId,
      'user_id': userId,
      'user_name': userName,
      'duration_seconds': durationSeconds,
      'started_at': startedAt.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
      'note': note,
    };
  }

  String get formattedDuration {
    final hours = durationSeconds ~/ 3600;
    final minutes = (durationSeconds % 3600) ~/ 60;
    final seconds = durationSeconds % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m ${seconds}s';
  }
}
