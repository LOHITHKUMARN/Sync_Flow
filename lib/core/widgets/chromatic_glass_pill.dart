import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 3D Liquid Glass Pill Button inspired by curved liquid crystal optics.
/// Features:
/// - Double-layered 3D glass lens body with clean obsidian / translucent glass
/// - Specular curved glint reflection line along the upper rim
/// - Inset sunken circular lens badge for icons
/// - Natural depth shadows without artificial neon color casts
/// - Inherits the app's clean dark / light aesthetic seamlessly
class ChromaticGlassPill extends StatefulWidget {
  final String? label;
  final IconData? icon;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isSelected;
  final Color? glowColor;
  final Color? secondaryGlowColor;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final bool showGlint;
  final TextStyle? textStyle;
  final bool isInsetIcon;
  final bool isCompact;

  const ChromaticGlassPill({
    super.key,
    this.label,
    this.icon,
    this.trailing,
    this.onTap,
    this.isSelected = true,
    this.glowColor,
    this.secondaryGlowColor,
    this.height,
    this.padding,
    this.showGlint = true,
    this.textStyle,
    this.isInsetIcon = true,
    this.isCompact = false,
  });

  @override
  State<ChromaticGlassPill> createState() => _ChromaticGlassPillState();
}

class _ChromaticGlassPillState extends State<ChromaticGlassPill> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = widget.isSelected;
    final isCompact = widget.isCompact;
    final scale = _isPressed ? 0.96 : 1.0;

    // Bigger, more comfortable default dimensions
    final effectivePadding = widget.padding ??
        EdgeInsets.symmetric(
          horizontal: isCompact ? 12 : 16,
          vertical: isCompact ? 8 : 10,
        );

    final lensSize = isCompact ? 24.0 : 28.0;
    final iconSize = isCompact ? 14.0 : 16.0;
    final iconGap = isCompact ? 7.0 : 8.0;

    // Clean neutral liquid glass colors inheriting the design system
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF09090B);
    final mutedTextColor = isDark
        ? Colors.white.withValues(alpha: 0.55)
        : const Color(0xFF71717A);

    return AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutCubic,
      child: GestureDetector(
        onTapDown: widget.onTap != null ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: widget.onTap != null ? (_) => setState(() => _isPressed = false) : null,
        onTapCancel: widget.onTap != null ? () => setState(() => _isPressed = false) : null,
        onTap: widget.onTap,
        child: Container(
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            // Layer 1: Natural 3D Glass Depth Shadow
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
                      blurRadius: isCompact ? 10 : 16,
                      offset: Offset(0, isCompact ? 3.5 : 5),
                    ),
                    BoxShadow(
                      color: (isDark ? Colors.white : Colors.black).withValues(alpha: isDark ? 0.05 : 0.03),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 1.5),
                    ),
                  ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding: effectivePadding,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  // Layer 2: 3D Crystal Lens Body (Inheriting clean obsidian / white glass)
                  gradient: isSelected
                      ? LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: isDark
                              ? [
                                  const Color(0xFF2B2F40).withValues(alpha: 0.96), // Upper specular obsidian
                                  const Color(0xFF171A26).withValues(alpha: 0.98), // Core obsidian
                                  const Color(0xFF0E1017).withValues(alpha: 0.98), // Deep base
                                ]
                              : [
                                  Colors.white.withValues(alpha: 0.98),
                                  const Color(0xFFF3F5FA),
                                  const Color(0xFFE5EAF2),
                                ],
                          stops: const [0.0, 0.48, 1.0],
                        )
                      : LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: isDark
                              ? [
                                  Colors.white.withValues(alpha: 0.07),
                                  Colors.white.withValues(alpha: 0.02),
                                ]
                              : [
                                  Colors.black.withValues(alpha: 0.05),
                                  Colors.black.withValues(alpha: 0.02),
                                ],
                        ),
                  // Layer 3: Specular Rim Border
                  border: Border.all(
                    color: isSelected
                        ? (isDark
                            ? Colors.white.withValues(alpha: 0.28)
                            : Colors.black.withValues(alpha: 0.15))
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.09)
                            : Colors.black.withValues(alpha: 0.06)),
                    width: isSelected ? 1.2 : 0.8,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // Layer 4: Top Specular Glint (Reflection line on curved glass lens)
                    if (widget.showGlint && isSelected)
                      Positioned(
                        top: 0,
                        left: 10,
                        right: 10,
                        child: Container(
                          height: 1.5,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(1),
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0.0),
                                Colors.white.withValues(alpha: isDark ? 0.75 : 0.85),
                                Colors.white.withValues(alpha: isDark ? 0.92 : 0.98),
                                Colors.white.withValues(alpha: isDark ? 0.75 : 0.85),
                                Colors.white.withValues(alpha: 0.0),
                              ],
                              stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
                            ),
                          ),
                        ),
                      ),

                    // Layer 5: Button Content (Inset circular lens for icon + Crisp text + Trailing chip)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Inset circular sunken glass lens badge (Reference: "Icon button")
                        if (widget.icon != null) ...[
                          if (widget.isInsetIcon)
                            Container(
                              width: lensSize,
                              height: lensSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: isSelected
                                      ? [
                                          (isDark ? Colors.white : Colors.black).withValues(alpha: isDark ? 0.18 : 0.09),
                                          (isDark ? Colors.black : Colors.white).withValues(alpha: 0.38),
                                        ]
                                      : [
                                          (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
                                          Colors.transparent,
                                        ],
                                ),
                                border: Border.all(
                                  color: isSelected
                                      ? (isDark
                                          ? Colors.white.withValues(alpha: 0.24)
                                          : Colors.black.withValues(alpha: 0.14))
                                      : (isDark
                                          ? Colors.white.withValues(alpha: 0.08)
                                          : Colors.black.withValues(alpha: 0.05)),
                                  width: 0.9,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.06),
                                          blurRadius: 4,
                                          offset: const Offset(0, 1),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Center(
                                child: Icon(
                                  widget.icon,
                                  size: iconSize,
                                  color: isSelected ? primaryTextColor : mutedTextColor,
                                ),
                              ),
                            )
                          else
                            Icon(
                              widget.icon,
                              size: iconSize,
                              color: isSelected ? primaryTextColor : mutedTextColor,
                            ),
                          if (widget.label != null) SizedBox(width: iconGap),
                        ],

                        // Label
                        if (widget.label != null)
                          Text(
                            widget.label!,
                            style: widget.textStyle ??
                                GoogleFonts.plusJakartaSans(
                                  fontSize: isCompact ? 12.5 : 13.5,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected ? primaryTextColor : mutedTextColor,
                                  letterSpacing: -0.2,
                                ),
                          ),

                        // Trailing element (e.g. badge count or clear chip)
                        if (widget.trailing != null) ...[
                          const SizedBox(width: 6),
                          widget.trailing!,
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
