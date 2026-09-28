import 'package:flutter_test/flutter_test.dart';
import 'package:sync_flow/features/tasks/data/time_tracking_repository.dart';
import 'package:sync_flow/features/tasks/domain/time_entry_model.dart';
import 'package:sync_flow/features/tasks/presentation/time_tracking_providers.dart';

void main() {
  group('TimeEntry Model', () {
    test('formats duration correctly with hours and minutes', () {
      final entry = TimeEntry(
        id: '1',
        taskId: 't-1',
        userId: 'u-1',
        userName: 'Alex',
        durationSeconds: 4500, // 1h 15m
        startedAt: DateTime.now(),
      );
      expect(entry.formattedDuration, '1h 15m');
    });

    test('formats duration correctly with minutes and seconds under 1 hour', () {
      final entry = TimeEntry(
        id: '2',
        taskId: 't-1',
        userId: 'u-1',
        userName: 'Alex',
        durationSeconds: 155, // 2m 35s
        startedAt: DateTime.now(),
      );
      expect(entry.formattedDuration, '2m 35s');
    });

    test('serializes and deserializes from JSON correctly', () {
      final now = DateTime.now();
      final entry = TimeEntry(
        id: 'te-test',
        taskId: 'task-100',
        userId: 'user-200',
        userName: 'Test User',
        durationSeconds: 3600,
        startedAt: now,
        note: 'Refactored state management',
      );

      final json = entry.toJson();
      final fromJson = TimeEntry.fromJson(json);

      expect(fromJson.id, 'te-test');
      expect(fromJson.taskId, 'task-100');
      expect(fromJson.userId, 'user-200');
      expect(fromJson.durationSeconds, 3600);
      expect(fromJson.note, 'Refactored state management');
    });
  });

  group('MockTimeTrackingRepository', () {
    late MockTimeTrackingRepository repo;

  setUp(() {
    repo = MockTimeTrackingRepository();
  });

  test('loads seeded entries for task t-1', () async {
    final entries = await repo.getTimeEntries('t-1');
    expect(entries.length, greaterThanOrEqualTo(2));
    expect(entries.any((e) => e.userName == 'Alex Rivera'), isTrue);
  });

  test('adds time entry successfully', () async {
    final newEntry = TimeEntry(
      id: 'te-new',
      taskId: 't-1',
      userId: 'u-1',
      userName: 'Alex Rivera',
      durationSeconds: 1800, // 30m
      startedAt: DateTime.now(),
      note: 'Writing unit tests',
    );

    final created = await repo.addTimeEntry(newEntry);
    expect(created.id, 'te-new');
    expect(created.durationSeconds, 1800);

    final entries = await repo.getTimeEntries('t-1');
    expect(entries.first.id, 'te-new');
    expect(entries.first.note, 'Writing unit tests');
  });

  test('deletes time entry successfully', () async {
    final entriesBefore = await repo.getTimeEntries('t-1');
    final idToDelete = entriesBefore.first.id;

    await repo.deleteTimeEntry(idToDelete);

    final entriesAfter = await repo.getTimeEntries('t-1');
    expect(entriesAfter.any((e) => e.id == idToDelete), isFalse);
  });
});

  group('ActiveTimerState', () {
    test('formats time string with padded hours, minutes, and seconds', () {
      const state1 = ActiveTimerState(elapsedSeconds: 0);
      expect(state1.formattedTime, '00:00:00');

      const state2 = ActiveTimerState(elapsedSeconds: 65);
      expect(state2.formattedTime, '00:01:05');

      const state3 = ActiveTimerState(elapsedSeconds: 3661);
      expect(state3.formattedTime, '01:01:01');
    });

    test('copyWith updates fields appropriately', () {
      const state = ActiveTimerState(taskId: 't-1', elapsedSeconds: 10, isRunning: true);
      final updated = state.copyWith(isRunning: false, elapsedSeconds: 20);

      expect(updated.taskId, 't-1');
      expect(updated.elapsedSeconds, 20);
      expect(updated.isRunning, isFalse);
    });
  });
}
