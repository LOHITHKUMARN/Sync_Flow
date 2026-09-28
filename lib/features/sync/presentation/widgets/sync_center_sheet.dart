import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/sync_mutation.dart';
import '../sync_providers.dart';

class SyncCenterSheet extends ConsumerWidget {
  const SyncCenterSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const SyncCenterSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStateAsync = ref.watch(syncEngineStateProvider);
    final syncEngine = ref.watch(syncEngineProvider);
    final state = syncStateAsync.value ?? syncEngine.currentState;

    final connectivityService = ref.watch(connectivityServiceProvider);
    final queueRepo = ref.watch(mutationQueueRepositoryProvider);
    final queue = queueRepo.getAll();

    final isOffline = state.networkStatus.isOffline;
    final isSyncing = state.isSyncing;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
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
          // Handle
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
                        Icons.sync_alt_rounded,
                        color: AppColors.primaryLight,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sync & Offline Center',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Offline-First Mutation Engine',
                          style: TextStyle(
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

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Status Card
                Container(
                  padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline,
                        width: Theme.of(context).dividerTheme.thickness ?? 1.0,
                      ),
                    ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isOffline
                                      ? AppColors.warning
                                      : (isSyncing ? AppColors.primaryLight : AppColors.statusDone),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                isOffline
                                    ? 'Network Status: Offline'
                                    : (isSyncing ? 'Synchronizing...' : 'Network Status: Online'),
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${state.pendingCount} in queue',
                              style: TextStyle(
                                color: state.pendingCount > 0
                                    ? AppColors.warning
                                    : AppColors.textMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Last Successful Sync:',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                          ),
                          Text(
                            state.lastSyncTime != null
                                ? DateFormat('HH:mm:ss').format(state.lastSyncTime!)
                                : 'Not yet synced',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Simulation Switch Card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: connectivityService.isSimulatedOffline
                          ? AppColors.warning.withValues(alpha: 0.5)
                          : Theme.of(context).colorScheme.outline,
                      width: Theme.of(context).dividerTheme.thickness ?? 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Simulate Offline Mode',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Test offline queue & auto-reconnect',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      Switch.adaptive(
                        value: connectivityService.isSimulatedOffline,
                        activeColor: AppColors.warning,
                        onChanged: (val) {
                          connectivityService.setSimulatedOffline(val);
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Sync Now Action Button
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: (isOffline || isSyncing || state.pendingCount == 0)
                        ? null
                        : () => syncEngine.drainQueue(),
                    icon: isSyncing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.sync_rounded, size: 18),
                    label: Text(
                      isSyncing ? 'Syncing Mutations...' : 'Force Sync Now',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      disabledBackgroundColor: AppColors.surfaceLight,
                      disabledForegroundColor: AppColors.textMuted,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Queue Section Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'PENDING MUTATIONS',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    if (queue.isNotEmpty)
                      TextButton(
                        onPressed: () => queueRepo.clearAll(),
                        child: const Text(
                          'Clear All',
                          style: TextStyle(color: AppColors.error, fontSize: 12),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                // Queue List or Empty State
                if (queue.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 36),
                    child: Column(
                      children: [
                        Icon(
                          Icons.cloud_done_rounded,
                          size: 40,
                          color: AppColors.statusDone.withValues(alpha: 0.7),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Everything is in sync',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'No pending mutations in the local queue.',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...queue.map((mutation) => _buildMutationTile(context, ref, mutation)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMutationTile(BuildContext context, WidgetRef ref, SyncMutation mutation) {
    Color actionColor;
    switch (mutation.action) {
      case 'create':
        actionColor = AppColors.statusDone;
        break;
      case 'update':
        actionColor = AppColors.primaryLight;
        break;
      case 'delete':
        actionColor = AppColors.error;
        break;
      default:
        actionColor = AppColors.warning;
    }

    final taskTitle = mutation.payload['title'] as String? ?? mutation.targetId;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline,
            width: Theme.of(context).dividerTheme.thickness ?? 1.0,
          ),
        ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: actionColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              mutation.action.toUpperCase(),
              style: TextStyle(
                color: actionColor,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  taskTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${DateFormat('HH:mm:ss').format(mutation.createdAt)} • ${mutation.status.name}',
                  style: TextStyle(
                    color: mutation.status == MutationStatus.failed
                        ? AppColors.error
                        : AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16, color: AppColors.textMuted),
            onPressed: () {
              ref.read(mutationQueueRepositoryProvider).removeMutation(mutation.id);
            },
          ),
        ],
      ),
    );
  }
}
