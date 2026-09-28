import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../data/workspace_repository.dart';
import '../domain/workspace_model.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../auth/domain/user_model.dart';
import '../../../core/config/env_config.dart';
import '../../../core/config/shared_prefs_provider.dart';

final workspaceRepositoryProvider = Provider<WorkspaceRepository>((ref) {
  if (EnvConfig.hasLiveSupabaseConfig) {
    return SupabaseWorkspaceRepository(sb.Supabase.instance.client);
  }
  try {
    final prefs = ref.watch(sharedPreferencesProvider);
    return MockWorkspaceRepository(prefs);
  } catch (_) {
    return MockWorkspaceRepository();
  }
});

class ActiveWorkspaceNotifier extends Notifier<Workspace?> {
  String? _selectedId;

  @override
  Workspace? build() {
    final workspacesAsync = ref.watch(workspacesNotifierProvider);
    return workspacesAsync.maybeWhen(
      data: (list) {
        if (list.isEmpty) return null;
        if (_selectedId != null) {
          for (final w in list) {
            if (w.id == _selectedId) return w;
          }
        }
        return list.first;
      },
      orElse: () => null,
    );
  }

  void setWorkspace(Workspace? ws) {
    _selectedId = ws?.id;
    state = ws;
  }
}

final activeWorkspaceProvider =
    NotifierProvider<ActiveWorkspaceNotifier, Workspace?>(ActiveWorkspaceNotifier.new);

class WorkspacesNotifier extends Notifier<AsyncValue<List<Workspace>>> {
  @override
  AsyncValue<List<Workspace>> build() {
    // Watch currentUserProvider so workspaces update when user state changes
    ref.watch(currentUserProvider);
    // Kick off initial loading
    Future.microtask(loadWorkspaces);
    return const AsyncValue.loading();
  }

  Future<void> loadWorkspaces() async {
    final user = ref.read(currentUserProvider);
    final userId = user?.id ?? 'demo-user-001';

    state = const AsyncValue.loading();
    try {
      final repo = ref.read(workspaceRepositoryProvider);
      final list = await repo.getWorkspaces(userId);
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Workspace> createWorkspace({
    required String name,
    required String slug,
    String? description,
  }) async {
    var user = ref.read(currentUserProvider);
    if (user == null) {
      // Auto-recover session from preferences or set default contributor profile
      try {
        final prefs = ref.read(sharedPreferencesProvider);
        final id = prefs.getString('syncflow_session_user_id') ?? 'demo-user-001';
        final email = prefs.getString('syncflow_session_email') ?? 'alex.rivera@syncflow.dev';
        final fullName = prefs.getString('syncflow_session_fullname') ?? 'Alex Rivera';
        user = AppUser(
          id: id,
          email: email,
          fullName: fullName,
          roleTitle: 'Product Lead',
          createdAt: DateTime.now(),
        );
        ref.read(currentUserProvider.notifier).setUser(user);
      } catch (_) {
        user = AppUser(
          id: 'demo-user-001',
          email: 'alex.rivera@syncflow.dev',
          fullName: 'Alex Rivera',
          roleTitle: 'Product Lead',
          createdAt: DateTime.now(),
        );
        ref.read(currentUserProvider.notifier).setUser(user);
      }
    }

    final repo = ref.read(workspaceRepositoryProvider);
    final ws = await repo.createWorkspace(
      name: name,
      slug: slug,
      userId: user.id,
      description: description,
    );

    final current = state.value ?? [];
    state = AsyncValue.data([ws, ...current]);
    ref.read(activeWorkspaceProvider.notifier).setWorkspace(ws);
    return ws;
  }
}

final workspacesNotifierProvider =
    NotifierProvider<WorkspacesNotifier, AsyncValue<List<Workspace>>>(WorkspacesNotifier.new);
