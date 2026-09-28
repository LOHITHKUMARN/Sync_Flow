import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../core/widgets/chromatic_glass_pill.dart';
import '../../../core/widgets/primary_button.dart';
import '../../projects/presentation/project_providers.dart';
import '../domain/task_model.dart';
import 'task_providers.dart';
import '../../notifications/presentation/widgets/notification_bell_button.dart';
import 'widgets/create_task_dialog.dart';
import 'widgets/kanban_column.dart';
import 'widgets/column_jump_strip.dart';
import 'widgets/task_filter_sheet.dart';
import '../domain/task_view_mode.dart';
import 'widgets/task_view_mode_toggle.dart';
import 'widgets/task_list_view.dart';
import 'widgets/task_calendar_view.dart';
import '../../workspaces/presentation/workspace_providers.dart';
import '../../members/presentation/widgets/member_list_sheet.dart';
import '../../sync/presentation/widgets/sync_status_badge.dart';
import '../../sync/presentation/widgets/offline_banner.dart';
import '../../analytics/presentation/widgets/analytics_dashboard_sheet.dart';
import '../../ai/presentation/widgets/ai_copilot_sheet.dart';
import '../../../core/theme/theme_provider.dart';

class KanbanBoardScreen extends ConsumerStatefulWidget {
  final String projectId;

  const KanbanBoardScreen({super.key, required this.projectId});

  @override
  ConsumerState<KanbanBoardScreen> createState() => _KanbanBoardScreenState();
}

class _KanbanBoardScreenState extends ConsumerState<KanbanBoardScreen> {
  final _searchController = TextEditingController();
  final _boardScrollController = ScrollController();
  bool _isSearching = false;
  int _activeColumnIndex = 0;

  @override
  void initState() {
    super.initState();
    _boardScrollController.addListener(_onBoardScroll);
  }

