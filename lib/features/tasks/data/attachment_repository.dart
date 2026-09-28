import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:uuid/uuid.dart';
import '../domain/attachment_model.dart';

abstract class AttachmentRepository {
  Future<List<TaskAttachment>> getAttachments(String taskId);
  Future<TaskAttachment> addAttachment(TaskAttachment attachment);
  Future<void> deleteAttachment(String attachmentId);
  Stream<List<TaskAttachment>> watchAttachments(String taskId);
}

class SupabaseAttachmentRepository implements AttachmentRepository {
  final sb.SupabaseClient _client;

  SupabaseAttachmentRepository(this._client);

  @override
  Future<List<TaskAttachment>> getAttachments(String taskId) async {
    final res = await _client
        .from('task_attachments')
        .select()
        .eq('task_id', taskId)
        .order('created_at', ascending: false);

    return (res as List).map((json) => TaskAttachment.fromJson(json)).toList();
  }

  @override
  Future<TaskAttachment> addAttachment(TaskAttachment attachment) async {
    final json = attachment.toJson()..remove('id');
    final res = await _client.from('task_attachments').insert(json).select().single();
    return TaskAttachment.fromJson(res);
  }

  @override
  Future<void> deleteAttachment(String attachmentId) async {
    await _client.from('task_attachments').delete().eq('id', attachmentId);
  }

  @override
  Stream<List<TaskAttachment>> watchAttachments(String taskId) {
    return _client
        .from('task_attachments')
        .stream(primaryKey: ['id'])
        .eq('task_id', taskId)
        .order('created_at', ascending: false)
        .map((maps) => maps.map((json) => TaskAttachment.fromJson(json)).toList());
  }
}

class MockAttachmentRepository implements AttachmentRepository {
  final Map<String, List<TaskAttachment>> _attachments = {};
  final _controllers = <String, StreamController<List<TaskAttachment>>>{};

  MockAttachmentRepository() {
    _seedData();
  }

  void _seedData() {
    final now = DateTime.now();

    _attachments['t-1'] = [
      TaskAttachment(
        id: 'att-1',
        taskId: 't-1',
        fileName: 'aura_dark_palette.png',
        fileUrl: 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=800',
        fileSizeBytes: 1420000,
        fileType: 'image/png',
        uploadedBy: 'Alex Rivera',
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      TaskAttachment(
        id: 'att-2',
        taskId: 't-1',
        fileName: 'design_spec_v1.pdf',
        fileUrl: 'https://example.com/spec.pdf',
        fileSizeBytes: 3400000,
        fileType: 'application/pdf',
        uploadedBy: 'Alex Rivera',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
    ];

    _attachments['t-2'] = [
      TaskAttachment(
        id: 'att-3',
        taskId: 't-2',
        fileName: 'kanban_interaction_flow.png',
        fileUrl: 'https://images.unsplash.com/photo-1507238691740-187a5b1d37b8?w=800',
        fileSizeBytes: 2100000,
        fileType: 'image/png',
        uploadedBy: 'Rahul Sharma',
        createdAt: now.subtract(const Duration(hours: 14)),
      ),
    ];
  }

  StreamController<List<TaskAttachment>> _getController(String taskId) {
    return _controllers.putIfAbsent(
      taskId,
      () => StreamController<List<TaskAttachment>>.broadcast(),
    );
  }

  List<TaskAttachment> _getList(String taskId) {
    return _attachments.putIfAbsent(taskId, () => []);
  }

  void _notify(String taskId) {
    final list = _getList(taskId);
    _getController(taskId).add(List.unmodifiable(list));
  }

  @override
  Future<List<TaskAttachment>> getAttachments(String taskId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return List.unmodifiable(_getList(taskId));
  }

  @override
  Future<TaskAttachment> addAttachment(TaskAttachment attachment) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final item = TaskAttachment(
      id: attachment.id.isEmpty ? const Uuid().v4() : attachment.id,
      taskId: attachment.taskId,
      fileName: attachment.fileName,
      fileUrl: attachment.fileUrl,
      fileSizeBytes: attachment.fileSizeBytes,
      fileType: attachment.fileType,
      uploadedBy: attachment.uploadedBy ?? 'Current User',
      createdAt: DateTime.now(),
    );

    final list = _getList(attachment.taskId);
    list.insert(0, item);
    _notify(attachment.taskId);
    return item;
  }

  @override
  Future<void> deleteAttachment(String attachmentId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    for (final entry in _attachments.entries) {
      final index = entry.value.indexWhere((a) => a.id == attachmentId);
      if (index != -1) {
        entry.value.removeAt(index);
        _notify(entry.key);
        break;
      }
    }
  }

  @override
  Stream<List<TaskAttachment>> watchAttachments(String taskId) {
    final controller = _getController(taskId);
    Future.microtask(() => controller.add(List.unmodifiable(_getList(taskId))));
    return controller.stream;
  }
}
