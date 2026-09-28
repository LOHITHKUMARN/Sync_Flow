import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/chromatic_glass_pill.dart';
import '../../domain/task_view_mode.dart';
import '../task_providers.dart';

class TaskViewModeToggle extends ConsumerWidget {
  final bool isFullWidth;

  const TaskViewModeToggle({super.key, this.isFullWidth = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(taskViewModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final containerBg = isDark
        ? const Color(0xFF0F121A).withValues(alpha: 0.70)
        : Colors.white.withValues(alpha: 0.75);
    final containerBorder = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.08);

    final items = [
      _buildItem(
        context,
        ref,
        mode: TaskViewMode.board,
        icon: Icons.view_kanban_rounded,
        label: 'Board',
        isSelected: currentMode == TaskViewMode.board,
      ),
      _buildItem(
        context,
        ref,
        mode: TaskViewMode.list,
        icon: Icons.format_list_bulleted_rounded,
        label: 'List',
        isSelected: currentMode == TaskViewMode.list,
      ),
      _buildItem(
        context,
        ref,
        mode: TaskViewMode.calendar,
        icon: Icons.calendar_month_rounded,
        label: 'Calendar',
        isSelected: currentMode == TaskViewMode.calendar,
      ),
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: containerBg,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: containerBorder, width: 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
            children: isFullWidth
                ? items.map((item) => Expanded(child: item)).toList()
                : items,
          ),
        ),
      ),
    );
  }

  Widget _buildItem(
    BuildContext context,
    WidgetRef ref, {
    required TaskViewMode mode,
    required IconData icon,
    required String label,
    required bool isSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.0),
      child: ChromaticGlassPill(
        label: label,
        icon: icon,
        isSelected: isSelected,
        isCompact: false,
        isInsetIcon: isSelected,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 13 : 9,
          vertical: 7.5,
        ),
        onTap: () {
          ref.read(taskViewModeProvider.notifier).setMode(mode);
        },
      ),
    );
  }
}

