import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:uuid/uuid.dart';
import '../../workspaces/domain/workspace_model.dart';

abstract class MemberRepository {
  Future<List<WorkspaceMember>> getMembers(String workspaceId);
  Future<WorkspaceMember> inviteMember({
    required String workspaceId,
    required String email,
    required WorkspaceRole role,
  });
  Future<void> updateMemberRole({
    required String memberId,
    required WorkspaceRole newRole,
  });
  Future<void> removeMember({
    required String memberId,
    required String workspaceId,
  });
  Stream<List<WorkspaceMember>> watchMembers(String workspaceId);
  Stream<List<String>> watchActivePresence(String workspaceId);
}

class SupabaseMemberRepository implements MemberRepository {
  final sb.SupabaseClient _client;

  SupabaseMemberRepository(this._client);

  @override
  Future<List<WorkspaceMember>> getMembers(String workspaceId) async {
    final res = await _client
        .from('workspace_members')
        .select('*, profiles(full_name, email, avatar_url)')
        .eq('workspace_id', workspaceId)
        .order('joined_at', ascending: true);

    return (res as List).map((json) => WorkspaceMember.fromJson(json)).toList();
  }

  @override
  Future<WorkspaceMember> inviteMember({
    required String workspaceId,
    required String email,
    required WorkspaceRole role,
  }) async {
    // 1. Create invitation record
    final token = const Uuid().v4();
    await _client.from('workspace_invitations').insert({
      'workspace_id': workspaceId,
      'email': email,
      'role': role.name,
      'token': token,
    });

    // 2. Check if user already exists in profiles
    final profileRes = await _client
        .from('profiles')
        .select()
        .eq('email', email)
        .maybeSingle();

    if (profileRes != null) {
      final insertRes = await _client.from('workspace_members').insert({
        'workspace_id': workspaceId,
        'user_id': profileRes['id'],
        'role': role.name,
      }).select('*, profiles(full_name, email, avatar_url)').single();

      return WorkspaceMember.fromJson(insertRes);
    }

    // Return pending placeholder
    return WorkspaceMember(
      id: token,
      workspaceId: workspaceId,
      userId: '',
      fullName: email.split('@').first,
      email: email,
      role: role,
      joinedAt: DateTime.now(),
    );
  }

  @override
  Future<void> updateMemberRole({
    required String memberId,
    required WorkspaceRole newRole,
  }) async {
    await _client
        .from('workspace_members')
        .update({'role': newRole.name})
        .eq('id', memberId);
  }

  @override
  Future<void> removeMember({
    required String memberId,
    required String workspaceId,
  }) async {
    await _client.from('workspace_members').delete().eq('id', memberId);
  }

  @override
  Stream<List<WorkspaceMember>> watchMembers(String workspaceId) {
    return _client
        .from('workspace_members')
        .stream(primaryKey: ['id'])
        .eq('workspace_id', workspaceId)
        .asyncMap((_) => getMembers(workspaceId));
  }

  @override
  Stream<List<String>> watchActivePresence(String workspaceId) {
    // Uses Supabase presence channel
    final channel = _client.channel('presence:workspace_$workspaceId');
    final controller = StreamController<List<String>>.broadcast();

    channel.onPresenceSync((_) {
      final state = channel.presenceState();
      final userIds = state
          .expand((p) => p.presences)
          .map((item) => item.payload['user_id'] as String? ?? '')
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();
      controller.add(userIds);
    }).subscribe();

    return controller.stream;
  }
}

class MockMemberRepository implements MemberRepository {
  final Map<String, List<WorkspaceMember>> _membersByWorkspace = {};
  final _streamController = StreamController<Map<String, List<WorkspaceMember>>>.broadcast();

  MockMemberRepository() {
    _seedMembers();
  }

