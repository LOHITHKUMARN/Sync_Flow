import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../auth/presentation/auth_providers.dart';
import '../../../workspaces/presentation/workspace_providers.dart';
import '../../../workspaces/domain/workspace_model.dart';
import '../../../members/presentation/member_providers.dart';
import '../../domain/task_model.dart';
import '../../domain/subtask_model.dart';
import '../../domain/label_model.dart';
import '../task_providers.dart';
import '../comment_providers.dart';
import '../activity_providers.dart';
import '../attachment_providers.dart';
import '../time_tracking_providers.dart';
import '../../../notifications/domain/notification_model.dart';
import '../../../notifications/presentation/notification_providers.dart';
import 'task_comments_view.dart';
import 'task_attachments_view.dart';
import 'task_time_tracking_view.dart';
import 'task_activity_view.dart';
import 'label_picker_dialog.dart';
import '../../../ai/presentation/widgets/ai_task_breakdown_dialog.dart';
import '../../../ai/presentation/widgets/ai_copilot_sheet.dart';

class TaskDetailSheet extends ConsumerStatefulWidget {
  final TaskItem task;

  const TaskDetailSheet({super.key, required this.task});

  static Future<void> show(BuildContext context, TaskItem task, [String? projectId]) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => TaskDetailSheet(task: task),
    );
  }

  @override
  ConsumerState<TaskDetailSheet> createState() => _TaskDetailSheetState();
}

class _TaskDetailSheetState extends ConsumerState<TaskDetailSheet> {
  late TaskItem _task;
  late TaskStatus _status;
  late TaskPriority _priority;
  final _subtaskController = TextEditingController();
  int _activeTab = 0; // 0: Details & Subtasks, 1: Discussion, 2: Activity

  @override
  void initState() {
    super.initState();
    _task = widget.task;
    _status = widget.task.status;
    _priority = widget.task.priority;
  }

  @override
  void dispose() {
    _subtaskController.dispose();
    super.dispose();
  }

  void _logActivity(String actionType, String summary) {
    final currentUser = ref.read(currentUserProvider);
    ref.read(taskActivitiesProvider(_task.id).notifier).recordActivity(
          actorId: currentUser?.id ?? 'demo-user-001',
          actorName: currentUser?.fullName ?? 'Alex Rivera',
          actorAvatar: currentUser?.avatarUrl,
          actionType: actionType,
          summary: summary,
          projectId: _task.projectId,
        );
  }

  Future<void> _updateStatus(TaskStatus newStatus) async {
    setState(() {
      _status = newStatus;
      _task = _task.copyWith(status: newStatus, updatedAt: DateTime.now());
    });

    _logActivity('status_changed', 'moved status to ${newStatus.label}');

    await ref.read(tasksNotifierProvider(_task.projectId).notifier).moveTaskStatus(
          taskId: _task.id,
          newStatus: newStatus,
        );
  }

  Future<void> _updatePriority(TaskPriority newPriority) async {
    setState(() {
      _priority = newPriority;
      _task = _task.copyWith(priority: newPriority, updatedAt: DateTime.now());
    });

    _logActivity('priority_changed', 'changed priority to ${newPriority.label}');

    await ref.read(tasksNotifierProvider(_task.projectId).notifier).updateTaskDetails(_task);
  }

  Future<void> _updateAssignee(WorkspaceMember? member) async {
    final updated = _task.copyWith(
      assigneeId: member?.id,
      assigneeName: member?.name,
      assigneeAvatar: member?.avatarUrl,
      updatedAt: DateTime.now(),
    );
    setState(() => _task = updated);

    _logActivity('assigned', member != null ? 'assigned to ${member.name}' : 'unassigned task');

    if (member != null && member.userId.isNotEmpty) {
      final currentUser = ref.read(currentUserProvider);
      ref.read(notificationsProvider(member.userId).notifier).sendNotification(
            recipientUserId: member.userId,
            actorId: currentUser?.id ?? 'demo-user-001',
            actorName: currentUser?.fullName ?? 'Alex Rivera',
            actorAvatar: currentUser?.avatarUrl,
            type: NotificationType.taskAssigned,
            title: 'Task Reassigned',
            body: '${currentUser?.fullName ?? 'Alex Rivera'} assigned you to "${_task.title}".',
            taskId: _task.id,
            projectId: _task.projectId,
          );
    }

    await ref.read(tasksNotifierProvider(_task.projectId).notifier).updateTaskDetails(updated);
  }

