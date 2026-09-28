import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../domain/task_model.dart';
import 'create_task_dialog.dart';
import 'task_detail_sheet.dart';

/// Ultra-sleek Neumorphic Dark Soft-UI Calendar View matching the reference design:
/// - Embossed circular navigation buttons (<, >)
/// - Embossed pill capsules with dropdown carets for Month & Year selection
/// - Main floating soft-sculpted plate
/// - Uppercase weekday headers (SUN - SAT)
/// - 2-digit dates with leading zeros (01, 02, ..., 31)
/// - Concave inset crater for the active/selected day
/// - Glowing circular event/task status dots
/// - Dedicated interactive agenda view for selected day
class TaskCalendarView extends ConsumerStatefulWidget {
  final String projectId;
  final List<TaskItem> tasks;

  const TaskCalendarView({
    super.key,
    required this.projectId,
    required this.tasks,
  });

  @override
  ConsumerState<TaskCalendarView> createState() => _TaskCalendarViewState();
}

class _TaskCalendarViewState extends ConsumerState<TaskCalendarView> {
  late DateTime _focusedMonth;
  late DateTime _selectedDate;

  final List<String> _months = const [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month, 1);
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  void _previousMonth() {
    HapticFeedback.lightImpact();
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    HapticFeedback.lightImpact();
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
    });
  }

  void _selectMonth(int monthIndex) {
    HapticFeedback.selectionClick();
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, monthIndex + 1, 1);
    });
  }

  void _selectYear(int year) {
    HapticFeedback.selectionClick();
    setState(() {
      _focusedMonth = DateTime(year, _focusedMonth.month, 1);
    });
  }

  void _jumpToToday() {
    HapticFeedback.mediumImpact();
    final now = DateTime.now();
    setState(() {
      _focusedMonth = DateTime(now.year, now.month, 1);
      _selectedDate = DateTime(now.year, now.month, now.day);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Palette tailored for true neumorphic dark aesthetic matching reference
    final bgColor = isDark ? const Color(0xFF141518) : const Color(0xFFEDF1F7);
    final plateColor = isDark ? const Color(0xFF1C1D21) : const Color(0xFFF3F6FA);
    final textMuted = isDark ? const Color(0xFF71747E) : const Color(0xFF8C93A4);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);

    // Group tasks by yyyy-MM-dd
    final Map<String, List<TaskItem>> tasksByDate = {};
    for (final task in widget.tasks) {
      if (task.dueDate != null) {
        final key = DateFormat('yyyy-MM-dd').format(task.dueDate!);
        tasksByDate.putIfAbsent(key, () => []).add(task);
      }
    }

    final selectedKey = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final selectedDayTasks = tasksByDate[selectedKey] ?? [];

    return Container(
      color: bgColor,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        physics: const BouncingScrollPhysics(),
        children: [
          // Top Neumorphic Controls Row (<, >, [Month v], [Year v])
          _buildControlsRow(isDark, textPrimary, textMuted),

          const SizedBox(height: 16),

          // Main Neumorphic Calendar Plate
          _buildNeumorphicCalendarPlate(
            context: context,
            isDark: isDark,
            plateColor: plateColor,
            textPrimary: textPrimary,
            textMuted: textMuted,
            tasksByDate: tasksByDate,
          ),

          const SizedBox(height: 22),

          // Agenda Header & Task List for the Selected Day
          _buildAgendaSection(
            context: context,
            isDark: isDark,
            plateColor: plateColor,
            textPrimary: textPrimary,
            textMuted: textMuted,
            selectedDayTasks: selectedDayTasks,
          ),
        ],
      ),
    );
  }

  /// Neumorphic controls matching reference: <, >, [Month v], [Year v]
  Widget _buildControlsRow(bool isDark, Color textPrimary, Color textMuted) {
    return Row(
      children: [
        // Circular embossed < button
        _buildCircularNeumorphicButton(
          icon: Icons.chevron_left_rounded,
          isDark: isDark,
          textPrimary: textPrimary,
          onTap: _previousMonth,
        ),
        const SizedBox(width: 10),

        // Circular embossed > button
        _buildCircularNeumorphicButton(
          icon: Icons.chevron_right_rounded,
          isDark: isDark,
          textPrimary: textPrimary,
          onTap: _nextMonth,
        ),

        const SizedBox(width: 12),

        // Pill Capsule for Month Dropdown
        Expanded(
          flex: 5,
          child: _buildPillDropdownButton(
            title: DateFormat('MMMM').format(_focusedMonth),
            isDark: isDark,
            textPrimary: textPrimary,
            onTap: () => _showMonthPicker(context, isDark),
            onLongPress: _jumpToToday,
          ),
        ),

        const SizedBox(width: 10),

        // Pill Capsule for Year Dropdown
        Expanded(
          flex: 4,
          child: _buildPillDropdownButton(
            title: '${_focusedMonth.year}',
            isDark: isDark,
            textPrimary: textPrimary,
            onTap: () => _showYearPicker(context, isDark),
            onLongPress: _jumpToToday,
          ),
        ),
      ],
    );
  }

  /// Circular embossed soft-UI button
  Widget _buildCircularNeumorphicButton({
    required IconData icon,
    required bool isDark,
    required Color textPrimary,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? const Color(0xFF1B1C20) : const Color(0xFFF1F4F9),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.white,
              width: 0.8,
            ),
            boxShadow: isDark
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.75),
                      offset: const Offset(3, 4),
                      blurRadius: 7,
                    ),
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.05),
                      offset: const Offset(-2, -2),
                      blurRadius: 5,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: const Color(0xFFA8B4C7).withValues(alpha: 0.50),
                      offset: const Offset(3, 4),
                      blurRadius: 6,
                    ),
                    const BoxShadow(
                      color: Colors.white,
                      offset: Offset(-2, -2),
                      blurRadius: 5,
                    ),
                  ],
          ),
          child: Center(
            child: Icon(icon, size: 20, color: textPrimary),
          ),
        ),
      ),
    );
  }

  /// Neumorphic pill capsule dropdown
  Widget _buildPillDropdownButton({
    required String title,
    required bool isDark,
    required Color textPrimary,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: isDark ? const Color(0xFF1B1C20) : const Color(0xFFF1F4F9),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.white,
              width: 0.8,
            ),
            boxShadow: isDark
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.70),
                      offset: const Offset(3, 4),
                      blurRadius: 7,
                    ),
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.05),
                      offset: const Offset(-2, -2),
                      blurRadius: 5,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: const Color(0xFFA8B4C7).withValues(alpha: 0.45),
                      offset: const Offset(3, 4),
                      blurRadius: 6,
                    ),
                    const BoxShadow(
                      color: Colors.white,
                      offset: Offset(-2, -2),
                      blurRadius: 5,
                    ),
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    color: textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: textPrimary.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Main Neumorphic Plate holding Weekdays & 42 Day Cells
  Widget _buildNeumorphicCalendarPlate({
    required BuildContext context,
    required bool isDark,
    required Color plateColor,
    required Color textPrimary,
    required Color textMuted,
    required Map<String, List<TaskItem>> tasksByDate,
  }) {
    // Days of the week starting from Sunday as in reference image
    final weekDays = const ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Calculate dates for 6 full rows (42 cells) starting on Sunday
    final firstDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final int firstWeekdayOffset = firstDayOfMonth.weekday % 7; 
    final startDate = firstDayOfMonth.subtract(Duration(days: firstWeekdayOffset));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      decoration: BoxDecoration(
        color: plateColor,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.90),
          width: 0.9,
        ),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.85),
                  offset: const Offset(6, 8),
                  blurRadius: 18,
                  spreadRadius: -2,
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.05),
                  offset: const Offset(-3, -3),
                  blurRadius: 12,
                ),
              ]
            : [
                BoxShadow(
                  color: const Color(0xFFA5B2C5).withValues(alpha: 0.50),
                  offset: const Offset(6, 8),
                  blurRadius: 16,
                  spreadRadius: -2,
                ),
                const BoxShadow(
                  color: Colors.white,
                  offset: Offset(-4, -4),
                  blurRadius: 12,
                ),
              ],
      ),
      child: Column(
        children: [
          // Weekday header row: SUN  MON  TUE  WED  THU  FRI  SAT
          Row(
            children: weekDays.map((day) {
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: GoogleFonts.plusJakartaSans(
                      color: textMuted,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 14),

          // 6 Rows x 7 Columns Day Grid
          Column(
            children: List.generate(6, (rowIndex) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3.5),
                child: Row(
                  children: List.generate(7, (colIndex) {
                    final cellIndex = rowIndex * 7 + colIndex;
                    final cellDate = startDate.add(Duration(days: cellIndex));
                    final isCurrentMonth = cellDate.month == _focusedMonth.month;
                    final isSelected = cellDate.year == _selectedDate.year &&
                        cellDate.month == _selectedDate.month &&
                        cellDate.day == _selectedDate.day;
                    final isToday = cellDate.isAtSameMomentAs(today);

                    final dateKey = DateFormat('yyyy-MM-dd').format(cellDate);
                    final dayTasks = tasksByDate[dateKey] ?? [];

                    return Expanded(
                      child: _buildDayCell(
                        cellDate: cellDate,
                        dayNumberStr: cellDate.day.toString().padLeft(2, '0'),
                        isCurrentMonth: isCurrentMonth,
                        isSelected: isSelected,
                        isToday: isToday,
                        tasks: dayTasks,
                        isDark: isDark,
                        textPrimary: textPrimary,
                        textMuted: textMuted,
                      ),
                    );
                  }),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  /// Individual Day Cell: Inset well crater if selected, 2-digit number, colored event dots
  Widget _buildDayCell({
    required DateTime cellDate,
    required String dayNumberStr,
    required bool isCurrentMonth,
    required bool isSelected,
    required bool isToday,
    required List<TaskItem> tasks,
    required bool isDark,
    required Color textPrimary,
    required Color textMuted,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedDate = cellDate;
          if (cellDate.month != _focusedMonth.month) {
            _focusedMonth = DateTime(cellDate.year, cellDate.month, 1);
          }
        });
      },
      child: Center(
        child: isSelected
            ? _buildSelectedConcaveCrater(
                dayNumberStr: dayNumberStr,
                isDark: isDark,
                tasks: tasks,
              )
            : Container(
                width: 38,
                height: 44,
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Date Number (e.g. 01, 14, 29)
                    Text(
                      dayNumberStr,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                        color: isCurrentMonth
                            ? (isToday
                                ? (isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB))
                                : textPrimary)
                            : (isDark ? const Color(0xFF383A42) : const Color(0xFFB5BAC6)),
                      ),
                    ),
                    const SizedBox(height: 3),
                    // Task indicator dots underneath
                    _buildTaskDots(tasks, isSelected: false),
                  ],
                ),
              ),
      ),
    );
  }

  /// Inset Neumorphic Concave Socket / Crater for Selected Date (matching `15` in reference)
  Widget _buildSelectedConcaveCrater({
    required String dayNumberStr,
    required bool isDark,
    required List<TaskItem> tasks,
  }) {
    return Container(
      width: 40,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? const Color(0xFF131417) : const Color(0xFFE2E7EE),
        border: Border.all(
          color: isDark ? const Color(0xFF0C0D0F) : const Color(0xFFCCD4E0),
          width: 1.1,
        ),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.90),
                  offset: const Offset(2.5, 3),
                  blurRadius: 5,
                  spreadRadius: 0.5,
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.08),
                  offset: const Offset(-1.5, -1.5),
                  blurRadius: 3,
                ),
              ]
            : [
                BoxShadow(
                  color: const Color(0xFF9FAEC3).withValues(alpha: 0.65),
                  offset: const Offset(2.5, 3),
                  blurRadius: 5,
                  spreadRadius: 0.5,
                ),
                const BoxShadow(
                  color: Colors.white,
                  offset: Offset(-1.5, -1.5),
                  blurRadius: 3,
                ),
              ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            dayNumberStr,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF090A0F),
            ),
          ),
          const SizedBox(height: 2.5),
          _buildTaskDots(tasks, isSelected: true),
        ],
      ),
    );
  }

  /// Small colored circular dots beneath date matching reference image
  Widget _buildTaskDots(List<TaskItem> tasks, {required bool isSelected}) {
    if (tasks.isEmpty) {
      return const SizedBox(height: 4.5);
    }

    return SizedBox(
      height: 4.5,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: tasks.take(2).map((t) {
          final color = _getTaskStatusDotColor(t.status);
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 1.2),
            width: 4.5,
            height: 4.5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.75),
                  blurRadius: 3,
                  spreadRadius: 0.5,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Colored dot mapping matching the reference:
  /// Amber/Yellow, Cyan, Purple/Pink, Mint Green
  Color _getTaskStatusDotColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return const Color(0xFFFBBF24); // Amber glow (like 01, 04, 23 in reference)
      case TaskStatus.inProgress:
        return const Color(0xFF38BDF8); // Electric cyan (like left dot on 15)
      case TaskStatus.inReview:
        return const Color(0xFFA855F7); // Purple/Magenta (like 13 in reference)
      case TaskStatus.done:
        return const Color(0xFF34D399); // Emerald/Mint green (like 18 in reference)
    }
  }

  /// Agenda section below the calendar for the selected date
  Widget _buildAgendaSection({
    required BuildContext context,
    required bool isDark,
    required Color plateColor,
    required Color textPrimary,
    required Color textMuted,
    required List<TaskItem> selectedDayTasks,
  }) {
    final formattedDate = DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Agenda Header with Date & Add Task Button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formattedDate,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  selectedDayTasks.isEmpty
                      ? 'No tasks scheduled'
                      : '${selectedDayTasks.length} task${selectedDayTasks.length == 1 ? "" : "s"} due',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: textMuted,
                  ),
                ),
              ],
            ),
            // Floating Neumorphic Add Task Button
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  showDialog(
                    context: context,
                    builder: (_) => CreateTaskDialog(
                      projectId: widget.projectId,
                      initialDueDate: _selectedDate,
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1F24) : const Color(0xFFF1F4F9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.10)
                          : Colors.white,
                      width: 0.8,
                    ),
                    boxShadow: isDark
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.70),
                              offset: const Offset(3, 4),
                              blurRadius: 6,
                            ),
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.05),
                              offset: const Offset(-2, -2),
                              blurRadius: 4,
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: const Color(0xFFA8B4C7).withValues(alpha: 0.45),
                              offset: const Offset(3, 4),
                              blurRadius: 6,
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
                      const Icon(Icons.add_rounded, size: 16, color: Color(0xFF38BDF8)),
                      const SizedBox(width: 4),
                      Text(
                        'New Task',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Task Cards or Empty State
        if (selectedDayTasks.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: plateColor.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.04),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.event_note_rounded,
                  size: 32,
                  color: textMuted.withValues(alpha: 0.6),
                ),
                const SizedBox(height: 8),
                Text(
                  'Clear day! No deadlines due on this date.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    color: textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          )
        else
          ...selectedDayTasks.map((task) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildAgendaTaskCard(
                context: context,
                task: task,
                isDark: isDark,
                plateColor: plateColor,
                textPrimary: textPrimary,
                textMuted: textMuted,
              ),
            );
          }),
      ],
    );
  }

  /// Neumorphic agenda task card
  Widget _buildAgendaTaskCard({
    required BuildContext context,
    required TaskItem task,
    required bool isDark,
    required Color plateColor,
    required Color textPrimary,
    required Color textMuted,
  }) {
    final statusColor = _getTaskStatusDotColor(task.status);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          TaskDetailSheet.show(context, task, widget.projectId);
        },
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1B1C21) : const Color(0xFFF6F8FC),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.07)
                  : Colors.white,
              width: 0.9,
            ),
            boxShadow: isDark
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.60),
                      offset: const Offset(3, 4),
                      blurRadius: 8,
                    ),
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.04),
                      offset: const Offset(-2, -2),
                      blurRadius: 6,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: const Color(0xFFA5B2C5).withValues(alpha: 0.40),
                      offset: const Offset(3, 4),
                      blurRadius: 8,
                    ),
                    const BoxShadow(
                      color: Colors.white,
                      offset: Offset(-3, -3),
                      blurRadius: 6,
                    ),
                  ],
          ),
          child: Row(
            children: [
              // Glowing status pill indicator
              Container(
                width: 4,
                height: 32,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withValues(alpha: 0.6),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          task.status.label.toUpperCase(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                            color: statusColor,
                          ),
                        ),
                        if (task.assigneeName != null) ...[
                          Text(
                            ' · ',
                            style: TextStyle(color: textMuted, fontSize: 11),
                          ),
                          Flexible(
                            child: Text(
                              task.assigneeName!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: textMuted,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: textMuted.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Month selector modal sheet
  void _showMonthPicker(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1B1C21) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Month',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      _jumpToToday();
                      Navigator.pop(context);
                    },
                    child: const Text('Today'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 2.2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: 12,
                itemBuilder: (ctx, index) {
                  final isCurrent = _focusedMonth.month == index + 1;
                  return InkWell(
                    onTap: () {
                      _selectMonth(index);
                      Navigator.pop(ctx);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? const Color(0xFF38BDF8).withValues(alpha: 0.20)
                            : (isDark ? const Color(0xFF24262E) : const Color(0xFFF1F4F9)),
                        borderRadius: BorderRadius.circular(12),
                        border: isCurrent
                            ? Border.all(color: const Color(0xFF38BDF8), width: 1.2)
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _months[index].substring(0, 3),
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: isCurrent
                              ? const Color(0xFF38BDF8)
                              : (isDark ? Colors.white70 : Colors.black87),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// Year selector modal sheet
  void _showYearPicker(BuildContext context, bool isDark) {
    final currentYear = DateTime.now().year;
    final years = List.generate(11, (i) => currentYear - 5 + i);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1B1C21) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Year',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      _jumpToToday();
                      Navigator.pop(context);
                    },
                    child: const Text('This Year'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 2.2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: years.length,
                itemBuilder: (ctx, index) {
                  final year = years[index];
                  final isCurrent = _focusedMonth.year == year;
                  return InkWell(
                    onTap: () {
                      _selectYear(year);
                      Navigator.pop(ctx);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? const Color(0xFF38BDF8).withValues(alpha: 0.20)
                            : (isDark ? const Color(0xFF24262E) : const Color(0xFFF1F4F9)),
                        borderRadius: BorderRadius.circular(12),
                        border: isCurrent
                            ? Border.all(color: const Color(0xFF38BDF8), width: 1.2)
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$year',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: isCurrent
                              ? const Color(0xFF38BDF8)
                              : (isDark ? Colors.white70 : Colors.black87),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
