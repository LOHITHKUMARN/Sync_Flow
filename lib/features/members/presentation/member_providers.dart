import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../data/member_repository.dart';
import '../../workspaces/domain/workspace_model.dart';
import '../../../core/config/env_config.dart';

final memberRepositoryProvider = Provider<MemberRepository>((ref) {
  if (EnvConfig.hasLiveSupabaseConfig) {
    return SupabaseMemberRepository(sb.Supabase.instance.client);
  }
  return MockMemberRepository();
});

class WorkspaceMembersNotifier
    extends Notifier<AsyncValue<List<WorkspaceMember>>> {
  final String workspaceId;

  WorkspaceMembersNotifier(this.workspaceId);

  @override
  AsyncValue<List<WorkspaceMember>> build() {
    final repo = ref.watch(memberRepositoryProvider);
    final sub = repo.watchMembers(workspaceId).listen(
      (members) => state = AsyncValue.data(members),
      onError: (_, __) {},
    );
    ref.onDispose(sub.cancel);

    Future.microtask(loadMembers);
    return const AsyncValue.loading();
  }

  Future<void> loadMembers() async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(memberRepositoryProvider);
      final list = await repo.getMembers(workspaceId);
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<WorkspaceMember> inviteMember({
    required String email,
    required WorkspaceRole role,
  }) async {
    final repo = ref.read(memberRepositoryProvider);
    final newMember = await repo.inviteMember(
      workspaceId: workspaceId,
      email: email,
      role: role,
    );
    final current = state.value ?? [];
    if (!current.any((m) => m.email == email)) {
      state = AsyncValue.data([...current, newMember]);
    }
    return newMember;
  }

  Future<void> updateMemberRole({
    required String memberId,
    required WorkspaceRole newRole,
  }) async {
    final repo = ref.read(memberRepositoryProvider);
    await repo.updateMemberRole(memberId: memberId, newRole: newRole);
    final current = state.value ?? [];
    state = AsyncValue.data(
      current.map((m) => m.id == memberId ? m.copyWith(role: newRole) : m).toList(),
    );
  }

  Future<void> removeMember(String memberId) async {
    final repo = ref.read(memberRepositoryProvider);
    await repo.removeMember(memberId: memberId, workspaceId: workspaceId);
    final current = state.value ?? [];
    state = AsyncValue.data(current.where((m) => m.id != memberId).toList());
  }
}

final workspaceMembersProvider = NotifierProvider.family<
    WorkspaceMembersNotifier, AsyncValue<List<WorkspaceMember>>, String>(
  (arg) => WorkspaceMembersNotifier(arg),
);

final workspacePresenceProvider =
    StreamProvider.family<List<String>, String>((ref, workspaceId) {
  final repo = ref.watch(memberRepositoryProvider);
  return repo.watchActivePresence(workspaceId);
});
