import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../data/project_repository.dart';
import '../domain/project_model.dart';
import '../../workspaces/presentation/workspace_providers.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../../core/config/env_config.dart';

final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  if (EnvConfig.hasLiveSupabaseConfig) {
    return SupabaseProjectRepository(sb.Supabase.instance.client);
  }
  return MockProjectRepository();
});

class ActiveProjectNotifier extends Notifier<Project?> {
  @override
  Project? build() => null;

  void setProject(Project? p) {
    state = p;
  }
}

final activeProjectProvider =
    NotifierProvider<ActiveProjectNotifier, Project?>(ActiveProjectNotifier.new);

class ProjectsNotifier extends Notifier<AsyncValue<List<Project>>> {
  @override
  AsyncValue<List<Project>> build() {
    final ws = ref.watch(activeWorkspaceProvider);
    if (ws != null) {
      Future.microtask(() => loadProjects(ws.id));
      return const AsyncValue.loading();
    }
    return const AsyncValue.data([]);
  }

  Future<void> loadProjects(String workspaceId) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(projectRepositoryProvider);
      final list = await repo.getProjects(workspaceId);
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Project> createProject({
    required String name,
    String? description,
    String color = '#FFFFFF',
  }) async {
    var ws = ref.read(activeWorkspaceProvider);
    if (ws == null) {
      final workspaces = ref.read(workspacesNotifierProvider).value;
      if (workspaces != null && workspaces.isNotEmpty) {
        ws = workspaces.first;
        ref.read(activeWorkspaceProvider.notifier).setWorkspace(ws);
      }
    }
    if (ws == null) {
      throw Exception('No active workspace selected. Please select or create a workspace first.');
    }

    final user = ref.read(currentUserProvider);
    final repo = ref.read(projectRepositoryProvider);

    final project = await repo.createProject(
      workspaceId: ws.id,
      name: name,
      description: description,
      color: color,
      creatorId: user?.id,
    );

    final current = state.value ?? [];
    state = AsyncValue.data([project, ...current]);
    return project;
  }
}

final projectsNotifierProvider =
    NotifierProvider<ProjectsNotifier, AsyncValue<List<Project>>>(ProjectsNotifier.new);
