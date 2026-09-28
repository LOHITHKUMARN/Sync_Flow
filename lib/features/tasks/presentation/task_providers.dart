import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/task_repository.dart';
import '../domain/task_model.dart';
import '../domain/task_view_mode.dart';
import '../../sync/presentation/sync_providers.dart';

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return ref.watch(offlineFirstTaskRepositoryProvider);
});


class TasksNotifier extends Notifier<AsyncValue<List<TaskItem>>> {
  final String projectId;

  TasksNotifier(this.projectId);

  @override
  AsyncValue<List<TaskItem>> build() {
    final repo = ref.watch(taskRepositoryProvider);
    final sub = repo.watchTasks(projectId).listen(
      (tasks) {
        state = AsyncValue.data(tasks);
      },
      onError: (_, __) {},
    );
    ref.onDispose(sub.cancel);

    Future.microtask(loadTasks);
    return const AsyncValue.loading();
  }

  Future<void> loadTasks() async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(taskRepositoryProvider);
      final tasks = await repo.getTasks(projectId);
      state = AsyncValue.data(tasks);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Optimistic status move for instant fluid drag-and-drop
  Future<void> moveTaskStatus({
    required String taskId,
    required TaskStatus newStatus,
  }) async {
    final currentTasks = state.value;
    if (currentTasks == null) return;

    final targetIndex = currentTasks.indexWhere((t) => t.id == taskId);
    if (targetIndex == -1) return;

    final oldTask = currentTasks[targetIndex];
    if (oldTask.status == newStatus) return;

    final updatedTask = oldTask.copyWith(
      status: newStatus,
      updatedAt: DateTime.now(),
    );

    // 1. Instant optimistic update
    final updatedList = List<TaskItem>.from(currentTasks);
    updatedList[targetIndex] = updatedTask;
    state = AsyncValue.data(updatedList);

    // 2. Persist to backend
    try {
      final repo = ref.read(taskRepositoryProvider);
      await repo.updateTask(updatedTask);
    } catch (e) {
      // Rollback on error
      final reverted = List<TaskItem>.from(currentTasks);
      state = AsyncValue.data(reverted);
      rethrow;
    }
  }

  Future<void> addTask(TaskItem task) async {
    final repo = ref.read(taskRepositoryProvider);
    final created = await repo.createTask(task);
    final current = state.value ?? [];
    state = AsyncValue.data([...current, created]);
  }

  Future<void> updateTaskDetails(TaskItem task) async {
    final repo = ref.read(taskRepositoryProvider);
    final updated = await repo.updateTask(task);
    final current = state.value ?? [];
    final index = current.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      final list = List<TaskItem>.from(current);
      list[index] = updated;
      state = AsyncValue.data(list);
    }
  }

  Future<void> removeTask(String taskId) async {
    final repo = ref.read(taskRepositoryProvider);
    await repo.deleteTask(taskId);
    final current = state.value ?? [];
    state = AsyncValue.data(current.where((t) => t.id != taskId).toList());
  }
}

final tasksNotifierProvider =
    NotifierProvider.family<TasksNotifier, AsyncValue<List<TaskItem>>, String>(
  (arg) => TasksNotifier(arg),
);

class TaskSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  void setQuery(String q) => state = q;
}

final taskSearchQueryProvider =
    NotifierProvider<TaskSearchQueryNotifier, String>(TaskSearchQueryNotifier.new);

class TaskPriorityFilterNotifier extends Notifier<TaskPriority?> {
  @override
  TaskPriority? build() => null;
  void setFilter(TaskPriority? p) => state = p;
}

final taskPriorityFilterProvider =
    NotifierProvider<TaskPriorityFilterNotifier, TaskPriority?>(TaskPriorityFilterNotifier.new);

class TaskLabelFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void setFilter(String? labelId) => state = labelId;
}

final taskLabelFilterProvider =
    NotifierProvider<TaskLabelFilterNotifier, String?>(TaskLabelFilterNotifier.new);

final filteredTasksProvider = Provider.family<List<TaskItem>, String>((ref, projectId) {
  final tasksAsync = ref.watch(tasksNotifierProvider(projectId));
  final query = ref.watch(taskSearchQueryProvider).toLowerCase();
  final priorityFilter = ref.watch(taskPriorityFilterProvider);
  final labelFilter = ref.watch(taskLabelFilterProvider);

  return tasksAsync.maybeWhen(
    data: (tasks) {
      return tasks.where((t) {
        final matchesQuery = query.isEmpty ||
            t.title.toLowerCase().contains(query) ||
            t.description.toLowerCase().contains(query) ||
            (t.assigneeName != null && t.assigneeName!.toLowerCase().contains(query));
        final matchesPriority = priorityFilter == null || t.priority == priorityFilter;
        final matchesLabel = labelFilter == null || t.labels.any((l) => l.id == labelFilter);
        return matchesQuery && matchesPriority && matchesLabel;
      }).toList();
    },
    orElse: () => [],
  );
});

class TaskViewModeNotifier extends Notifier<TaskViewMode> {
  @override
  TaskViewMode build() => TaskViewMode.board;
  void setMode(TaskViewMode mode) => state = mode;
}

final taskViewModeProvider =
    NotifierProvider<TaskViewModeNotifier, TaskViewMode>(TaskViewModeNotifier.new);

class TaskListSortNotifier extends Notifier<TaskListSortBy> {
  @override
  TaskListSortBy build() => TaskListSortBy.dueDate;
  void setSort(TaskListSortBy sort) => state = sort;
}

final taskListSortProvider =
    NotifierProvider<TaskListSortNotifier, TaskListSortBy>(TaskListSortNotifier.new);
