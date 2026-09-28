import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../domain/comment_model.dart';

abstract class CommentRepository {
  Future<List<TaskComment>> getComments(String taskId);
  Future<TaskComment> addComment(TaskComment comment);
  Future<void> deleteComment({required String commentId, required String taskId});
  Stream<List<TaskComment>> watchComments(String taskId);
}

class SupabaseCommentRepository implements CommentRepository {
  final sb.SupabaseClient _client;

  SupabaseCommentRepository(this._client);

  @override
  Future<List<TaskComment>> getComments(String taskId) async {
    final res = await _client
        .from('task_comments')
        .select('*, profiles:author_id(full_name, avatar_url)')
        .eq('task_id', taskId)
        .order('created_at', ascending: true);

    return (res as List).map((json) => TaskComment.fromJson(json)).toList();
  }

  @override
  Future<TaskComment> addComment(TaskComment comment) async {
    final json = comment.toJson()..remove('id');
    final res = await _client
        .from('task_comments')
        .insert(json)
        .select('*, profiles:author_id(full_name, avatar_url)')
        .single();
    return TaskComment.fromJson(res);
  }

  @override
  Future<void> deleteComment({required String commentId, required String taskId}) async {
    await _client.from('task_comments').delete().eq('id', commentId);
  }

  @override
  Stream<List<TaskComment>> watchComments(String taskId) {
    return _client
        .from('task_comments')
        .stream(primaryKey: ['id'])
        .eq('task_id', taskId)
        .order('created_at', ascending: true)
        .asyncMap((_) => getComments(taskId));
  }
}

class MockCommentRepository implements CommentRepository {
  final Map<String, List<TaskComment>> _commentsByTask = {};
  final _streamController = StreamController<Map<String, List<TaskComment>>>.broadcast();

  MockCommentRepository() {
    _seedComments();
  }

  void _seedComments() {
    final now = DateTime.now();

    // Seed conversations for default tasks
    _commentsByTask['task-auth-001'] = [
      TaskComment(
        id: 'c-1',
        taskId: 'task-auth-001',
        authorId: 'demo-user-002',
        authorName: 'Rahul Sharma',
        authorAvatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
        content: 'JWT refresh rotation is set up. Let me know if you hit token expiry issues during testing.',
        createdAt: now.subtract(const Duration(hours: 3)),
      ),
      TaskComment(
        id: 'c-2',
        taskId: 'task-auth-001',
        authorId: 'demo-user-001',
        authorName: 'Alex Rivera',
        authorAvatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
        content: 'Verified on Android! Refresh flow handles offline reconnect gracefully.',
        replyToId: 'c-1',
        createdAt: now.subtract(const Duration(hours: 1)),
      ),
    ];

    _commentsByTask['task-sync-002'] = [
      TaskComment(
        id: 'c-3',
        taskId: 'task-sync-002',
        authorId: 'demo-user-003',
        authorName: 'Ananya Rao',
        authorAvatar: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
        content: 'I added WebSocket ping/pong heartbeat to maintain connections across cellular handoffs.',
        createdAt: now.subtract(const Duration(minutes: 45)),
      ),
    ];
  }

  List<TaskComment> _getOrCreateList(String taskId) {
    return _commentsByTask.putIfAbsent(taskId, () => []);
  }

  @override
  Future<List<TaskComment>> getComments(String taskId) async {
    await Future.delayed(const Duration(milliseconds: 10));
    return List<TaskComment>.from(_getOrCreateList(taskId));
  }

  @override
  Future<TaskComment> addComment(TaskComment comment) async {
    await Future.delayed(const Duration(milliseconds: 15));
    final list = _getOrCreateList(comment.taskId);
    list.add(comment);
    _streamController.add(Map.from(_commentsByTask));
    return comment;
  }

  @override
  Future<void> deleteComment({required String commentId, required String taskId}) async {
    await Future.delayed(const Duration(milliseconds: 10));
    final list = _getOrCreateList(taskId);
    list.removeWhere((c) => c.id == commentId || c.replyToId == commentId);
    _streamController.add(Map.from(_commentsByTask));
  }

  @override
  Stream<List<TaskComment>> watchComments(String taskId) {
    return _streamController.stream.map(
      (map) => List<TaskComment>.from(map[taskId] ?? _getOrCreateList(taskId)),
    );
  }
}
