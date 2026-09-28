import 'package:flutter_test/flutter_test.dart';
import 'package:sync_flow/features/analytics/domain/project_analytics.dart';
import 'package:sync_flow/features/tasks/domain/task_model.dart';

void main() {
  group('Phase 6: Project Analytics & Velocity Metrics Tests', () {
    final now = DateTime.now();

    test('should calculate correct metrics for empty task list', () {
      final analytics = ProjectAnalytics.fromTasks([]);

      expect(analytics.totalTasks, 0);
      expect(analytics.completedTasks, 0);
      expect(analytics.completionRate, 0.0);
      expect(analytics.overdueTasks, 0);
      expect(analytics.memberWorkloads, isEmpty);
    });

    test('should calculate accurate completion rate, statuses, and priorities', () {
      final tasks = [
        TaskItem(
          id: 't-1',
          projectId: 'p-1',
          title: 'Task 1',
          status: TaskStatus.done,
          priority: TaskPriority.urgent,
          assigneeName: 'Alex Rivera',
          position: 1000,
          createdAt: now,
          updatedAt: now,
        ),
        TaskItem(
          id: 't-2',
          projectId: 'p-1',
          title: 'Task 2',
          status: TaskStatus.done,
          priority: TaskPriority.high,
          assigneeName: 'Alex Rivera',
          position: 2000,
          createdAt: now,
          updatedAt: now,
        ),
        TaskItem(
          id: 't-3',
          projectId: 'p-1',
          title: 'Task 3',
          status: TaskStatus.inProgress,
          priority: TaskPriority.medium,
          assigneeName: 'Rahul Sharma',
          position: 3000,
          createdAt: now,
          updatedAt: now,
        ),
        TaskItem(
          id: 't-4',
          projectId: 'p-1',
          title: 'Task 4',
          status: TaskStatus.todo,
          priority: TaskPriority.low,
          position: 4000,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final analytics = ProjectAnalytics.fromTasks(tasks);

      expect(analytics.totalTasks, 4);
      expect(analytics.completedTasks, 2);
      expect(analytics.inProgressTasks, 1);
      expect(analytics.todoTasks, 1);
      expect(analytics.inReviewTasks, 0);
      expect(analytics.completionRate, 0.5); // 2 out of 4 = 50%

      expect(analytics.priorityCounts[TaskPriority.urgent], 1);
      expect(analytics.priorityCounts[TaskPriority.high], 1);
      expect(analytics.priorityCounts[TaskPriority.medium], 1);
      expect(analytics.priorityCounts[TaskPriority.low], 1);
    });

    test('should detect and count overdue tasks accurately', () {
      final pastDate = now.subtract(const Duration(days: 3));
      final futureDate = now.add(const Duration(days: 3));

      final tasks = [
        TaskItem(
          id: 't-overdue-1',
          projectId: 'p-1',
          title: 'Overdue Todo',
          status: TaskStatus.todo,
          priority: TaskPriority.urgent,
          dueDate: pastDate,
          position: 1000,
          createdAt: now,
          updatedAt: now,
        ),
        TaskItem(
          id: 't-overdue-2',
          projectId: 'p-1',
          title: 'Overdue In Progress',
          status: TaskStatus.inProgress,
          priority: TaskPriority.high,
          dueDate: pastDate,
          position: 2000,
          createdAt: now,
          updatedAt: now,
        ),
        TaskItem(
          id: 't-done-past',
          projectId: 'p-1',
          title: 'Done in the past (not counted as overdue)',
          status: TaskStatus.done,
          priority: TaskPriority.low,
          dueDate: pastDate,
          position: 3000,
          createdAt: now,
          updatedAt: now,
        ),
        TaskItem(
          id: 't-future',
          projectId: 'p-1',
          title: 'On track future task',
          status: TaskStatus.todo,
          priority: TaskPriority.medium,
          dueDate: futureDate,
          position: 4000,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final analytics = ProjectAnalytics.fromTasks(tasks);
      expect(analytics.overdueTasks, 2);
    });

    test('should calculate member workload and rank by volume', () {
      final tasks = [
        TaskItem(
          id: 't-1',
          projectId: 'p-1',
          title: 'Task 1',
          status: TaskStatus.done,
          priority: TaskPriority.low,
          assigneeName: 'Alex Rivera',
          position: 1000,
          createdAt: now,
          updatedAt: now,
        ),
        TaskItem(
          id: 't-2',
          projectId: 'p-1',
          title: 'Task 2',
          status: TaskStatus.inProgress,
          priority: TaskPriority.low,
          assigneeName: 'Alex Rivera',
          position: 2000,
          createdAt: now,
          updatedAt: now,
        ),
        TaskItem(
          id: 't-3',
          projectId: 'p-1',
          title: 'Task 3',
          status: TaskStatus.todo,
          priority: TaskPriority.low,
          assigneeName: 'Alex Rivera',
          position: 3000,
          createdAt: now,
          updatedAt: now,
        ),
        TaskItem(
          id: 't-4',
          projectId: 'p-1',
          title: 'Task 4',
          status: TaskStatus.done,
          priority: TaskPriority.low,
          assigneeName: 'Rahul Sharma',
          position: 4000,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final analytics = ProjectAnalytics.fromTasks(tasks);
      expect(analytics.memberWorkloads.length, 2);

      // Alex has 3 tasks, so ranks #1
      final topMember = analytics.memberWorkloads.first;
      expect(topMember.name, 'Alex Rivera');
      expect(topMember.totalAssigned, 3);
      expect(topMember.completed, 1);
      expect(topMember.completionRate, closeTo(1 / 3, 0.01));

      // Rahul has 1 task (100% completed)
      final secondMember = analytics.memberWorkloads[1];
      expect(secondMember.name, 'Rahul Sharma');
      expect(secondMember.totalAssigned, 1);
      expect(secondMember.completed, 1);
      expect(secondMember.completionRate, 1.0);
    });
  });
}
