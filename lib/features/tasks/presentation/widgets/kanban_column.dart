import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/liquid_glass_box.dart';
import '../../domain/task_model.dart';
import '../task_providers.dart';
import 'create_task_dialog.dart';
import 'task_card.dart';

/// Hyper-realistic 3D Liquid Crystal Glass Kanban Column directly matching the reference
/// visionOS liquid glass capsule: double chrome bevel rim, diagonal curved glare sheen,
/// sparkle lens-flare glints, and smoked obsidian crystal bodies.
class KanbanColumn extends ConsumerWidget {
  final TaskStatus status;
  final List<TaskItem> tasks;
  final String projectId;

  const KanbanColumn({
    super.key,
    required this.status,
    required this.tasks,
    required this.projectId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = _getStatusColor(status);

    return DragTarget<TaskItem>(
      onWillAcceptWithDetails: (details) => details.data.status != status,
      onAcceptWithDetails: (details) {
        HapticFeedback.mediumImpact();
        ref.read(tasksNotifierProvider(projectId).notifier).moveTaskStatus(
              taskId: details.data.id,
              newStatus: status,
            );
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;

        return LiquidGlassBox(
          width: 300,
          borderRadius: 24,
          margin: const EdgeInsets.only(right: 14),
          padding: EdgeInsets.zero,
          showSparkles: false,
          showDiagonalSheen: false,
          tintColor: isHovered ? statusColor : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Frosted Glass Column Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        // Glowing Status Indicator Dot
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: statusColor.withValues(alpha: 0.80),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 9),
                        Text(
                          status.label,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            letterSpacing: 0.1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Sleek Frosted Glass Count Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: isDark ? 0.16 : 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: statusColor.withValues(alpha: isDark ? 0.38 : 0.30),
                              width: 0.85,
                            ),
                          ),
                          child: Text(
                            '${tasks.length}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Frosted Glass Squircle Add Button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          showDialog(
                            context: context,
                            builder: (_) => CreateTaskDialog(
                              projectId: projectId,
                              initialStatus: status,
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.14)
                                  : Colors.black.withValues(alpha: 0.08),
                              width: 0.9,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.04),
                                blurRadius: 4,
                                offset: const Offset(0, 1.5),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.add_rounded,
                            size: 18,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Crystalline Glass Divider
              Divider(
                height: 1,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.10)
                    : Colors.black.withValues(alpha: 0.06),
              ),

              // Task Card List / Liquid Glass Empty placeholder
              Expanded(
                child: tasks.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: _buildLiquidGlassEmptyBox(context, isDark, statusColor),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          return TaskCard(task: tasks[index]);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 3D Liquid Crystal Stadium Capsule Empty State Box directly matching the reference image
  Widget _buildLiquidGlassEmptyBox(
    BuildContext context,
    bool isDark,
    Color statusColor,
  ) {
    return LiquidGlassBox(
      borderRadius: 28,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      showSparkles: false,
      showDiagonalSheen: false,
      onTap: () {
        HapticFeedback.lightImpact();
        showDialog(
          context: context,
          builder: (_) => CreateTaskDialog(
            projectId: projectId,
            initialStatus: status,
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Circular Glass Socket for Add Icon
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        Colors.white.withValues(alpha: 0.20),
                        Colors.white.withValues(alpha: 0.04),
                      ]
                    : [
                        Colors.white,
                        Colors.white.withValues(alpha: 0.6),
                      ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: isDark ? 0.12 : 0.8),
                  blurRadius: 6,
                  offset: const Offset(0, -1),
                ),
              ],
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.35)
                    : Colors.white,
                width: 1.3,
              ),
            ),
            child: Icon(
              Icons.add_rounded,
              size: 24,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'No tasks here',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap + or drop tasks here',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(TaskStatus s) {
    switch (s) {
      case TaskStatus.todo:
        return const Color(0xFF94A3B8); // Slate
      case TaskStatus.inProgress:
        return const Color(0xFF60A5FA); // Electric Blue
      case TaskStatus.inReview:
        return const Color(0xFFA855F7); // Purple
      case TaskStatus.done:
        return const Color(0xFF34D399); // Emerald Green
    }
  }
}
