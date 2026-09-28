import 'dart:ui';
import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? borderColor;
  final Color? backgroundColor;
  final double blur;
  final Gradient? gradient;
  final bool showSpecularSheen;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 16,
    this.borderColor,
    this.backgroundColor,
    this.blur = 24.0,
    this.gradient,
    this.showSpecularSheen = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final defaultBorder = borderColor ??
        (isDark
            ? Colors.white.withValues(alpha: 0.20)
            : Colors.white.withValues(alpha: 0.90));

    final effectiveGradient = gradient ??
        LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  Colors.white.withValues(alpha: 0.09),
                  const Color(0xFF141418).withValues(alpha: 0.42),
                ]
              : [
                  Colors.white.withValues(alpha: 0.38),
                  Colors.white.withValues(alpha: 0.16),
                ],
        );

    final borderWidth = Theme.of(context).dividerTheme.thickness ?? 1.5;

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          // Soft ambient glass shadow
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.09),
            blurRadius: 32,
            spreadRadius: -4,
            offset: const Offset(0, 16),
          ),
          // Subtle rim highlight
          BoxShadow(
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: isDark ? 0.04 : 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            decoration: BoxDecoration(
              color: backgroundColor,
              gradient: backgroundColor == null ? effectiveGradient : null,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: defaultBorder,
                width: borderWidth,
              ),
            ),
            child: Stack(
              children: [
                // Top glossy specular reflection sheen
                if (showSpecularSheen)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 120,
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(borderRadius),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withValues(alpha: isDark ? 0.16 : 0.48),
                              Colors.white.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                // Main Content
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
  }
}
