import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Pure Soft Neumorphic Status Badge modeled after classic soft UI principles:
/// Extruded seamless surface with dual-directional ambient light & shadow.
class StatusBadge extends StatelessWidget {
  final String status;
  final bool isSmall;

  const StatusBadge({
    super.key,
    required this.status,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (label, rawColor) = _getBadgeConfig(status);
    final color = (!isDark && rawColor == Colors.white) ? const Color(0xFF09090B) : rawColor;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 9 : 12,
        vertical: isSmall ? 4 : 5.5,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: color.withValues(alpha: isDark ? 0.14 : 0.10),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.38 : 0.30),
          width: 0.9,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isDark ? 0.20 : 0.08),
            blurRadius: 6,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isSmall ? 6 : 7.5,
            height: isSmall ? 6 : 7.5,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.8),
                  blurRadius: 4,
                  spreadRadius: 0.5,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: isSmall ? 10.5 : 12,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  (String, Color) _getBadgeConfig(String rawStatus) {
    switch (rawStatus.toUpperCase()) {
      case 'TODO':
        return ('To Do', const Color(0xFF94A3B8));
      case 'IN_PROGRESS':
        return ('In Progress', const Color(0xFF3B82F6));
      case 'IN_REVIEW':
        return ('In Review', const Color(0xFFA855F7));
      case 'DONE':
        return ('Done', const Color(0xFF10B981));
      default:
        return (rawStatus, const Color(0xFF94A3B8));
    }
  }
}

/// Refined Frosted Glass Priority Badge modeled on the reference pill design:
/// Translucent tinted capsule with crisp border, glowing indicator dot, and radiant typography.
class PriorityBadge extends StatelessWidget {
  final String priority;
  final bool isSmall;

  const PriorityBadge({
    super.key,
    required this.priority,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (label, accentColor, icon) = _getPriorityConfig(priority);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 9 : 12,
        vertical: isSmall ? 4 : 5.5,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: accentColor.withValues(alpha: isDark ? 0.14 : 0.10),
        border: Border.all(
          color: accentColor.withValues(alpha: isDark ? 0.38 : 0.30),
          width: 0.9,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: isDark ? 0.20 : 0.08),
            blurRadius: 6,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Soft Glowing Radiant Indicator Dot
          Container(
            width: isSmall ? 6 : 7,
            height: isSmall ? 6 : 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentColor,
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.85),
                  blurRadius: 5,
                  spreadRadius: 0.5,
                ),
              ],
            ),
          ),
          const SizedBox(width: 5),
          Icon(
            icon,
            size: isSmall ? 11.5 : 13,
            color: accentColor,
          ),
          const SizedBox(width: 3.5),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: isSmall ? 11 : 12,
              fontWeight: FontWeight.w700,
              color: accentColor,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  (String, Color, IconData) _getPriorityConfig(String rawPriority) {
    switch (rawPriority.toUpperCase()) {
      case 'LOW':
        return (
          'Low',
          const Color(0xFF10B981), // Emerald Green
          Icons.arrow_downward_rounded,
        );
      case 'MEDIUM':
        return (
          'Medium',
          const Color(0xFFF59E0B), // Amber Gold
          Icons.remove_rounded,
        );
      case 'HIGH':
        return (
          'High',
          const Color(0xFFF97316), // Sunset Orange
          Icons.arrow_upward_rounded,
        );
      case 'URGENT':
        return (
          'Urgent',
          const Color(0xFFEF4444), // Crimson Red
          Icons.priority_high_rounded,
        );
      default:
        return (
          rawPriority,
          const Color(0xFF94A3B8),
          Icons.remove_rounded,
        );
    }
  }
}