  void _seedMembers() {
    final now = DateTime.now();

    final defaultMembers = [
      WorkspaceMember(
        id: 'wm-1',
        workspaceId: 'ws-tech-ventures',
        userId: 'demo-user-001',
        fullName: 'Alex Rivera',
        email: 'alex@syncflow.dev',
        avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
        role: WorkspaceRole.owner,
        joinedAt: now.subtract(const Duration(days: 60)),
      ),
      WorkspaceMember(
        id: 'wm-2',
        workspaceId: 'ws-tech-ventures',
        userId: 'demo-user-002',
        fullName: 'Rahul Sharma',
        email: 'rahul@syncflow.dev',
        avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
        role: WorkspaceRole.admin,
        joinedAt: now.subtract(const Duration(days: 45)),
      ),
      WorkspaceMember(
        id: 'wm-3',
        workspaceId: 'ws-tech-ventures',
        userId: 'demo-user-003',
        fullName: 'Ananya Rao',
        email: 'ananya@syncflow.dev',
        avatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
        role: WorkspaceRole.member,
        joinedAt: now.subtract(const Duration(days: 30)),
      ),
      WorkspaceMember(
        id: 'wm-4',
        workspaceId: 'ws-tech-ventures',
        userId: 'demo-user-004',
        fullName: 'Priya Nair',
        email: 'priya@syncflow.dev',
        avatarUrl: null,
        role: WorkspaceRole.member,
        joinedAt: now.subtract(const Duration(days: 15)),
      ),
      WorkspaceMember(
        id: 'wm-5',
        workspaceId: 'ws-tech-ventures',
        userId: 'demo-user-005',
        fullName: 'David Chen',
        email: 'david@syncflow.dev',
        avatarUrl: null,
        role: WorkspaceRole.viewer,
        joinedAt: now.subtract(const Duration(days: 5)),
      ),
    ];

    _membersByWorkspace['ws-tech-ventures'] = List.from(defaultMembers);
    _membersByWorkspace['ws-design-studio'] = List.from(defaultMembers.take(3));
  }

  List<WorkspaceMember> _getOrCreateList(String workspaceId) {
    return _membersByWorkspace.putIfAbsent(
      workspaceId,
      () => _membersByWorkspace.isNotEmpty
          ? List<WorkspaceMember>.from(_membersByWorkspace.values.first)
          : [],
    );
  }

  @override
  Future<List<WorkspaceMember>> getMembers(String workspaceId) async {
    await Future.delayed(const Duration(milliseconds: 10));
    return List<WorkspaceMember>.from(_getOrCreateList(workspaceId));
  }

  @override
  Future<WorkspaceMember> inviteMember({
    required String workspaceId,
    required String email,
    required WorkspaceRole role,
  }) async {
    await Future.delayed(const Duration(milliseconds: 20));
    final list = _getOrCreateList(workspaceId);

    final newMember = WorkspaceMember(
      id: 'wm-${DateTime.now().millisecondsSinceEpoch}',
      workspaceId: workspaceId,
      userId: 'user-${email.split('@').first}',
      fullName: email.split('@').first.replaceFirst(email[0], email[0].toUpperCase()),
      email: email,
      avatarUrl: null,
      role: role,
      joinedAt: DateTime.now(),
    );

    list.add(newMember);
    _streamController.add(Map.from(_membersByWorkspace));
    return newMember;
  }

  @override
  Future<void> updateMemberRole({
    required String memberId,
    required WorkspaceRole newRole,
  }) async {
    await Future.delayed(const Duration(milliseconds: 10));
    for (final list in _membersByWorkspace.values) {
      final index = list.indexWhere((m) => m.id == memberId);
      if (index != -1) {
        list[index] = list[index].copyWith(role: newRole);
      }
    }
    _streamController.add(Map.from(_membersByWorkspace));
  }

  @override
  Future<void> removeMember({
    required String memberId,
    required String workspaceId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 10));
    final list = _getOrCreateList(workspaceId);
    list.removeWhere((m) => m.id == memberId);
    _streamController.add(Map.from(_membersByWorkspace));
  }

  @override
  Stream<List<WorkspaceMember>> watchMembers(String workspaceId) {
    return _streamController.stream.map(
      (map) => List<WorkspaceMember>.from(map[workspaceId] ?? _getOrCreateList(workspaceId)),
    );
  }

  @override
  Stream<List<String>> watchActivePresence(String workspaceId) async* {
    final members = _getOrCreateList(workspaceId);
    yield members.take(3).map((m) => m.userId).toList();
    yield* Stream.periodic(const Duration(seconds: 3), (_) {
      final current = _getOrCreateList(workspaceId);
      return current.take(3).map((m) => m.userId).toList();
    });
  }
}
