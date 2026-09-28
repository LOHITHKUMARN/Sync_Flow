import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../workspaces/presentation/workspace_providers.dart';
import '../../domain/task_model.dart';
import '../../domain/label_model.dart';
import '../task_providers.dart';
import '../label_providers.dart';

class TaskFilterSheet extends ConsumerWidget {
  final String projectId;

  const TaskFilterSheet({super.key, required this.projectId});

  static void show(BuildContext context, String projectId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TaskFilterSheet(projectId: projectId),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedPriority = ref.watch(taskPriorityFilterProvider);
    final selectedLabelId = ref.watch(taskLabelFilterProvider);
    final activeWs = ref.watch(activeWorkspaceProvider);

    final labelsAsync = activeWs != null
        ? ref.watch(workspaceLabelsProvider(activeWs.id))
        : const AsyncValue<List<TaskLabel>>.data([]);
    final availableLabels = labelsAsync.value ?? [];

    final hasActiveFilter = selectedPriority != null || selectedLabelId != null;
    final activeCount = (selectedPriority != null ? 1 : 0) + (selectedLabelId != null ? 1 : 0);

    final primaryText = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedText = isDark ? const Color(0xFF8E99AF) : const Color(0xFF64748B);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.75,
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141620) : const Color(0xFFEFF2F7),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF282C3A) : const Color(0xFFCBD5E1),
            width: 1.2,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.70 : 0.20),
            offset: const Offset(0, -6),
            blurRadius: 20,
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Drag Handle (Neumorphic Inset Well)
            Center(
              child: Container(
                width: 44,
                height: 5,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F1017) : const Color(0xFFD6DFEC),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: isDark
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.90),
                            offset: const Offset(0, 1),
                            blurRadius: 1.5,
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Container(
                    width: 28,
                    height: 3,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2E3344) : const Color(0xFFA0ADC0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),

            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Filter Tasks',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: primaryText,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (hasActiveFilter) ...[
                      const SizedBox(width: 10),
                      // Neumorphic Inset Well Counter
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF10121A) : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? const Color(0xFF282D3D) : const Color(0xFFCBD5E1),
                            width: 0.9,
                          ),
                          boxShadow: isDark
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.80),
                                    offset: const Offset(1, 1.5),
                                    blurRadius: 2.5,
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 5.5,
                              height: 5.5,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF38BDF8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFF38BDF8),
                                    blurRadius: 4,
                                    spreadRadius: 0.5,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 5.5),
                            Text(
                              '$activeCount active',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                if (hasActiveFilter)
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        ref.read(taskPriorityFilterProvider.notifier).setFilter(null);
                        ref.read(taskLabelFilterProvider.notifier).setFilter(null);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Text(
                          'Reset all',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFF87171),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // Carved Groove Divider
            Container(
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
            const SizedBox(height: 16),

            // Scrollable Content
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Priority Section
                    Text(
                      'PRIORITY',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: mutedText,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 9,
                      children: [
                        _NeumorphicChip(
                          label: 'All Priorities',
                          isSelected: selectedPriority == null,
                          isDark: isDark,
                          accentColor: const Color(0xFF38BDF8),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            ref.read(taskPriorityFilterProvider.notifier).setFilter(null);
                          },
                        ),
                        ...TaskPriority.values.map((p) {
                          final isSelected = selectedPriority == p;
                          final (label, pColor, pIcon) = _getPriorityConfig(p);

                          return _NeumorphicChip(
                            label: label,
                            icon: pIcon,
                            isSelected: isSelected,
                            isDark: isDark,
                            accentColor: pColor,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              ref
                                  .read(taskPriorityFilterProvider.notifier)
                                  .setFilter(isSelected ? null : p);
                            },
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 22),

                    // Labels Section
                    if (availableLabels.isNotEmpty) ...[
                      Text(
                        'LABELS',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: mutedText,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 9,
                        children: availableLabels.map((l) {
                          final isSelected = selectedLabelId == l.id;
                          Color labelColor = const Color(0xFF38BDF8);
                          try {
                            final hex = l.colorHex.replaceAll('#', '');
                            labelColor = Color(int.parse('0xFF$hex'));
                          } catch (_) {}

                          return _NeumorphicChip(
                            label: l.name,
                            isSelected: isSelected,
                            isDark: isDark,
                            accentColor: labelColor,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              ref
                                  .read(taskLabelFilterProvider.notifier)
                                  .setFilter(isSelected ? null : l.id);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Sculpted 3D Neumorphic "Apply Filters" Action Button
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  HapticFeedback.mediumImpact();
                  Navigator.of(context).pop();
                },
                child: Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                              const Color(0xFF282D3D),
                              const Color(0xFF191B26),
                            ]
                          : [
                              Colors.white,
                              const Color(0xFFE2E8F0),
                            ],
                    ),
                    border: Border.all(
                      color: isDark ? const Color(0xFF384055) : const Color(0xFFCBD5E1),
                      width: 1.1,
                    ),
                    boxShadow: isDark
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.85),
                              offset: const Offset(3, 4.5),
                              blurRadius: 9,
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
                              color: const Color(0xFFA5B2C5).withValues(alpha: 0.50),
                              offset: const Offset(3, 4.5),
                              blurRadius: 8,
                              spreadRadius: -1,
                            ),
                            const BoxShadow(
                              color: Colors.white,
                              offset: Offset(-2, -2),
                              blurRadius: 6,
                            ),
                          ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_rounded,
                        size: 18,
                        color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF0F172A),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Apply Filters',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  (String, Color, IconData) _getPriorityConfig(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return ('Low', const Color(0xFF10B981), Icons.arrow_downward_rounded);
      case TaskPriority.medium:
        return ('Medium', const Color(0xFFF59E0B), Icons.remove_rounded);
      case TaskPriority.high:
        return ('High', const Color(0xFFEA580C), Icons.arrow_upward_rounded);
      case TaskPriority.urgent:
        return ('Urgent', const Color(0xFFEF4444), Icons.priority_high_rounded);
    }
  }
}

