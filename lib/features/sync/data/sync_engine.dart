import 'dart:async';
import '../../tasks/data/task_repository.dart';
import '../../tasks/domain/task_model.dart';
import '../domain/network_status.dart';
import '../domain/sync_mutation.dart';
import 'connectivity_service.dart';
import 'local_cache_service.dart';
import 'mutation_queue_repository.dart';

class SyncEngineState {
  final NetworkStatus networkStatus;
  final bool isSyncing;
  final int pendingCount;
  final DateTime? lastSyncTime;
  final String? lastSyncError;

  const SyncEngineState({
    required this.networkStatus,
    required this.isSyncing,
    required this.pendingCount,
    this.lastSyncTime,
    this.lastSyncError,
  });

  SyncEngineState copyWith({
    NetworkStatus? networkStatus,
    bool? isSyncing,
    int? pendingCount,
    DateTime? lastSyncTime,
    String? lastSyncError,
  }) {
    return SyncEngineState(
      networkStatus: networkStatus ?? this.networkStatus,
      isSyncing: isSyncing ?? this.isSyncing,
      pendingCount: pendingCount ?? this.pendingCount,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      lastSyncError: lastSyncError,
    );
  }
}

class SyncEngine {
  final ConnectivityService _connectivity;
  final MutationQueueRepository _queueRepo;
  final LocalCacheService _cacheService;
  final TaskRepository _remoteRepo;

  final _stateController = StreamController<SyncEngineState>.broadcast();
  StreamSubscription<NetworkStatus>? _connSubscription;
  StreamSubscription<List<SyncMutation>>? _queueSubscription;

  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  String? _lastSyncError;

  SyncEngine({
    required ConnectivityService connectivity,
    required MutationQueueRepository queueRepo,
    required LocalCacheService cacheService,
    required TaskRepository remoteRepo,
  })  : _connectivity = connectivity,
        _queueRepo = queueRepo,
        _cacheService = cacheService,
        _remoteRepo = remoteRepo {
    _init();
  }

  Stream<SyncEngineState> get onStateChanged => _stateController.stream;

  SyncEngineState get currentState => SyncEngineState(
        networkStatus: _connectivity.currentStatus,
        isSyncing: _isSyncing,
        pendingCount: _queueRepo.pendingCount,
        lastSyncTime: _lastSyncTime,
        lastSyncError: _lastSyncError,
      );

  void _init() {
    _connSubscription = _connectivity.onStatusChanged.listen((status) {
      _emitState();
      if (status.isOnline) {
        drainQueue();
      }
    });

    _queueSubscription = _queueRepo.watchQueue().listen((_) {
      _emitState();
    });

    _emitState();

    // Auto-drain if already online
    if (_connectivity.currentStatus.isOnline) {
      Future.delayed(const Duration(milliseconds: 500), drainQueue);
    }
  }

  void _emitState() {
    _stateController.add(currentState);
  }

  Future<void> drainQueue() async {
    if (_isSyncing) return;
    if (_connectivity.currentStatus.isOffline) return;

    final pending = _queueRepo.getPendingMutations();
    if (pending.isEmpty) return;

    _isSyncing = true;
    _lastSyncError = null;
    _emitState();

    try {
      for (final mutation in pending) {
        if (_connectivity.currentStatus.isOffline) break;

        await _queueRepo.updateMutation(
          mutation.copyWith(status: MutationStatus.syncing),
        );

        try {
          await _processMutation(mutation);
          // Success: remove from queue and clear
          await _queueRepo.removeMutation(mutation.id);
        } catch (e) {
          final retries = mutation.retryCount + 1;
          _lastSyncError = e.toString();
          await _queueRepo.updateMutation(
            mutation.copyWith(
              retryCount: retries,
              status: retries >= 5 ? MutationStatus.failed : MutationStatus.pending,
              lastError: e.toString(),
            ),
          );
        }
      }
      _lastSyncTime = DateTime.now();
    } finally {
      _isSyncing = false;
      _emitState();
    }
  }

  Future<void> _processMutation(SyncMutation mutation) async {
    switch (mutation.action) {
      case 'create':
        final task = TaskItem.fromJson(mutation.payload);
        final created = await _remoteRepo.createTask(task);
        await _cacheService.upsertTask(created);
        break;

      case 'update':
        final clientTask = TaskItem.fromJson(mutation.payload);

        // Version Conflict Check & Resolution
        // If server task exists and has higher version, client takes server version + 1
        TaskItem resolvedTask = clientTask;
        try {
          final serverTasks = await _remoteRepo.getTasks(clientTask.projectId);
          final serverTask = serverTasks.firstWhere(
            (t) => t.id == clientTask.id,
            orElse: () => clientTask,
          );

          if (serverTask.version > mutation.clientVersion) {
            // Conflict detected: Last-Write-Wins with version increment
            resolvedTask = clientTask.copyWith(
              version: serverTask.version + 1,
              updatedAt: DateTime.now(),
            );
          }
        } catch (_) {
          // If checking server tasks fails, proceed with client task
        }

        final updated = await _remoteRepo.updateTask(resolvedTask);
        await _cacheService.upsertTask(updated);
        break;

      case 'delete':
        await _remoteRepo.deleteTask(mutation.targetId);
        await _cacheService.removeTask(mutation.projectId, mutation.targetId);
        break;
    }
  }

  void dispose() {
    _connSubscription?.cancel();
    _queueSubscription?.cancel();
    _stateController.close();
  }
}
