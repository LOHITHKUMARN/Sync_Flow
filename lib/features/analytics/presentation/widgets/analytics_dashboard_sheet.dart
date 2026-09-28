import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../tasks/domain/task_model.dart';
import '../../domain/project_analytics.dart';
import '../analytics_providers.dart';

class AnalyticsDashboardSheet extends ConsumerWidget {
  final String projectId;
  final String projectName;

  const AnalyticsDashboardSheet({
    super.key,
    required this.projectId,
    required this.projectName,
  });

  static Future<void> show(BuildContext context, String projectId, String projectName) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => AnalyticsDashboardSheet(
        projectId: projectId,
        projectName: projectName,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analytics = ref.watch(projectAnalyticsProvider(projectId));

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1),
          left: BorderSide(color: AppColors.border, width: 1),
          right: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.insights_rounded,
                        color: AppColors.primaryLight,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Project Analytics',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          projectName,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textMuted, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const Divider(color: AppColors.border, height: 1),

          // Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // 1. KPI Summary Cards
                _buildKpiGrid(analytics),

                const SizedBox(height: 24),

                // 2. Status Distribution Section
                _buildSectionHeader('STATUS DISTRIBUTION', Icons.pie_chart_outline_rounded),
                const SizedBox(height: 12),
                _buildStatusDistribution(analytics),

                const SizedBox(height: 24),

                // 3. Priority Breakdown
                _buildSectionHeader('PRIORITY BREAKDOWN', Icons.flag_outlined),
                const SizedBox(height: 12),
                _buildPriorityBreakdown(analytics),

                const SizedBox(height: 24),

                // 4. Team Workload Leaderboard
                _buildSectionHeader('TEAM WORKLOAD LEADERBOARD', Icons.people_outline_rounded),
                const SizedBox(height: 12),
                _buildWorkloadLeaderboard(analytics),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.primaryLight),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  Widget _buildKpiGrid(ProjectAnalytics a) {
    final completionPercent = (a.completionRate * 100).round();

    return Row(
      children: [
        Expanded(
          child: _buildKpiCard(
            title: 'Total Tasks',
            value: '${a.totalTasks}',
            subtitle: '${a.completedTasks} completed',
            color: AppColors.primary,
            icon: Icons.checklist_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildKpiCard(
            title: 'Completion',
            value: '$completionPercent%',
            subtitle: '${a.totalTasks - a.completedTasks} remaining',
            color: AppColors.statusDone,
            icon: Icons.donut_large_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildKpiCard(
            title: 'Overdue',
            value: '${a.overdueTasks}',
            subtitle: a.overdueTasks > 0 ? 'Action needed' : 'All on track',
            color: a.overdueTasks > 0 ? AppColors.error : AppColors.todo,
            icon: Icons.alarm_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w500),
              ),
              Icon(icon, size: 14, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDistribution(ProjectAnalytics a) {
    if (a.totalTasks == 0) {
      return _buildEmptyNote('No tasks to analyze.');
    }

    final total = a.totalTasks;
    final todoFlex = a.statusCounts[TaskStatus.todo] ?? 0;
    final inProgressFlex = a.statusCounts[TaskStatus.inProgress] ?? 0;
    final inReviewFlex = a.statusCounts[TaskStatus.inReview] ?? 0;
    final doneFlex = a.statusCounts[TaskStatus.done] ?? 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Segmented Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  if (todoFlex > 0)
                    Expanded(
                      flex: todoFlex,
                      child: Container(color: AppColors.todo),
                    ),
                  if (inProgressFlex > 0)
                    Expanded(
                      flex: inProgressFlex,
                      child: Container(color: AppColors.inProgress),
                    ),
                  if (inReviewFlex > 0)
                    Expanded(
                      flex: inReviewFlex,
                      child: Container(color: AppColors.inReview),
                    ),
                  if (doneFlex > 0)
                    Expanded(
                      flex: doneFlex,
                      child: Container(color: AppColors.done),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Legend
          Wrap(
            spacing: 16,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildLegendItem('Todo', todoFlex, total, AppColors.todo),
              _buildLegendItem('Progress', inProgressFlex, total, AppColors.inProgress),
              _buildLegendItem('Review', inReviewFlex, total, AppColors.inReview),
              _buildLegendItem('Done', doneFlex, total, AppColors.done),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, int count, int total, Color color) {
    final pct = total == 0 ? 0 : ((count / total) * 100).round();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          '$label: $count ($pct%)',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPriorityBreakdown(ProjectAnalytics a) {
    if (a.totalTasks == 0) {
      return _buildEmptyNote('No tasks to analyze.');
    }

    final total = a.totalTasks;
    final urgent = a.priorityCounts[TaskPriority.urgent] ?? 0;
    final high = a.priorityCounts[TaskPriority.high] ?? 0;
    final med = a.priorityCounts[TaskPriority.medium] ?? 0;
    final low = a.priorityCounts[TaskPriority.low] ?? 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _buildPriorityRow('Urgent', urgent, total, AppColors.priorityUrgent),
          const SizedBox(height: 10),
          _buildPriorityRow('High', high, total, AppColors.priorityHigh),
          const SizedBox(height: 10),
          _buildPriorityRow('Medium', med, total, AppColors.priorityMedium),
          const SizedBox(height: 10),
          _buildPriorityRow('Low', low, total, AppColors.priorityLow),
        ],
      ),
    );
  }

  Widget _buildPriorityRow(String label, int count, int total, Color color) {
    final ratio = total == 0 ? 0.0 : count / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
            Text('$count tasks (${(ratio * 100).round()}%)', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            backgroundColor: AppColors.surface,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildWorkloadLeaderboard(ProjectAnalytics a) {
    if (a.memberWorkloads.isEmpty) {
      return _buildEmptyNote('No assignees with tasks in this project.');
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: a.memberWorkloads.length,
        separatorBuilder: (_, __) => const Divider(color: AppColors.border, height: 1),
        itemBuilder: (context, index) {
          final m = a.memberWorkloads[index];
          final completionPct = (m.completionRate * 100).round();

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                // Rank
                Text(
                  '#${index + 1}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 10),

                // Avatar
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.primary,
                  backgroundImage: m.avatarUrl != null ? NetworkImage(m.avatarUrl!) : null,
                  child: m.avatarUrl == null
                      ? Text(m.name[0].toUpperCase(), style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold))
                      : null,
                ),
                const SizedBox(width: 10),

                // Name & progress bar
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            m.name,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            '${m.completed}/${m.totalAssigned} done ($completionPct%)',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: m.completionRate,
                          backgroundColor: AppColors.surface,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.statusDone),
                          minHeight: 4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyNote(String msg) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Center(
        child: Text(msg, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
      ),
    );
  }
}
