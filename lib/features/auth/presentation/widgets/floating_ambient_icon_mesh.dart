import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'glossy_3d_icon_tile.dart';

/// Configuration for a floating ambient icon in the depth mesh.
class _AmbientIconConfig {
  final Icon3DType type;
  final double size;
  final double relativeX; // 0.0 to 1.0 of screen width
  final double relativeY; // 0.0 to 1.0 of screen height
  final double opacity;
  final double blurSigma;
  final double rotationDegrees;
  final double floatOffset;
  final Duration floatDuration;

  const _AmbientIconConfig({
    required this.type,
    required this.size,
    required this.relativeX,
    required this.relativeY,
    required this.opacity,
    required this.blurSigma,
    required this.rotationDegrees,
    required this.floatOffset,
    required this.floatDuration,
  });
}

/// A balanced, depth-layered mesh of floating 3D-styled icons
/// (Folder, Checklist, Kanban/Projects, Transfer arrows, Layers).
///
/// Implements exact fractional screen positioning, sharp vs blurred depth tiers,
/// organic slow-motion floating loops, and visible dashed network connection lines.
class FloatingAmbientIconMesh extends StatelessWidget {
  const FloatingAmbientIconMesh({super.key});

  // Balanced placements matching the design specification:
  // 1. (0.10, 0.16) Folder - Small, sharp, 40%
  // 2. (0.86, 0.14) Transfer arrows - Small, sharp, 38%
  // 3. (0.88, 0.30) Checklist - Large, blurred, 15%
  // 4. (0.07, 0.45) Kanban/projects - Medium, 25%, behind card edge
  // 5. (0.92, 0.58) Transfer arrows - Medium, 25%, behind card edge
  // 6. (0.28, 0.62) Layers - Large, blurred, 14%, behind frosted card
  // 7. (0.12, 0.93) Checkmark - Medium, 30%
  // 8. (0.85, 0.95) Folder - Small, sharp, 40%
  static const List<_AmbientIconConfig> _icons = [
    // 0: (0.10, 0.16) Folder - Small, sharp, 40%
    _AmbientIconConfig(
      type: Icon3DType.folder,
      size: 44,
      relativeX: 0.10,
      relativeY: 0.16,
      opacity: 0.40,
      blurSigma: 0.0, // Sharp
      rotationDegrees: -8,
      floatOffset: 6,
      floatDuration: Duration(milliseconds: 7200),
    ),

    // 1: (0.86, 0.14) Transfer arrows - Small, sharp, 38%
    _AmbientIconConfig(
      type: Icon3DType.sync,
      size: 40,
      relativeX: 0.86,
      relativeY: 0.14,
      opacity: 0.38,
      blurSigma: 0.0, // Sharp
      rotationDegrees: -10,
      floatOffset: 6,
      floatDuration: Duration(milliseconds: 7600),
    ),

    // 2: (0.88, 0.30) Checklist - Large, blurred, 15%
    _AmbientIconConfig(
      type: Icon3DType.checklist,
      size: 92,
      relativeX: 0.88,
      relativeY: 0.30,
      opacity: 0.15,
      blurSigma: 8.0, // Large, heavily blurred
      rotationDegrees: 12,
      floatOffset: 8,
      floatDuration: Duration(milliseconds: 10800),
    ),

    // 3: (0.07, 0.45) Kanban/projects - Medium, 25%, behind card edge
    _AmbientIconConfig(
      type: Icon3DType.kanban,
      size: 54,
      relativeX: 0.07,
      relativeY: 0.45,
      opacity: 0.25,
      blurSigma: 1.5, // Medium, softened
      rotationDegrees: -11,
      floatOffset: 7,
      floatDuration: Duration(milliseconds: 8600),
    ),

    // 4: (0.92, 0.58) Transfer arrows - Medium, 25%, behind card edge
    _AmbientIconConfig(
      type: Icon3DType.sync,
      size: 56,
      relativeX: 0.92,
      relativeY: 0.58,
      opacity: 0.25,
      blurSigma: 1.5, // Medium, softened
      rotationDegrees: 9,
      floatOffset: 7,
      floatDuration: Duration(milliseconds: 9200),
    ),

    // 5: (0.28, 0.62) Layers - Large, blurred, 14%, behind frosted card
    _AmbientIconConfig(
      type: Icon3DType.layers,
      size: 88,
      relativeX: 0.28,
      relativeY: 0.62,
      opacity: 0.14,
      blurSigma: 8.0, // Large, heavily blurred
      rotationDegrees: 8,
      floatOffset: 8,
      floatDuration: Duration(milliseconds: 11400),
    ),

    // 6: (0.12, 0.93) Checkmark - Medium, 30%
    _AmbientIconConfig(
      type: Icon3DType.checklist,
      size: 50,
      relativeX: 0.12,
      relativeY: 0.93,
      opacity: 0.30,
      blurSigma: 0.0, // Crisp
      rotationDegrees: -6,
      floatOffset: 6,
      floatDuration: Duration(milliseconds: 8000),
    ),

    // 7: (0.85, 0.95) Folder - Small, sharp, 40%
    _AmbientIconConfig(
      type: Icon3DType.folder,
      size: 42,
      relativeX: 0.85,
      relativeY: 0.95,
      opacity: 0.40,
      blurSigma: 0.0, // Sharp
      rotationDegrees: 14,
      floatOffset: 6,
      floatDuration: Duration(milliseconds: 6800),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return IgnorePointer(
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;

            final points = _icons
                .map((cfg) => Offset(cfg.relativeX * w, cfg.relativeY * h))
                .toList();

            return Stack(
              clipBehavior: Clip.none,
              children: [
                // 1. Clearly connected dashed lines directly between icon centers
                Positioned.fill(
                  child: CustomPaint(
                    painter: _DirectDashedConnectionPainter(
                      points: points,
                      isDark: isDark,
                    ),
                  ),
                ),

                // 2. The depth-layered ambient floating icons
                for (final cfg in _icons)
                  Positioned(
                    left: (cfg.relativeX * w - (cfg.size / 2))
                        .clamp(4.0, w - cfg.size - 4.0),
                    top: (cfg.relativeY * h - (cfg.size / 2))
                        .clamp(8.0, h - cfg.size - 8.0),
                    child: _buildLayeredIcon(cfg),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLayeredIcon(_AmbientIconConfig cfg) {
    Widget content = Glossy3DIconTile(
      type: cfg.type,
      size: cfg.size,
      rotationDegrees: cfg.rotationDegrees,
      animateFloat: false,
    );

    if (cfg.blurSigma > 0) {
      content = ImageFiltered(
        imageFilter: ui.ImageFilter.blur(
          sigmaX: cfg.blurSigma,
          sigmaY: cfg.blurSigma,
          tileMode: TileMode.decal,
        ),
        child: content,
      );
    }

    content = Opacity(
      opacity: cfg.opacity,
      child: content,
    );

    // Organic slow-motion floating loop (6 to 12s, no pending Timers)
    return content
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .moveY(
          begin: -cfg.floatOffset,
          end: cfg.floatOffset,
          duration: cfg.floatDuration,
          curve: Curves.easeInOutSine,
        );
  }
}

/// Custom painter that draws clearly visible dashed lines directly connecting
/// pairs of icons (e.g. Folder to Kanban to Checkmark, Transfer to Checklist to Folder).
class _DirectDashedConnectionPainter extends CustomPainter {
  final List<Offset> points;
  final bool isDark;

  const _DirectDashedConnectionPainter({
    required this.points,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 8) return;

    final cyanPaint = Paint()
      ..color = (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7))
          .withValues(alpha: isDark ? 0.35 : 0.30)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final violetPaint = Paint()
      ..color = (isDark ? const Color(0xFF8B5CF6) : const Color(0xFF7C3AED))
          .withValues(alpha: isDark ? 0.35 : 0.28)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Left cluster connections:
    // 0: (0.10, 0.16) Folder -> 3: (0.07, 0.45) Kanban
    _drawDashedLine(canvas, points[0], points[3], cyanPaint);
    // 3: (0.07, 0.45) Kanban -> 6: (0.12, 0.93) Checkmark
    _drawDashedLine(canvas, points[3], points[6], violetPaint);

    // Right cluster connections:
    // 1: (0.86, 0.14) Sync -> 2: (0.88, 0.30) Checklist
    _drawDashedLine(canvas, points[1], points[2], cyanPaint);
    // 2: (0.88, 0.30) Checklist -> 4: (0.92, 0.58) Sync
    _drawDashedLine(canvas, points[2], points[4], violetPaint);
    // 4: (0.92, 0.58) Sync -> 7: (0.85, 0.95) Folder
    _drawDashedLine(canvas, points[4], points[7], cyanPaint);
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset p1,
    Offset p2,
    Paint paint, {
    double dashLength = 6.0,
    double spaceLength = 6.0,
  }) {
    final dx = p2.dx - p1.dx;
    final dy = p2.dy - p1.dy;
    final distance = math.sqrt(dx * dx + dy * dy);
    if (distance == 0) return;

    final unitX = dx / distance;
    final unitY = dy / distance;
    final step = dashLength + spaceLength;

    double current = 0;
    while (current < distance) {
      final startX = p1.dx + unitX * current;
      final startY = p1.dy + unitY * current;
      final endDistance = math.min(current + dashLength, distance);
      final endX = p1.dx + unitX * endDistance;
      final endY = p1.dy + unitY * endDistance;

      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
      current += step;
    }
  }

  @override
  bool shouldRepaint(covariant _DirectDashedConnectionPainter oldDelegate) {
    return oldDelegate.isDark != isDark || oldDelegate.points != points;
  }
}
