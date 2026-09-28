import 'package:flutter_test/flutter_test.dart';
import 'package:sync_flow/features/sync/data/connectivity_service.dart';
import 'package:sync_flow/features/sync/data/local_cache_service.dart';
import 'package:sync_flow/features/sync/data/mutation_queue_repository.dart';
import 'package:sync_flow/features/sync/data/offline_first_task_repository.dart';
import 'package:sync_flow/features/sync/data/sync_engine.dart';
import 'package:sync_flow/features/sync/domain/network_status.dart';
import 'package:sync_flow/features/sync/domain/sync_mutation.dart';
import 'package:sync_flow/features/tasks/data/task_repository.dart';
import 'package:sync_flow/features/tasks/domain/task_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocalCacheService', () {
    late LocalCacheService cacheService;

    setUp(() {
      cacheService = LocalCacheService();
    });

    test('should cache and retrieve tasks in memory', () async {
      final task = TaskItem(
        id: 't-cache-1',
        projectId: 'p-1',
        title: 'Cached Task',
        status: TaskStatus.todo,
        priority: TaskPriority.medium,
        position: 1000,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await cacheService.saveTasks('p-1', [task]);
      final retrieved = cacheService.getCachedTasks('p-1');

      expect(retrieved, isNotNull);
      expect(retrieved!.length, 1);
      expect(retrieved.first.id, 't-cache-1');
    });

    test('upsertTask should add new task and update existing task', () async {
      final task1 = TaskItem(
        id: 't-1',
        projectId: 'p-1',
        title: 'Initial',
        status: TaskStatus.todo,
        priority: TaskPriority.low,
        position: 1000,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await cacheService.upsertTask(task1);
      expect(cacheService.getCachedTasks('p-1')?.length, 1);

      final updatedTask1 = task1.copyWith(title: 'Updated Title');
      await cacheService.upsertTask(updatedTask1);

      final list = cacheService.getCachedTasks('p-1');
      expect(list?.length, 1);
      expect(list?.first.title, 'Updated Title');
    });

    test('removeTask should remove task from cache', () async {
      final task = TaskItem(
        id: 't-delete',
        projectId: 'p-1',
        title: 'To Delete',
        status: TaskStatus.todo,
        priority: TaskPriority.low,
        position: 1000,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await cacheService.upsertTask(task);
      expect(cacheService.getCachedTasks('p-1')?.length, 1);

      await cacheService.removeTask('p-1', 't-delete');
      expect(cacheService.getCachedTasks('p-1')?.length, 0);
    });
  });

  group('MutationQueueRepository', () {
    late MutationQueueRepository queueRepo;

    setUp(() {
      queueRepo = MutationQueueRepository();
    });

    test('should enqueue mutations and retrieve in FIFO order', () async {
      final now = DateTime.now();
      final m1 = SyncMutation(
        id: 'm-1',
        entityType: 'task',
        action: 'create',
        targetId: 't-1',
        projectId: 'p-1',
        payload: {'title': 'First'},
        createdAt: now.subtract(const Duration(seconds: 10)),
      );
      final m2 = SyncMutation(
        id: 'm-2',
        entityType: 'task',
        action: 'update',
        targetId: 't-1',
        projectId: 'p-1',
        payload: {'title': 'Second'},
        createdAt: now,
      );

      await queueRepo.enqueue(m2);
      await queueRepo.enqueue(m1);

      expect(queueRepo.pendingCount, 2);

      final pending = queueRepo.getPendingMutations();
      expect(pending.length, 2);
      // FIFO: m1 was created earlier so it should be first
      expect(pending.first.id, 'm-1');
      expect(pending.last.id, 'm-2');
    });

    test('should update and remove mutations', () async {
      final mutation = SyncMutation(
        id: 'm-test',
        entityType: 'task',
        action: 'create',
        targetId: 't-10',
        projectId: 'p-1',
        payload: {},
        createdAt: DateTime.now(),
      );

      await queueRepo.enqueue(mutation);
      expect(queueRepo.pendingCount, 1);

      await queueRepo.updateMutation(mutation.copyWith(status: MutationStatus.syncing));
      final updated = queueRepo.getAll().first;
      expect(updated.status, MutationStatus.syncing);

      await queueRepo.removeMutation('m-test');
      expect(queueRepo.pendingCount, 0);
    });
  });

  group('Offline-First Sync Engine Integration', () {
    late ConnectivityService connectivity;
    late LocalCacheService cacheService;
    late MutationQueueRepository queueRepo;
    late MockTaskRepository remoteRepo;
    late OfflineFirstTaskRepository offlineRepo;
    late SyncEngine syncEngine;

    setUp(() {
      connectivity = ConnectivityService();
      cacheService = LocalCacheService();
      queueRepo = MutationQueueRepository();
      remoteRepo = MockTaskRepository();

      offlineRepo = OfflineFirstTaskRepository(
        remoteRepo: remoteRepo,
        cacheService: cacheService,
        queueRepo: queueRepo,
        connectivity: connectivity,
      );

      syncEngine = SyncEngine(
        connectivity: connectivity,
        queueRepo: queueRepo,
        cacheService: cacheService,
        remoteRepo: remoteRepo,
      );
    });

    test('should execute offline task creation, queue mutation, and drain when online', () async {
      // 1. Simulate offline
      connectivity.setSimulatedOffline(true);
      expect(connectivity.currentStatus, NetworkStatus.offline);

      final task = TaskItem(
        id: 'offline-task-1',
        projectId: 'proj-mobile-app',
        title: 'Offline Created Task',
        description: 'Created during a flight without internet',
        status: TaskStatus.inProgress,
        priority: TaskPriority.high,
        position: 1500,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // 2. Create task while offline
      final created = await offlineRepo.createTask(task);
      expect(created.id, 'offline-task-1');

      // Verify task exists immediately in local cache (zero lag)
      final cached = cacheService.getCachedTasks('proj-mobile-app');
      expect(cached, isNotNull);
      expect(cached!.any((t) => t.id == 'offline-task-1'), isTrue);

      // Verify mutation is queued
      expect(queueRepo.pendingCount, 1);
      final queuedMutation = queueRepo.getPendingMutations().first;
      expect(queuedMutation.action, 'create');
      expect(queuedMutation.targetId, 'offline-task-1');

      // 3. Reconnect to internet
      connectivity.setSimulatedOffline(false);
      expect(connectivity.currentStatus, NetworkStatus.online);

      // 4. Drain queue
      await syncEngine.drainQueue();

      // Queue should now be empty (drained)
      expect(queueRepo.pendingCount, 0);

      // Remote repository now contains the task
      final remoteTasks = await remoteRepo.getTasks('proj-mobile-app');
      expect(remoteTasks.any((t) => t.id == 'offline-task-1'), isTrue);
    });

    test('should handle concurrent updates with version conflict resolution', () async {
      // Create initial task on remote
      final initialTask = await remoteRepo.createTask(
        TaskItem(
          id: 'conflict-task-1',
          projectId: 'proj-mobile-app',
          title: 'Remote Task v1',
          status: TaskStatus.todo,
          priority: TaskPriority.low,
          position: 1000,
          version: 1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      // Go offline
      connectivity.setSimulatedOffline(true);

      // User modifies task offline
      final offlineEdit = initialTask.copyWith(
        title: 'Client Edited Title',
        status: TaskStatus.done,
      );
      await offlineRepo.updateTask(offlineEdit);

      // Meanwhile, server state bumped to version 3
      await remoteRepo.updateTask(initialTask.copyWith(version: 2));

      // Reconnect
      connectivity.setSimulatedOffline(false);

      // Drain queue with conflict resolution
      await syncEngine.drainQueue();

      // Verify queue drained
      expect(queueRepo.pendingCount, 0);

      // Verify server received updated title with reconciled higher version
      final serverTasks = await remoteRepo.getTasks('proj-mobile-app');
      final reconciled = serverTasks.firstWhere((t) => t.id == 'conflict-task-1');
      expect(reconciled.title, 'Client Edited Title');
      expect(reconciled.version >= 3, isTrue);
    });
  });
}
