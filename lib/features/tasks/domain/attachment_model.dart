class TaskAttachment {
  final String id;
  final String taskId;
  final String fileName;
  final String fileUrl;
  final int fileSizeBytes;
  final String fileType;
  final String? uploadedBy;
  final DateTime createdAt;

  const TaskAttachment({
    required this.id,
    required this.taskId,
    required this.fileName,
    required this.fileUrl,
    this.fileSizeBytes = 0,
    this.fileType = 'file',
    this.uploadedBy,
    required this.createdAt,
  });

  factory TaskAttachment.fromJson(Map<String, dynamic> json) {
    return TaskAttachment(
      id: json['id'] as String? ?? '',
      taskId: json['task_id'] as String? ?? '',
      fileName: json['file_name'] as String? ?? json['name'] as String? ?? 'attachment',
      fileUrl: json['file_url'] as String? ?? json['url'] as String? ?? '',
      fileSizeBytes: json['file_size_bytes'] as int? ?? json['size_bytes'] as int? ?? 0,
      fileType: json['file_type'] as String? ?? json['mime_type'] as String? ?? 'file',
      uploadedBy: json['uploaded_by'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_id': taskId,
      'file_name': fileName,
      'file_url': fileUrl,
      'file_size_bytes': fileSizeBytes,
      'file_type': fileType,
      'uploaded_by': uploadedBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isImage {
    final lower = fileName.toLowerCase();
    return lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.gif') ||
        fileType.startsWith('image/');
  }

  String get formattedSize {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

