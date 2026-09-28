import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:uuid/uuid.dart';
import '../domain/time_entry_model.dart';

abstract class TimeTrackingRepository {
  Future<List<TimeEntry>> getTimeEntries(String taskId);
  Future<TimeEntry> addTimeEntry(TimeEntry entry);
  Future<void> deleteTimeEntry(String entryId);
  Stream<List<TimeEntry>> watchTimeEntries(String taskId);
}

class SupabaseTimeTrackingRepository implements TimeTrackingRepository {
  final sb.SupabaseClient _client;

  SupabaseTimeTrackingRepository(this._client);

  @override
  Future<List<TimeEntry>> getTimeEntries(String taskId) async {
    final res = await _client
        .from('task_time_entries')
        .select('*, profiles(full_name)')
        .eq('task_id', taskId)
        .order('created_at', ascending: false);

    return (res as List).map((json) {
      final map = Map<String, dynamic>.from(json);
      if (json['profiles'] != null && json['profiles'] is Map) {
        map['user_name'] = json['profiles']['full_name'];
      }
      return TimeEntry.fromJson(map);
    }).toList();
  }

  @override
  Future<TimeEntry> addTimeEntry(TimeEntry entry) async {
    final json = entry.toJson()..remove('id');
    final res = await _client.from('task_time_entries').insert(json).select().single();
    return TimeEntry.fromJson(res);
  }

  @override
  Future<void> deleteTimeEntry(String entryId) async {
    await _client.from('task_time_entries').delete().eq('id', entryId);
  }

  @override
  Stream<List<TimeEntry>> watchTimeEntries(String taskId) {
    return _client
        .from('task_time_entries')
        .stream(primaryKey: ['id'])
        .eq('task_id', taskId)
        .order('created_at', ascending: false)
        .map((maps) => maps.map((json) => TimeEntry.fromJson(json)).toList());
  }
}

class MockTimeTrackingRepository implements TimeTrackingRepository {
  final Map<String, List<TimeEntry>> _entries = {};
  final _controllers = <String, StreamController<List<TimeEntry>>>{};

  MockTimeTrackingRepository() {
    _seedData();
  }

  void _seedData() {
    final now = DateTime.now();

    _entries['t-1'] = [
      TimeEntry(
        id: 'te-1',
        taskId: 't-1',
        userId: 'u-1',
        userName: 'Alex Rivera',
        durationSeconds: 4500, // 1h 15m
        startedAt: now.subtract(const Duration(days: 2, hours: 2)),
        endedAt: now.subtract(const Duration(days: 2, minutes: 45)),
        note: 'Designed typography scales and primary neon glass tokens',
      ),
      TimeEntry(
        id: 'te-2',
        taskId: 't-1',
        userId: 'u-2',
        userName: 'Rahul Sharma',
        durationSeconds: 2700, // 45m
        startedAt: now.subtract(const Duration(days: 1, hours: 3)),
        endedAt: now.subtract(const Duration(days: 1, hours: 2, minutes: 15)),
        note: 'Reviewed contrast ratios for accessibility (WCAG AA)',
      ),
    ];

    _entries['t-2'] = [
      TimeEntry(
        id: 'te-3',
        taskId: 't-2',
        userId: 'u-1',
        userName: 'Alex Rivera',
        durationSeconds: 5400, // 1h 30m
        startedAt: now.subtract(const Duration(hours: 8)),
        endedAt: now.subtract(const Duration(hours: 6, minutes: 30)),
        note: 'Implemented drag target feedback animations and spring physics',
      ),
    ];
  }

  StreamController<List<TimeEntry>> _getController(String taskId) {
    return _controllers.putIfAbsent(
      taskId,
      () => StreamController<List<TimeEntry>>.broadcast(),
    );
  }

  List<TimeEntry> _getList(String taskId) {
    return _entries.putIfAbsent(taskId, () => []);
  }

  void _notify(String taskId) {
    final list = _getList(taskId);
    _getController(taskId).add(List.unmodifiable(list));
  }

  @override
  Future<List<TimeEntry>> getTimeEntries(String taskId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return List.unmodifiable(_getList(taskId));
  }

  @override
  Future<TimeEntry> addTimeEntry(TimeEntry entry) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final item = TimeEntry(
      id: entry.id.isEmpty ? const Uuid().v4() : entry.id,
      taskId: entry.taskId,
      userId: entry.userId,
      userName: entry.userName,
      durationSeconds: entry.durationSeconds,
      startedAt: entry.startedAt,
      endedAt: entry.endedAt ?? entry.startedAt.add(Duration(seconds: entry.durationSeconds)),
      note: entry.note,
    );

    final list = _getList(entry.taskId);
    list.insert(0, item);
    _notify(entry.taskId);
    return item;
  }

  @override
  Future<void> deleteTimeEntry(String entryId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    for (final entry in _entries.entries) {
      final index = entry.value.indexWhere((e) => e.id == entryId);
      if (index != -1) {
        entry.value.removeAt(index);
        _notify(entry.key);
        break;
      }
    }
  }

  @override
  Stream<List<TimeEntry>> watchTimeEntries(String taskId) {
    final controller = _getController(taskId);
    Future.microtask(() => controller.add(List.unmodifiable(_getList(taskId))));
    return controller.stream;
  }
}