  void _onBoardScroll() {
    if (!_boardScrollController.hasClients) return;
    final index = (_boardScrollController.offset / 314.0).round().clamp(0, TaskStatus.values.length - 1);
    if (index != _activeColumnIndex) {
      setState(() => _activeColumnIndex = index);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _boardScrollController.removeListener(_onBoardScroll);
    _boardScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeProject = ref.watch(activeProjectProvider);
    final activeWs = ref.watch(activeWorkspaceProvider);
    final filteredTasks = ref.watch(filteredTasksProvider(widget.projectId));
    final tasksAsync = ref.watch(tasksNotifierProvider(widget.projectId));
    final selectedPriority = ref.watch(taskPriorityFilterProvider);
    final selectedLabelId = ref.watch(taskLabelFilterProvider);
    final viewMode = ref.watch(taskViewModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final projectName = activeProject?.name ?? 'Project Board';
    final isCompactScreen = MediaQuery.sizeOf(context).width < 650;
    final accentColor = Theme.of(context).colorScheme.primary;

    final hasActiveFilter = selectedPriority != null || selectedLabelId != null;
    final activeFilterCount = (selectedPriority != null ? 1 : 0) + (selectedLabelId != null ? 1 : 0);

    // Column counts for jump strip
    final counts = <TaskStatus, int>{
      for (final s in TaskStatus.values)
        s: filteredTasks.where((t) => t.status == s).length,
    };

    return Scaffold(
      floatingActionButton: isCompactScreen
          ? FloatingActionButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => CreateTaskDialog(projectId: widget.projectId),
                );
              },
              backgroundColor: accentColor,
              foregroundColor: accentColor.computeLuminance() > 0.5 ? Colors.black : Colors.white,
              elevation: 4,
              child: const Icon(Icons.add_rounded, size: 24),
            )
          : null,
      extendBody: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 8,
        leadingWidth: 52,
        // Fluid Frosted Liquid Glass Bar Background
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? [
                          const Color(0xFF141722).withValues(alpha: 0.82),
                          const Color(0xFF0C0E14).withValues(alpha: 0.60),
                        ]
                      : [
                          Colors.white.withValues(alpha: 0.90),
                          Colors.white.withValues(alpha: 0.70),
                        ],
                ),
                border: Border(
                  bottom: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.10)
                        : Colors.black.withValues(alpha: 0.08),
                    width: 1.0,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Liquid Glass Back Button
        leading: Padding(
          padding: const EdgeInsets.only(left: 14),
          child: Center(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                if (_isSearching) {
                  setState(() => _isSearching = false);
                  _searchController.clear();
                  ref.read(taskSearchQueryProvider.notifier).setQuery('');
                } else {
                  context.go('/projects');
                }
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            Colors.white.withValues(alpha: 0.12),
                            Colors.white.withValues(alpha: 0.03),
                          ]
                        : [
                            Colors.white.withValues(alpha: 0.90),
                            Colors.white.withValues(alpha: 0.50),
                          ],
                  ),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.18)
                        : Colors.white.withValues(alpha: 0.85),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.30)
                          : const Color(0xFFA0ADC0).withValues(alpha: 0.20),
                      offset: const Offset(0, 2),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.arrow_back_rounded,
                  size: 18,
                  color: isDark ? Colors.white : const Color(0xFF09090B),
                ),
              ),
            ),
          ),
        ),
        // Title or Search Bar Capsule
        title: _isSearching
            ? Container(
                height: 38,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.05),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.15)
                        : Colors.black.withValues(alpha: 0.12),
                    width: 1.0,
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: isDark ? Colors.white : const Color(0xFF09090B),
                  ),
                  onChanged: (v) => ref.read(taskSearchQueryProvider.notifier).setQuery(v),
                  decoration: InputDecoration(
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      size: 18,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                    prefixIconConstraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                    hintText: 'Search tasks...',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 16),
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            padding: EdgeInsets.zero,
                            onPressed: () {
                              _searchController.clear();
                              ref.read(taskSearchQueryProvider.notifier).setQuery('');
                            },
                          )
                        : null,
                  ),
                ),
              )
            : InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => context.go('/projects'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                              Colors.white.withValues(alpha: 0.13),
                              Colors.white.withValues(alpha: 0.03),
                            ]
                          : [
                              Colors.white.withValues(alpha: 0.90),
                              Colors.white.withValues(alpha: 0.50),
                            ],
                    ),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.18)
                          : Colors.white.withValues(alpha: 0.85),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withValues(alpha: 0.35)
                            : const Color(0xFFA0ADC0).withValues(alpha: 0.25),
                        offset: const Offset(0, 2),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: accentColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withValues(alpha: 0.6),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          projectName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF09090B),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: isDark ? 0.22 : 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: accentColor.withValues(alpha: 0.3),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: accentColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'Live',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: accentColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        // Liquid Glass Actions Capsule
        actions: _isSearching
            ? [
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () {
                    setState(() => _isSearching = false);
                    _searchController.clear();
                    ref.read(taskSearchQueryProvider.notifier).setQuery('');
                  },
                ),
                const SizedBox(width: 10),
              ]
            : [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                              Colors.white.withValues(alpha: 0.12),
                              Colors.white.withValues(alpha: 0.03),
                            ]
                          : [
                              Colors.white.withValues(alpha: 0.90),
                              Colors.white.withValues(alpha: 0.50),
                            ],
                    ),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.18)
                          : Colors.white.withValues(alpha: 0.85),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withValues(alpha: 0.35)
                            : const Color(0xFFA0ADC0).withValues(alpha: 0.25),
                        offset: const Offset(0, 2),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SyncStatusBadge(compact: true),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.search_rounded, size: 19),
                        tooltip: 'Search tasks',
                        onPressed: () => setState(() => _isSearching = true),
                      ),
                      PopupMenuButton<String>(
                        constraints: const BoxConstraints(minWidth: 260, maxWidth: 290),
                        padding: EdgeInsets.zero,
                        offset: const Offset(0, 46),
                        elevation: 16,
                        shadowColor: Colors.black.withValues(alpha: isDark ? 0.80 : 0.25),
                        surfaceTintColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                          side: BorderSide(
                            color: isDark
                                ? const Color(0xFF282C3A)
                                : const Color(0xFFCBD5E1),
                            width: 1.2,
                          ),
                        ),
                        color: isDark ? const Color(0xFF161822) : const Color(0xFFEFF3F8),
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark ? const Color(0xFF1C1E28) : const Color(0xFFEFF2F7),
                            border: Border.all(
                              color: isDark ? const Color(0xFF2B2F40) : const Color(0xFFCBD5E1),
                              width: 0.9,
                            ),
                            boxShadow: isDark
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.70),
                                      offset: const Offset(1.5, 2),
                                      blurRadius: 3,
                                    ),
                                  ]
                                : [
                                    BoxShadow(
                                      color: const Color(0xFFA8B4C7).withValues(alpha: 0.45),
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
                          child: Icon(
                            Icons.more_vert_rounded,
                            size: 16,
                            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                          ),
                        ),
                        onSelected: (val) {
                          if (val == 'copilot') {
                            AiCopilotSheet.show(
                              context,
                              projectId: widget.projectId,
                              projectName: projectName,
                            );
                          } else if (val == 'theme') {
                            ref.read(themeModeProvider.notifier).toggleTheme();
                          } else if (val == 'analytics') {
                            AnalyticsDashboardSheet.show(context, widget.projectId, projectName);
                          } else if (val == 'members' && activeWs != null) {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => MemberListSheet(
                                workspaceId: activeWs.id,
                                workspaceName: activeWs.name,
                              ),
                            );
                          }
                        },
                        itemBuilder: (context) {
                          final iconColor = isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B);
                          return [
                            _buildNeumorphicMenuItem(
                              value: 'copilot',
                              icon: Icons.auto_awesome_rounded,
                              iconColor: iconColor,
                              title: 'SyncFlow Copilot',
                              subtitle: 'AI assistant & auto-summary',
                              isDark: isDark,
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: isDark ? const Color(0xFF222634) : const Color(0xFFE2E8F0),
                                  border: Border.all(
                                    color: isDark ? const Color(0xFF333A4D) : const Color(0xFFCBD5E1),
                                    width: 0.8,
                                  ),
                                  boxShadow: isDark
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.6),
                                            offset: const Offset(1, 1.5),
                                            blurRadius: 2,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Text(
                                  'AI',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                            ),
                            _buildNeumorphicGrooveDivider(isDark),
                            _buildNeumorphicMenuItem(
                              value: 'theme',
                              icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                              iconColor: iconColor,
                              title: isDark ? 'White Mode' : 'Dark Mode',
                              subtitle: isDark ? 'Switch to light appearance' : 'Switch to dark appearance',
                              isDark: isDark,
                              trailing: Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                            _buildNeumorphicMenuItem(
                              value: 'analytics',
                              icon: Icons.insights_rounded,
                              iconColor: iconColor,
                              title: 'Project Analytics',
                              subtitle: 'Burndown & sprint metrics',
                              isDark: isDark,
                              trailing: Icon(
                                Icons.chevron_right_rounded,
                                size: 16,
                                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                              ),
                            ),
                            if (activeWs != null)
                              _buildNeumorphicMenuItem(
                                value: 'members',
                                icon: Icons.group_rounded,
                                iconColor: iconColor,
                                title: 'Team Members',
                                subtitle: 'Collaborators & roles',
                                isDark: isDark,
                                trailing: Icon(
                                  Icons.chevron_right_rounded,
                                  size: 16,
                                  color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                ),
                              ),
                          ];
                        },
                      ),
                      const NotificationBellButton(),
                    ],
                  ),
                ),
                if (!isCompactScreen) ...[
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: PrimaryButton(
                      label: 'New Task',
                      icon: Icons.add_rounded,
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => CreateTaskDialog(projectId: widget.projectId),
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(width: 14),
              ],
      ),
      body: Column(
        children: [
          const OfflineBanner(),

          // Phase 1: 3D Liquid Glass Control Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF0D0F16).withValues(alpha: 0.70)
                  : Colors.white.withValues(alpha: 0.75),
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.06),
                  width: 0.8,
                ),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: (MediaQuery.sizeOf(context).width - 28).clamp(0.0, double.infinity),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // View Switcher (Board, List, Calendar)
                    const TaskViewModeToggle(),

                    const SizedBox(width: 10),

                    // 3D Liquid Glass Filter Button
                    ChromaticGlassPill(
                      label: hasActiveFilter ? 'Filter · $activeFilterCount' : 'Filter',
                      icon: Icons.filter_list_rounded,
                      isSelected: hasActiveFilter,
                      isCompact: false,
                      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7.5),
                      onTap: () => TaskFilterSheet.show(context, widget.projectId),
                      trailing: hasActiveFilter
                          ? InkWell(
                              onTap: () {
                                ref.read(taskPriorityFilterProvider.notifier).setFilter(null);
                                ref.read(taskLabelFilterProvider.notifier).setFilter(null);
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.20)
                                      : Colors.black.withValues(alpha: 0.12),
                                ),
                                child: const Center(
                                  child: Icon(Icons.close_rounded, size: 12, color: Colors.white),
                                ),
                              ),
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Phase 3: Column Jump Strip (Board Mode Only)
          if (viewMode == TaskViewMode.board)
            ColumnJumpStrip(
              counts: counts,
              activeIndex: _activeColumnIndex,
              onSelectColumn: (index) {
                _boardScrollController.animateTo(
                  index * 314.0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
            ),

          // Dynamic Multi-View Viewport (Board, List, Calendar)
          Expanded(
            child: tasksAsync.when(
              data: (_) {
                if (filteredTasks.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 48,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            hasActiveFilter || _searchController.text.isNotEmpty
                                ? 'No tasks match your filter'
                                : 'No tasks in this project yet',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF09090B),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            hasActiveFilter || _searchController.text.isNotEmpty
                                ? 'Try clearing your filters or search keywords to see all tasks.'
                                : 'Create your first task to start organizing your workflow.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                            ),
                          ),
                          if (hasActiveFilter || _searchController.text.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            OutlinedButton(
                              onPressed: () {
                                _searchController.clear();
                                ref.read(taskSearchQueryProvider.notifier).setQuery('');
                                ref.read(taskPriorityFilterProvider.notifier).setFilter(null);
                                ref.read(taskLabelFilterProvider.notifier).setFilter(null);
                              },
                              style: OutlinedButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text('Clear all filters'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }

                switch (viewMode) {
                  case TaskViewMode.board:
                    return ListView(
                      controller: _boardScrollController,
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                      physics: const BouncingScrollPhysics(),
                      children: TaskStatus.values.map((status) {
                        final columnTasks = filteredTasks.where((t) => t.status == status).toList();

                        return KanbanColumn(
                          status: status,
                          tasks: columnTasks,
                          projectId: widget.projectId,
                        );
                      }).toList(),
                    );
                  case TaskViewMode.list:
                    return TaskListView(
                      projectId: widget.projectId,
                      tasks: filteredTasks,
                    );
                  case TaskViewMode.calendar:
                    return TaskCalendarView(
                      projectId: widget.projectId,
                      tasks: filteredTasks,
                    );
                }
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error loading tasks: $e')),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 1),
    );
  }

  PopupMenuItem<String> _buildNeumorphicMenuItem({
    required String value,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isDark,
    Widget? trailing,
  }) {
    final primaryText = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedText = isDark ? const Color(0xFF8E99AF) : const Color(0xFF64748B);

    return PopupMenuItem<String>(
      value: value,
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.transparent,
        ),
        child: Row(
          children: [
            // Sculpted Neumorphic Icon Socket
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(11),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          const Color(0xFF222634),
                          const Color(0xFF161822),
                        ]
                      : [
                          const Color(0xFFFFFFFF),
                          const Color(0xFFE5EBF4),
                        ],
                ),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF2E3446)
                      : const Color(0xFFCBD5E1),
                  width: 1.0,
                ),
                boxShadow: isDark
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.85),
                          offset: const Offset(2, 2.5),
                          blurRadius: 4,
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: const Color(0xFFA5B2C5).withValues(alpha: 0.55),
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
              child: Center(
                child: Icon(
                  icon,
                  size: 18,
                  color: iconColor,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Title & Subtitle Stack
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: primaryText,
                      letterSpacing: -0.1,
                    ),
                  ),
                  const SizedBox(height: 1.5),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: mutedText,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing,
            ],
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildNeumorphicGrooveDivider(bool isDark) {
    return PopupMenuItem<String>(
      enabled: false,
      height: 14,
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Container(
          height: 1.2,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F1117) : const Color(0xFFD6DFEC),
            boxShadow: isDark
                ? [
                    const BoxShadow(
                      color: Color(0xFF282D3D),
                      offset: Offset(0, 1),
                      blurRadius: 0.5,
                    ),
                  ]
                : [
                    const BoxShadow(
                      color: Colors.white,
                      offset: Offset(0, 1),
                      blurRadius: 0.5,
                    ),
                  ],
          ),
        ),
      ),
    );
  }
}

