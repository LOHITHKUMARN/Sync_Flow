import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/widgets/liquid_glass_box.dart';
import '../../domain/task_model.dart';
import '../../domain/task_view_mode.dart';
import '../task_providers.dart';
import 'task_detail_sheet.dart';

/// Ultra-refined Liquid Glass Task List View matching the visionOS glassmorphism design language:
/// - Optical frosted glass task cards with specular refraction rims and ambient drop shadows
/// - Translucent status toggle circles with glow highlights
/// - Radiant priority and tag capsules
/// - Sleek frosted glass sort & filter control bar
class TaskListView extends ConsumerWidget {
  final String projectId;
  final List<TaskItem> tasks;

  const TaskListView({
    super.key,
    required this.projectId,
    required this.tasks,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSort = ref.watch(taskListSortProvider);

    // Sort tasks based on currentSort
    final sortedTasks = List<TaskItem>.from(tasks);
    switch (currentSort) {
      case TaskListSortBy.dueDate:
        sortedTasks.sort((a, b) {
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return a.dueDate!.compareTo(b.dueDate!);
        });
        break;
      case TaskListSortBy.priority:
        sortedTasks.sort((a, b) => b.priority.index.compareTo(a.priority.index));
        break;
      case TaskListSortBy.status:
        sortedTasks.sort((a, b) => a.status.index.compareTo(b.status.index));
        break;
      case TaskListSortBy.title:
        sortedTasks.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedText = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Column(
      children: [
        // Neumorphic Soft-UI Sort & Counter Header Bar
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: isDark ? const Color(0xFF1B1C20) : const Color(0xFFEFF2F7),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF282C38)
                  : const Color(0xFFD6DEE9),
              width: 0.8,
            ),
            boxShadow: isDark
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.85),
                      offset: const Offset(3, 4),
                      blurRadius: 10,
                      spreadRadius: -1,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.40),
                      offset: const Offset(0, 1.5),
                      blurRadius: 3,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: const Color(0xFFA5B2C5).withValues(alpha: 0.45),
                      offset: const Offset(4, 5),
                      blurRadius: 9,
                      spreadRadius: -1,
                    ),
                    const BoxShadow(
                      color: Colors.white,
                      offset: Offset(-3, -3),
                      blurRadius: 7,
                    ),
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Neumorphic Inset / Sculpted Task Count Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: isDark ? const Color(0xFF141518) : const Color(0xFFE5EAF2),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF0E0F12)
                        : const Color(0xFFD6DEE9),
                    width: 0.9,
                  ),
                  boxShadow: isDark
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.90),
                            offset: const Offset(1.5, 2),
                            blurRadius: 3,
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: const Color(0xFFA0B0C4).withValues(alpha: 0.5),
                            offset: const Offset(1.5, 2),
                            blurRadius: 3,
                          ),
                          const BoxShadow(
                            color: Colors.white,
                            offset: Offset(-1, -1),
                            blurRadius: 2,
                          ),
                        ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF38BDF8),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF38BDF8).withValues(alpha: 0.8),
                            blurRadius: 4,
                            spreadRadius: 0.5,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      '${sortedTasks.length} ${sortedTasks.length == 1 ? "task" : "tasks"}',
                      style: GoogleFonts.plusJakartaSans(
                        color: primaryText,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              // Sort Section with Neumorphic Dropdown Pill
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Sort:',
                    style: GoogleFonts.plusJakartaSans(
                      color: mutedText,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<TaskListSortBy>(
                    initialValue: currentSort,
                    onSelected: (val) {
                      HapticFeedback.selectionClick();
                      ref.read(taskListSortProvider.notifier).setSort(val);
                    },
                    color: isDark ? const Color(0xFF1B1C21) : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isDark
                            ? const Color(0xFF282C38)
                            : Colors.black.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5.5),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF222328) : const Color(0xFFF3F6FA),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF282C38)
                              : const Color(0xFFD6DEE9),
                          width: 0.8,
                        ),
                        boxShadow: isDark
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.80),
                                  offset: const Offset(2.5, 3.5),
                                  blurRadius: 6,
                                ),
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  offset: const Offset(0, 1),
                                  blurRadius: 2,
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: const Color(0xFFA8B4C7).withValues(alpha: 0.45),
                                  offset: const Offset(2.5, 3.5),
                                  blurRadius: 5,
                                ),
                                const BoxShadow(
                                  color: Colors.white,
                                  offset: Offset(-2, -2),
                                  blurRadius: 4,
                                ),
                              ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _getSortLabel(currentSort),
                            style: GoogleFonts.plusJakartaSans(
                              color: primaryText,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 16,
                            color: isDark ? const Color(0xFF38BDF8) : primaryText,
                          ),
                        ],
                      ),
                    ),
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: TaskListSortBy.dueDate,
                        child: Text(
                          'Due Date',
                          style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: primaryText),
                        ),
                      ),
                      PopupMenuItem(
                        value: TaskListSortBy.priority,
                        child: Text(
                          'Priority',
                          style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: primaryText),
                        ),
                      ),
                      PopupMenuItem(
                        value: TaskListSortBy.status,
                        child: Text(
                          'Status',
                          style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: primaryText),
                        ),
                      ),
                      PopupMenuItem(
                        value: TaskListSortBy.title,
                        child: Text(
                          'Title',
                          style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: primaryText),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),

        // Liquid Glass Task List View
        Expanded(
          child: sortedTasks.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.checklist_rounded,
                          size: 48,
                          color: mutedText.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No tasks found',
                          style: GoogleFonts.plusJakartaSans(
                            color: primaryText,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Try clearing your search or filters.',
                          style: GoogleFonts.plusJakartaSans(
                            color: mutedText,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  physics: const BouncingScrollPhysics(),
                  itemCount: sortedTasks.length,
                  itemBuilder: (context, index) {
                    final task = sortedTasks[index];
                    return _buildGlassTaskRow(context, ref, task);
                  },
                ),
        ),
      ],
    );
  }

  String _getSortLabel(TaskListSortBy sort) {
    switch (sort) {
      case TaskListSortBy.dueDate:
        return 'Due Date';
      case TaskListSortBy.priority:
        return 'Priority';
      case TaskListSortBy.status:
        return 'Status';
      case TaskListSortBy.title:
        return 'Title';
    }
  }

  /// Refined optical liquid glass task card in list view
  Widget _buildGlassTaskRow(BuildContext context, WidgetRef ref, TaskItem task) {
    final isDone = task.status == TaskStatus.done;
    final now = DateTime.now();
    final isOverdue = task.dueDate != null &&
        task.dueDate!.isBefore(DateTime(now.year, now.month, now.day)) &&
        !isDone;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedText = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Dismissible(
      key: Key('task-row-${task.id}'),
      direction: DismissDirection.horizontal,
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 22),
            const SizedBox(width: 8),
            Text(
              isDone ? 'Reopen' : 'Mark Done',
              style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 10),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Delete',
              style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 22),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          HapticFeedback.mediumImpact();
          ref.read(tasksNotifierProvider(projectId).notifier).moveTaskStatus(
                taskId: task.id,
                newStatus: isDone ? TaskStatus.todo : TaskStatus.done,
              );
          return false;
        } else {
          HapticFeedback.heavyImpact();
          ref.read(tasksNotifierProvider(projectId).notifier).removeTask(task.id);
          return true;
        }
      },
      child: LiquidGlassBox(
        borderRadius: 20,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        blur: 20.0,
        showWhiteGlare: false,
        tintColor: isDone ? const Color(0xFF10B981).withValues(alpha: isDark ? 0.08 : 0.05) : null,
        customShadow: isDark
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.85),
                  offset: const Offset(4, 6),
                  blurRadius: 14,
                  spreadRadius: -1,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                ),
                if (isDone)
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.16),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
              ]
            : [
                BoxShadow(
                  color: const Color(0xFFA5B2C5).withValues(alpha: 0.45),
                  offset: const Offset(4, 6),
                  blurRadius: 12,
                  spreadRadius: -1,
                ),
                BoxShadow(
                  color: const Color(0xFFBCC8D9).withValues(alpha: 0.35),
                  offset: const Offset(-2, -2),
                  blurRadius: 6,
                ),
              ],
        onTap: () {
          HapticFeedback.lightImpact();
          TaskDetailSheet.show(context, task, projectId);
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Neumorphic Sunken Inset Crater / Convex Completed Button
            Padding(
              padding: const EdgeInsets.only(top: 2, right: 13),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    final nextStatus = _getNextStatus(task.status);
                    ref.read(tasksNotifierProvider(projectId).notifier).moveTaskStatus(
                          taskId: task.id,
                          newStatus: nextStatus,
                        );
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: isDone
                          ? const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF059669),
                                Color(0xFF10B981),
                              ],
                            )
                          : null,
                      color: isDone
                          ? null
                          : (isDark
                              ? const Color(0xFF121316)
                              : const Color(0xFFDFE4EC)),
                      border: Border.all(
                        color: isDone
                            ? const Color(0xFF34D399)
                            : (isDark
                                ? const Color(0xFF1E212B)
                                : const Color(0xFFCBD5E1)),
                        width: 1.1,
                      ),
                      boxShadow: isDone
                          ? [
                              BoxShadow(
                                color: const Color(0xFF10B981).withValues(alpha: 0.55),
                                blurRadius: 8,
                                spreadRadius: 0.5,
                              ),
                              const BoxShadow(
                                color: Colors.black54,
                                offset: Offset(2, 2.5),
                                blurRadius: 4,
                              ),
                            ]
                          : (isDark
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.95),
                                    offset: const Offset(2, 2.5),
                                    blurRadius: 4,
                                    spreadRadius: 0.5,
                                  ),
                                ]
                              : [
                                  BoxShadow(
                                    color: const Color(0xFF9FAEC3).withValues(alpha: 0.60),
                                    offset: const Offset(2, 2.5),
                                    blurRadius: 4,
                                    spreadRadius: 0.5,
                                  ),
                                  const BoxShadow(
                                    color: Colors.white,
                                    offset: Offset(-1, -1),
                                    blurRadius: 2,
                                  ),
                                ]),
                    ),
                    child: isDone
                        ? const Icon(
                            Icons.check_rounded,
                            size: 15,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ),
              ),
            ),

            // Title & Meta Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDone
                          ? (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))
                          : primaryText,
                      decoration: isDone ? TextDecoration.lineThrough : null,
                      decorationColor: const Color(0xFF10B981).withValues(alpha: 0.75),
                      decorationThickness: 1.8,
                    ),
                  ),
                  if (task.description.isNotEmpty) ...[
                    const SizedBox(height: 3.5),
                    Text(
                      task.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: isDone
                            ? (isDark ? const Color(0xFF475569) : const Color(0xFFA1A1AA))
                            : mutedText,
                        height: 1.35,
                      ),
                    ),
                  ],
                  const SizedBox(height: 9),

                  // Badges Row: Done pill + Embossed Priority Pill + Subtasks + Comments + Labels
                  Wrap(
                    spacing: 7,
                    runSpacing: 5,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Emerald Completed Badge
                      if (isDone)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.16 : 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.40 : 0.30),
                              width: 0.8,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10B981).withValues(alpha: 0.18),
                                blurRadius: 6,
                                offset: const Offset(0, 1.5),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF34D399),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0xFF34D399),
                                      blurRadius: 4,
                                      spreadRadius: 0.5,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 4.5),
                              Text(
                                'Done',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF34D399),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Neumorphic Embossed Priority Badge (gently subdued if Done)
                      Opacity(
                        opacity: isDone ? 0.60 : 1.0,
                        child: _buildNeumorphicPriorityPill(task.priority, isDark),
                      ),

                      // Subtask Counter Micro-Chip
                      if (task.subtasks.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF191A20)
                                : const Color(0xFFEFF2F7),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF262A36)
                                  : const Color(0xFFD6DEE9),
                              width: 0.8,
                            ),
                            boxShadow: isDark
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.75),
                                      offset: const Offset(1.5, 2),
                                      blurRadius: 3,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.checklist_rounded, size: 11, color: mutedText),
                              const SizedBox(width: 3.5),
                              Text(
                                '${task.completedSubtaskCount}/${task.subtasks.length}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  color: mutedText,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Comments Counter Micro-Chip
                      if (task.commentCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF191A20)
                                : const Color(0xFFEFF2F7),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF262A36)
                                  : const Color(0xFFD6DEE9),
                              width: 0.8,
                            ),
                            boxShadow: isDark
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.75),
                                      offset: const Offset(1.5, 2),
                                      blurRadius: 3,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.chat_bubble_outline_rounded, size: 11, color: mutedText),
                              const SizedBox(width: 3.5),
                              Text(
                                '${task.commentCount}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  color: mutedText,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Custom Colored Label Pills
                      ...task.labels.map(
                        (l) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: l.color.withValues(alpha: isDark ? 0.18 : 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: l.color.withValues(alpha: isDark ? 0.35 : 0.25),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            l.name,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: l.color,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Right side: Neumorphic Due Date Chip & Neumorphic Avatar Socket
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (task.dueDate != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: isOverdue
                          ? const Color(0xFFEF4444).withValues(alpha: isDark ? 0.20 : 0.12)
                          : (isDark
                              ? const Color(0xFF1B1D23)
                              : const Color(0xFFF3F6FA)),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isOverdue
                            ? const Color(0xFFEF4444).withValues(alpha: isDark ? 0.45 : 0.35)
                            : (isDark
                                ? const Color(0xFF262A36)
                                : const Color(0xFFD6DEE9)),
                        width: 0.8,
                      ),
                      boxShadow: isDark
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.80),
                                offset: const Offset(2, 2.5),
                                blurRadius: 4,
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: const Color(0xFFA8B4C7).withValues(alpha: 0.45),
                                offset: const Offset(2, 2.5),
                                blurRadius: 4,
                              ),
                              const BoxShadow(
                                color: Colors.white,
                                offset: Offset(-1.5, -1.5),
                                blurRadius: 3,
                              ),
                            ],
                    ),
                    child: Text(
                      DateFormat('MMM d').format(task.dueDate!),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isOverdue
                            ? const Color(0xFFF87171)
                            : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                if (task.assigneeName != null)
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF2D3242)
                            : const Color(0xFFCBD5E1),
                        width: 1.0,
                      ),
                      boxShadow: isDark
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.85),
                                offset: const Offset(2, 2.5),
                                blurRadius: 5,
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: const Color(0xFFA8B4C7).withValues(alpha: 0.50),
                                offset: const Offset(2, 2.5),
                                blurRadius: 4,
                              ),
                              const BoxShadow(
                                color: Colors.white,
                                offset: Offset(-1.5, -1.5),
                                blurRadius: 3,
                              ),
                            ],
                    ),
                    child: CircleAvatar(
                      radius: 12,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      backgroundImage: task.assigneeAvatar != null
                          ? NetworkImage(task.assigneeAvatar!)
                          : null,
                      child: task.assigneeAvatar == null
                          ? Text(
                              task.assigneeName![0].toUpperCase(),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            )
                          : null,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Neumorphic embossed priority badge matching reference
  Widget _buildNeumorphicPriorityPill(TaskPriority priority, bool isDark) {
    Color color;
    String label;
    IconData? icon;

    switch (priority) {
      case TaskPriority.urgent:
        color = const Color(0xFFEF4444);
        label = '! Urgent';
        break;
      case TaskPriority.high:
        color = const Color(0xFFF97316);
        label = 'High';
        icon = Icons.arrow_upward_rounded;
        break;
      case TaskPriority.medium:
        color = const Color(0xFFF59E0B);
        label = 'Medium';
        break;
      case TaskPriority.low:
        color = const Color(0xFF10B981);
        label = 'Low';
        icon = Icons.arrow_downward_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1D23) : const Color(0xFFF3F6FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.35 : 0.25),
          width: 0.9,
        ),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.75),
                  offset: const Offset(2, 2.5),
                  blurRadius: 4,
                ),
                BoxShadow(
                  color: color.withValues(alpha: 0.20),
                  blurRadius: 6,
                  spreadRadius: 0.5,
                ),
              ]
            : [
                BoxShadow(
                  color: const Color(0xFFA8B4C7).withValues(alpha: 0.40),
                  offset: const Offset(2, 2.5),
                  blurRadius: 4,
                ),
                const BoxShadow(
                  color: Colors.white,
                  offset: Offset(-1.5, -1.5),
                  blurRadius: 3,
                ),
              ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5.5,
            height: 5.5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.8),
                  blurRadius: 4,
                  spreadRadius: 0.5,
                ),
              ],
            ),
          ),
          const SizedBox(width: 5),
          if (icon != null) ...[
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  TaskStatus _getNextStatus(TaskStatus current) {
    switch (current) {
      case TaskStatus.todo:
        return TaskStatus.inProgress;
      case TaskStatus.inProgress:
        return TaskStatus.inReview;
      case TaskStatus.inReview:
        return TaskStatus.done;
      case TaskStatus.done:
        return TaskStatus.todo;
    }
  }
}
