import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../features/projects/presentation/project_providers.dart';

class AppBottomNavBar extends ConsumerWidget {
  final int currentIndex;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
  });

  void _onTap(int index, BuildContext context, WidgetRef ref) {
    if (index == currentIndex) return;
    HapticFeedback.lightImpact();

    switch (index) {
      case 0:
        context.go('/projects');
        break;
      case 1:
        final activeProject = ref.read(activeProjectProvider);
        final projects = ref.read(projectsNotifierProvider).value ?? [];
        if (activeProject != null) {
          context.go('/projects/${activeProject.id}/kanban');
        } else if (projects.isNotEmpty) {
          ref.read(activeProjectProvider.notifier).setProject(projects.first);
          context.go('/projects/${projects.first.id}/kanban');
        } else {
          context.go('/projects');
        }
        break;
      case 2:
        context.go('/activity');
        break;
      case 3:
        context.go('/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final items = const [
      _NavItemConfig(
        icon: Icons.grid_view_rounded,
        label: 'Projects',
      ),
      _NavItemConfig(
        icon: Icons.task_alt_rounded,
        label: 'Tasks',
      ),
      _NavItemConfig(
        icon: Icons.sync_alt_rounded,
        label: 'Activity',
      ),
      _NavItemConfig(
        icon: Icons.settings_outlined,
        label: 'Settings',
      ),
    ];

    // Full-Width Clean Liquid Glass Dock
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black.withValues(alpha: 0.40)
                : Colors.white.withValues(alpha: 0.40),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: 0.08),
                width: 1.0,
              ),
              bottom: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.04),
                width: 1.0,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(items.length, (index) {
                  final item = items[index];
                  final isSelected = index == currentIndex;
                  return _NavBarItem(
                    config: item,
                    isSelected: isSelected,
                    isDark: isDark,
                    onTap: () => _onTap(index, context, ref),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItemConfig {
  final IconData icon;
  final String label;

  const _NavItemConfig({
    required this.icon,
    required this.label,
  });
}

class _NavBarItem extends StatelessWidget {
  final _NavItemConfig config;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.config,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeTextColor = isDark ? Colors.white : const Color(0xFF09090B);
    final inactiveColor = isDark
        ? Colors.white.withValues(alpha: 0.50)
        : const Color(0xFF71717A);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: isSelected
              ? const EdgeInsets.symmetric(horizontal: 16, vertical: 8)
              : const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: isSelected
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  // Clean Translucent Glass Capsule (No cloudy grey or fuzzy glow)
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDark
                        ? [
                            Colors.white.withValues(alpha: 0.13),
                            Colors.white.withValues(alpha: 0.04),
                          ]
                        : [
                            Colors.black.withValues(alpha: 0.07),
                            Colors.black.withValues(alpha: 0.02),
                          ],
                  ),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.28)
                        : Colors.black.withValues(alpha: 0.14),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                )
              : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                config.icon,
                size: isSelected ? 18 : 22,
                color: isSelected ? activeTextColor : inactiveColor,
              ),
              if (isSelected) ...[
                const SizedBox(width: 7),
                Text(
                  config.label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: activeTextColor,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
