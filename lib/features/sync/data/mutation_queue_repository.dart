import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/sync_mutation.dart';

class MutationQueueRepository {
  final SharedPreferences? _prefs;
  final List<SyncMutation> _queue = [];
  final _queueStreamController = StreamController<List<SyncMutation>>.broadcast();

  static const String _queueKey = 'syncflow_mutation_queue';

  MutationQueueRepository({SharedPreferences? prefs}) : _prefs = prefs {
    _loadFromStorage();
  }

  void _loadFromStorage() {
    if (_prefs == null) return;
    final jsonString = _prefs.getString(_queueKey);
    if (jsonString != null) {
      try {
        final list = jsonDecode(jsonString) as List;
        _queue.clear();
        _queue.addAll(
          list.map((item) => SyncMutation.fromJson(Map<String, dynamic>.from(item as Map))),
        );
        _notify();
      } catch (_) {}
    }
  }

  Future<void> _persist() async {
    if (_prefs == null) return;
    final jsonString = jsonEncode(_queue.map((m) => m.toJson()).toList());
    await _prefs.setString(_queueKey, jsonString);
  }

  void _notify() {
    _queueStreamController.add(List.unmodifiable(_queue));
  }

  int get pendingCount => _queue.where((m) => m.status != MutationStatus.synced).length;

  List<SyncMutation> getAll() => List.unmodifiable(_queue);

  List<SyncMutation> getPendingMutations() {
    return _queue
        .where((m) => m.status == MutationStatus.pending || m.status == MutationStatus.failed)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt)); // FIFO order
  }

  Future<void> enqueue(SyncMutation mutation) async {
    _queue.add(mutation);
    _notify();
    await _persist();
  }

  Future<void> updateMutation(SyncMutation mutation) async {
    final index = _queue.indexWhere((m) => m.id == mutation.id);
    if (index != -1) {
      _queue[index] = mutation;
      _notify();
      await _persist();
    }
  }

  Future<void> removeMutation(String mutationId) async {
    _queue.removeWhere((m) => m.id == mutationId);
    _notify();
    await _persist();
  }

  Future<void> clearCompleted() async {
    _queue.removeWhere((m) => m.status == MutationStatus.synced);
    _notify();
    await _persist();
  }

  Future<void> clearAll() async {
    _queue.clear();
    _notify();
    await _persist();
  }

  Stream<List<SyncMutation>> watchQueue() {
    // Immediate current state emission on listen
    return _queueStreamController.stream;
  }

  void dispose() {
    _queueStreamController.close();
  }
}
