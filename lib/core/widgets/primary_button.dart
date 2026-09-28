import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// 3D Liquid Glass Primary Button inspired by curved liquid crystal optics.
/// Features:
/// - Stadium pill shape with 3D crystal glass lens body
/// - Clean specular curved glint reflection line along the upper rim
/// - Inset sunken circular lens for icons
/// - Inherits the app's clean obsidian / white design without unnatural rainbow colors
class PrimaryButton extends ConsumerStatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool? isOutlined;
  final Color? color;
  final EdgeInsetsGeometry? padding;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.isOutlined,
    this.color,
    this.padding,
  });

  @override
  ConsumerState<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends ConsumerState<PrimaryButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themePrimary = Theme.of(context).colorScheme.primary;
    final effectiveColor = widget.color ?? themePrimary;
    final effectivePadding = widget.padding ?? const EdgeInsets.symmetric(horizontal: 18, vertical: 12);

    final preferredStyle = ref.watch(buttonStyleProvider);
    final actuallyOutlined = widget.isOutlined ?? (preferredStyle == AppButtonStyle.outlined);

    if (actuallyOutlined) {
      return AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: effectiveColor.withValues(alpha: isDark ? 0.10 : 0.05),
            border: Border.all(
              color: effectiveColor,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTapDown: widget.onPressed != null ? (_) => setState(() => _isPressed = true) : null,
              onTapUp: widget.onPressed != null ? (_) => setState(() => _isPressed = false) : null,
              onTapCancel: widget.onPressed != null ? () => setState(() => _isPressed = false) : null,
              onTap: widget.isLoading ? null : widget.onPressed,
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: effectivePadding,
                child: _buildChild(context, effectiveColor, isDark),
              ),
            ),
          ),
        ),
      );
    }

    // 3D Liquid Crystal Glass Pill
    return AnimatedScale(
      scale: _isPressed ? 0.96 : 1.0,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutCubic,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          // Layer 1: Natural Depth Shadow (No artificial rainbow colors)
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.10),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: effectiveColor.withValues(alpha: isDark ? 0.22 : 0.12),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                // Layer 2: 3D Crystal Lens Body (Translucent obsidian with subtle base tint)
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? [
                          const Color(0xFF282C3C).withValues(alpha: 0.95), // Upper specular obsidian
                          const Color(0xFF161924).withValues(alpha: 0.98), // Core obsidian
                          const Color(0xFF0F1118).withValues(alpha: 0.98), // Deep base
                        ]
                      : [
                          Colors.white.withValues(alpha: 0.98),
                          const Color(0xFFF3F5FA),
                          const Color(0xFFE7ECF4),
                        ],
                  stops: const [0.0, 0.50, 1.0],
                ),
                // Layer 3: Specular Rim Border
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.25)
                      : Colors.black.withValues(alpha: 0.14),
                  width: 1.1,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTapDown: widget.onPressed != null ? (_) => setState(() => _isPressed = true) : null,
                  onTapUp: widget.onPressed != null ? (_) => setState(() => _isPressed = false) : null,
                  onTapCancel: widget.onPressed != null ? () => setState(() => _isPressed = false) : null,
                  onTap: widget.isLoading ? null : widget.onPressed,
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Layer 4: Top Specular Glint (Simulates overhead studio light reflection on curved glass)
                      Positioned(
                        top: 0,
                        left: 12,
                        right: 12,
                        child: Container(
                          height: 1.5,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(1),
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0.0),
                                Colors.white.withValues(alpha: isDark ? 0.70 : 0.85),
                                Colors.white.withValues(alpha: isDark ? 0.85 : 0.95),
                                Colors.white.withValues(alpha: isDark ? 0.70 : 0.85),
                                Colors.white.withValues(alpha: 0.0),
                              ],
                              stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
                            ),
                          ),
                        ),
                      ),

                      // Layer 5: Child Content
                      Padding(
                        padding: effectivePadding,
                        child: _buildChild(
                          context,
                          isDark ? Colors.white : const Color(0xFF09090B),
                          isDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChild(BuildContext context, Color textColor, bool isDark) {
    if (widget.isLoading) {
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(textColor),
        ),
      );
    }

    if (widget.icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Inset circular sunken lens for icon (Reference: "Icon button")
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  (isDark ? Colors.white : Colors.black).withValues(alpha: isDark ? 0.16 : 0.08),
                  (isDark ? Colors.black : Colors.white).withValues(alpha: 0.35),
                ],
              ),
              border: Border.all(
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.20),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.05),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Center(
              child: Icon(widget.icon, size: 13, color: textColor),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              widget.label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: textColor,
                letterSpacing: -0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    return Text(
      widget.label,
      textAlign: TextAlign.center,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: textColor,
        letterSpacing: -0.2,
      ),
    );
  }
}
