import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:uuid/uuid.dart';
import '../domain/task_model.dart';

abstract class TaskRepository {
  Future<List<TaskItem>> getTasks(String projectId);
  Future<TaskItem> createTask(TaskItem task);
  Future<TaskItem> updateTask(TaskItem task);
  Future<void> deleteTask(String taskId);
  Stream<List<TaskItem>> watchTasks(String projectId);
}

class SupabaseTaskRepository implements TaskRepository {
  final sb.SupabaseClient _client;

  SupabaseTaskRepository(this._client);

  @override
  Future<List<TaskItem>> getTasks(String projectId) async {
    final res = await _client
        .from('tasks')
        .select('*, profiles:assignee_id(full_name, avatar_url)')
        .eq('project_id', projectId)
        .order('position', ascending: true);

    return (res as List).map((json) => TaskItem.fromJson(json)).toList();
  }

  @override
  Future<TaskItem> createTask(TaskItem task) async {
    final json = task.toJson()..remove('id');
    final res = await _client.from('tasks').insert(json).select().single();
    return TaskItem.fromJson(res);
  }

  @override
  Future<TaskItem> updateTask(TaskItem task) async {
    final json = task.toJson();
    json['version'] = task.version + 1;
    json['updated_at'] = DateTime.now().toIso8601String();

    final res = await _client
        .from('tasks')
        .update(json)
        .eq('id', task.id)
        .select()
        .single();

    return TaskItem.fromJson(res);
  }

  @override
  Future<void> deleteTask(String taskId) async {
    await _client.from('tasks').delete().eq('id', taskId);
  }

  @override
  Stream<List<TaskItem>> watchTasks(String projectId) {
    return _client
        .from('tasks')
        .stream(primaryKey: ['id'])
        .eq('project_id', projectId)
        .order('position')
        .map((maps) => maps.map((json) => TaskItem.fromJson(json)).toList());
  }
}

class MockTaskRepository implements TaskRepository {
  final List<TaskItem> _tasks = [];
  final _streamController = StreamController<List<TaskItem>>.broadcast();

  MockTaskRepository() {
    _seedInitialTasks();
  }

  void _seedInitialTasks() {
    final now = DateTime.now();

    _tasks.addAll([
      TaskItem(
        id: 't-1',
        projectId: 'proj-mobile-app',
        title: 'Design Dark Aura UI System',
        description: 'Set up typography, glass cards, and status badge color palette.',
        status: TaskStatus.done,
        priority: TaskPriority.high,
        assigneeName: 'Alex Rivera',
        assigneeAvatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
        dueDate: now.subtract(const Duration(days: 1)),
        position: 1000.0,
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
      TaskItem(
        id: 't-2',
        projectId: 'proj-mobile-app',
        title: 'Implement Interactive Kanban Board',
        description: 'Smooth drag-and-drop between TODO, IN PROGRESS, IN REVIEW, and DONE.',
        status: TaskStatus.inProgress,
        priority: TaskPriority.urgent,
        assigneeName: 'Rahul Sharma',
        assigneeAvatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
        dueDate: now.add(const Duration(days: 2)),
        position: 2000.0,
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now,
      ),
      TaskItem(
        id: 't-3',
        projectId: 'proj-mobile-app',
        title: 'Multi-Workspace Tenancy Switcher',
        description: 'Allow users to switch between personal and team organizations with zero reload.',
        status: TaskStatus.done,
        priority: TaskPriority.medium,
        assigneeName: 'Alex Rivera',
        dueDate: now.subtract(const Duration(hours: 6)),
        position: 3000.0,
        createdAt: now.subtract(const Duration(days: 4)),
        updatedAt: now.subtract(const Duration(hours: 6)),
      ),
      TaskItem(
        id: 't-4',
        projectId: 'proj-mobile-app',
        title: 'Real-time WebSocket CDC Listeners',
        description: 'Subscribe to postgres changes stream to update team members in real-time.',
        status: TaskStatus.inReview,
        priority: TaskPriority.high,
        assigneeName: 'Ananya Rao',
        assigneeAvatar: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
        dueDate: now.add(const Duration(days: 3)),
        position: 4000.0,
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now,
      ),
      TaskItem(
        id: 't-5',
        projectId: 'proj-mobile-app',
        title: 'Task Filtering & Search Modal',
        description: 'Instant client-side filter by assignee, priority, and text search.',
        status: TaskStatus.todo,
        priority: TaskPriority.medium,
        assigneeName: 'Rahul Sharma',
        dueDate: now.add(const Duration(days: 5)),
        position: 5000.0,
        createdAt: now.subtract(const Duration(hours: 12)),
        updatedAt: now.subtract(const Duration(hours: 12)),
      ),
      TaskItem(
        id: 't-6',
        projectId: 'proj-mobile-app',
        title: 'Offline Sync Queue (Stage 4)',
        description: 'Drift local SQLite storage and conflict detection with version tracking.',
        status: TaskStatus.todo,
        priority: TaskPriority.low,
        dueDate: now.add(const Duration(days: 10)),
        position: 6000.0,
        createdAt: now.subtract(const Duration(hours: 5)),
        updatedAt: now.subtract(const Duration(hours: 5)),
      ),
    ]);
  }

  @override
  Future<List<TaskItem>> getTasks(String projectId) async {
    await Future.delayed(const Duration(milliseconds: 250));
    return _tasks.where((t) => t.projectId == projectId).toList();
  }

  @override
  Future<TaskItem> createTask(TaskItem task) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final newTask = task.copyWith(
      id: task.id.isEmpty ? const Uuid().v4() : task.id,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _tasks.add(newTask);
    _notify(task.projectId);
    return newTask;
  }

  @override
  Future<TaskItem> updateTask(TaskItem task) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      final updated = task.copyWith(
        version: task.version + 1,
        updatedAt: DateTime.now(),
      );
      _tasks[index] = updated;
      _notify(task.projectId);
      return updated;
    }
    return task;
  }

  @override
  Future<void> deleteTask(String taskId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final projectId = _tasks[index].projectId;
      _tasks.removeAt(index);
      _notify(projectId);
    }
  }

  @override
  Stream<List<TaskItem>> watchTasks(String projectId) {
    return _streamController.stream.map(
      (all) => all.where((t) => t.projectId == projectId).toList(),
    );
  }

  void _notify(String projectId) {
    _streamController.add(List.unmodifiable(_tasks));
  }
}
