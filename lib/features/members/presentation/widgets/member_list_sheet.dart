import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../workspaces/domain/workspace_model.dart';
import '../member_providers.dart';
import 'invite_member_dialog.dart';

class MemberListSheet extends ConsumerWidget {
  final String workspaceId;
  final String workspaceName;

  const MemberListSheet({
    super.key,
    required this.workspaceId,
    required this.workspaceName,
  });

  Color _roleColor(WorkspaceRole role) {
    switch (role) {
      case WorkspaceRole.owner:
        return AppColors.priorityUrgent;
      case WorkspaceRole.admin:
        return AppColors.primary;
      case WorkspaceRole.member:
        return AppColors.done;
      case WorkspaceRole.viewer:
      case WorkspaceRole.guest:
        return AppColors.inProgress;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final membersAsync = ref.watch(workspaceMembersProvider(workspaceId));
    final presenceAsync = ref.watch(workspacePresenceProvider(workspaceId));
    final onlineUserIds = presenceAsync.value ?? [];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Team Members',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    workspaceName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                  ),
                ],
              ),
              PrimaryButton(
                label: 'Invite',
                icon: Icons.person_add_rounded,
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => InviteMemberDialog(workspaceId: workspaceId),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Members List
          Expanded(
            child: membersAsync.when(
              data: (members) {
                if (members.isEmpty) {
                  return const Center(child: Text('No team members found'));
                }

                return ListView.separated(
                  itemCount: members.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final member = members[index];
                    final isOnline = onlineUserIds.contains(member.userId);
                    final roleColor = _roleColor(member.role);

                    return GlassContainer(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          // Avatar with Online Badge
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: AppColors.primary.withAlpha(50),
                                backgroundImage: member.avatarUrl != null
                                    ? NetworkImage(member.avatarUrl!)
                                    : null,
                                child: member.avatarUrl == null
                                    ? Text(
                                        member.fullName.isNotEmpty
                                            ? member.fullName[0].toUpperCase()
                                            : 'U',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                        ),
                                      )
                                    : null,
                              ),
                              if (isOnline)
                                Positioned(
                                  right: -1,
                                  bottom: -1,
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: AppColors.done,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isDark ? AppColors.darkCard : AppColors.lightCard,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 12),

                          // Name & Email
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      member.fullName,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    if (isOnline) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: AppColors.done.withAlpha(20),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'Online',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.done,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                if (member.email != null)
                                  Text(
                                    member.email!,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      color: isDark
                                          ? AppColors.darkTextMuted
                                          : AppColors.lightTextMuted,
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // Role Dropdown / Badge
                          PopupMenuButton<WorkspaceRole>(
                            initialValue: member.role,
                            enabled: member.role != WorkspaceRole.owner,
                            onSelected: (newRole) {
                              ref
                                  .read(workspaceMembersProvider(workspaceId).notifier)
                                  .updateMemberRole(memberId: member.id, newRole: newRole);
                            },
                            itemBuilder: (context) => [
                              WorkspaceRole.admin,
                              WorkspaceRole.member,
                              WorkspaceRole.viewer,
                            ].map((role) {
                              return PopupMenuItem(
                                value: role,
                                child: Text(role.label),
                              );
                            }).toList(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: roleColor.withAlpha(25),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: roleColor.withAlpha(80)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    member.role.label,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: roleColor,
                                    ),
                                  ),
                                  if (member.role != WorkspaceRole.owner) ...[
                                    const SizedBox(width: 4),
                                    Icon(Icons.arrow_drop_down_rounded, size: 16, color: roleColor),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error loading members: $err')),
            ),
          ),
        ],
      ),
    );
  }
}
