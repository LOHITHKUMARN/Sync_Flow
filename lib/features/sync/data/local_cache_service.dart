import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../tasks/domain/task_model.dart';

class LocalCacheService {
  final SharedPreferences? _prefs;
  final Map<String, List<TaskItem>> _inMemoryTaskCache = {};

  LocalCacheService({SharedPreferences? prefs}) : _prefs = prefs;

  static const String _taskCachePrefix = 'syncflow_cache_tasks_';

  List<TaskItem>? getCachedTasks(String projectId) {
    if (_inMemoryTaskCache.containsKey(projectId)) {
      return List.unmodifiable(_inMemoryTaskCache[projectId]!);
    }

    if (_prefs != null) {
      final jsonString = _prefs.getString('$_taskCachePrefix$projectId');
      if (jsonString != null) {
        try {
          final list = jsonDecode(jsonString) as List;
          final tasks = list.map((item) => TaskItem.fromJson(Map<String, dynamic>.from(item as Map))).toList();
          _inMemoryTaskCache[projectId] = tasks;
          return List.unmodifiable(tasks);
        } catch (_) {}
      }
    }
    return null;
  }

  Future<void> saveTasks(String projectId, List<TaskItem> tasks) async {
    _inMemoryTaskCache[projectId] = List.from(tasks);
    if (_prefs != null) {
      final jsonString = jsonEncode(tasks.map((t) => t.toJson()).toList());
      await _prefs.setString('$_taskCachePrefix$projectId', jsonString);
    }
  }

  Future<void> upsertTask(TaskItem task) async {
    final list = _inMemoryTaskCache[task.projectId] != null
        ? List<TaskItem>.from(_inMemoryTaskCache[task.projectId]!)
        : (getCachedTasks(task.projectId) != null
            ? List<TaskItem>.from(getCachedTasks(task.projectId)!)
            : <TaskItem>[]);

    final index = list.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      list[index] = task;
    } else {
      list.add(task);
    }
    _inMemoryTaskCache[task.projectId] = list;

    if (_prefs != null) {
      final jsonString = jsonEncode(list.map((t) => t.toJson()).toList());
      await _prefs.setString('$_taskCachePrefix${task.projectId}', jsonString);
    }
  }

  Future<void> removeTask(String projectId, String taskId) async {
    final list = _inMemoryTaskCache[projectId] != null
        ? List<TaskItem>.from(_inMemoryTaskCache[projectId]!)
        : (getCachedTasks(projectId) != null
            ? List<TaskItem>.from(getCachedTasks(projectId)!)
            : <TaskItem>[]);

    list.removeWhere((t) => t.id == taskId);
    _inMemoryTaskCache[projectId] = list;

    if (_prefs != null) {
      final jsonString = jsonEncode(list.map((t) => t.toJson()).toList());
      await _prefs.setString('$_taskCachePrefix$projectId', jsonString);
    }
  }

  Future<void> clearAll() async {
    _inMemoryTaskCache.clear();
    if (_prefs != null) {
      final keys = _prefs.getKeys().where((k) => k.startsWith(_taskCachePrefix));
      for (final key in keys) {
        await _prefs.remove(key);
      }
    }
  }
}
