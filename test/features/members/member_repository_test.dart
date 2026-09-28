import 'package:flutter_test/flutter_test.dart';
import 'package:sync_flow/features/members/data/member_repository.dart';
import 'package:sync_flow/features/workspaces/domain/workspace_model.dart';
import 'package:sync_flow/features/tasks/domain/task_model.dart';
import 'package:sync_flow/features/tasks/domain/subtask_model.dart';
import 'package:sync_flow/features/tasks/domain/label_model.dart';

void main() {
  group('MockMemberRepository & Team Collaboration Tests', () {
    late MockMemberRepository memberRepo;

    setUp(() {
      memberRepo = MockMemberRepository();
    });

    test('Loads seeded members for default workspace', () async {
      final members = await memberRepo.getMembers('ws-default-1');
      expect(members.length, 5);
      expect(members.any((m) => m.role == WorkspaceRole.owner), true);
      expect(members.any((m) => m.role == WorkspaceRole.admin), true);
      expect(members.any((m) => m.role == WorkspaceRole.viewer), true);
      expect(members.first.fullName, 'Alex Rivera');
    });

    test('Invites new member with specified role', () async {
      final invited = await memberRepo.inviteMember(
        workspaceId: 'ws-default-1',
        email: 'collaborator@team.com',
        role: WorkspaceRole.admin,
      );

      expect(invited.email, 'collaborator@team.com');
      expect(invited.role, WorkspaceRole.admin);

      final members = await memberRepo.getMembers('ws-default-1');
      expect(members.any((m) => m.email == 'collaborator@team.com'), true);
    });

    test('Updates member role successfully', () async {
      final members = await memberRepo.getMembers('ws-default-1');
      final target = members.firstWhere((m) => m.role == WorkspaceRole.member);

      await memberRepo.updateMemberRole(
        memberId: target.id,
        newRole: WorkspaceRole.admin,
      );

      final updatedMembers = await memberRepo.getMembers('ws-default-1');
      final updated = updatedMembers.firstWhere((m) => m.id == target.id);
      expect(updated.role, WorkspaceRole.admin);
    });

    test('Removes member from workspace', () async {
      final members = await memberRepo.getMembers('ws-default-1');
      final target = members.firstWhere((m) => m.role == WorkspaceRole.viewer);

      await memberRepo.removeMember(
        memberId: target.id,
        workspaceId: 'ws-default-1',
      );

      final updatedMembers = await memberRepo.getMembers('ws-default-1');
      expect(updatedMembers.any((m) => m.id == target.id), false);
    });

    test('Active presence stream yields online user IDs', () async {
      final stream = memberRepo.watchActivePresence('ws-default-1');
      final firstEmission = await stream.first;
      expect(firstEmission.isNotEmpty, true);
      expect(firstEmission.contains('demo-user-001'), true);
    });
  });

  group('Phase 0 Rich Task Model Tests', () {
    test('Calculates subtask progress accurately', () {
      final task = TaskItem(
        id: 'task-100',
        projectId: 'proj-1',
        title: 'Complete Feature Spec',
        status: TaskStatus.inProgress,
        priority: TaskPriority.high,
        labels: const [
          TaskLabel(id: 'l1', name: 'Core Engine', colorHex: '#6366F1'),
        ],
        subtasks: [
          TaskSubtask(
            id: 'sub-1',
            taskId: 'task-100',
            title: 'Write SQL schema',
            isCompleted: true,
            createdAt: DateTime.now(),
          ),
          TaskSubtask(
            id: 'sub-2',
            taskId: 'task-100',
            title: 'Define RLS policies',
            isCompleted: true,
            createdAt: DateTime.now(),
          ),
          TaskSubtask(
            id: 'sub-3',
            taskId: 'task-100',
            title: 'Add presence indicator',
            isCompleted: false,
            createdAt: DateTime.now(),
          ),
          TaskSubtask(
            id: 'sub-4',
            taskId: 'task-100',
            title: 'Verify multi-user sync',
            isCompleted: false,
            createdAt: DateTime.now(),
          ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(task.subtasks.length, 4);
      expect(task.completedSubtaskCount, 2);
      expect(task.subtaskProgress, 0.5);
      expect(task.labels.length, 1);
    });
  });
}
