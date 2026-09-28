import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../data/label_repository.dart';
import '../domain/label_model.dart';
import '../../../core/config/env_config.dart';

final labelRepositoryProvider = Provider<LabelRepository>((ref) {
  if (EnvConfig.hasLiveSupabaseConfig) {
    return SupabaseLabelRepository(sb.Supabase.instance.client);
  }
  return MockLabelRepository();
});

class WorkspaceLabelsNotifier
    extends Notifier<AsyncValue<List<TaskLabel>>> {
  final String workspaceId;

  WorkspaceLabelsNotifier(this.workspaceId);

  @override
  AsyncValue<List<TaskLabel>> build() {
    Future.microtask(loadLabels);
    return const AsyncValue.loading();
  }

  Future<void> loadLabels() async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(labelRepositoryProvider);
      final list = await repo.getLabels(workspaceId);
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<TaskLabel> addCustomLabel({
    required String name,
    required String colorHex,
  }) async {
    final repo = ref.read(labelRepositoryProvider);
    final created = await repo.createLabel(
      workspaceId: workspaceId,
      name: name,
      colorHex: colorHex,
    );
    final current = state.value ?? [];
    state = AsyncValue.data([...current, created]);
    return created;
  }
}

final workspaceLabelsProvider = NotifierProvider.family<
    WorkspaceLabelsNotifier, AsyncValue<List<TaskLabel>>, String>(
  (arg) => WorkspaceLabelsNotifier(arg),
);
