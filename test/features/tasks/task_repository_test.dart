import 'package:flutter_test/flutter_test.dart';
import 'package:sync_flow/features/tasks/data/task_repository.dart';
import 'package:sync_flow/features/tasks/domain/task_model.dart';

void main() {
  group('MockTaskRepository Tests', () {
    late MockTaskRepository repository;

    setUp(() {
      repository = MockTaskRepository();
    });

    test('Loads initial seeded tasks for default project', () async {
      final tasks = await repository.getTasks('proj-mobile-app');
      expect(tasks.isNotEmpty, true);
      expect(tasks.any((t) => t.status == TaskStatus.done), true);
      expect(tasks.any((t) => t.status == TaskStatus.inProgress), true);
      expect(tasks.any((t) => t.status == TaskStatus.todo), true);
    });

    test('Updates task status and increments version for conflict tracking', () async {
      final tasks = await repository.getTasks('proj-mobile-app');
      final firstTask = tasks.first;
      final initialVersion = firstTask.version;

      final movedTask = firstTask.copyWith(status: TaskStatus.inReview);
      final updated = await repository.updateTask(movedTask);

      expect(updated.status, TaskStatus.inReview);
      expect(updated.version, initialVersion + 1);
    });

    test('Creates new task and persists in project stream', () async {
      final newTask = TaskItem(
        id: 'test-new-1',
        projectId: 'proj-mobile-app',
        title: 'New Unit Test Task',
        status: TaskStatus.todo,
        priority: TaskPriority.urgent,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final created = await repository.createTask(newTask);
      expect(created.id, 'test-new-1');

      final tasks = await repository.getTasks('proj-mobile-app');
      expect(tasks.any((t) => t.id == 'test-new-1'), true);
    });

    test('Deletes task properly', () async {
      final tasks = await repository.getTasks('proj-mobile-app');
      final idToDelete = tasks.first.id;

      await repository.deleteTask(idToDelete);
      final remaining = await repository.getTasks('proj-mobile-app');
      expect(remaining.any((t) => t.id == idToDelete), false);
    });
  });
}
