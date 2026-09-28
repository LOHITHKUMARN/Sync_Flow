import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../member_providers.dart';
import 'member_list_sheet.dart';

class PresenceAvatarBar extends ConsumerWidget {
  final String workspaceId;
  final String workspaceName;

  const PresenceAvatarBar({
    super.key,
    required this.workspaceId,
    required this.workspaceName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(workspaceMembersProvider(workspaceId));
    final presenceAsync = ref.watch(workspacePresenceProvider(workspaceId));
    final onlineIds = presenceAsync.value ?? [];

    return membersAsync.maybeWhen(
      data: (members) {
        if (members.isEmpty) return const SizedBox.shrink();

        final displayMembers = members.take(4).toList();
        final remaining = members.length - displayMembers.length;

        return InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => MemberListSheet(
                workspaceId: workspaceId,
                workspaceName: workspaceName,
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 28,
                  width: (displayMembers.length * 20.0) + 12,
                  child: Stack(
                    children: [
                      for (int i = 0; i < displayMembers.length; i++)
                        Positioned(
                          left: i * 18.0,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 1.5),
                                ),
                                child: CircleAvatar(
                                  radius: 12,
                                  backgroundColor: AppColors.primary,
                                  backgroundImage: displayMembers[i].avatarUrl != null
                                      ? NetworkImage(displayMembers[i].avatarUrl!)
                                      : null,
                                  child: displayMembers[i].avatarUrl == null
                                      ? Text(
                                          displayMembers[i].fullName.isNotEmpty
                                              ? displayMembers[i].fullName[0].toUpperCase()
                                              : 'U',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                              if (onlineIds.contains(displayMembers[i].userId))
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: AppColors.done,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                if (remaining > 0)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      '+$remaining',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}
