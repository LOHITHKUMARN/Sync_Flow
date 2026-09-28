import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:uuid/uuid.dart';
import '../../../core/config/env_config.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/time_tracking_repository.dart';
import '../domain/time_entry_model.dart';

final timeTrackingRepositoryProvider = Provider<TimeTrackingRepository>((ref) {
  if (EnvConfig.hasLiveSupabaseConfig) {
    return SupabaseTimeTrackingRepository(sb.Supabase.instance.client);
  }
  return MockTimeTrackingRepository();
});

class TaskTimeEntriesNotifier extends Notifier<AsyncValue<List<TimeEntry>>> {
  final String taskId;

  TaskTimeEntriesNotifier(this.taskId);

  @override
  AsyncValue<List<TimeEntry>> build() {
    final repo = ref.watch(timeTrackingRepositoryProvider);
    final sub = repo.watchTimeEntries(taskId).listen(
      (entries) {
        state = AsyncValue.data(entries);
      },
      onError: (e, st) {
        state = AsyncValue.error(e, st);
      },
    );
    ref.onDispose(sub.cancel);

    Future.microtask(loadEntries);
    return const AsyncValue.loading();
  }

  Future<void> loadEntries() async {
    try {
      final repo = ref.read(timeTrackingRepositoryProvider);
      final list = await repo.getTimeEntries(taskId);
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<TimeEntry> logTime({
    required int durationSeconds,
    required DateTime startedAt,
    DateTime? endedAt,
    String? note,
  }) async {
    final repo = ref.read(timeTrackingRepositoryProvider);
    final currentUser = ref.read(currentUserProvider);
    final entry = TimeEntry(
      id: const Uuid().v4(),
      taskId: taskId,
      userId: currentUser?.id ?? 'u-current',
      userName: currentUser?.fullName ?? 'Current User',
      durationSeconds: durationSeconds,
      startedAt: startedAt,
      endedAt: endedAt ?? startedAt.add(Duration(seconds: durationSeconds)),
      note: note,
    );

    final created = await repo.addTimeEntry(entry);
    final current = state.value ?? [];
    state = AsyncValue.data([created, ...current]);
    return created;
  }

  Future<void> deleteEntry(String entryId) async {
    final repo = ref.read(timeTrackingRepositoryProvider);
    await repo.deleteTimeEntry(entryId);
    final current = state.value ?? [];
    state = AsyncValue.data(current.where((e) => e.id != entryId).toList());
  }
}

final taskTimeEntriesProvider =
    NotifierProvider.family<TaskTimeEntriesNotifier, AsyncValue<List<TimeEntry>>, String>(
  (arg) => TaskTimeEntriesNotifier(arg),
);

// Active Stopwatch Timer State
class ActiveTimerState {
  final String? taskId;
  final String? taskTitle;
  final int elapsedSeconds;
  final bool isRunning;
  final DateTime? startedAt;

  const ActiveTimerState({
    this.taskId,
    this.taskTitle,
    this.elapsedSeconds = 0,
    this.isRunning = false,
    this.startedAt,
  });

  String get formattedTime {
    final hours = (elapsedSeconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((elapsedSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  ActiveTimerState copyWith({
    String? taskId,
    String? taskTitle,
    int? elapsedSeconds,
    bool? isRunning,
    DateTime? startedAt,
    bool clearTask = false,
  }) {
    return ActiveTimerState(
      taskId: clearTask ? null : (taskId ?? this.taskId),
      taskTitle: clearTask ? null : (taskTitle ?? this.taskTitle),
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      isRunning: isRunning ?? this.isRunning,
      startedAt: clearTask ? null : (startedAt ?? this.startedAt),
    );
  }
}

class ActiveTimerNotifier extends Notifier<ActiveTimerState> {
  Timer? _ticker;

  @override
  ActiveTimerState build() {
    ref.onDispose(() {
      _ticker?.cancel();
    });
    return const ActiveTimerState();
  }

  void startTimer(String taskId, String taskTitle) {
    if (state.taskId == taskId && state.isRunning) return;

    _ticker?.cancel();
    state = ActiveTimerState(
      taskId: taskId,
      taskTitle: taskTitle,
      elapsedSeconds: state.taskId == taskId ? state.elapsedSeconds : 0,
      isRunning: true,
      startedAt: DateTime.now(),
    );

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
    });
  }

  void pauseTimer() {
    _ticker?.cancel();
    state = state.copyWith(isRunning: false);
  }

  void resumeTimer() {
    if (state.taskId == null) return;
    _ticker?.cancel();
    state = state.copyWith(isRunning: true);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
    });
  }

  void resetTimer() {
    _ticker?.cancel();
    state = const ActiveTimerState();
  }

  Future<TimeEntry?> stopAndSave({String? note}) async {
    final taskId = state.taskId;
    final seconds = state.elapsedSeconds;
    final startedAt = state.startedAt ?? DateTime.now().subtract(Duration(seconds: seconds));

    if (taskId == null || seconds <= 0) {
      resetTimer();
      return null;
    }

    _ticker?.cancel();
    state = const ActiveTimerState();

    final notifier = ref.read(taskTimeEntriesProvider(taskId).notifier);
    return await notifier.logTime(
      durationSeconds: seconds,
      startedAt: startedAt,
      endedAt: DateTime.now(),
      note: note,
    );
  }
}

final activeTimerProvider =
    NotifierProvider<ActiveTimerNotifier, ActiveTimerState>(ActiveTimerNotifier.new);
