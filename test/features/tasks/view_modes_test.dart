import 'package:flutter_test/flutter_test.dart';
import 'package:sync_flow/features/tasks/domain/task_model.dart';
import 'package:sync_flow/features/tasks/domain/task_view_mode.dart';

void main() {
  group('Phase 5: Board, List, and Calendar View Modes', () {
    final now = DateTime(2026, 9, 18);

    final t1 = TaskItem(
      id: 't-1',
      projectId: 'p-1',
      title: 'Zebra Task',
      status: TaskStatus.todo,
      priority: TaskPriority.low,
      dueDate: now.add(const Duration(days: 5)),
      position: 1000,
      createdAt: now,
      updatedAt: now,
    );

    final t2 = TaskItem(
      id: 't-2',
      projectId: 'p-1',
      title: 'Alpha Task',
      status: TaskStatus.done,
      priority: TaskPriority.urgent,
      dueDate: now.add(const Duration(days: 1)),
      position: 2000,
      createdAt: now,
      updatedAt: now,
    );

    final t3 = TaskItem(
      id: 't-3',
      projectId: 'p-1',
      title: 'Beta Task',
      status: TaskStatus.inProgress,
      priority: TaskPriority.high,
      dueDate: now.add(const Duration(days: 3)),
      position: 3000,
      createdAt: now,
      updatedAt: now,
    );

    test('Sort tasks by Due Date', () {
      final list = [t1, t2, t3];
      list.sort((a, b) {
        if (a.dueDate == null && b.dueDate == null) return 0;
        if (a.dueDate == null) return 1;
        if (b.dueDate == null) return -1;
        return a.dueDate!.compareTo(b.dueDate!);
      });

      expect(list.map((t) => t.id).toList(), ['t-2', 't-3', 't-1']);
    });

    test('Sort tasks by Priority (Urgent to Low)', () {
      final list = [t1, t2, t3];
      list.sort((a, b) => b.priority.index.compareTo(a.priority.index));

      expect(list.map((t) => t.id).toList(), ['t-2', 't-3', 't-1']);
    });

    test('Sort tasks by Title (Alphabetical)', () {
      final list = [t1, t2, t3];
      list.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

      expect(list.map((t) => t.id).toList(), ['t-2', 't-3', 't-1']);
    });

    test('Sort tasks by Status', () {
      final list = [t1, t2, t3];
      list.sort((a, b) => a.status.index.compareTo(b.status.index));

      // todo (0), inProgress (1), done (3)
      expect(list.map((t) => t.status).toList(), [
        TaskStatus.todo,
        TaskStatus.inProgress,
        TaskStatus.done,
      ]);
    });

    test('Calendar date grouping groups tasks by date string', () {
      final tasks = [t1, t2, t3];
      final Map<String, List<TaskItem>> grouped = {};

      for (final t in tasks) {
        if (t.dueDate != null) {
          final dateStr = '${t.dueDate!.year}-${t.dueDate!.month.toString().padLeft(2, '0')}-${t.dueDate!.day.toString().padLeft(2, '0')}';
          grouped.putIfAbsent(dateStr, () => []).add(t);
        }
      }

      expect(grouped['2026-09-19']?.length, 1);
      expect(grouped['2026-09-19']?.first.id, 't-2');
      expect(grouped['2026-09-21']?.first.id, 't-3');
      expect(grouped['2026-09-23']?.first.id, 't-1');
    });

    test('TaskViewMode enum returns user-friendly labels', () {
      expect(TaskViewMode.board.label, 'Board');
      expect(TaskViewMode.list.label, 'List');
      expect(TaskViewMode.calendar.label, 'Calendar');
    });
  });
}
