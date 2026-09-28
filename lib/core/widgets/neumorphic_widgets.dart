import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Neumorphic color palette and surface lighting engine.
/// Advanced dual-directional lighting with realistic sun-angle physics.
class NeumorphicColors {
  NeumorphicColors._();

  // Dark Mode Surface & Shadows (Matte Obsidian)
  static const Color darkBase = Color(0xFF13161F);
  static const Color darkSurfaceTop = Color(0xFF181C27);
  static const Color darkSurfaceBottom = Color(0xFF0F121A);
  static const Color darkHighlight = Color(0x3D2B3347); // Light from top-left
  static const Color darkShadow = Color(0xD906070B); // Shadow to bottom-right
  static const Color darkPressedTop = Color(0xFF0B0D13);
  static const Color darkPressedBottom = Color(0xFF161923);
  static const Color darkRimBorder = Color(0x1FFFFFFF);

  // Light Mode Surface & Shadows (Porcelain Slate)
  static const Color lightBase = Color(0xFFE8EEF5);
  static const Color lightSurfaceTop = Color(0xFFF3F7FD);
  static const Color lightSurfaceBottom = Color(0xFFDFE6F1);
  static const Color lightHighlight = Color(0xFFFFFFFF); // Light from top-left
  static const Color lightShadow = Color(0x4098A6BA); // Shadow to bottom-right
  static const Color lightPressedTop = Color(0xFFD6DEEB);
  static const Color lightPressedBottom = Color(0xFFEDF2F9);
  static const Color lightRimBorder = Color(0x80FFFFFF);
}

/// Core Neumorphic Container supporting both extruded (convex/raised)
/// and sunken (concave/pressed) tactile states.
class NeumorphicContainer extends StatelessWidget {
  final Widget? child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final bool isPressed;
  final Color? accentColor;
  final bool glowWithAccent;
  final BoxShape shape;
  final VoidCallback? onTap;
  final Border? customBorder;
  final double depth;

  const NeumorphicContainer({
    super.key,
    this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius = 18,
    this.isPressed = false,
    this.accentColor,
    this.glowWithAccent = false,
    this.shape = BoxShape.rectangle,
    this.onTap,
    this.customBorder,
    this.depth = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final baseColor = isDark ? NeumorphicColors.darkBase : NeumorphicColors.lightBase;
    final topHighlight = isDark ? NeumorphicColors.darkHighlight : NeumorphicColors.lightHighlight;
    final bottomShadow = isDark ? NeumorphicColors.darkShadow : NeumorphicColors.lightShadow;
    final rimBorderColor = isDark ? NeumorphicColors.darkRimBorder : NeumorphicColors.lightRimBorder;

    final double d = depth.clamp(0.2, 3.0);
    final double shadowOffset = (isPressed ? 2.5 : 5.0) * d;
    final double blurRadius = (isPressed ? 5.0 : 10.0) * d;

    // Gradient calculation
    final Gradient surfaceGradient = isPressed
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [NeumorphicColors.darkPressedTop, NeumorphicColors.darkPressedBottom]
                : [NeumorphicColors.lightPressedTop, NeumorphicColors.lightPressedBottom],
          )
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [NeumorphicColors.darkSurfaceTop, NeumorphicColors.darkSurfaceBottom]
                : [NeumorphicColors.lightSurfaceTop, NeumorphicColors.lightSurfaceBottom],
          );

    List<BoxShadow> shadows = [];
    if (!isPressed) {
      // Extruded (Raised) Dual Shadows
      shadows = [
        BoxShadow(
          color: topHighlight,
          offset: Offset(-shadowOffset, -shadowOffset),
          blurRadius: blurRadius,
          spreadRadius: 0,
        ),
        BoxShadow(
          color: bottomShadow,
          offset: Offset(shadowOffset, shadowOffset),
          blurRadius: blurRadius,
          spreadRadius: 0,
        ),
        if (glowWithAccent && accentColor != null)
          BoxShadow(
            color: accentColor!.withValues(alpha: isDark ? 0.35 : 0.25),
            offset: const Offset(0, 4),
            blurRadius: 16 * d,
            spreadRadius: 1,
          ),
      ];
    } else {
      // Sunken (Pressed) Inner Depression simulation
      shadows = [
        BoxShadow(
          color: bottomShadow.withValues(alpha: isDark ? 0.5 : 0.35),
          offset: Offset(-shadowOffset * 0.7, -shadowOffset * 0.7),
          blurRadius: blurRadius * 0.8,
        ),
        BoxShadow(
          color: topHighlight.withValues(alpha: isDark ? 0.15 : 0.5),
          offset: Offset(shadowOffset * 0.7, shadowOffset * 0.7),
          blurRadius: blurRadius * 0.8,
        ),
      ];
    }

