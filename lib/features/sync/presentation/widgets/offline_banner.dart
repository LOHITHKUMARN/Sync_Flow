import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../sync_providers.dart';
import 'sync_center_sheet.dart';

/// An ultra-polished Neumorphic Offline Banner displaying network connectivity status,
/// local queue metrics, and tactile interactive controls.
class OfflineBanner extends ConsumerStatefulWidget {
  const OfflineBanner({super.key});

  @override
  ConsumerState<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends ConsumerState<OfflineBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final syncStateAsync = ref.watch(syncEngineStateProvider);
    final syncEngine = ref.watch(syncEngineProvider);
    final state = syncStateAsync.value ?? syncEngine.currentState;
    final isOffline = state.networkStatus.isOffline;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedSize(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOutCubic,
      child: isOffline
          ? Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
              child: _buildNeumorphicBanner(context, isDark, state.pendingCount),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildNeumorphicBanner(
    BuildContext context,
    bool isDark,
    int pendingCount,
  ) {
    // Curated warm amber accents for offline indication
    const amberAccent = Color(0xFFF59E0B);
    final amberGlow = amberAccent.withValues(alpha: isDark ? 0.35 : 0.25);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        // Modern Convex Satin-Finish Neumorphic Gradient
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [
                  Color(0xFF1E222B), // Specular graphite highlight
                  Color(0xFF101217), // Deep velvety obsidian base
                ]
              : const [
                  Color(0xFFFFFFFF),
                  Color(0xFFE8EEF6),
                ],
        ),
        // 4-Point Specular & Deep Neumorphic Shadow Stack
        boxShadow: [
          // 1. Razor-sharp Specular Top-Left Highlight
          BoxShadow(
            color: isDark
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.white.withValues(alpha: 0.95),
            offset: const Offset(-1.5, -1.5),
            blurRadius: 3,
            spreadRadius: 0,
          ),
          // 2. Soft Ambient Top-Left Glow
          BoxShadow(
            color: isDark
                ? const Color(0xFF2B3445).withValues(alpha: 0.45)
                : Colors.white,
            offset: const Offset(-5, -5),
            blurRadius: 14,
            spreadRadius: 0,
          ),
          // 3. Deep Obsidian Bottom-Right Cast Shadow
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.88)
                : const Color(0xFFA1B0C5).withValues(alpha: 0.45),
            offset: const Offset(6, 7),
            blurRadius: 16,
            spreadRadius: 0,
          ),
          // 4. Subtle Contact Ambient Shadow
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.4)
                : const Color(0xFFCBD5E1).withValues(alpha: 0.35),
            offset: const Offset(1, 2),
            blurRadius: 4,
            spreadRadius: 0,
          ),
        ],
        // Chamfered Micro-Border
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.85),
          width: 1.1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            SyncCenterSheet.show(context);
          },
          borderRadius: BorderRadius.circular(20),
          splashColor: amberAccent.withValues(alpha: 0.08),
          highlightColor: amberAccent.withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // Inset / Concave Neumorphic Icon Well
                _buildConcaveIconWell(isDark, amberAccent, amberGlow),
                const SizedBox(width: 12),

                // Text Information Hierarchy
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Offline Mode',
                              style: GoogleFonts.plusJakartaSans(
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.1,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Micro-pill tag
                          _buildMicroTag(isDark, amberAccent),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Changes saved locally • Syncs online',
                        style: GoogleFonts.plusJakartaSans(
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Raised Tactile Action Pill Button
                _TactileNeumorphicQueuePill(
                  pendingCount: pendingCount,
                  isDark: isDark,
                  amberAccent: amberAccent,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    SyncCenterSheet.show(context);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Neumorphic Inset / Concave Icon Well with breathing amber halo
  Widget _buildConcaveIconWell(
    bool isDark,
    Color amberAccent,
    Color amberGlow,
  ) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        final glowFactor = _pulseAnimation.value;

        return Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            // Concave / Inset gradient
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? const [
                      Color(0xFF0D0F13), // Deep recessed dark shade
                      Color(0xFF171A21), // Soft highlight lip
                    ]
                  : const [
                      Color(0xFFDCE3ED),
                      Color(0xFFF1F5FA),
                    ],
            ),
            // Inset shadow illusion
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.75)
                    : const Color(0xFFA3B1C6).withValues(alpha: 0.55),
                offset: const Offset(1.5, 1.5),
                blurRadius: 3,
              ),
              BoxShadow(
                color: isDark
                    ? const Color(0xFF262A35).withValues(alpha: 0.45)
                    : Colors.white.withValues(alpha: 0.95),
                offset: const Offset(-1, -1),
                blurRadius: 2,
              ),
              // Breathing amber halo
              BoxShadow(
                color: amberAccent.withValues(
                  alpha: (isDark ? 0.20 : 0.15) * glowFactor,
                ),
                blurRadius: 6 * glowFactor,
                spreadRadius: 1 * glowFactor,
              ),
            ],
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.white.withValues(alpha: 0.70),
              width: 1,
            ),
          ),
          child: Center(
            child: Icon(
              Icons.cloud_off_rounded,
              size: 18,
              color: amberAccent,
            ),
          ),
        );
      },
    );
  }

  /// Inset Micro-Tag "LOCAL" with soft breathing amber indicator dot
  Widget _buildMicroTag(bool isDark, Color amberAccent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: isDark
            ? const Color(0xFF0F1217)
            : const Color(0xFFE2E8F0),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.white.withValues(alpha: 0.8),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: amberAccent,
                  boxShadow: [
                    BoxShadow(
                      color: amberAccent.withValues(
                        alpha: 0.6 * _pulseAnimation.value,
                      ),
                      blurRadius: 4 * _pulseAnimation.value,
                      spreadRadius: 1 * _pulseAnimation.value,
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 4),
          Text(
            'LOCAL FIRST',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: isDark
                  ? const Color(0xFFCBD5E1)
                  : const Color(0xFF475569),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// A tactile raised neumorphic pill button with press animation & haptic response
class _TactileNeumorphicQueuePill extends StatefulWidget {
  final int pendingCount;
  final bool isDark;
  final Color amberAccent;
  final VoidCallback onTap;

  const _TactileNeumorphicQueuePill({
    required this.pendingCount,
    required this.isDark,
    required this.amberAccent,
    required this.onTap,
  });

  @override
  State<_TactileNeumorphicQueuePill> createState() =>
      _TactileNeumorphicQueuePillState();
}

class _TactileNeumorphicQueuePillState
    extends State<_TactileNeumorphicQueuePill> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final hasPending = widget.pendingCount > 0;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            // Convex Satin Surface
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.isDark
                  ? (hasPending
                      ? const [
                          Color(0xFF2E2210), // Warm amber-obsidian highlight
                          Color(0xFF1B1408), // Rich amber base
                        ]
                      : const [
                          Color(0xFF222631),
                          Color(0xFF14171E),
                        ])
                  : (hasPending
                      ? const [
                          Color(0xFFFFFBEB),
                          Color(0xFFFEF3C7),
                        ]
                      : const [
                          Color(0xFFFFFFFF),
                          Color(0xFFE2E8F0),
                        ]),
            ),
            // Tactile 3D Shadows (Inverted when pressed)
            boxShadow: _isPressed
                ? [
                    BoxShadow(
                      color: widget.isDark
                          ? Colors.black.withValues(alpha: 0.6)
                          : const Color(0xFFA1B0C5).withValues(alpha: 0.5),
                      offset: const Offset(1, 1),
                      blurRadius: 2,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: widget.isDark
                          ? Colors.white.withValues(alpha: 0.10)
                          : Colors.white.withValues(alpha: 0.9),
                      offset: const Offset(-1, -1),
                      blurRadius: 2,
                    ),
                    BoxShadow(
                      color: widget.isDark
                          ? Colors.black.withValues(alpha: 0.70)
                          : const Color(0xFFA1B0C5).withValues(alpha: 0.45),
                      offset: const Offset(2.5, 3),
                      blurRadius: 5,
                    ),
                  ],
            border: Border.all(
              color: hasPending
                  ? widget.amberAccent.withValues(alpha: 0.45)
                  : (widget.isDark
                      ? Colors.white.withValues(alpha: 0.10)
                      : Colors.white.withValues(alpha: 0.9)),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasPending) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: widget.amberAccent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${widget.pendingCount}',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.black,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  'Queued',
                  style: GoogleFonts.plusJakartaSans(
                    color: widget.isDark
                        ? const Color(0xFFFDE68A)
                        : const Color(0xFFB45309),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ] else ...[
                Icon(
                  Icons.check_circle_outline_rounded,
                  size: 13,
                  color: widget.isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
                const SizedBox(width: 4),
                Text(
                  '0 Queued',
                  style: GoogleFonts.plusJakartaSans(
                    color: widget.isDark
                        ? const Color(0xFFE2E8F0)
                        : const Color(0xFF334155),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(width: 3),
              Icon(
                Icons.chevron_right_rounded,
                size: 14,
                color: widget.isDark
                    ? const Color(0xFF64748B)
                    : const Color(0xFF94A3B8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
