import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/task_model.dart';

class ColumnJumpStrip extends StatelessWidget {
  final Map<TaskStatus, int> counts;
  final int activeIndex;
  final ValueChanged<int> onSelectColumn;

  const ColumnJumpStrip({
    super.key,
    required this.counts,
    required this.activeIndex,
    required this.onSelectColumn,
  });

  static Color getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return const Color(0xFF71717A); // Graphite Slate (No white)
      case TaskStatus.inProgress:
        return const Color(0xFF3B82F6); // Electric Sky Blue
      case TaskStatus.inReview:
        return const Color(0xFFF59E0B); // Amber / Orange (No purple)
      case TaskStatus.done:
        return const Color(0xFF10B981); // Emerald Green
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statuses = TaskStatus.values;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 0.8,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        clipBehavior: Clip.none,
        child: Row(
          children: List.generate(statuses.length, (index) {
            final status = statuses[index];
            final count = counts[status] ?? 0;
            final isSelected = activeIndex == index;
            final color = getStatusColor(status);

            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: LiquidGlassStatusButton(
                status: status,
                count: count,
                isSelected: isSelected,
                color: color,
                onTap: () => onSelectColumn(index),
              ),
            );
          }),
        ),
      ),
    );
  }
}

/// Capsule pill button with dark OLED/charcoal surface, pure colored accents,
/// and completely free of any whitish shade or haze.
class LiquidGlassStatusButton extends StatefulWidget {
  final TaskStatus status;
  final int count;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const LiquidGlassStatusButton({
    super.key,
    required this.status,
    required this.count,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  State<LiquidGlassStatusButton> createState() => _LiquidGlassStatusButtonState();
}

class _LiquidGlassStatusButtonState extends State<LiquidGlassStatusButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = widget.color;
    final isSelected = widget.isSelected;

    return AnimatedScale(
      scale: _isPressed ? 0.95 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            // Pure dark surface with status color tint when selected - ZERO white shade
            color: isSelected
                ? (isDark
                    ? color.withValues(alpha: 0.18)
                    : color.withValues(alpha: 0.12))
                : (isDark ? const Color(0xFF141416) : const Color(0xFFF4F4F6)),
            border: Border.all(
              color: isSelected
                  ? color
                  : (isDark ? const Color(0xFF26262B) : const Color(0xFFE4E4E7)),
              width: isSelected ? 1.4 : 1.0,
            ),
            boxShadow: [
              // Clean ambient status glow only when selected
              if (isSelected)
                BoxShadow(
                  color: color.withValues(alpha: isDark ? 0.30 : 0.18),
                  blurRadius: 10,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
              // Soft deep dark shadow
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Status Indicator Dot
              Container(
                width: 7.5,
                height: 7.5,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: isSelected ? 0.85 : 0.4),
                      blurRadius: isSelected ? 6 : 2,
                      spreadRadius: isSelected ? 1 : 0,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 7),

              // Status Label
              Text(
                widget.status.label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected
                      ? (isDark ? Colors.white : const Color(0xFF09090B))
                      : (isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A)),
                  letterSpacing: -0.15,
                ),
              ),
              const SizedBox(width: 7),

              // Counter Badge (Dark pill, no white tint)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6.5, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: isDark ? 0.35 : 0.22)
                      : (isDark ? const Color(0xFF1C1C20) : const Color(0xFFE4E4E7)),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? color.withValues(alpha: 0.6)
                        : (isDark ? const Color(0xFF2E2E34) : Colors.transparent),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  '${widget.count}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? (isDark ? Colors.white : color)
                        : (isDark ? const Color(0xFF8E8E93) : const Color(0xFF52525B)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