    Widget content = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: baseColor,
        shape: shape,
        borderRadius: shape == BoxShape.circle ? null : BorderRadius.circular(borderRadius),
        gradient: surfaceGradient,
        boxShadow: shadows,
        border: customBorder ??
            Border.all(
              color: glowWithAccent && accentColor != null
                  ? accentColor!.withValues(alpha: 0.6)
                  : rimBorderColor,
              width: 1.0,
            ),
      ),
      child: child,
    );

    if (onTap != null) {
      content = GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: content,
      );
    }

    return content;
  }
}

/// Interactive Tactile Neumorphic Button that physically sinks on touch.
class NeumorphicButton extends StatefulWidget {
  final Widget? child;
  final String? label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final double? width;
  final double? height;
  final double borderRadius;
  final Color? color;
  final bool isOutlined;
  final bool isLoading;
  final EdgeInsetsGeometry padding;

  const NeumorphicButton({
    super.key,
    this.child,
    this.label,
    this.icon,
    this.onPressed,
    this.width,
    this.height,
    this.borderRadius = 14,
    this.color,
    this.isOutlined = false,
    this.isLoading = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
  });

  @override
  State<NeumorphicButton> createState() => _NeumorphicButtonState();
}

class _NeumorphicButtonState extends State<NeumorphicButton> {
  bool _isDown = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveAccent = widget.color ??
        (isDark ? Colors.white : const Color(0xFF09090B));

    final bool isPressed = _isDown;

    return GestureDetector(
      onTapDown: widget.onPressed == null || widget.isLoading
          ? null
          : (_) => setState(() => _isDown = true),
      onTapUp: widget.onPressed == null || widget.isLoading
          ? null
          : (_) {
              setState(() => _isDown = false);
              widget.onPressed?.call();
            },
      onTapCancel: () {
        if (_isDown) setState(() => _isDown = false);
      },
      child: AnimatedScale(
        scale: _isDown ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: NeumorphicContainer(
          width: widget.width,
          height: widget.height,
          padding: widget.padding,
          borderRadius: widget.borderRadius,
          isPressed: isPressed,
          accentColor: effectiveAccent,
          glowWithAccent: !isDark && !widget.isOutlined,
          customBorder: widget.isOutlined
              ? Border.all(color: effectiveAccent, width: 1.6)
              : null,
          child: Center(
            child: widget.isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(effectiveAccent),
                    ),
                  )
                : widget.child ??
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(widget.icon, size: 18, color: effectiveAccent),
                          const SizedBox(width: 8),
                        ],
                        if (widget.label != null)
                          Flexible(
                            child: Text(
                              widget.label!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: effectiveAccent,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                      ],
                    ),
          ),
        ),
      ),
    );
  }
}

