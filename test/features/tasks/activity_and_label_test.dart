import 'package:flutter_test/flutter_test.dart';
import 'package:sync_flow/features/tasks/data/activity_repository.dart';
import 'package:sync_flow/features/tasks/data/label_repository.dart';
import 'package:sync_flow/features/tasks/domain/activity_model.dart';

void main() {
  group('MockActivityRepository Tests', () {
    late MockActivityRepository repo;

    setUp(() {
      repo = MockActivityRepository();
    });

    test('Loads seeded task activity logs', () async {
      final activities = await repo.getActivities('task-auth-001');
      expect(activities.isNotEmpty, true);
      expect(activities.any((a) => a.actionType == 'created'), true);
      expect(activities.any((a) => a.actionType == 'assigned'), true);
      expect(activities.any((a) => a.actionType == 'status_changed'), true);
    });

    test('Logs new activity event at top of timeline', () async {
      final newActivity = TaskActivity(
        id: 'act-new-1',
        taskId: 'task-auth-001',
        actorId: 'usr-1',
        actorName: 'Alex Rivera',
        actionType: 'label_changed',
        summary: 'added label "Critical Bug"',
        createdAt: DateTime.now(),
      );

      await repo.logActivity(newActivity);
      final list = await repo.getActivities('task-auth-001');
      expect(list.first.actionType, 'label_changed');
      expect(list.first.summary, 'added label "Critical Bug"');
    });
  });

  group('MockLabelRepository Tests', () {
    late MockLabelRepository repo;

    setUp(() {
      repo = MockLabelRepository();
    });

    test('Loads pre-configured workspace labels', () async {
      final labels = await repo.getLabels('ws-default-1');
      expect(labels.length, greaterThanOrEqualTo(5));
      expect(labels.any((l) => l.name == 'Frontend'), true);
      expect(labels.any((l) => l.name == 'Bug'), true);
      expect(labels.any((l) => l.name == 'Feature'), true);
    });

    test('Creates custom label dynamically', () async {
      final created = await repo.createLabel(
        workspaceId: 'ws-default-1',
        name: 'Urgent Patch',
        colorHex: '#DC2626',
      );

      expect(created.name, 'Urgent Patch');
      expect(created.colorHex, '#DC2626');

      final labels = await repo.getLabels('ws-default-1');
      expect(labels.any((l) => l.name == 'Urgent Patch'), true);
    });
  });
}
