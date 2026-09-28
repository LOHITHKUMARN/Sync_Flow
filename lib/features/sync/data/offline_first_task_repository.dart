import 'dart:async';
import 'package:uuid/uuid.dart';
import '../../tasks/data/task_repository.dart';
import '../../tasks/domain/task_model.dart';
import '../domain/sync_mutation.dart';
import 'connectivity_service.dart';
import 'local_cache_service.dart';
import 'mutation_queue_repository.dart';

class OfflineFirstTaskRepository implements TaskRepository {
  final TaskRepository _remoteRepo;
  final LocalCacheService _cacheService;
  final MutationQueueRepository _queueRepo;
  final ConnectivityService _connectivity;

  final _taskStreams = <String, StreamController<List<TaskItem>>>{};

  OfflineFirstTaskRepository({
    required TaskRepository remoteRepo,
    required LocalCacheService cacheService,
    required MutationQueueRepository queueRepo,
    required ConnectivityService connectivity,
  })  : _remoteRepo = remoteRepo,
        _cacheService = cacheService,
        _queueRepo = queueRepo,
        _connectivity = connectivity;

  StreamController<List<TaskItem>> _getController(String projectId) {
    return _taskStreams.putIfAbsent(
      projectId,
      () => StreamController<List<TaskItem>>.broadcast(),
    );
  }

  void _notifyLocal(String projectId) {
    final cached = _cacheService.getCachedTasks(projectId);
    if (cached != null) {
      _getController(projectId).add(cached);
    }
  }

  @override
  Future<List<TaskItem>> getTasks(String projectId) async {
    // 1. Fast path: check local cache
    final cached = _cacheService.getCachedTasks(projectId);

    if (_connectivity.currentStatus.isOffline) {
      if (cached != null && cached.isNotEmpty) {
        return cached;
      }
      // If mock repo has tasks, fall back
      try {
        final tasks = await _remoteRepo.getTasks(projectId);
        await _cacheService.saveTasks(projectId, tasks);
        return tasks;
      } catch (_) {
        return cached ?? [];
      }
    }

    // 2. Online path: fetch from remote & update cache
    try {
      final remoteTasks = await _remoteRepo.getTasks(projectId);
      await _cacheService.saveTasks(projectId, remoteTasks);
      _notifyLocal(projectId);
      return remoteTasks;
    } catch (_) {
      // Remote failed: return cached tasks
      if (cached != null) return cached;
      rethrow;
    }
  }

  @override
  Future<TaskItem> createTask(TaskItem task) async {
    final taskId = task.id.isEmpty ? const Uuid().v4() : task.id;
    final preparedTask = task.copyWith(
      id: taskId,
      createdAt: task.createdAt,
      updatedAt: DateTime.now(),
    );

    // 1. Optimistic local cache update
    await _cacheService.upsertTask(preparedTask);
    _notifyLocal(preparedTask.projectId);

    // 2. If online and queue is empty, attempt direct remote write
    if (_connectivity.currentStatus.isOnline && _queueRepo.pendingCount == 0) {
      try {
        final created = await _remoteRepo.createTask(preparedTask);
        await _cacheService.upsertTask(created);
        _notifyLocal(created.projectId);
        return created;
      } catch (_) {
        // Fall through to queue
      }
    }

    // 3. Queue mutation for background sync
    await _queueRepo.enqueue(
      SyncMutation(
        id: const Uuid().v4(),
        entityType: 'task',
        action: 'create',
        targetId: preparedTask.id,
        projectId: preparedTask.projectId,
        payload: preparedTask.toJson(),
        clientVersion: preparedTask.version,
        createdAt: DateTime.now(),
      ),
    );

    return preparedTask;
  }

  @override
  Future<TaskItem> updateTask(TaskItem task) async {
    final updatedTask = task.copyWith(
      version: task.version + 1,
      updatedAt: DateTime.now(),
    );

    // 1. Optimistic local cache update
    await _cacheService.upsertTask(updatedTask);
    _notifyLocal(updatedTask.projectId);

    // 2. If online and queue is empty, attempt direct remote write
    if (_connectivity.currentStatus.isOnline && _queueRepo.pendingCount == 0) {
      try {
        final saved = await _remoteRepo.updateTask(updatedTask);
        await _cacheService.upsertTask(saved);
        _notifyLocal(saved.projectId);
        return saved;
      } catch (_) {
        // Fall through to queue
      }
    }

    // 3. Queue mutation for background sync
    await _queueRepo.enqueue(
      SyncMutation(
        id: const Uuid().v4(),
        entityType: 'task',
        action: 'update',
        targetId: updatedTask.id,
        projectId: updatedTask.projectId,
        payload: updatedTask.toJson(),
        clientVersion: updatedTask.version,
        createdAt: DateTime.now(),
      ),
    );

    return updatedTask;
  }

  @override
  Future<void> deleteTask(String taskId) async {
    // Find project ID from cache if possible
    String projectId = '';
    for (final entry in _taskStreams.keys) {
      final cached = _cacheService.getCachedTasks(entry);
      if (cached != null && cached.any((t) => t.id == taskId)) {
        projectId = entry;
        break;
      }
    }

    // 1. Optimistic cache removal
    if (projectId.isNotEmpty) {
      await _cacheService.removeTask(projectId, taskId);
      _notifyLocal(projectId);
    }

    // 2. Direct write or queue
    if (_connectivity.currentStatus.isOnline && _queueRepo.pendingCount == 0) {
      try {
        await _remoteRepo.deleteTask(taskId);
        return;
      } catch (_) {
        // Fall through to queue
      }
    }

    await _queueRepo.enqueue(
      SyncMutation(
        id: const Uuid().v4(),
        entityType: 'task',
        action: 'delete',
        targetId: taskId,
        projectId: projectId,
        payload: {'id': taskId},
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Stream<List<TaskItem>> watchTasks(String projectId) {
    final controller = _getController(projectId);

    // Seed controller with cached data immediately if available
    final cached = _cacheService.getCachedTasks(projectId);
    if (cached != null) {
      Future.microtask(() {
        if (!controller.isClosed) controller.add(cached);
      });
    }

    // Also pipe remote stream updates into cache and controller
    final remoteSub = _remoteRepo.watchTasks(projectId).listen(
      (tasks) {
        _cacheService.saveTasks(projectId, tasks);
        if (!controller.isClosed) controller.add(tasks);
      },
      onError: (_) {},
    );

    // Cancel remote sub when controller closes
    controller.onCancel = () {
      remoteSub.cancel();
    };

    return controller.stream;
  }
}