  Future<void> _manageLabels(String workspaceId) async {
    final updatedLabels = await showDialog<List<TaskLabel>>(
      context: context,
      builder: (_) => LabelPickerDialog(
        workspaceId: workspaceId,
        currentLabels: _task.labels,
      ),
    );

    if (updatedLabels != null) {
      final updated = _task.copyWith(labels: updatedLabels, updatedAt: DateTime.now());
      setState(() => _task = updated);
      _logActivity('label_changed', 'updated task labels (${updatedLabels.map((l) => l.name).join(', ')})');
      await ref.read(tasksNotifierProvider(_task.projectId).notifier).updateTaskDetails(updated);
    }
  }

  Future<void> _removeLabel(TaskLabel label) async {
    final updatedLabels = _task.labels.where((l) => l.id != label.id).toList();
    final updated = _task.copyWith(labels: updatedLabels, updatedAt: DateTime.now());
    setState(() => _task = updated);
    _logActivity('label_changed', 'removed label "${label.name}"');
    await ref.read(tasksNotifierProvider(_task.projectId).notifier).updateTaskDetails(updated);
  }

  Future<void> _toggleSubtask(int index) async {
    final subtasks = List<TaskSubtask>.from(_task.subtasks);
    final item = subtasks[index];
    final updatedItem = item.copyWith(isCompleted: !item.isCompleted);
    subtasks[index] = updatedItem;
    final updated = _task.copyWith(subtasks: subtasks, updatedAt: DateTime.now());
    setState(() => _task = updated);

    _logActivity(
      'subtask_toggled',
      'marked "${item.title}" as ${updatedItem.isCompleted ? 'completed' : 'incomplete'}',
    );

    await ref.read(tasksNotifierProvider(_task.projectId).notifier).updateTaskDetails(updated);
  }

  Future<void> _addSubtask() async {
    final title = _subtaskController.text.trim();
    if (title.isEmpty) return;

    final newSub = TaskSubtask(
      id: const Uuid().v4(),
      taskId: _task.id,
      title: title,
      position: (_task.subtasks.length + 1) * 1000.0,
      createdAt: DateTime.now(),
    );

    final updated = _task.copyWith(
      subtasks: [..._task.subtasks, newSub],
      updatedAt: DateTime.now(),
    );

    _subtaskController.clear();
    setState(() => _task = updated);
    _logActivity('subtask_added', 'added subtask "$title"');
    await ref.read(tasksNotifierProvider(_task.projectId).notifier).updateTaskDetails(updated);
  }

  Future<void> _deleteSubtask(int index) async {
    final item = _task.subtasks[index];
    final subtasks = List<TaskSubtask>.from(_task.subtasks)..removeAt(index);
    final updated = _task.copyWith(subtasks: subtasks, updatedAt: DateTime.now());
    setState(() => _task = updated);
    _logActivity('subtask_deleted', 'deleted subtask "${item.title}"');
    await ref.read(tasksNotifierProvider(_task.projectId).notifier).updateTaskDetails(updated);
  }

