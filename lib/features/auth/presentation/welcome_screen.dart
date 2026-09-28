import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import 'widgets/glossy_3d_icon_tile.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: Stack(
        children: [
          // Background ambient gradient glow
          Positioned(
            top: -120,
            right: -80,
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    primaryColor.withAlpha(isDark ? 45 : 25),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    primaryColor.withAlpha(isDark ? 35 : 18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Main scrollable content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),

                      // Floating 3D Icon Collage
                      SizedBox(
                        height: 220,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Ambient blur center
                            Container(
                              width: 180,
                              height: 180,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    primaryColor.withAlpha(isDark ? 30 : 15),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                            // Top-left Kanban tile
                            Positioned(
                              top: 12,
                              left: 28,
                              child: const Glossy3DIconTile(
                                type: Icon3DType.kanban,
                                size: 58,
                                rotationDegrees: -12,
                                animateFloat: true,
                                floatOffset: -4,
                                floatDuration: Duration(milliseconds: 2800),
                              )
                                  .animate()
                                  .fadeIn(duration: 500.ms, delay: 100.ms)
                                  .scale(begin: const Offset(0.7, 0.7)),
                            ),
                            // Top-right Comments tile
                            Positioned(
                              top: 20,
                              right: 32,
                              child: const Glossy3DIconTile(
                                type: Icon3DType.comments,
                                size: 52,
                                rotationDegrees: 14,
                                animateFloat: true,
                                floatOffset: 4,
                                floatDuration: Duration(milliseconds: 3200),
                              )
                                  .animate()
                                  .fadeIn(duration: 500.ms, delay: 200.ms)
                                  .scale(begin: const Offset(0.7, 0.7)),
                            ),
                            // Center primary Sync tile
                            Positioned(
                              child: const Glossy3DIconTile(
                                type: Icon3DType.sync,
                                size: 84,
                                rotationDegrees: -4,
                                animateFloat: true,
                                floatOffset: 5,
                                floatDuration: Duration(milliseconds: 2400),
                              )
                                  .animate()
                                  .fadeIn(duration: 600.ms)
                                  .scale(begin: const Offset(0.6, 0.6)),
                            ),
                            // Bottom-left Notifications tile
                            Positioned(
                              bottom: 12,
                              left: 44,
                              child: const Glossy3DIconTile(
                                type: Icon3DType.notifications,
                                size: 50,
                                rotationDegrees: 10,
                                animateFloat: true,
                                floatOffset: 3,
                                floatDuration: Duration(milliseconds: 2600),
                              )
                                  .animate()
                                  .fadeIn(duration: 500.ms, delay: 300.ms)
                                  .scale(begin: const Offset(0.7, 0.7)),
                            ),
                            // Bottom-right Checklist tile
                            Positioned(
                              bottom: 16,
                              right: 38,
                              child: const Glossy3DIconTile(
                                type: Icon3DType.checklist,
                                size: 62,
                                rotationDegrees: -8,
                                animateFloat: true,
                                floatOffset: -4,
                                floatDuration: Duration(milliseconds: 3000),
                              )
                                  .animate()
                                  .fadeIn(duration: 500.ms, delay: 250.ms)
                                  .scale(begin: const Offset(0.7, 0.7)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Brand Logo & Title
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white : const Color(0xFF09090B),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: (isDark ? Colors.white : Colors.black)
                                      .withAlpha(isDark ? 30 : 20),
                                  blurRadius: 12,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.sync_alt_rounded,
                              size: 24,
                              color: isDark ? Colors.black : Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'SyncFlow',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.15, end: 0),
                      const SizedBox(height: 12),

                      // Tagline
                      Text(
                        'Real-time collaborative workspace for teams',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? const Color(0xFFA1A1AA)
                              : const Color(0xFF52525B),
                          height: 1.4,
                        ),
                      ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
                      const SizedBox(height: 40),

                      // "Get Started" Primary Button
                      ElevatedButton(
                        onPressed: () => context.go('/register'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: ThemeData.estimateBrightnessForColor(primaryColor) == Brightness.dark
                              ? Colors.white
                              : const Color(0xFF09090B),
                          minimumSize: const Size.fromHeight(56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                          shadowColor: primaryColor.withAlpha(80),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Get started',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_rounded, size: 20),
                          ],
                        ),
                      ).animate().fadeIn(duration: 400.ms, delay: 200.ms).slideY(begin: 0.1, end: 0),
                      const SizedBox(height: 16),

                      // "I already have an account" Secondary Link
                      Center(
                        child: TextButton(
                          onPressed: () => context.go('/login'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            minimumSize: const Size(48, 48),
                          ),
                          child: Text(
                            'I already have an account',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? const Color(0xFFA1A1AA)
                                  : const Color(0xFF52525B),
                            ),
                          ),
                        ),
                      ).animate().fadeIn(duration: 400.ms, delay: 300.ms),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Theme mode toggle in top-right corner (layered on top for hit testing)
          Positioned(
            top: 16,
            right: 16,
            child: SafeArea(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF18181B).withAlpha(200)
                      : Colors.white.withAlpha(220),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(isDark ? 30 : 10),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                  icon: Icon(
                    isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                    size: 20,
                    color: isDark ? Colors.white : const Color(0xFF09090B),
                  ),
                  tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                  onPressed: () => ref.read(themeModeProvider.notifier).toggleTheme(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
