import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/app_bottom_nav_bar.dart';
import 'sync_providers.dart';
import 'widgets/sync_status_badge.dart';

class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedText = isDark ? const Color(0xFF8E99AF) : const Color(0xFF64748B);

    final syncStateAsync = ref.watch(syncEngineStateProvider);
    final syncEngine = ref.watch(syncEngineProvider);
    final state = syncStateAsync.value ?? syncEngine.currentState;

    final queueRepo = ref.watch(mutationQueueRepositoryProvider);
    final queue = queueRepo.getAll();

    return Scaffold(
      extendBody: false,
      backgroundColor: isDark ? const Color(0xFF0C0E14) : const Color(0xFFEFF2F7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 20,
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
                          const Color(0xFF141722).withValues(alpha: 0.90),
                          const Color(0xFF0C0E14).withValues(alpha: 0.75),
                        ]
                      : [
                          Colors.white.withValues(alpha: 0.92),
                          const Color(0xFFEFF2F7).withValues(alpha: 0.80),
                        ],
                ),
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? const Color(0xFF262A38) : const Color(0xFFD6DEE9),
                    width: 1.0,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            ),
          ),
        ),
        title: Text(
          'Sync & Activity',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: primaryText,
            letterSpacing: -0.3,
          ),
        ),
        actions: const [
          SyncStatusBadge(compact: true),
          SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sync Engine Overview Card (Sculpted Neumorphic Slab)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? const [
                          Color(0xFF1E212D),
                          Color(0xFF13151E),
                        ]
                      : const [
                          Colors.white,
                          Color(0xFFE5EBF4),
                        ],
                ),
                border: Border.all(
                  color: isDark ? const Color(0xFF2A2E3D) : const Color(0xFFCBD5E1),
                  width: 1.1,
                ),
                boxShadow: isDark
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.80),
                          offset: const Offset(4, 6),
                          blurRadius: 16,
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
                          offset: const Offset(4, 6),
                          blurRadius: 14,
                          spreadRadius: -1,
                        ),
                        const BoxShadow(
                          color: Colors.white,
                          offset: Offset(-2, -2),
                          blurRadius: 6,
                        ),
                      ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Engine Status Header Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          // Sunken Socket for status dot
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark ? const Color(0xFF10121A) : const Color(0xFFE2E8F0),
                              border: Border.all(
                                color: isDark ? const Color(0xFF262A38) : const Color(0xFFCBD5E1),
                                width: 0.8,
                              ),
                              boxShadow: isDark
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.80),
                                        offset: const Offset(1, 1.5),
                                        blurRadius: 2,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: state.networkStatus.isOnline
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFEF4444),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (state.networkStatus.isOnline
                                              ? const Color(0xFF10B981)
                                              : const Color(0xFFEF4444))
                                          .withValues(alpha: 0.65),
                                      blurRadius: 4,
                                      spreadRadius: 0.5,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            state.networkStatus.isOnline ? 'Online Engine' : 'Offline Engine',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: primaryText,
                            ),
                          ),
                        ],
                      ),

                      // Inset Neumorphic Ready / Syncing Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF10121A) : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? const Color(0xFF262A38) : const Color(0xFFCBD5E1),
                            width: 0.8,
                          ),
                          boxShadow: isDark
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.80),
                                    offset: const Offset(1, 1.5),
                                    blurRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          state.isSyncing ? 'Syncing...' : 'Ready',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: state.isSyncing
                                ? const Color(0xFF38BDF8)
                                : const Color(0xFF10B981),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Sunken Inset Metric Tiles
                  Row(
                    children: [
                      Expanded(
                        child: _NeumorphicMetricWell(
                          label: 'Pending',
                          value: '${state.pendingCount}',
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _NeumorphicMetricWell(
                          label: 'Last Synced',
                          value: state.lastSyncTime != null
                              ? DateFormat('HH:mm').format(state.lastSyncTime!)
                              : 'Never',
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Embossed 3D Neumorphic "Force Sync Now" Button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: state.isSyncing
                          ? null
                          : () {
                              HapticFeedback.mediumImpact();
                              syncEngine.drainQueue();
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
                                ? const [
                                    Color(0xFF2A2E3D),
                                    Color(0xFF191B26),
                                  ]
                                : const [
                                    Colors.white,
                                    Color(0xFFE2E8F0),
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
                                    blurRadius: 8,
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
                            if (state.isSyncing)
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            else
                              Icon(
                                Icons.sync_rounded,
                                size: 18,
                                color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF0F172A),
                              ),
                            const SizedBox(width: 8),
                            Text(
                              state.isSyncing ? 'Syncing...' : 'Force Sync Now',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
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
            const SizedBox(height: 28),

            // Section Header: OFFLINE MUTATION QUEUE
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                'OFFLINE MUTATION QUEUE',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: mutedText,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Card 2: Empty State or Mutation Queue
            if (queue.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? const [
                            Color(0xFF1E212D),
                            Color(0xFF13151E),
                          ]
                        : const [
                            Colors.white,
                            Color(0xFFE5EBF4),
                          ],
                  ),
                  border: Border.all(
                    color: isDark ? const Color(0xFF2A2E3D) : const Color(0xFFCBD5E1),
                    width: 1.1,
                  ),
                  boxShadow: isDark
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.80),
                          offset: const Offset(4, 6),
                          blurRadius: 16,
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
                          offset: const Offset(4, 6),
                          blurRadius: 14,
                          spreadRadius: -1,
                        ),
                        const BoxShadow(
                          color: Colors.white,
                          offset: Offset(-2, -2),
                          blurRadius: 6,
                        ),
                      ],
                ),
                child: Center(
                  child: Column(
                    children: [
                      // Sunken Cloud Icon Crater
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? const Color(0xFF10121A) : const Color(0xFFE2E8F0),
                          border: Border.all(
                            color: isDark ? const Color(0xFF262A38) : const Color(0xFFCBD5E1),
                            width: 1.0,
                          ),
                          boxShadow: isDark
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.90),
                                    offset: const Offset(2, 2.5),
                                    blurRadius: 4,
                                  ),
                                ]
                              : [
                                  BoxShadow(
                                    color: const Color(0xFF9FAEC3).withValues(alpha: 0.60),
                                    offset: const Offset(2, 2.5),
                                    blurRadius: 4,
                                  ),
                                ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.cloud_done_rounded,
                            size: 26,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Everything is up to date',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: primaryText,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'All local changes have been synchronized with the cloud.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: mutedText,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: queue.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final mutation = queue[index];
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? const [
                                Color(0xFF1E212D),
                                Color(0xFF13151E),
                              ]
                            : const [
                                Colors.white,
                                Color(0xFFE5EBF4),
                              ],
                      ),
                      border: Border.all(
                        color: isDark ? const Color(0xFF2A2E3D) : const Color(0xFFCBD5E1),
                        width: 1.0,
                      ),
                      boxShadow: isDark
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.75),
                                offset: const Offset(3, 4),
                                blurRadius: 10,
                                spreadRadius: -1,
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: const Color(0xFFA5B2C5).withValues(alpha: 0.45),
                                offset: const Offset(3, 4),
                                blurRadius: 8,
                              ),
                              const BoxShadow(
                                color: Colors.white,
                                offset: Offset(-2, -2),
                                blurRadius: 4,
                              ),
                            ],
                    ),
                    child: Row(
                      children: [
                        // Sculpted icon socket
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: isDark ? const Color(0xFF10121A) : const Color(0xFFE2E8F0),
                            border: Border.all(
                              color: isDark ? const Color(0xFF262A38) : const Color(0xFFCBD5E1),
                              width: 0.8,
                            ),
                            boxShadow: isDark
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.80),
                                      offset: const Offset(1.5, 2),
                                      blurRadius: 3,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Icon(
                            Icons.edit_note_rounded,
                            size: 19,
                            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${mutation.action.toUpperCase()} ${mutation.entityType}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: primaryText,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Retries: ${mutation.retryCount} • Created ${DateFormat('HH:mm:ss').format(mutation.createdAt)}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: mutedText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Neumorphic status pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF10121A) : const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark ? const Color(0xFF262A38) : const Color(0xFFCBD5E1),
                              width: 0.8,
                            ),
                            boxShadow: isDark
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.70),
                                      offset: const Offset(1, 1.5),
                                      blurRadius: 2,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Text(
                            mutation.status.name,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 2),
    );
  }
}

/// Sunken Inset Crater Metric Well (tactile neumorphism)
class _NeumorphicMetricWell extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _NeumorphicMetricWell({
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final primaryText = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedText = isDark ? const Color(0xFF8E99AF) : const Color(0xFF64748B);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF10121A) : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF242836) : const Color(0xFFCBD5E1),
          width: 1.0,
        ),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.85),
                  offset: const Offset(1.5, 2),
                  blurRadius: 3,
                ),
              ]
            : [
                BoxShadow(
                  color: const Color(0xFF9FAEC3).withValues(alpha: 0.60),
                  offset: const Offset(1.5, 2),
                  blurRadius: 3,
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: mutedText,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: primaryText,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}
