import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../domain/activity_model.dart';

abstract class ActivityRepository {
  Future<List<TaskActivity>> getActivities(String taskId);
  Future<TaskActivity> logActivity(TaskActivity activity);
  Stream<List<TaskActivity>> watchActivities(String taskId);
}

class SupabaseActivityRepository implements ActivityRepository {
  final sb.SupabaseClient _client;

  SupabaseActivityRepository(this._client);

  @override
  Future<List<TaskActivity>> getActivities(String taskId) async {
    final res = await _client
        .from('activity_events')
        .select('*, profiles:actor_id(full_name, avatar_url)')
        .eq('task_id', taskId)
        .order('created_at', ascending: false);

    return (res as List).map((json) => TaskActivity.fromJson(json)).toList();
  }

  @override
  Future<TaskActivity> logActivity(TaskActivity activity) async {
    final json = activity.toJson()..remove('id');
    final res = await _client
        .from('activity_events')
        .insert(json)
        .select('*, profiles:actor_id(full_name, avatar_url)')
        .single();
    return TaskActivity.fromJson(res);
  }

  @override
  Stream<List<TaskActivity>> watchActivities(String taskId) {
    return _client
        .from('activity_events')
        .stream(primaryKey: ['id'])
        .eq('task_id', taskId)
        .order('created_at', ascending: false)
        .asyncMap((_) => getActivities(taskId));
  }
}

class MockActivityRepository implements ActivityRepository {
  final Map<String, List<TaskActivity>> _activitiesByTask = {};
  final _streamController = StreamController<Map<String, List<TaskActivity>>>.broadcast();

  MockActivityRepository() {
    _seedActivities();
  }

  void _seedActivities() {
    final now = DateTime.now();

    _activitiesByTask['task-auth-001'] = [
      TaskActivity(
        id: 'act-1',
        taskId: 'task-auth-001',
        actorId: 'demo-user-001',
        actorName: 'Alex Rivera',
        actionType: 'created',
        summary: 'created the task',
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      TaskActivity(
        id: 'act-2',
        taskId: 'task-auth-001',
        actorId: 'demo-user-001',
        actorName: 'Alex Rivera',
        actionType: 'assigned',
        summary: 'assigned to Rahul Sharma',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      TaskActivity(
        id: 'act-3',
        taskId: 'task-auth-001',
        actorId: 'demo-user-002',
        actorName: 'Rahul Sharma',
        actionType: 'status_changed',
        summary: 'moved from IN_PROGRESS to DONE',
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
    ];

    _activitiesByTask['task-sync-002'] = [
      TaskActivity(
        id: 'act-4',
        taskId: 'task-sync-002',
        actorId: 'demo-user-001',
        actorName: 'Alex Rivera',
        actionType: 'created',
        summary: 'created the task',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      TaskActivity(
        id: 'act-5',
        taskId: 'task-sync-002',
        actorId: 'demo-user-003',
        actorName: 'Ananya Rao',
        actionType: 'status_changed',
        summary: 'moved from TODO to IN_PROGRESS',
        createdAt: now.subtract(const Duration(hours: 5)),
      ),
    ];
  }

  List<TaskActivity> _getOrCreateList(String taskId) {
    return _activitiesByTask.putIfAbsent(taskId, () => []);
  }

  @override
  Future<List<TaskActivity>> getActivities(String taskId) async {
    await Future.delayed(const Duration(milliseconds: 10));
    return List<TaskActivity>.from(_getOrCreateList(taskId));
  }

  @override
  Future<TaskActivity> logActivity(TaskActivity activity) async {
    await Future.delayed(const Duration(milliseconds: 10));
    final list = _getOrCreateList(activity.taskId);
    list.insert(0, activity); // Most recent first
    _streamController.add(Map.from(_activitiesByTask));
    return activity;
  }

  @override
  Stream<List<TaskActivity>> watchActivities(String taskId) {
    return _streamController.stream.map(
      (map) => List<TaskActivity>.from(map[taskId] ?? _getOrCreateList(taskId)),
    );
  }
}
