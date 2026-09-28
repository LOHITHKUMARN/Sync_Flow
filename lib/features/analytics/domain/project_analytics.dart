import '../../tasks/domain/task_model.dart';

class MemberWorkload {
  final String name;
  final String? avatarUrl;
  final int totalAssigned;
  final int completed;

  const MemberWorkload({
    required this.name,
    this.avatarUrl,
    required this.totalAssigned,
    required this.completed,
  });

  double get completionRate => totalAssigned == 0 ? 0.0 : completed / totalAssigned;
}

class ProjectAnalytics {
  final int totalTasks;
  final int completedTasks;
  final int inProgressTasks;
  final int inReviewTasks;
  final int todoTasks;
  final int overdueTasks;
  final double completionRate;
  final Map<TaskStatus, int> statusCounts;
  final Map<TaskPriority, int> priorityCounts;
  final List<MemberWorkload> memberWorkloads;

  const ProjectAnalytics({
    required this.totalTasks,
    required this.completedTasks,
    required this.inProgressTasks,
    required this.inReviewTasks,
    required this.todoTasks,
    required this.overdueTasks,
    required this.completionRate,
    required this.statusCounts,
    required this.priorityCounts,
    required this.memberWorkloads,
  });

  factory ProjectAnalytics.fromTasks(List<TaskItem> tasks) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    int completed = 0;
    int inProgress = 0;
    int inReview = 0;
    int todo = 0;
    int overdue = 0;

    final statusMap = <TaskStatus, int>{
      TaskStatus.todo: 0,
      TaskStatus.inProgress: 0,
      TaskStatus.inReview: 0,
      TaskStatus.done: 0,
    };

    final priorityMap = <TaskPriority, int>{
      TaskPriority.urgent: 0,
      TaskPriority.high: 0,
      TaskPriority.medium: 0,
      TaskPriority.low: 0,
    };

    final Map<String, _MemberAccumulator> memberMap = {};

    for (final task in tasks) {
      // Status counting
      statusMap[task.status] = (statusMap[task.status] ?? 0) + 1;
      switch (task.status) {
        case TaskStatus.done:
          completed++;
          break;
        case TaskStatus.inProgress:
          inProgress++;
          break;
        case TaskStatus.inReview:
          inReview++;
          break;
        case TaskStatus.todo:
          todo++;
          break;
      }

      // Priority counting
      priorityMap[task.priority] = (priorityMap[task.priority] ?? 0) + 1;

      // Overdue counting
      if (task.dueDate != null &&
          task.dueDate!.isBefore(today) &&
          task.status != TaskStatus.done) {
        overdue++;
      }

      // Member workload
      if (task.assigneeName != null && task.assigneeName!.isNotEmpty) {
        final acc = memberMap.putIfAbsent(
          task.assigneeName!,
          () => _MemberAccumulator(
            name: task.assigneeName!,
            avatarUrl: task.assigneeAvatar,
          ),
        );
        acc.totalAssigned++;
        if (task.status == TaskStatus.done) {
          acc.completed++;
        }
      }
    }

    final total = tasks.length;
    final rate = total == 0 ? 0.0 : (completed / total);

    final workloads = memberMap.values
        .map((m) => MemberWorkload(
              name: m.name,
              avatarUrl: m.avatarUrl,
              totalAssigned: m.totalAssigned,
              completed: m.completed,
            ))
        .toList()
      ..sort((a, b) => b.totalAssigned.compareTo(a.totalAssigned));

    return ProjectAnalytics(
      totalTasks: total,
      completedTasks: completed,
      inProgressTasks: inProgress,
      inReviewTasks: inReview,
      todoTasks: todo,
      overdueTasks: overdue,
      completionRate: rate,
      statusCounts: statusMap,
      priorityCounts: priorityMap,
      memberWorkloads: workloads,
    );
  }
}

class _MemberAccumulator {
  final String name;
  final String? avatarUrl;
  int totalAssigned = 0;
  int completed = 0;

  _MemberAccumulator({required this.name, this.avatarUrl});
}
