import 'dart:ui';
import 'package:flutter/material.dart';

/// Ultra-refined Optical Frosted Glass Container matching the physical glass slab reference design:
///
/// Features:
/// - True optical backdrop blur revealing background ambient glow
/// - Frosted satin face sheen with light-wash gradient
/// - Specular refracted glass rim: luminous sharp top & corner reflections
/// - Soft ambient floating drop shadow
class LiquidGlassBox extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final bool showSparkles;
  final bool showDiagonalSheen;
  final bool showWhiteGlare;
  final Color? tintColor;
  final double blur;
  final VoidCallback? onTap;
  final List<BoxShadow>? customShadow;

  const LiquidGlassBox({
    super.key,
    required this.child,
    this.borderRadius = 26,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.showSparkles = false,
    this.showDiagonalSheen = false,
    this.showWhiteGlare = false,
    this.tintColor,
    this.blur = 24.0,
    this.onTap,
    this.customShadow,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget content = Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        // Layer 1: Ambient Floating Glass Drop Shadow
        boxShadow: customShadow ??
            [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.38 : 0.08),
                blurRadius: 26,
                spreadRadius: -2,
                offset: const Offset(0, 10),
              ),
              if (tintColor != null)
                BoxShadow(
                  color: tintColor!.withValues(alpha: isDark ? 0.25 : 0.15),
                  blurRadius: 20,
                  spreadRadius: 1,
                ),
            ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            // Layer 2: Translucent Frosted Glass Satin Surface
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        (tintColor ?? (showWhiteGlare ? Colors.white.withValues(alpha: 0.12) : const Color(0xFF1E212D).withValues(alpha: 0.55))),
                        const Color(0xFF141620).withValues(alpha: 0.65),
                        const Color(0xFF0B0D14).withValues(alpha: 0.80),
                      ]
                    : (showWhiteGlare
                        ? [
                            Colors.white.withValues(alpha: 0.75),
                            const Color(0xFFEFF3F8).withValues(alpha: 0.55),
                            const Color(0xFFE2E8F0).withValues(alpha: 0.45),
                          ]
                        : [
                            const Color(0xFFF1F5F9).withValues(alpha: 0.75),
                            const Color(0xFFE2E8F0).withValues(alpha: 0.65),
                            const Color(0xFFCBD5E1).withValues(alpha: 0.55),
                          ]),
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
            child: Stack(
              children: [
                // Layer 3: Specular Refracted Glass Rim Highlight Painter
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _GlassSpecularRimPainter(
                        borderRadius: borderRadius,
                        borderWidth: 1.15,
                        isDark: isDark,
                        tintColor: tintColor,
                        showWhiteGlare: showWhiteGlare,
                      ),
                    ),
                  ),
                ),

                // Layer 4: Main Content
                Padding(
                  padding: padding ?? const EdgeInsets.all(16),
                  child: child,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          splashColor: Colors.white.withValues(alpha: 0.08),
          highlightColor: Colors.white.withValues(alpha: 0.04),
          child: content,
        ),
      );
    }

    return content;
  }
}

/// Custom painter for the exact specular refraction on the edge of the glass slab:
/// Luminous top-right and bottom-left reflections with continuous thin glass rim.
class _GlassSpecularRimPainter extends CustomPainter {
  final double borderRadius;
  final double borderWidth;
  final bool isDark;
  final Color? tintColor;
  final bool showWhiteGlare;

  _GlassSpecularRimPainter({
    required this.borderRadius,
    this.borderWidth = 1.15,
    required this.isDark,
    this.tintColor,
    this.showWhiteGlare = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final rect = Offset(borderWidth / 2, borderWidth / 2) &
        Size(size.width - borderWidth, size.height - borderWidth);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    // 1. Continuous structural perimeter rim ensuring a complete, visible, closed box on all 4 sides
    final baseRimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..color = (tintColor ??
              (isDark
                  ? (showWhiteGlare ? Colors.white : const Color(0xFF2C3242))
                  : (showWhiteGlare ? Colors.white : const Color(0xFFCBD5E1))))
          .withValues(
        alpha: isDark ? (showWhiteGlare ? 0.18 : 0.45) : 0.25,
      );
    canvas.drawRRect(rrect, baseRimPaint);

    // 2. Specular Refraction Gradient Rim for premium glass edge glint
    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? (showWhiteGlare
                ? [
                    (tintColor ?? Colors.white).withValues(alpha: 0.70),
                    (tintColor ?? Colors.white).withValues(alpha: 0.35),
                    (tintColor ?? Colors.white).withValues(alpha: 0.22),
                    (tintColor ?? Colors.white).withValues(alpha: 0.45),
                  ]
                : [
                    (tintColor ?? const Color(0xFF333A4D)).withValues(alpha: 0.40),
                    (tintColor ?? const Color(0xFF252A38)).withValues(alpha: 0.25),
                    (tintColor ?? const Color(0xFF1B1E29)).withValues(alpha: 0.20),
                    (tintColor ?? const Color(0xFF2E3547)).withValues(alpha: 0.35),
                  ])
            : (showWhiteGlare
                ? [
                    Colors.white.withValues(alpha: 0.90),
                    Colors.white.withValues(alpha: 0.55),
                    Colors.white.withValues(alpha: 0.30),
                    Colors.white.withValues(alpha: 0.60),
                  ]
                : [
                    const Color(0xFFB0BAC9).withValues(alpha: 0.50),
                    const Color(0xFFCAD3DF).withValues(alpha: 0.40),
                    const Color(0xFFDCE2EC).withValues(alpha: 0.35),
                    const Color(0xFFBCC6D5).withValues(alpha: 0.45),
                  ]),
        stops: const [0.0, 0.30, 0.70, 1.0],
      ).createShader(Offset.zero & size);

    canvas.drawRRect(rrect, rimPaint);

    // 3. Inner specular wash near top edge (strictly only if white glare is requested)
    if (showWhiteGlare) {
      final innerRect = Offset(borderWidth + 0.6, borderWidth + 0.6) &
          Size(size.width - (borderWidth * 2 + 1.2), size.height - (borderWidth * 2 + 1.2));
      final innerRRect = RRect.fromRectAndRadius(
        innerRect,
        Radius.circular((borderRadius - 1).clamp(0.0, double.infinity)),
      );

      final innerGlowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.85
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: isDark ? 0.20 : 0.40),
            Colors.white.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.25],
        ).createShader(Offset.zero & size);

      canvas.drawRRect(innerRRect, innerGlowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GlassSpecularRimPainter oldDelegate) =>
      oldDelegate.borderRadius != borderRadius ||
      oldDelegate.borderWidth != borderWidth ||
      oldDelegate.isDark != isDark ||
      oldDelegate.showWhiteGlare != showWhiteGlare ||
      oldDelegate.tintColor != tintColor;
}
