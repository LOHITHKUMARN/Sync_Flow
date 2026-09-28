import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/neumorphic_widgets.dart';
import '../../../auth/presentation/auth_providers.dart';
import '../../../workspaces/presentation/workspace_providers.dart';
import '../../../workspaces/domain/workspace_model.dart';
import '../../../members/presentation/member_providers.dart';
import '../../domain/task_model.dart';
import '../../domain/subtask_model.dart';
import '../../domain/label_model.dart';
import '../task_providers.dart';
import '../activity_providers.dart';
import '../../../notifications/domain/notification_model.dart';
import '../../../notifications/presentation/notification_providers.dart';
import 'label_picker_dialog.dart';

class CreateTaskDialog extends ConsumerStatefulWidget {
  final String projectId;
  final TaskStatus initialStatus;
  final DateTime? initialDueDate;

  const CreateTaskDialog({
    super.key,
    required this.projectId,
    this.initialStatus = TaskStatus.todo,
    this.initialDueDate,
  });

  @override
  ConsumerState<CreateTaskDialog> createState() => _CreateTaskDialogState();
}

class _CreateTaskDialogState extends ConsumerState<CreateTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _subtaskInputController = TextEditingController();
  String? _selectedAssigneeId;
  late TaskStatus _selectedStatus;
  TaskPriority _selectedPriority = TaskPriority.medium;
  DateTime? _selectedDueDate;
  final List<String> _subtaskDrafts = [];
  List<TaskLabel> _selectedLabels = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.initialStatus;
    _selectedDueDate = widget.initialDueDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _subtaskInputController.dispose();
    super.dispose();
  }

  void _addSubtaskDraft() {
    final text = _subtaskInputController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _subtaskDrafts.add(text);
        _subtaskInputController.clear();
      });
    }
  }

  void _removeSubtaskDraft(int index) {
    setState(() {
      _subtaskDrafts.removeAt(index);
    });
  }

  Future<void> _manageLabels(String workspaceId) async {
    final updated = await showDialog<List<TaskLabel>>(
      context: context,
      builder: (_) => LabelPickerDialog(
        workspaceId: workspaceId,
        currentLabels: _selectedLabels,
      ),
    );
    if (updated != null) {
      setState(() => _selectedLabels = updated);
    }
  }

  Future<void> _handleSave(List<WorkspaceMember> members) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final selectedMember = members.where((m) => m.id == _selectedAssigneeId).firstOrNull;
      final taskId = const Uuid().v4();

      final subtasks = _subtaskDrafts.asMap().entries.map((e) {
        return TaskSubtask(
          id: const Uuid().v4(),
          taskId: taskId,
          title: e.value,
          position: (e.key + 1) * 1000.0,
          createdAt: DateTime.now(),
        );
      }).toList();

      final task = TaskItem(
        id: taskId,
        projectId: widget.projectId,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        status: _selectedStatus,
        priority: _selectedPriority,
        assigneeId: selectedMember?.id,
        assigneeName: selectedMember?.name,
        assigneeAvatar: selectedMember?.avatarUrl,
        dueDate: _selectedDueDate,
        labels: _selectedLabels,
        subtasks: subtasks,
        position: DateTime.now().millisecondsSinceEpoch.toDouble(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await ref.read(tasksNotifierProvider(widget.projectId).notifier).addTask(task);

      // Log creation in activity feed
      final currentUser = ref.read(currentUserProvider);
      ref.read(taskActivitiesProvider(taskId).notifier).recordActivity(
            actorId: currentUser?.id ?? 'demo-user-001',
            actorName: currentUser?.fullName ?? 'Alex Rivera',
            actorAvatar: currentUser?.avatarUrl,
            actionType: 'created',
            summary: 'created the task',
            projectId: widget.projectId,
          );

      // Send notification to assignee
      if (selectedMember != null && selectedMember.userId.isNotEmpty) {
        ref.read(notificationsProvider(selectedMember.userId).notifier).sendNotification(
              recipientUserId: selectedMember.userId,
              actorId: currentUser?.id ?? 'demo-user-001',
              actorName: currentUser?.fullName ?? 'Alex Rivera',
              actorAvatar: currentUser?.avatarUrl,
              type: NotificationType.taskAssigned,
              title: 'New Task Assigned',
              body: '${currentUser?.fullName ?? 'Alex Rivera'} assigned you to "${task.title}".',
              taskId: taskId,
              projectId: widget.projectId,
            );
      }

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create task: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildFieldLabel(String label, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7, left: 2),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isDark ? const Color(0xFF9AA0A6) : const Color(0xFF5F6368),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeWorkspace = ref.watch(activeWorkspaceProvider);
    final membersAsync = activeWorkspace != null
        ? ref.watch(workspaceMembersProvider(activeWorkspace.id))
        : const AsyncValue<List<WorkspaceMember>>.data([]);
    final members = membersAsync.value ?? [];

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: NeumorphicContainer(
          borderRadius: 24,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dialog Header with Title and Close Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Create New Task',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF09090B),
                        ),
                      ),
                      NeumorphicIconButton(
                        icon: Icons.close_rounded,
                        size: 34,
                        iconSize: 18,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Task Title Field
                  _buildFieldLabel('Task Title', isDark),
                  NeumorphicContainer(
                    isPressed: true,
                    borderRadius: 14,
                    depth: 0.8,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                    child: TextFormField(
                      controller: _titleController,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : const Color(0xFF09090B),
                      ),
                      cursorColor: AppColors.primary,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        hintText: 'e.g. Implement WebSocket listener...',
                        hintStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Description Field
                  _buildFieldLabel('Description', isDark),
                  NeumorphicContainer(
                    isPressed: true,
                    borderRadius: 14,
                    depth: 0.8,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    child: TextFormField(
                      controller: _descController,
                      maxLines: 3,
                      minLines: 2,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        height: 1.4,
                        color: isDark ? Colors.white : const Color(0xFF09090B),
                      ),
                      cursorColor: AppColors.primary,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 4),
                        hintText: 'Details, requirements, and links...',
                        hintStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Assignee Selector
                  _buildFieldLabel('Assignee', isDark),
                  NeumorphicContainer(
                    isPressed: true,
                    borderRadius: 14,
                    depth: 0.8,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: _selectedAssigneeId,
                        isExpanded: true,
                        dropdownColor: isDark ? NeumorphicColors.darkSurfaceTop : NeumorphicColors.lightSurfaceTop,
                        icon: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: isDark ? Colors.white60 : Colors.black54,
                          size: 20,
                        ),
                        hint: Text(
                          'Select team member...',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                        ),
                        items: [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 11,
                                  backgroundColor: isDark ? Colors.white12 : Colors.black12,
                                  child: const Icon(Icons.person_outline_rounded, size: 13, color: Colors.grey),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Unassigned',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    color: isDark ? Colors.white70 : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...members.map((m) {
                            return DropdownMenuItem<String?>(
                              value: m.id,
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 11,
                                    backgroundColor: AppColors.primary,
                                    backgroundImage: m.avatarUrl != null ? NetworkImage(m.avatarUrl!) : null,
                                    child: m.avatarUrl == null
                                        ? Text(
                                            m.name.isNotEmpty ? m.name[0].toUpperCase() : '?',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      m.name,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withAlpha(35),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      m.role.label,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                        onChanged: (val) {
                          setState(() => _selectedAssigneeId = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Status and Priority Row
                  Row(
                    children: [
                      // Status Column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFieldLabel('Status', isDark),
                            NeumorphicContainer(
                              isPressed: true,
                              borderRadius: 14,
                              depth: 0.8,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<TaskStatus>(
                                  value: _selectedStatus,
                                  isExpanded: true,
                                  dropdownColor: isDark
                                      ? NeumorphicColors.darkSurfaceTop
                                      : NeumorphicColors.lightSurfaceTop,
                                  icon: Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: isDark ? Colors.white60 : Colors.black54,
                                    size: 18,
                                  ),
                                  items: TaskStatus.values.map((s) {
                                    return DropdownMenuItem(
                                      value: s,
                                      child: Text(
                                        s.label,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) setState(() => _selectedStatus = val);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Priority Column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFieldLabel('Priority', isDark),
                            NeumorphicContainer(
                              isPressed: true,
                              borderRadius: 14,
                              depth: 0.8,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<TaskPriority>(
                                  value: _selectedPriority,
                                  isExpanded: true,
                                  dropdownColor: isDark
                                      ? NeumorphicColors.darkSurfaceTop
                                      : NeumorphicColors.lightSurfaceTop,
                                  icon: Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: isDark ? Colors.white60 : Colors.black54,
                                    size: 18,
                                  ),
                                  items: TaskPriority.values.map((p) {
                                    Color pColor;
                                    switch (p) {
                                      case TaskPriority.low:
                                        pColor = AppColors.priorityLow;
                                        break;
                                      case TaskPriority.medium:
                                        pColor = AppColors.priorityMedium;
                                        break;
                                      case TaskPriority.high:
                                        pColor = AppColors.priorityHigh;
                                        break;
                                      case TaskPriority.urgent:
                                        pColor = AppColors.priorityUrgent;
                                        break;
                                    }
                                    return DropdownMenuItem(
                                      value: p,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(color: pColor, shape: BoxShape.circle),
                                          ),
                                          const SizedBox(width: 8),
                                          Flexible(
                                            child: Text(
                                              p.label,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: pColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) setState(() => _selectedPriority = val);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Due Date Tile
                  _buildFieldLabel('Due Date', isDark),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDueDate ?? DateTime.now().add(const Duration(days: 3)),
                        firstDate: DateTime.now().subtract(const Duration(days: 30)),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setState(() => _selectedDueDate = picked);
                      }
                    },
                    child: NeumorphicContainer(
                      isPressed: true,
                      borderRadius: 14,
                      depth: 0.8,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.primary),
                              const SizedBox(width: 10),
                              Text(
                                _selectedDueDate == null
                                    ? 'Set Due Date'
                                    : DateFormat('MMM dd, yyyy').format(_selectedDueDate!),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: _selectedDueDate != null ? FontWeight.w600 : FontWeight.w400,
                                  color: _selectedDueDate != null
                                      ? (isDark ? Colors.white : Colors.black87)
                                      : (isDark ? Colors.white54 : Colors.black45),
                                ),
                              ),
                            ],
                          ),
                          if (_selectedDueDate != null)
                            GestureDetector(
                              onTap: () => setState(() => _selectedDueDate = null),
                              child: Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Labels Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildFieldLabel('Labels', isDark),
                      if (activeWorkspace != null)
                        GestureDetector(
                          onTap: () => _manageLabels(activeWorkspace.id),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 7),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.label_outline_rounded, size: 14, color: AppColors.primary),
                                const SizedBox(width: 5),
                                Text(
                                  _selectedLabels.isEmpty
                                      ? 'Add Labels'
                                      : 'Edit Labels (${_selectedLabels.length})',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (_selectedLabels.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _selectedLabels.map((l) {
                        Color color = AppColors.primary;
                        try {
                          final hex = l.colorHex.replaceAll('#', '');
                          color = Color(int.parse('0xFF$hex'));
                        } catch (_) {}
                        return NeumorphicContainer(
                          borderRadius: 8,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          depth: 0.6,
                          customBorder: Border.all(color: color.withAlpha(80)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                l.name,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: color,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Subtasks / Checklist Section
                  _buildFieldLabel('Subtasks / Checklist', isDark),
                  Row(
                    children: [
                      Expanded(
                        child: NeumorphicContainer(
                          isPressed: true,
                          borderRadius: 14,
                          depth: 0.8,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                          child: TextField(
                            controller: _subtaskInputController,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: isDark ? Colors.white : const Color(0xFF09090B),
                            ),
                            cursorColor: AppColors.primary,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 10),
                              hintText: 'Add a subtask item...',
                              hintStyle: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: isDark ? Colors.white30 : Colors.black38,
                              ),
                            ),
                            onSubmitted: (_) => _addSubtaskDraft(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      NeumorphicIconButton(
                        icon: Icons.add_rounded,
                        size: 42,
                        iconSize: 20,
                        iconColor: Colors.white,
                        onTap: _addSubtaskDraft,
                        tooltip: 'Add Subtask',
                      ),
                    ],
                  ),
                  if (_subtaskDrafts.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    ..._subtaskDrafts.asMap().entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: NeumorphicContainer(
                          borderRadius: 12,
                          depth: 0.6,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_box_outline_blank_rounded,
                                size: 16,
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  entry.value,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _removeSubtaskDraft(entry.key),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 16,
                                  color: isDark ? Colors.white38 : Colors.black38,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                  const SizedBox(height: 22),

                  // Bottom Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: NeumorphicButton(
                          label: 'Cancel',
                          isOutlined: true,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: NeumorphicButton(
                          label: 'Create Task',
                          color: AppColors.primary,
                          isLoading: _isLoading,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          onPressed: () => _handleSave(members),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
