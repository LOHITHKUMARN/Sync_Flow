import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../activity_providers.dart';

class TaskActivityView extends ConsumerWidget {
  final String taskId;

  const TaskActivityView({super.key, required this.taskId});

  String _formatRelativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.month}/${dt.day}/${dt.year}';
  }

  IconData _iconForAction(String type) {
    switch (type) {
      case 'created':
        return Icons.add_task_rounded;
      case 'status_changed':
        return Icons.sync_alt_rounded;
      case 'assigned':
        return Icons.person_outline_rounded;
      case 'commented':
        return Icons.chat_bubble_outline_rounded;
      case 'label_added':
      case 'label_changed':
        return Icons.label_outline_rounded;
      default:
        return Icons.history_rounded;
    }
  }

  Color _colorForAction(String type) {
    switch (type) {
      case 'created':
        return AppColors.done;
      case 'status_changed':
        return AppColors.secondary;
      case 'assigned':
        return AppColors.primary;
      case 'commented':
        return AppColors.priorityHigh;
      default:
        return AppColors.accent;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activitiesAsync = ref.watch(taskActivitiesProvider(taskId));
    final activities = activitiesAsync.value ?? [];

    if (activities.isEmpty && !activitiesAsync.isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 28),
          child: Column(
            children: [
              Icon(
                Icons.history_toggle_off_rounded,
                size: 36,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
              const SizedBox(height: 10),
              Text(
                'No activity history yet',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Changes to status, assignees, and checklist will appear here.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: activities.length,
      itemBuilder: (context, index) {
        final act = activities[index];
        final icon = _iconForAction(act.actionType);
        final color = _colorForAction(act.actionType);
        final isLast = index == activities.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline line & icon
            Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color.withAlpha(25),
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withAlpha(60)),
                  ),
                  child: Icon(icon, size: 14, color: color),
                ),
                if (!isLast)
                  Container(
                    width: 1.5,
                    height: 36,
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
              ],
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: isDark ? AppColors.darkText : AppColors.lightText,
                        ),
                        children: [
                          TextSpan(
                            text: act.actorName,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          TextSpan(
                            text: ' ${act.summary}',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatRelativeTime(act.createdAt),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
