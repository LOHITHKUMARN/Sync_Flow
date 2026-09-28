import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../data/activity_repository.dart';
import '../domain/activity_model.dart';
import '../../../core/config/env_config.dart';

final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  if (EnvConfig.hasLiveSupabaseConfig) {
    return SupabaseActivityRepository(sb.Supabase.instance.client);
  }
  return MockActivityRepository();
});

class TaskActivitiesNotifier extends Notifier<AsyncValue<List<TaskActivity>>> {
  final String taskId;

  TaskActivitiesNotifier(this.taskId);

  @override
  AsyncValue<List<TaskActivity>> build() {
    final repo = ref.watch(activityRepositoryProvider);
    final sub = repo.watchActivities(taskId).listen(
      (acts) => state = AsyncValue.data(acts),
      onError: (_, __) {},
    );
    ref.onDispose(sub.cancel);

    Future.microtask(loadActivities);
    return const AsyncValue.loading();
  }

  Future<void> loadActivities() async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(activityRepositoryProvider);
      final list = await repo.getActivities(taskId);
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> recordActivity({
    required String actorId,
    required String actorName,
    String? actorAvatar,
    required String actionType,
    required String summary,
    String? projectId,
  }) async {
    final repo = ref.read(activityRepositoryProvider);
    final act = TaskActivity(
      id: 'act-${DateTime.now().millisecondsSinceEpoch}',
      taskId: taskId,
      projectId: projectId,
      actorId: actorId,
      actorName: actorName,
      actorAvatar: actorAvatar,
      actionType: actionType,
      summary: summary,
      createdAt: DateTime.now(),
    );
    final created = await repo.logActivity(act);
    final current = state.value ?? [];
    state = AsyncValue.data([created, ...current]);
  }
}

final taskActivitiesProvider = NotifierProvider.family<
    TaskActivitiesNotifier, AsyncValue<List<TaskActivity>>, String>(
  (arg) => TaskActivitiesNotifier(arg),
);
