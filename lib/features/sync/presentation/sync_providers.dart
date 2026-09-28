import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../../core/config/env_config.dart';
import '../../tasks/data/task_repository.dart';
import '../data/connectivity_service.dart';
import '../data/local_cache_service.dart';
import '../data/mutation_queue_repository.dart';
import '../data/offline_first_task_repository.dart';
import '../data/sync_engine.dart';
import '../domain/network_status.dart';
import '../domain/sync_mutation.dart';

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService();
  ref.onDispose(service.dispose);
  return service;
});

final localCacheServiceProvider = Provider<LocalCacheService>((ref) {
  return LocalCacheService();
});

final mutationQueueRepositoryProvider = Provider<MutationQueueRepository>((ref) {
  final repo = MutationQueueRepository();
  ref.onDispose(repo.dispose);
  return repo;
});

final rawRemoteTaskRepositoryProvider = Provider<TaskRepository>((ref) {
  if (EnvConfig.hasLiveSupabaseConfig) {
    return SupabaseTaskRepository(sb.Supabase.instance.client);
  }
  return MockTaskRepository();
});

final offlineFirstTaskRepositoryProvider = Provider<TaskRepository>((ref) {
  final remoteRepo = ref.watch(rawRemoteTaskRepositoryProvider);
  final cacheService = ref.watch(localCacheServiceProvider);
  final queueRepo = ref.watch(mutationQueueRepositoryProvider);
  final connectivity = ref.watch(connectivityServiceProvider);

  return OfflineFirstTaskRepository(
    remoteRepo: remoteRepo,
    cacheService: cacheService,
    queueRepo: queueRepo,
    connectivity: connectivity,
  );
});

final syncEngineProvider = Provider<SyncEngine>((ref) {
  final connectivity = ref.watch(connectivityServiceProvider);
  final queueRepo = ref.watch(mutationQueueRepositoryProvider);
  final cacheService = ref.watch(localCacheServiceProvider);
  final remoteRepo = ref.watch(rawRemoteTaskRepositoryProvider);

  final engine = SyncEngine(
    connectivity: connectivity,
    queueRepo: queueRepo,
    cacheService: cacheService,
    remoteRepo: remoteRepo,
  );
  ref.onDispose(engine.dispose);
  return engine;
});

final syncEngineStateProvider = StreamProvider<SyncEngineState>((ref) {
  final engine = ref.watch(syncEngineProvider);
  return engine.onStateChanged;
});

final networkStatusStreamProvider = StreamProvider<NetworkStatus>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.onStatusChanged;
});

final mutationQueueStreamProvider = StreamProvider<List<SyncMutation>>((ref) {
  final repo = ref.watch(mutationQueueRepositoryProvider);
  return repo.watchQueue();
});
