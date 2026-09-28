import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../time_tracking_providers.dart';
import '../../domain/time_entry_model.dart';
import '../../domain/task_model.dart';

class TaskTimeTrackingView extends ConsumerStatefulWidget {
  final TaskItem task;

  const TaskTimeTrackingView({
    super.key,
    required this.task,
  });

  @override
  ConsumerState<TaskTimeTrackingView> createState() => _TaskTimeTrackingViewState();
}

class _TaskTimeTrackingViewState extends ConsumerState<TaskTimeTrackingView> {
  final _manualHoursController = TextEditingController();
  final _manualMinutesController = TextEditingController();
  final _manualNoteController = TextEditingController();
  bool _isLoggingManual = false;

  @override
  void dispose() {
    _manualHoursController.dispose();
    _manualMinutesController.dispose();
    _manualNoteController.dispose();
    super.dispose();
  }

  void _showStopAndSaveDialog(ActiveTimerState timer) {
    final noteController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        title: const Row(
          children: [
            Icon(Icons.save_rounded, color: AppColors.primary, size: 20),
            SizedBox(width: 8),
            Text(
              'Save Tracked Time',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                  width: Theme.of(context).dividerTheme.thickness ?? 1.0,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined, color: AppColors.accent, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Recorded: ${timer.formattedTime}',
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: noteController,
              maxLines: 2,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Add an optional note or work summary...',
                hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(activeTimerProvider.notifier)
                  .stopAndSave(note: noteController.text.trim());
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Time entry saved successfully!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Save Entry'),
          ),
        ],
      ),
    );
  }

  void _submitManualEntry() async {
    final hours = int.tryParse(_manualHoursController.text.trim()) ?? 0;
    final minutes = int.tryParse(_manualMinutesController.text.trim()) ?? 0;
    final totalSeconds = (hours * 3600) + (minutes * 60);

    if (totalSeconds <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a duration greater than 0 minutes'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final note = _manualNoteController.text.trim();
    final now = DateTime.now();
    final startedAt = now.subtract(Duration(seconds: totalSeconds));

    setState(() => _isLoggingManual = false);
    _manualHoursController.clear();
    _manualMinutesController.clear();
    _manualNoteController.clear();

    await ref.read(taskTimeEntriesProvider(widget.task.id).notifier).logTime(
          durationSeconds: totalSeconds,
          startedAt: startedAt,
          endedAt: now,
          note: note.isNotEmpty ? note : null,
        );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Manual time logged successfully!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final timer = ref.watch(activeTimerProvider);
    final entriesAsync = ref.watch(taskTimeEntriesProvider(widget.task.id));
    final isTrackingThisTask = timer.taskId == widget.task.id;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Live Stopwatch Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isTrackingThisTask && timer.isRunning
                    ? [
                        AppColors.primary.withValues(alpha: 0.2),
                        AppColors.accent.withValues(alpha: 0.1),
                      ]
                    : [
                        AppColors.darkCard,
                        AppColors.surface,
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isTrackingThisTask && timer.isRunning
                    ? AppColors.primary.withValues(alpha: 0.6)
                    : AppColors.border,
              ),
              boxShadow: [
                if (isTrackingThisTask && timer.isRunning)
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isTrackingThisTask && timer.isRunning
                                ? AppColors.accent
                                : AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isTrackingThisTask
                              ? (timer.isRunning ? 'TRACKING LIVE' : 'TIMER PAUSED')
                              : 'STOPWATCH',
                          style: TextStyle(
                            color: isTrackingThisTask && timer.isRunning
                                ? AppColors.accent
                                : AppColors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                    if (isTrackingThisTask && timer.elapsedSeconds > 0)
                      TextButton.icon(
                        onPressed: () => ref.read(activeTimerProvider.notifier).resetTimer(),
                        icon: const Icon(Icons.refresh_rounded, size: 14, color: AppColors.textMuted),
                        label: const Text('Reset', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                        style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                // Digital Timer Display
                Text(
                  isTrackingThisTask ? timer.formattedTime : '00:00:00',
                  style: const TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3.0,
                    fontFamily: 'monospace',
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                // Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!isTrackingThisTask || !timer.isRunning)
                      ElevatedButton.icon(
                        onPressed: () {
                          if (isTrackingThisTask) {
                            ref.read(activeTimerProvider.notifier).resumeTimer();
                          } else {
                            ref.read(activeTimerProvider.notifier).startTimer(
                                  widget.task.id,
                                  widget.task.title,
                                );
                          }
                        },
                        icon: const Icon(Icons.play_arrow_rounded, size: 20),
                        label: Text(
                          isTrackingThisTask && timer.elapsedSeconds > 0 ? 'Resume' : 'Start Timer',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      )
                    else
                      ElevatedButton.icon(
                        onPressed: () => ref.read(activeTimerProvider.notifier).pauseTimer(),
                        icon: const Icon(Icons.pause_rounded, size: 20),
                        label: const Text('Pause', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.warning,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    if (isTrackingThisTask && timer.elapsedSeconds > 0) ...[
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () => _showStopAndSaveDialog(timer),
                        icon: const Icon(Icons.check_rounded, size: 18, color: AppColors.accent),
                        label: const Text('Save Log', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.accent),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 2. Manual Log Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Logged Time',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() => _isLoggingManual = !_isLoggingManual);
                },
                icon: Icon(
                  _isLoggingManual ? Icons.close_rounded : Icons.add_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
                label: Text(
                  _isLoggingManual ? 'Cancel' : 'Log Manually',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          // Manual Input Form
          if (_isLoggingManual) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                  width: Theme.of(context).dividerTheme.thickness ?? 1.0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Manual Time Entry',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _manualHoursController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                          decoration: InputDecoration(
                            labelText: 'Hours',
                            labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                            hintText: '0',
                            filled: true,
                            fillColor: AppColors.darkCard,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _manualMinutesController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                          decoration: InputDecoration(
                            labelText: 'Minutes',
                            labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                            hintText: '30',
                            filled: true,
                            fillColor: AppColors.darkCard,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _manualNoteController,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Work description or note...',
                      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                      filled: true,
                      fillColor: AppColors.darkCard,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: _submitManualEntry,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      ),
                      child: const Text('Add Entry', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // 3. Entries List & Total
          entriesAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (err, _) => Center(
              child: Text(
                'Failed to load entries: $err',
                style: const TextStyle(color: AppColors.error, fontSize: 12),
              ),
            ),
            data: (entries) {
              if (entries.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.darkCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                      width: Theme.of(context).dividerTheme.thickness ?? 1.0,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.history_toggle_off_rounded, size: 36, color: AppColors.textMuted.withValues(alpha: 0.6)),
                        const SizedBox(height: 8),
                        const Text(
                          'No time logged yet',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Use the stopwatch above or log hours manually',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final totalSeconds = entries.fold<int>(0, (sum, e) => sum + e.durationSeconds);
              final totalHours = totalSeconds ~/ 3600;
              final totalMinutes = (totalSeconds % 3600) ~/ 60;
              final formattedTotal = totalHours > 0 ? '${totalHours}h ${totalMinutes}m' : '${totalMinutes}m';

              return Column(
                children: [
                  // Total summary badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline,
                        width: Theme.of(context).dividerTheme.thickness ?? 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.timelapse_rounded, size: 16, color: AppColors.accent),
                            const SizedBox(width: 8),
                            Text(
                              'Total Logged: $formattedTotal',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${entries.length} ${entries.length == 1 ? 'entry' : 'entries'}',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Entries List
                  ...entries.map((entry) => _buildEntryTile(entry)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEntryTile(TimeEntry entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
          width: Theme.of(context).dividerTheme.thickness ?? 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.primary.withValues(alpha: 0.2),
            child: Text(
              entry.userName.isNotEmpty ? entry.userName[0].toUpperCase() : 'U',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.userName,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        entry.formattedDuration,
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                if (entry.note != null && entry.note!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    entry.note!,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  _formatDate(entry.startedAt),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.textMuted),
            onPressed: () async {
              await ref
                  .read(taskTimeEntriesProvider(widget.task.id).notifier)
                  .deleteEntry(entry.id);
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    }
  }
}
