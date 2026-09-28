import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../../features/projects/presentation/project_providers.dart';

class MainScaffoldShell extends ConsumerWidget {
  final Widget child;

  const MainScaffoldShell({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/settings')) {
      return 3;
    }
    if (location.startsWith('/activity')) {
      return 2;
    }
    if (location.contains('/kanban') || location == '/board') {
      return 1;
    }
    return 0; // Default to Projects
  }

  void _onItemTapped(int index, BuildContext context, WidgetRef ref) {
    switch (index) {
      case 0:
        context.go('/projects');
        break;
      case 1:
        final activeProject = ref.read(activeProjectProvider);
        final projectsAsync = ref.read(projectsNotifierProvider);
        final projects = projectsAsync.value ?? [];

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
    final selectedIndex = _calculateSelectedIndex(context);

    final navBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final navBorder = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final activeColor = isDark ? Colors.white : const Color(0xFF09090B);
    final inactiveColor = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: navBg,
          border: Border(
            top: BorderSide(color: navBorder, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 50 : 15),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavBarItem(
                  icon: Icons.grid_view_rounded,
                  label: 'Projects',
                  isSelected: selectedIndex == 0,
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                  isDark: isDark,
                  onTap: () => _onItemTapped(0, context, ref),
                ),
                _NavBarItem(
                  icon: Icons.view_kanban_rounded,
                  label: 'Board',
                  isSelected: selectedIndex == 1,
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                  isDark: isDark,
                  onTap: () => _onItemTapped(1, context, ref),
                ),
                _NavBarItem(
                  icon: Icons.sync_alt_rounded,
                  label: 'Activity',
                  isSelected: selectedIndex == 2,
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                  isDark: isDark,
                  onTap: () => _onItemTapped(2, context, ref),
                ),
                _NavBarItem(
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  isSelected: selectedIndex == 3,
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                  isDark: isDark,
                  onTap: () => _onItemTapped(3, context, ref),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final Color activeColor;
  final Color inactiveColor;
  final bool isDark;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.activeColor,
    required this.inactiveColor,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withAlpha(isDark ? 30 : 16)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? activeColor : inactiveColor,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