/// Advanced Tactile Neumorphic Switch with recessed track and extruded ceramic knob.
class NeumorphicSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? activeColor;

  const NeumorphicSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = activeColor ?? (isDark ? Colors.white : const Color(0xFF09090B));

    const double trackWidth = 56.0;
    const double trackHeight = 32.0;
    const double thumbSize = 24.0;
    const double thumbPadding = 4.0;

    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        width: trackWidth,
        height: trackHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(trackHeight / 2),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: value
                ? [
                    accent.withValues(alpha: isDark ? 0.40 : 0.28),
                    accent.withValues(alpha: isDark ? 0.20 : 0.12),
                  ]
                : isDark
                    ? [NeumorphicColors.darkPressedTop, NeumorphicColors.darkPressedBottom]
                    : [NeumorphicColors.lightPressedTop, NeumorphicColors.lightPressedBottom],
          ),
          border: Border.all(
            color: value
                ? accent.withValues(alpha: isDark ? 0.70 : 0.50)
                : (isDark ? NeumorphicColors.darkRimBorder : NeumorphicColors.lightRimBorder),
            width: 1.2,
          ),
          boxShadow: [
            // Sunken track inner shadow
            BoxShadow(
              color: (isDark ? Colors.black : const Color(0xFF98A6BA)).withValues(alpha: 0.45),
              offset: const Offset(2, 2),
              blurRadius: 4,
            ),
            if (value)
              BoxShadow(
                color: accent.withValues(alpha: 0.35),
                blurRadius: 10,
                spreadRadius: 1,
              ),
          ],
        ),
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutBack,
              left: value ? (trackWidth - thumbSize - thumbPadding) : thumbPadding,
              child: Container(
                width: thumbSize,
                height: thumbSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: value
                        ? [accent, accent]
                        : (isDark
                            ? [NeumorphicColors.darkSurfaceTop, NeumorphicColors.darkSurfaceBottom]
                            : [NeumorphicColors.lightSurfaceTop, NeumorphicColors.lightSurfaceBottom]),
                  ),
                  border: Border.all(
                    color: value
                        ? Colors.white.withValues(alpha: 0.6)
                        : (isDark ? Colors.white.withValues(alpha: 0.15) : Colors.white),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.25),
                      offset: const Offset(2, 2),
                      blurRadius: 4,
                    ),
                    BoxShadow(
                      color: (isDark ? const Color(0x3D2B3347) : Colors.white).withValues(alpha: 0.8),
                      offset: const Offset(-2, -2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: value ? 8 : 4,
                    height: value ? 8 : 4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: value
                          ? (accent.computeLuminance() > 0.5 ? Colors.black : Colors.white)
                          : (isDark ? Colors.white38 : Colors.black26),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Neumorphic Segmented Tab Switcher with recessed groove and extruded sliding pill.
class NeumorphicSegmentedControl<T> extends StatelessWidget {
  final T selectedValue;
  final List<NeumorphicSegmentItem<T>> items;
  final ValueChanged<T> onSelected;
  final Color? accentColor;

  const NeumorphicSegmentedControl({
    super.key,
    required this.selectedValue,
    required this.items,
    required this.onSelected,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = accentColor ?? (isDark ? Colors.white : const Color(0xFF09090B));

    return NeumorphicContainer(
      isPressed: true,
      borderRadius: 16,
      padding: const EdgeInsets.all(5),
      child: Row(
        children: items.map((item) {
          final isSelected = item.value == selectedValue;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelected(item.value),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: isSelected
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? [NeumorphicColors.darkSurfaceTop, NeumorphicColors.darkSurfaceBottom]
                              : [NeumorphicColors.lightSurfaceTop, NeumorphicColors.lightSurfaceBottom],
                        )
                      : null,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: isDark ? NeumorphicColors.darkHighlight : NeumorphicColors.lightHighlight,
                            offset: const Offset(-3, -3),
                            blurRadius: 6,
                          ),
                          BoxShadow(
                            color: isDark ? NeumorphicColors.darkShadow : NeumorphicColors.lightShadow,
                            offset: const Offset(3, 3),
                            blurRadius: 6,
                          ),
                        ]
                      : null,
                  border: isSelected
                      ? Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.15)
                              : Colors.white,
                          width: 1.0,
                        )
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      item.icon,
                      size: 16,
                      color: isSelected
                          ? accent
                          : (isDark ? const Color(0xFF8E8E93) : const Color(0xFF71717A)),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? (isDark ? Colors.white : const Color(0xFF09090B))
                              : (isDark ? const Color(0xFF8E8E93) : const Color(0xFF71717A)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class NeumorphicSegmentItem<T> {
  final T value;
  final String label;
  final IconData icon;

  const NeumorphicSegmentItem({
    required this.value,
    required this.label,
    required this.icon,
  });
}

/// Neumorphic Tactile Icon Button (squircle or circular).
class NeumorphicIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;
  final Color? iconColor;
  final bool isPressed;
  final BoxShape shape;
  final String? tooltip;

  const NeumorphicIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.size = 42,
    this.iconSize = 18,
    this.iconColor,
    this.isPressed = false,
    this.shape = BoxShape.circle,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = iconColor ?? (isDark ? Colors.white : const Color(0xFF09090B));

    Widget button = NeumorphicContainer(
      width: size,
      height: size,
      shape: shape,
      borderRadius: 12,
      isPressed: isPressed,
      onTap: onTap,
      child: Center(
        child: Icon(icon, size: iconSize, color: color),
      ),
    );

    if (tooltip != null) {
      button = Tooltip(message: tooltip!, child: button);
    }

    return button;
  }
}

/// Neumorphic Tactile Badge / Pill (e.g. for status, tags, micro counters).
class NeumorphicPill extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Color? color;
  final bool isPressed;
  final EdgeInsetsGeometry padding;

  const NeumorphicPill({
    super.key,
    required this.text,
    this.icon,
    this.color,
    this.isPressed = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = color ?? (isDark ? Colors.white : const Color(0xFF09090B));

    return NeumorphicContainer(
      isPressed: isPressed,
      borderRadius: 20,
      padding: padding,
      depth: 0.6,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: accent),
            const SizedBox(width: 5),
          ],
          Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}
