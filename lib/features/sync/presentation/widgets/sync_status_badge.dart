import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../sync_providers.dart';
import 'sync_center_sheet.dart';

class SyncStatusBadge extends ConsumerStatefulWidget {
  final bool? compact;

  const SyncStatusBadge({super.key, this.compact});

  @override
  ConsumerState<SyncStatusBadge> createState() => _SyncStatusBadgeState();
}

class _SyncStatusBadgeState extends ConsumerState<SyncStatusBadge> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isCompact = widget.compact ?? (MediaQuery.sizeOf(context).width < 500);
    final syncStateAsync = ref.watch(syncEngineStateProvider);
    final syncEngine = ref.watch(syncEngineProvider);
    final state = syncStateAsync.value ?? syncEngine.currentState;

    final isOffline = state.networkStatus.isOffline;
    final isSyncing = state.isSyncing;
    final pendingCount = state.pendingCount;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color accentColor;
    String label;
    IconData icon;

    if (isOffline) {
      accentColor = const Color(0xFFF59E0B); // Amber
      label = pendingCount > 0 ? 'Offline ($pendingCount)' : 'Offline';
      icon = Icons.cloud_off_rounded;
    } else if (isSyncing) {
      accentColor = const Color(0xFF60A5FA); // Blue
      label = 'Syncing...';
      icon = Icons.sync_rounded;
    } else if (pendingCount > 0) {
      accentColor = const Color(0xFFF59E0B);
      label = '$pendingCount pending';
      icon = Icons.cloud_upload_outlined;
    } else {
      accentColor = const Color(0xFF10B981); // Emerald
      label = 'Synced';
      icon = Icons.cloud_done_rounded;
    }

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        HapticFeedback.lightImpact();
        SyncCenterSheet.show(context);
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 8 : 10,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            // Neumorphic Concave / Recessed Surface
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? const [
                      Color(0xFF14171E),
                      Color(0xFF1D222C),
                    ]
                  : const [
                      Color(0xFFE8EEF5),
                      Color(0xFFF8FAFC),
                    ],
            ),
            boxShadow: _isPressed
                ? [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.6)
                          : const Color(0xFFA1B0C5).withValues(alpha: 0.5),
                      offset: const Offset(1, 1),
                      blurRadius: 2,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.white.withValues(alpha: 0.95),
                      offset: const Offset(-1, -1),
                      blurRadius: 2,
                    ),
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.70)
                          : const Color(0xFFA1B0C5).withValues(alpha: 0.45),
                      offset: const Offset(2, 2.5),
                      blurRadius: 4,
                    ),
                  ],
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.white.withValues(alpha: 0.8),
              width: 0.9,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Micro status dot with glow
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor,
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.6),
                      blurRadius: 3,
                      spreadRadius: 0.5,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              if (isSyncing)
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: accentColor,
                  ),
                )
              else
                Icon(icon, size: 13, color: accentColor),
              if (!isCompact) ...[
                const SizedBox(width: 5),
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
