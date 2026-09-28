import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:uuid/uuid.dart';
import '../domain/workspace_model.dart';

abstract class WorkspaceRepository {
  Future<List<Workspace>> getWorkspaces(String userId);
  Future<Workspace> createWorkspace({
    required String name,
    required String slug,
    required String userId,
    String? description,
  });
}

class SupabaseWorkspaceRepository implements WorkspaceRepository {
  final sb.SupabaseClient _client;

  SupabaseWorkspaceRepository(this._client);

  @override
  Future<List<Workspace>> getWorkspaces(String userId) async {
    final res = await _client
        .from('workspaces')
        .select('*, workspace_members(*, profiles(*))')
        .order('created_at', ascending: false);

    return (res as List).map((json) => Workspace.fromJson(json)).toList();
  }

  @override
  Future<Workspace> createWorkspace({
    required String name,
    required String slug,
    required String userId,
    String? description,
  }) async {
    // 1. Ensure user's profile exists in public.profiles to satisfy foreign key constraint
    try {
      final authUser = _client.auth.currentUser;
      if (authUser != null) {
        await _client.from('profiles').upsert({
          'id': authUser.id,
          'email': authUser.email ?? '',
          'full_name': authUser.userMetadata?['full_name'] as String? ?? 'Team Member',
          'role_title': 'Product Lead',
        });
      }
    } catch (_) {}

    // 2. Generate a clean unique slug to prevent unique constraint conflicts
    final cleanSlug = slug.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\-]'), '').trim();
    final uniqueSlug = cleanSlug.isEmpty
        ? 'workspace-${DateTime.now().millisecondsSinceEpoch}'
        : '$cleanSlug-${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}';

    // 3. Insert workspace
    final res = await _client.from('workspaces').insert({
      'name': name.trim(),
      'slug': uniqueSlug,
      'description': description?.trim(),
      'owner_id': userId,
    }).select().single();

    // 4. Safely add owner as workspace member (ignore conflict if trigger auto-added)
    try {
      await _client.from('workspace_members').upsert({
        'workspace_id': res['id'],
        'user_id': userId,
        'role': 'owner',
      });
    } catch (_) {}

    return Workspace.fromJson(res);
  }
}

class MockWorkspaceRepository implements WorkspaceRepository {
  final List<Workspace> _workspaces = [];
  final SharedPreferences? _prefs;
  static const String _kStorageKey = 'syncflow_mock_workspaces_v2';

  MockWorkspaceRepository([this._prefs]) {
    _loadWorkspaces();
  }

  void _loadWorkspaces() {
    if (_prefs != null) {
      final savedList = _prefs.getStringList(_kStorageKey);
      if (savedList != null && savedList.isNotEmpty) {
        try {
          _workspaces.clear();
          for (final item in savedList) {
            final map = jsonDecode(item) as Map<String, dynamic>;
            _workspaces.add(Workspace.fromJson(map));
          }
          if (_workspaces.isNotEmpty) return;
        } catch (_) {}
      }
    }

    _workspaces.addAll([
      Workspace(
        id: 'ws-tech-ventures',
        name: 'TechFlow Systems',
        slug: 'techflow-systems',
        description: 'Core Engineering & Cloud Platform workspace',
        ownerId: 'demo-user-001',
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
        members: const [
          WorkspaceMember(
            id: 'wm-1',
            workspaceId: 'ws-tech-ventures',
            userId: 'demo-user-001',
            fullName: 'Alex Rivera',
            role: WorkspaceRole.owner,
          ),
          WorkspaceMember(
            id: 'wm-2',
            workspaceId: 'ws-tech-ventures',
            userId: 'demo-user-002',
            fullName: 'Rahul Sharma',
            role: WorkspaceRole.admin,
          ),
          WorkspaceMember(
            id: 'wm-3',
            workspaceId: 'ws-tech-ventures',
            userId: 'demo-user-003',
            fullName: 'Ananya Rao',
            role: WorkspaceRole.member,
          ),
        ],
      ),
      Workspace(
        id: 'ws-design-studio',
        name: 'Design Craft Lab',
        slug: 'design-craft-lab',
        description: 'Brand identity, UI/UX systems & mobile prototypes',
        ownerId: 'demo-user-001',
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        members: const [
          WorkspaceMember(
            id: 'wm-4',
            workspaceId: 'ws-design-studio',
            userId: 'demo-user-001',
            fullName: 'Alex Rivera',
            role: WorkspaceRole.owner,
          ),
        ],
      ),
    ]);
  }

  void _persistWorkspaces() {
    if (_prefs != null) {
      try {
        final serialized = _workspaces.map((w) => jsonEncode(w.toJson())).toList();
        _prefs.setStringList(_kStorageKey, serialized);
      } catch (_) {}
    }
  }

  @override
  Future<List<Workspace>> getWorkspaces(String userId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return List.unmodifiable(_workspaces);
  }

  @override
  Future<Workspace> createWorkspace({
    required String name,
    required String slug,
    required String userId,
    String? description,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));

    final newWs = Workspace(
      id: 'ws-${const Uuid().v4().substring(0, 8)}',
      name: name.trim(),
      slug: slug.trim().isNotEmpty
          ? slug.trim()
          : 'ws-${DateTime.now().millisecondsSinceEpoch}',
      description: description?.trim(),
      ownerId: userId,
      createdAt: DateTime.now(),
      members: [
        WorkspaceMember(
          id: 'wm-${const Uuid().v4().substring(0, 8)}',
          workspaceId: name.trim(),
          userId: userId,
          fullName: 'You',
          role: WorkspaceRole.owner,
        ),
      ],
    );

    _workspaces.insert(0, newWs);
    _persistWorkspaces();
    return newWs;
  }
}
