import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/widgets/neumorphic_widgets.dart';
import '../../auth/presentation/auth_providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _ringController;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _scheduleNavigation();
  }

  void _scheduleNavigation() {
    Future.delayed(const Duration(milliseconds: 2300), () {
      _proceed();
    });
  }

  void _proceed() {
    if (!mounted || _navigated) return;
    _navigated = true;
    final currentUser = ref.read(currentUserProvider);
    final target = currentUser != null ? '/projects' : '/welcome';
    context.go(target);
  }

  @override
  void dispose() {
    _ringController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgDark = const Color(0xFF0F121A);
    final bgLight = const Color(0xFFE8EEF5);

    return Scaffold(
      backgroundColor: isDark ? bgDark : bgLight,
      body: GestureDetector(
        onTap: _proceed,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            // Ambient animated backdrop aura 1 (Top Right)
            Positioned(
              top: -100,
              right: -80,
              child: Container(
                width: 380,
                height: 380,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF0096FF).withValues(alpha: isDark ? 0.35 : 0.20),
                      Colors.transparent,
                    ],
                  ),
                ),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(begin: const Offset(0.85, 0.85), end: const Offset(1.15, 1.15), duration: 3200.ms),
            ),

            // Ambient animated backdrop aura 2 (Bottom Left)
            Positioned(
              bottom: -120,
              left: -80,
              child: Container(
                width: 360,
                height: 360,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF00D2FF).withValues(alpha: isDark ? 0.28 : 0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(begin: const Offset(1.1, 1.1), end: const Offset(0.9, 0.9), duration: 2800.ms),
            ),

            // Center Content
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),

                      // Logo Orbit Container
                      SizedBox(
                        width: 240,
                        height: 240,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer rotating synchronization ring
                            AnimatedBuilder(
                              animation: _ringController,
                              builder: (context, child) {
                                return Transform.rotate(
                                  angle: _ringController.value * 2 * math.pi,
                                  child: child,
                                );
                              },
                              child: Container(
                                width: 220,
                                height: 220,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF0096FF).withValues(alpha: isDark ? 0.25 : 0.20),
                                    width: 1.5,
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    Align(
                                      alignment: Alignment.topCenter,
                                      child: Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: const Color(0xFF00D2FF),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF00D2FF).withValues(alpha: 0.8),
                                              blurRadius: 8,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Align(
                                      alignment: Alignment.bottomCenter,
                                      child: Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: const Color(0xFF0077B6),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF0077B6).withValues(alpha: 0.6),
                                              blurRadius: 6,
                                              spreadRadius: 1,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Inner counter-rotating ring
                            AnimatedBuilder(
                              animation: _ringController,
                              builder: (context, child) {
                                return Transform.rotate(
                                  angle: -_ringController.value * 2 * math.pi,
                                  child: child,
                                );
                              },
                              child: Container(
                                width: 175,
                                height: 175,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF00D2FF).withValues(alpha: isDark ? 0.18 : 0.15),
                                    width: 1.2,
                                  ),
                                ),
                              ),
                            ),

                            // Tactile Neumorphic Pedestal
                            NeumorphicContainer(
                              shape: BoxShape.circle,
                              width: 145,
                              height: 145,
                              depth: 1.4,
                              accentColor: const Color(0xFF0096FF),
                              glowWithAccent: true,
                              child: Center(
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  padding: const EdgeInsets.all(12),
                                  child: Image.asset(
                                    'assets/images/logo.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            )
                                .animate()
                                .scale(
                                  begin: const Offset(0.2, 0.2),
                                  end: const Offset(1.0, 1.0),
                                  duration: 900.ms,
                                  curve: Curves.elasticOut,
                                )
                                .shimmer(
                                  duration: 1200.ms,
                                  delay: 500.ms,
                                  color: Colors.white.withValues(alpha: 0.45),
                                ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // App Title Branding
                      Text(
                        'SyncFlow',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 600.ms, delay: 350.ms)
                          .slideY(begin: 0.3, end: 0, duration: 500.ms, curve: Curves.easeOutCubic),

                      const SizedBox(height: 8),

                      // Tagline
                      Text(
                        'SEAMLESS WORKSPACE COLLABORATION',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.8,
                          color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 600.ms, delay: 550.ms)
                          .slideY(begin: 0.2, end: 0, duration: 500.ms, curve: Curves.easeOutCubic),

                      const SizedBox(height: 38),

                      // Tactile Loading Pill Indicator
                      NeumorphicContainer(
                        isPressed: true,
                        borderRadius: 16,
                        width: 140,
                        height: 6,
                        depth: 0.6,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              width: 50,
                              height: 6,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF0077B6), Color(0xFF00D2FF)],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00D2FF).withValues(alpha: 0.8),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            )
                                .animate(onPlay: (c) => c.repeat())
                                .moveX(begin: -50, end: 140, duration: 1300.ms, curve: Curves.easeInOut),
                          ),
                        ),
                      ).animate().fadeIn(duration: 500.ms, delay: 700.ms),

                      const SizedBox(height: 30),
                    ],
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