  Future<void> _deleteTask() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Task?'),
        content: const Text('Are you sure you want to permanently delete this task?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.priorityUrgent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(tasksNotifierProvider(_task.projectId).notifier).removeTask(_task.id);
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeWorkspace = ref.watch(activeWorkspaceProvider);
    final membersAsync = activeWorkspace != null
        ? ref.watch(workspaceMembersProvider(activeWorkspace.id))
        : const AsyncValue<List<WorkspaceMember>>.data([]);
    final members = membersAsync.value ?? [];

    final commentsAsync = ref.watch(taskCommentsProvider(_task.id));
    final commentsCount = commentsAsync.value?.length ?? _task.commentCount;

    final attachmentsAsync = ref.watch(taskAttachmentsProvider(_task.id));
    final attachmentsCount = attachmentsAsync.value?.length ?? _task.attachmentCount;

    final timeEntriesAsync = ref.watch(taskTimeEntriesProvider(_task.id));
    final timeEntriesCount = timeEntriesAsync.value?.length ?? 0;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Drag Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header: Status, Priority & Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      StatusBadge(status: _status.code),
                      const SizedBox(width: 8),
                      PriorityBadge(priority: _priority.code),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => AiCopilotSheet.show(
                          context,
                          projectId: _task.projectId,
                          projectName: 'Task Insights',
                          task: _task,
                        ),
                        icon: Icon(
                          Icons.auto_awesome_rounded,
                          color: isDark ? const Color(0xFFA78BFA) : const Color(0xFF7C3AED),
                          size: 20,
                        ),
                        tooltip: 'AI Copilot Insights',
                      ),
                      IconButton(
                        onPressed: _deleteTask,
                        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.priorityUrgent, size: 20),
                        tooltip: 'Delete Task',
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded, size: 20),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                _task.title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                ),
              ),
              if (_task.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  _task.description,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    height: 1.5,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // Segmented Horizontal Tab Selector
              SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildTabButton(index: 0, label: 'Details', icon: Icons.notes_rounded, isDark: isDark),
                    const SizedBox(width: 8),
                    _buildTabButton(
                      index: 1,
                      label: 'Comments',
                      count: commentsCount,
                      icon: Icons.chat_bubble_outline_rounded,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 8),
                    _buildTabButton(
                      index: 2,
                      label: 'Files',
                      count: attachmentsCount,
                      icon: Icons.attach_file_rounded,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 8),
                    _buildTabButton(
                      index: 3,
                      label: 'Time',
                      count: timeEntriesCount,
                      icon: Icons.timer_outlined,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 8),
                    _buildTabButton(index: 4, label: 'Activity', icon: Icons.history_rounded, isDark: isDark),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Tab 0: Details, Meta, Labels & Subtasks
              if (_activeTab == 0) ...[
                // Assignee & Due Date Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Interactive Assignee selector
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.person_outline_rounded, size: 14, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                              const SizedBox(width: 6),
                              Text(
                                'Assignee',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          DropdownButton<String?>(
                            value: _task.assigneeId,
                            isExpanded: true,
                            underline: const SizedBox.shrink(),
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                            items: [
                              DropdownMenuItem<String?>(
                                value: null,
                                child: Text('Unassigned', style: GoogleFonts.plusJakartaSans(fontSize: 13)),
                              ),
                              ...members.map((m) {
                                return DropdownMenuItem<String?>(
                                  value: m.id,
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 10,
                                        backgroundColor: isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7),
                                        backgroundImage: m.avatarUrl != null ? NetworkImage(m.avatarUrl!) : null,
                                        child: m.avatarUrl == null
                                            ? Text(
                                                m.name.isNotEmpty ? m.name[0].toUpperCase() : '?',
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                  color: isDark ? Colors.white : const Color(0xFF09090B),
                                                ),
                                              )
                                            : null,
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          m.name,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                            onChanged: (memberId) {
                              final member = members.where((m) => m.id == memberId).firstOrNull;
                              _updateAssignee(member);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Due Date Display
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.calendar_today_rounded, size: 14, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                              const SizedBox(width: 6),
                              Text(
                                'Due Date',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _task.dueDate ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2035),
                              );
                              if (picked != null) {
                                final updated = _task.copyWith(dueDate: picked, updatedAt: DateTime.now());
                                setState(() => _task = updated);
                                _logActivity('due_date_changed', 'changed due date to ${DateFormat('MMM dd, yyyy').format(picked)}');
                                await ref.read(tasksNotifierProvider(_task.projectId).notifier).updateTaskDetails(updated);
                              }
                            },
                            borderRadius: BorderRadius.circular(6),
                            child: Row(
                              children: [
                                Text(
                                  _task.dueDate != null
                                      ? DateFormat('MMM dd, yyyy').format(_task.dueDate!)
                                      : 'Set deadline',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.edit_calendar_rounded, size: 14, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Labels Section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Labels',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (activeWorkspace != null)
                          TextButton.icon(
                            onPressed: () => _manageLabels(activeWorkspace.id),
                            icon: const Icon(Icons.add_rounded, size: 16),
                            label: const Text('Manage Labels'),
                            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (_task.labels.isEmpty)
                      Text(
                        'No labels assigned yet.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                      )
                    else
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _task.labels.map((l) {
                          Color color = AppColors.primary;
                          try {
                            final hex = l.colorHex.replaceAll('#', '');
                            color = Color(int.parse('0xFF$hex'));
                          } catch (_) {}

                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: color.withAlpha(25),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: color.withAlpha(80)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  l.name,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: color,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () => _removeLabel(l),
                                  child: Icon(Icons.close_rounded, size: 14, color: color),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
                const SizedBox(height: 18),

                // Priority Selector
                Text(
                  'Priority',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: TaskPriority.values.map((p) {
                    final isCurrent = _priority == p;
                    final (pColor, pIcon) = switch (p) {
                      TaskPriority.low => (
                          isDark ? const Color(0xFF10B981) : const Color(0xFF059669),
                          Icons.arrow_downward_rounded,
                        ),
                      TaskPriority.medium => (
                          isDark ? const Color(0xFFF59E0B) : const Color(0xFFB45309),
                          Icons.remove_rounded,
                        ),
                      TaskPriority.high => (
                          isDark ? const Color(0xFFEA580C) : const Color(0xFFC2410C),
                          Icons.arrow_upward_rounded,
                        ),
                      TaskPriority.urgent => (
                          isDark ? const Color(0xFFEF4444) : const Color(0xFFDC2626),
                          Icons.priority_high_rounded,
                        ),
                    };

                    return InkWell(
                      onTap: () => _updatePriority(p),
                      borderRadius: BorderRadius.circular(8),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? (isDark ? pColor.withValues(alpha: 0.22) : pColor.withValues(alpha: 0.12))
                              : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isCurrent
                                ? pColor
                                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                            width: isCurrent ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isCurrent ? Icons.check_rounded : pIcon,
                              size: 14,
                              color: isCurrent ? pColor : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              p.label,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                                color: isCurrent ? pColor : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),

                // Status Switcher
                Text(
                  'Move Status',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: TaskStatus.values.map((s) {
                    final isCurrent = _status == s;
                    final (statusColor, statusIcon) = switch (s) {
                      TaskStatus.todo => (const Color(0xFF71717A), Icons.radio_button_unchecked_rounded),
                      TaskStatus.inProgress => (const Color(0xFF3B82F6), Icons.pending_rounded),
                      TaskStatus.inReview => (const Color(0xFFF59E0B), Icons.rate_review_rounded),
                      TaskStatus.done => (const Color(0xFF10B981), Icons.check_circle_rounded),
                    };

                    return InkWell(
                      onTap: () => _updateStatus(s),
                      borderRadius: BorderRadius.circular(8),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? (isDark ? statusColor.withValues(alpha: 0.22) : statusColor.withValues(alpha: 0.12))
                              : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isCurrent
                                ? statusColor
                                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                            width: isCurrent ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isCurrent ? Icons.check_rounded : statusIcon,
                              size: 14,
                              color: isCurrent
                                  ? (isDark ? (statusColor == const Color(0xFF71717A) ? Colors.white : statusColor) : (statusColor == const Color(0xFF71717A) ? const Color(0xFF18181B) : statusColor))
                                  : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              s.label,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                                color: isCurrent
                                    ? (isDark ? (statusColor == const Color(0xFF71717A) ? Colors.white : statusColor) : (statusColor == const Color(0xFF71717A) ? const Color(0xFF18181B) : statusColor))
                                    : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 22),

                // Subtasks / Checklist
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Subtasks (${_task.completedSubtaskCount}/${_task.subtasks.length})',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => AiTaskBreakdownDialog.show(context, _task),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF8B5CF6).withValues(alpha: 0.20) : const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isDark ? const Color(0xFF8B5CF6).withValues(alpha: 0.45) : const Color(0xFF7C3AED).withValues(alpha: 0.35),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.auto_awesome_rounded,
                                  size: 13,
                                  color: isDark ? const Color(0xFFA78BFA) : const Color(0xFF7C3AED),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'AI Breakdown',
                                  style: TextStyle(
                                    color: isDark ? const Color(0xFFA78BFA) : const Color(0xFF7C3AED),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_task.subtasks.isNotEmpty)
                      Text(
                        '${(_task.subtaskProgress * 100).toInt()}%',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _task.subtaskProgress == 1.0
                              ? AppColors.done
                              : (isDark ? Colors.white : const Color(0xFF09090B)),
                        ),
                      ),
                  ],
                ),
                if (_task.subtasks.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: _task.subtaskProgress,
                      minHeight: 4,
                      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBorder,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _task.subtaskProgress == 1.0
                            ? AppColors.done
                            : (isDark ? Colors.white : const Color(0xFF09090B)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ..._task.subtasks.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final sub = entry.value;
                    return InkWell(
                      onTap: () => _toggleSubtask(idx),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                        child: Row(
                          children: [
                            Icon(
                              sub.isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                              size: 18,
                              color: sub.isCompleted ? AppColors.done : Colors.grey,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                sub.title,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  decoration: sub.isCompleted ? TextDecoration.lineThrough : null,
                                  color: sub.isCompleted
                                      ? (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)
                                      : null,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => _deleteSubtask(idx),
                              icon: const Icon(Icons.close_rounded, size: 16, color: Colors.grey),
                              tooltip: 'Remove',
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _subtaskController,
                        style: GoogleFonts.plusJakartaSans(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Add a new subtask...',
                          hintStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          fillColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: isDark ? Colors.white70 : const Color(0xFF09090B), width: 1.5),
                          ),
                        ),
                        onSubmitted: (_) => _addSubtask(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _addSubtask,
                      style: IconButton.styleFrom(
                        backgroundColor: isDark ? Colors.white : const Color(0xFF09090B),
                        foregroundColor: isDark ? Colors.black : Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.add_rounded, size: 20),
                      tooltip: 'Add Subtask',
                    ),
                  ],
                ),
              ] else if (_activeTab == 1) ...[
                // Tab 1: Discussion (Comments & Replies)
                TaskCommentsView(
                  taskId: _task.id,
                  projectId: _task.projectId,
                ),
              ] else if (_activeTab == 2) ...[
                // Tab 2: Attachments & Files
                SizedBox(
                  height: 380,
                  child: TaskAttachmentsView(taskId: _task.id),
                ),
              ] else if (_activeTab == 3) ...[
                // Tab 3: Time Tracking (Stopwatch & Manual Logs)
                SizedBox(
                  height: 420,
                  child: TaskTimeTrackingView(task: _task),
                ),
              ] else ...[
                // Tab 4: Activity Audit Timeline
                TaskActivityView(taskId: _task.id),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required int index,
    required String label,
    required IconData icon,
    int? count,
    required bool isDark,
  }) {
    final isSelected = _activeTab == index;
    return InkWell(
      onTap: () => setState(() => _activeTab = index),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF27272A) : const Color(0xFF09090B))
              : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? (isDark ? const Color(0xFF3F3F46) : const Color(0xFF09090B))
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected
                  ? Colors.white
                  : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? Colors.white24 : Colors.white.withValues(alpha: 0.2))
                      : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}


