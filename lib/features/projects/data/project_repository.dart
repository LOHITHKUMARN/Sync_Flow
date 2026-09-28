import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:uuid/uuid.dart';
import '../domain/project_model.dart';

abstract class ProjectRepository {
  Future<List<Project>> getProjects(String workspaceId);
  Future<Project> createProject({
    required String workspaceId,
    required String name,
    String? description,
    String color = '#FFFFFF',
    String? creatorId,
  });
}

class SupabaseProjectRepository implements ProjectRepository {
  final sb.SupabaseClient _client;

  SupabaseProjectRepository(this._client);

  @override
  Future<List<Project>> getProjects(String workspaceId) async {
    final res = await _client
        .from('projects')
        .select('*, tasks(count)')
        .eq('workspace_id', workspaceId)
        .order('created_at', ascending: false);

    return (res as List).map((json) {
      final taskData = json['tasks'] as List?;
      final count = taskData?.isNotEmpty == true ? (taskData!.first['count'] as int? ?? 0) : 0;
      final map = Map<String, dynamic>.from(json);
      map['task_count'] = count;
      return Project.fromJson(map);
    }).toList();
  }

  @override
  Future<Project> createProject({
    required String workspaceId,
    required String name,
    String? description,
    String color = '#FFFFFF',
    String? creatorId,
  }) async {
    final res = await _client.from('projects').insert({
      'workspace_id': workspaceId,
      'name': name,
      'description': description,
      'color': color,
      'creator_id': creatorId,
    }).select().single();

    return Project.fromJson(res);
  }
}

class MockProjectRepository implements ProjectRepository {
  final List<Project> _projects = [];

  MockProjectRepository() {
    _projects.addAll([
      Project(
        id: 'proj-mobile-app',
        workspaceId: 'ws-tech-ventures',
        name: 'SyncFlow Flutter Client',
        description: 'Next-gen collaborative project workspace and Kanban boards',
        color: '#FFFFFF',
        createdAt: DateTime.now().subtract(const Duration(days: 14)),
        taskCount: 6,
        completedTaskCount: 2,
      ),
      Project(
        id: 'proj-cloud-api',
        workspaceId: 'ws-tech-ventures',
        name: 'Cloud Microservices & CDC',
        description: 'PostgreSQL change-data-capture channels and authentication',
        color: '#E4E4E7',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        taskCount: 4,
        completedTaskCount: 1,
      ),
      Project(
        id: 'proj-design-system',
        workspaceId: 'ws-design-studio',
        name: 'Dark Aura Component Kit',
        description: 'Mobile typography tokens, glass effects and iconography',
        color: '#D4D4D8',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        taskCount: 3,
        completedTaskCount: 1,
      ),
    ]);
  }

  @override
  Future<List<Project>> getProjects(String workspaceId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _projects.where((p) => p.workspaceId == workspaceId).toList();
  }

  @override
  Future<Project> createProject({
    required String workspaceId,
    required String name,
    String? description,
    String color = '#FFFFFF',
    String? creatorId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final newProj = Project(
      id: const Uuid().v4(),
      workspaceId: workspaceId,
      name: name,
      description: description,
      color: color,
      creatorId: creatorId,
      createdAt: DateTime.now(),
      taskCount: 0,
      completedTaskCount: 0,
    );
    _projects.insert(0, newProj);
    return newProj;
  }
}