/// Tactile Neumorphic Filter Chip with Embossed Unselected & Sunken Crater Selected states
class _NeumorphicChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isDark;
  final Color accentColor;
  final IconData? icon;
  final VoidCallback onTap;

  const _NeumorphicChip({
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.accentColor,
    this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7.5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            gradient: isSelected
                ? null
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            const Color(0xFF222634),
                            const Color(0xFF161822),
                          ]
                        : [
                            Colors.white,
                            const Color(0xFFE5EBF4),
                          ],
                  ),
            color: isSelected
                ? (isDark ? const Color(0xFF10121A) : const Color(0xFFDEE5F0))
                : null,
            border: Border.all(
              color: isSelected
                  ? accentColor
                  : (isDark ? const Color(0xFF2A2E3E) : const Color(0xFFD6DEE9)),
              width: isSelected ? 1.2 : 0.9,
            ),
            boxShadow: isSelected
                ? (isDark
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.90),
                          offset: const Offset(1.5, 2),
                          blurRadius: 3,
                        ),
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.22),
                          blurRadius: 6,
                          spreadRadius: 0.5,
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: const Color(0xFF9FAEC3).withValues(alpha: 0.60),
                          offset: const Offset(1.5, 2),
                          blurRadius: 3,
                        ),
                      ])
                : (isDark
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.75),
                          offset: const Offset(2, 2.5),
                          blurRadius: 4,
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: const Color(0xFFA5B2C5).withValues(alpha: 0.45),
                          offset: const Offset(2, 2.5),
                          blurRadius: 4,
                        ),
                        const BoxShadow(
                          color: Colors.white,
                          offset: Offset(-1.5, -1.5),
                          blurRadius: 3,
                        ),
                      ]),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 13,
                  color: isSelected
                      ? accentColor
                      : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B)),
                ),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected
                      ? accentColor
                      : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
