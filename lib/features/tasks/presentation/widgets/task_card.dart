import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/liquid_glass_box.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/task_model.dart';
import '../task_providers.dart';
import 'task_detail_sheet.dart';

/// Frosted Glass Kanban Task Card modeled after the modern glassmorphism reference design:
/// Translucent surface with background blur, crisp light-refraction borders, and sleek glowing capsule pills.
class TaskCard extends ConsumerWidget {
  final TaskItem task;

  const TaskCard({super.key, required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dueDateInfo = _getDueDateInfo(task.dueDate, task.status);

    return Draggable<TaskItem>(
      data: task,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: 290,
          child: Transform.rotate(
            angle: 0.03,
            child: _buildCardContent(context, ref, isDark, dueDateInfo, isDragging: true),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.28,
        child: _buildCardContent(context, ref, isDark, dueDateInfo),
      ),
      child: Semantics(
        label:
            '${task.title}, ${task.priority.label} priority, ${dueDateInfo?.label ?? "No due date"}, in ${task.status.label}',
        button: true,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (_) => TaskDetailSheet(task: task),
              );
            },
            onLongPress: () {
              HapticFeedback.mediumImpact();
              _showQuickActions(context, ref);
            },
            borderRadius: BorderRadius.circular(22),
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            child: _buildCardContent(context, ref, isDark, dueDateInfo),
          ),
        ),
      ),
    );
  }

  Widget _buildCardContent(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    _DueDateInfo? dueDateInfo, {
    bool isDragging = false,
  }) {
    return LiquidGlassBox(
      borderRadius: 22,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      blur: 24.0,
      customShadow: isDragging
          ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.65 : 0.22),
                blurRadius: 28,
                offset: const Offset(4, 12),
              ),
            ]
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Glowing Glass Priority Badge + Activity Sockets
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              PriorityBadge(priority: task.priority.code, isSmall: true),
              // Activity Sockets (Comments & Attachments)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (task.commentCount > 0) ...[
                    _buildActivitySocket(
                      icon: Icons.chat_bubble_outline_rounded,
                      count: task.commentCount,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 6),
                  ],
                  if (task.attachmentCount > 0) ...[
                    _buildActivitySocket(
                      icon: Icons.attach_file_rounded,
                      count: task.attachmentCount,
                      isDark: isDark,
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 11),

          // Title: max 2 lines with clean modern typography
          Text(
            task.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              height: 1.35,
              color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
              letterSpacing: 0.1,
            ),
          ),

          // Description: max 2 lines with gentle muted tone
          if (task.description.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              task.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                height: 1.45,
              ),
            ),
          ],

          // Labels: Sleek Frosted Micro-Pills
          if (task.labels.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 5,
              children: task.labels.take(3).map((l) {
                Color color = Theme.of(context).colorScheme.primary;
                try {
                  final hex = l.colorHex.replaceAll('#', '');
                  color = Color(int.parse('0xFF$hex'));
                } catch (_) {}
                return _buildLabelPill(l.name, color, isDark);
              }).toList(),
            ),
          ],

          // Subtasks Progress: Refined Frosted Glass Slider
          if (task.subtasks.isNotEmpty) ...[
            const SizedBox(height: 11),
            _buildSunkenProgressSlider(context, isDark),
          ],

          const SizedBox(height: 13),

          // Footer: Frosted Glass Due Date Pill & Sleek Assignee Capsule
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Smart Due Date Pill
              if (dueDateInfo != null)
                _buildDueDatePill(dueDateInfo, isDark)
              else
                const SizedBox.shrink(),

              // Assignee Group
              if (task.assigneeName != null && task.assigneeName!.isNotEmpty)
                _buildAssigneeDish(task.assigneeName!, task.assigneeAvatar, isDark)
              else
                _buildUnassignedPill(isDark),
            ],
          ),
        ],
      ),
    );
  }

  /// Frosted Glass Activity Socket (Comments / Attachments)
  Widget _buildActivitySocket({
    required IconData icon,
    required int count,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7.5, vertical: 3.5),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.10)
              : Colors.black.withValues(alpha: 0.07),
          width: 0.85,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 11.5,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }

  /// Sleek Frosted Glass Label Pill
  Widget _buildLabelPill(String labelName, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.14 : 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.35 : 0.28),
          width: 0.85,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4.5),
          Text(
            labelName,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Refined Frosted Progress Channel
  Widget _buildSunkenProgressSlider(BuildContext context, bool isDark) {
    final isComplete = task.completedSubtaskCount == task.subtasks.length;
    final accent = isComplete ? const Color(0xFF10B981) : const Color(0xFFF59E0B);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  isComplete ? Icons.check_circle_rounded : Icons.checklist_rounded,
                  size: 13,
                  color: accent,
                ),
                const SizedBox(width: 5),
                Text(
                  'Subtasks',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            Text(
              '${task.completedSubtaskCount}/${task.subtasks.length}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 6,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.05),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.05),
              width: 0.6,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: task.subtaskProgress.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: accent,
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.6),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Frosted Glass Due Date Pill modeled on reference calendar capsules
  Widget _buildDueDatePill(_DueDateInfo info, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.11)
              : Colors.black.withValues(alpha: 0.08),
          width: 0.85,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            info.icon,
            size: 12,
            color: info.color,
          ),
          const SizedBox(width: 5),
          Text(
            info.label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: info.color,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  /// Sleek Frosted Glass Assignee Capsule modeled on reference pill design
  Widget _buildAssigneeDish(String name, String? avatarUrl, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 10, 4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.11)
              : Colors.black.withValues(alpha: 0.08),
          width: 0.85,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? const Color(0xFF222634) : const Color(0xFFE2E8F0),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.18)
                    : Colors.black.withValues(alpha: 0.10),
                width: 0.8,
              ),
            ),
            child: ClipOval(
              child: (avatarUrl != null && avatarUrl.isNotEmpty)
                  ? Image.network(
                      avatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildAvatarFallback(name, isDark),
                    )
                  : _buildAvatarFallback(name, isDark),
            ),
          ),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 85),
            child: Text(
              name.split(' ').first,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarFallback(String name, bool isDark) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: isDark ? Colors.white : const Color(0xFF0F172A),
        ),
      ),
    );
  }

  /// Frosted Glass Capsule for Unassigned tasks
  Widget _buildUnassignedPill(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.11)
              : Colors.black.withValues(alpha: 0.08),
          width: 0.85,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.person_outline_rounded,
            size: 13,
            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          ),
          const SizedBox(width: 4),
          Text(
            'Unassigned',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  void _showQuickActions(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                task.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),

              // Move Status Options
              Text(
                'MOVE STATUS',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: TaskStatus.values.map((s) {
                  final isCurrent = task.status == s;
                  return ChoiceChip(
                    label: Text(s.label),
                    selected: isCurrent,
                    onSelected: (val) {
                      if (val && !isCurrent) {
                        ref.read(tasksNotifierProvider(task.projectId).notifier).moveTaskStatus(
                              taskId: task.id,
                              newStatus: s,
                            );
                        Navigator.pop(sheetContext);
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              // Quick Actions List
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.open_in_new_rounded, size: 20),
                title: const Text('Open Details'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    isScrollControlled: true,
                    builder: (_) => TaskDetailSheet(task: task),
                  );
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.priorityUrgent),
                title: const Text('Delete Task', style: TextStyle(color: AppColors.priorityUrgent)),
                onTap: () {
                  ref.read(tasksNotifierProvider(task.projectId).notifier).removeTask(task.id);
                  Navigator.pop(sheetContext);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  _DueDateInfo? _getDueDateInfo(DateTime? dueDate, TaskStatus status) {
    if (dueDate == null) return null;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final diffDays = dueDay.difference(today).inDays;

    if (diffDays < 0 && status != TaskStatus.done) {
      final daysAgo = -diffDays;
      return _DueDateInfo(
        label: daysAgo == 1 ? 'Overdue (1d)' : 'Overdue (${daysAgo}d)',
        color: const Color(0xFFEF4444), // Crimson
        icon: Icons.warning_amber_rounded,
      );
    } else if (diffDays == 0) {
      return const _DueDateInfo(
        label: 'Due today',
        color: Color(0xFFF59E0B), // Amber
        icon: Icons.alarm_rounded,
      );
    } else if (diffDays == 1) {
      return const _DueDateInfo(
        label: 'Due tomorrow',
        color: Color(0xFFF59E0B), // Amber
        icon: Icons.schedule_rounded,
      );
    } else if (diffDays <= 7) {
      return _DueDateInfo(
        label: 'In $diffDays days',
        color: const Color(0xFF3B82F6), // Blue
        icon: Icons.schedule_rounded,
      );
    } else {
      return _DueDateInfo(
        label: DateFormat('MMM dd').format(dueDate),
        color: const Color(0xFF94A3B8), // Slate Muted
        icon: Icons.calendar_today_rounded,
      );
    }
  }
}

class _DueDateInfo {
  final String label;
  final Color color;
  final IconData icon;

  const _DueDateInfo({
    required this.label,
    required this.color,
    required this.icon,
  });
}
