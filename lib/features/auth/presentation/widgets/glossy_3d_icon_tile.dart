import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

enum Icon3DType {
  sync,
  checklist,
  kanban,
  comments,
  notifications,
  calendar,
  folder,
  layers,
}

class Glossy3DIconTile extends StatelessWidget {
  final Icon3DType type;
  final double size;
  final double? rotationDegrees;
  final bool animateFloat;
  final Duration floatDuration;
  final double floatOffset;

  const Glossy3DIconTile({
    super.key,
    required this.type,
    this.size = 64,
    this.rotationDegrees,
    this.animateFloat = false,
    this.floatDuration = const Duration(milliseconds: 2400),
    this.floatOffset = 4.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget tile = ExcludeSemantics(
      child: Transform.rotate(
        angle: (rotationDegrees ?? 0) * (math.pi / 180),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * 0.32),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      const Color(0xFF26262B),
                      const Color(0xFF141416),
                      const Color(0xFF0D0D0E),
                    ]
                  : [
                      Colors.white,
                      const Color(0xFFF4F4F5),
                      const Color(0xFFE4E4E7),
                    ],
            ),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.14)
                  : Colors.white.withValues(alpha: 0.85),
              width: 1.2,
            ),
            boxShadow: [
              // Deep diffused 3D shadow
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.55)
                    : Colors.black.withValues(alpha: 0.10),
                blurRadius: size * 0.35,
                offset: Offset(0, size * 0.16),
              ),
              // Soft ambient colorful back-glow
              BoxShadow(
                color: _getGlowColor(type).withValues(alpha: isDark ? 0.28 : 0.16),
                blurRadius: size * 0.45,
                offset: Offset(0, size * 0.08),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Top-left glossy specular glass sheen
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: size * 0.52,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(size * 0.32),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: isDark ? 0.22 : 0.45),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),

              // 3D Vector Icon Graphic
              Center(
                child: _buildIconGraphic(isDark),
              ),
            ],
          ),
        ),
      ),
    );

    if (animateFloat) {
      tile = tile
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .moveY(
            begin: -floatOffset,
            end: floatOffset,
            duration: floatDuration,
            curve: Curves.easeInOut,
          );
    }

    return tile;
  }

  Color _getGlowColor(Icon3DType type) {
    switch (type) {
      case Icon3DType.sync:
        return const Color(0xFF06B6D4); // Cyan
      case Icon3DType.checklist:
        return const Color(0xFF10B981); // Emerald
      case Icon3DType.kanban:
        return const Color(0xFF8B5CF6); // Purple
      case Icon3DType.comments:
        return const Color(0xFFEC4899); // Pink
      case Icon3DType.notifications:
        return const Color(0xFFF59E0B); // Amber
      case Icon3DType.calendar:
        return const Color(0xFF3B82F6); // Blue
      case Icon3DType.folder:
        return const Color(0xFF06B6D4); // Cyan
      case Icon3DType.layers:
        return const Color(0xFF8B5CF6); // Violet
    }
  }

  Widget _buildIconGraphic(bool isDark) {
    final iconSize = size * 0.52;

    switch (type) {
      case Icon3DType.sync:
        return Image.asset(
          'assets/images/logo.png',
          width: iconSize * 1.15,
          height: iconSize * 1.15,
          fit: BoxFit.contain,
        );

      case Icon3DType.checklist:
        return ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF10B981), Color(0xFF06B6D4)],
          ).createShader(bounds),
          child: Icon(
            Icons.task_alt_rounded,
            size: iconSize,
            color: Colors.white,
          ),
        );

      case Icon3DType.kanban:
        return ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
          ).createShader(bounds),
          child: Icon(
            Icons.view_kanban_rounded,
            size: iconSize,
            color: Colors.white,
          ),
        );

      case Icon3DType.comments:
        return ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFEC4899), Color(0xFFF59E0B)],
          ).createShader(bounds),
          child: Icon(
            Icons.chat_bubble_rounded,
            size: iconSize,
            color: Colors.white,
          ),
        );

      case Icon3DType.notifications:
        return ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
          ).createShader(bounds),
          child: Icon(
            Icons.notifications_active_rounded,
            size: iconSize,
            color: Colors.white,
          ),
        );

      case Icon3DType.calendar:
        return ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
          ).createShader(bounds),
          child: Icon(
            Icons.calendar_month_rounded,
            size: iconSize,
            color: Colors.white,
          ),
        );

      case Icon3DType.folder:
        return ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
          ).createShader(bounds),
          child: Icon(
            Icons.folder_rounded,
            size: iconSize,
            color: Colors.white,
          ),
        );

      case Icon3DType.layers:
        return ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
          ).createShader(bounds),
          child: Icon(
            Icons.layers_rounded,
            size: iconSize,
            color: Colors.white,
          ),
        );
    }
  }
}
