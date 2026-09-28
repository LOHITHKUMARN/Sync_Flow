import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../domain/label_model.dart';

abstract class LabelRepository {
  Future<List<TaskLabel>> getLabels(String workspaceId);
  Future<TaskLabel> createLabel({
    required String workspaceId,
    required String name,
    required String colorHex,
  });
}

class SupabaseLabelRepository implements LabelRepository {
  final sb.SupabaseClient _client;

  SupabaseLabelRepository(this._client);

  @override
  Future<List<TaskLabel>> getLabels(String workspaceId) async {
    final res = await _client
        .from('task_labels')
        .select()
        .eq('workspace_id', workspaceId)
        .order('name', ascending: true);

    return (res as List).map((json) => TaskLabel.fromJson(json)).toList();
  }

  @override
  Future<TaskLabel> createLabel({
    required String workspaceId,
    required String name,
    required String colorHex,
  }) async {
    final res = await _client
        .from('task_labels')
        .insert({
          'workspace_id': workspaceId,
          'name': name,
          'color_hex': colorHex,
        })
        .select()
        .single();
    return TaskLabel.fromJson(res);
  }
}

class MockLabelRepository implements LabelRepository {
  final List<TaskLabel> _labels = [
    const TaskLabel(id: 'lbl-1', name: 'Frontend', colorHex: '#FFFFFF'),
    const TaskLabel(id: 'lbl-2', name: 'Backend', colorHex: '#E4E4E7'),
    const TaskLabel(id: 'lbl-3', name: 'Bug', colorHex: '#D4D4D8'),
    const TaskLabel(id: 'lbl-4', name: 'Feature', colorHex: '#A1A1AA'),
    const TaskLabel(id: 'lbl-5', name: 'Design', colorHex: '#71717A'),
    const TaskLabel(id: 'lbl-6', name: 'High Priority', colorHex: '#FFFFFF'),
    const TaskLabel(id: 'lbl-7', name: 'DevOps', colorHex: '#D4D4D8'),
  ];

  @override
  Future<List<TaskLabel>> getLabels(String workspaceId) async {
    await Future.delayed(const Duration(milliseconds: 10));
    return List.from(_labels);
  }

  @override
  Future<TaskLabel> createLabel({
    required String workspaceId,
    required String name,
    required String colorHex,
  }) async {
    await Future.delayed(const Duration(milliseconds: 10));
    final newLabel = TaskLabel(
      id: 'lbl-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      colorHex: colorHex,
    );
    _labels.add(newLabel);
    return newLabel;
  }
}
