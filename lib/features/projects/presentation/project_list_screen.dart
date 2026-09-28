import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../workspaces/presentation/workspace_providers.dart';
import '../../workspaces/presentation/workspace_switcher_sheet.dart';
import '../../notifications/presentation/widgets/notification_bell_button.dart';
import '../../sync/presentation/widgets/sync_status_badge.dart';
import 'create_project_dialog.dart';
import 'project_providers.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../core/widgets/neumorphic_widgets.dart';

class ProjectListScreen extends ConsumerWidget {
  const ProjectListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeWs = ref.watch(activeWorkspaceProvider);
    final projectsAsync = ref.watch(projectsNotifierProvider);
    final currentUser = ref.watch(currentUserProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final buttonBgColor = isDark ? Colors.white : const Color(0xFF09090B);
    final buttonTextColor = isDark ? const Color(0xFF09090B) : Colors.white;
    final badgeBgColor = isDark ? const Color(0xFF09090B) : Colors.white;
    final badgeIconColor = isDark ? Colors.white : const Color(0xFF09090B);

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 16,
        // Fluid Frosted Liquid Glass Bar Background
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? [
                          const Color(0xFF141722).withValues(alpha: 0.78),
                          const Color(0xFF0C0E14).withValues(alpha: 0.55),
                        ]
                      : [
                          Colors.white.withValues(alpha: 0.88),
                          Colors.white.withValues(alpha: 0.65),
                        ],
                ),
                border: Border(
                  bottom: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.10)
                        : Colors.black.withValues(alpha: 0.08),
                    width: 1.0,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Liquid Glass Workspace Capsule
        title: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              builder: (_) => const WorkspaceSwitcherSheet(),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        Colors.white.withValues(alpha: 0.13),
                        Colors.white.withValues(alpha: 0.03),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.90),
                        Colors.white.withValues(alpha: 0.50),
                      ],
              ),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.18)
                    : Colors.white.withValues(alpha: 0.85),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.35)
                      : const Color(0xFFA0ADC0).withValues(alpha: 0.25),
                  offset: const Offset(0, 2),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : const Color(0xFF09090B)).withValues(alpha: isDark ? 0.12 : 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.15)
                          : Colors.black.withValues(alpha: 0.08),
                      width: 0.8,
                    ),
                  ),
                  child: Icon(
                    Icons.domain_rounded,
                    size: 15,
                    color: isDark ? Colors.white : const Color(0xFF09090B),
                  ),
                ),
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: (MediaQuery.sizeOf(context).width - 170).clamp(50.0, 180.0),
                  ),
                  child: Text(
                    activeWs?.name ?? 'SyncFlow',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ],
            ),
          ),
        ),
        // Liquid Glass Actions Capsule
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        Colors.white.withValues(alpha: 0.12),
                        Colors.white.withValues(alpha: 0.03),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.90),
                        Colors.white.withValues(alpha: 0.50),
                      ],
              ),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.18)
                    : Colors.white.withValues(alpha: 0.85),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.35)
                      : const Color(0xFFA0ADC0).withValues(alpha: 0.25),
                  offset: const Offset(0, 2),
                  blurRadius: 6,
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SyncStatusBadge(compact: true),
                SizedBox(width: 3),
                NotificationBellButton(),
              ],
            ),
          ),
          const SizedBox(width: 14),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 96),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Modern Neumorphic Welcome Banner / Stats Card
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                // Modern Satin-Finish Convex Gradient
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          const Color(0xFF1C2029), // Luminous graphite-slate highlight
                          const Color(0xFF101217), // Velvety deep obsidian base
                        ]
                      : [
                          const Color(0xFFFFFFFF),
                          const Color(0xFFE6EDF7),
                        ],
                ),
                // Modern 4-Point Specular & Deep Neumorphic Shadows
                boxShadow: [
                  // 1. Razor-sharp Specular Top-Left Chamfer Highlight
                  BoxShadow(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.14)
                        : Colors.white.withValues(alpha: 0.95),
                    offset: const Offset(-1.5, -1.5),
                    blurRadius: 2.5,
                    spreadRadius: 0,
                  ),
                  // 2. Soft Ambient Top-Left Bounce Glow
                  BoxShadow(
                    color: isDark
                        ? const Color(0xFF2D3546).withValues(alpha: 0.65)
                        : Colors.white,
                    offset: const Offset(-7, -7),
                    blurRadius: 18,
                    spreadRadius: 0,
                  ),
                  // 3. Deep Obsidian Bottom-Right Cast Shadow
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.95)
                        : const Color(0xFFA1B0C5).withValues(alpha: 0.55),
                    offset: const Offset(9, 10),
                    blurRadius: 22,
                    spreadRadius: 0,
                  ),
                  // 4. Contact Ambient Shadow
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.40)
                        : const Color(0xFFCBD5E1).withValues(alpha: 0.35),
                    offset: const Offset(2, 3),
                    blurRadius: 6,
                    spreadRadius: 0,
                  ),
                ],
                // Chamfered Micro-Border
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.09)
                      : Colors.white.withValues(alpha: 0.90),
                  width: 1.2,
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            // Neumorphic Inset / Concave "LIVE WORKSPACE" Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: isDark
                                      ? [
                                          const Color(0xFF0F1013),
                                          const Color(0xFF181A1F),
                                        ]
                                      : [
                                          const Color(0xFFDCE2EC),
                                          const Color(0xFFF1F5FA),
                                        ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: isDark
                                        ? Colors.black.withValues(alpha: 0.65)
                                        : const Color(0xFFA3B1C6).withValues(alpha: 0.55),
                                    offset: const Offset(2, 2),
                                    blurRadius: 4,
                                  ),
                                  BoxShadow(
                                    color: isDark
                                        ? const Color(0xFF282C34).withValues(alpha: 0.45)
                                        : Colors.white,
                                    offset: const Offset(-1, -1),
                                    blurRadius: 3,
                                  ),
                                ],
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.05)
                                      : Colors.white.withValues(alpha: 0.65),
                                  width: 1.0,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF10B981),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'LIVE WORKSPACE',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: isDark ? const Color(0xFFE4E4E7) : const Color(0xFF334155),
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // OG Neumorphic Sliding Theme Toggle Switch (Extra Compact Micro Size)
                            GestureDetector(
                              onTap: () => ref.read(themeModeProvider.notifier).toggleTheme(),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                width: 78,
                                height: 28,
                                padding: const EdgeInsets.all(2.5),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(100),
                                  // Sunken / Inset Trench Background
                                  color: isDark ? const Color(0xFF1E222C) : const Color(0xFFE2E7F0),
                                  boxShadow: [
                                    // Inset / Sunken groove shadow simulation
                                    BoxShadow(
                                      color: isDark
                                          ? Colors.black.withValues(alpha: 0.85)
                                          : const Color(0xFFA6B3C6).withValues(alpha: 0.65),
                                      offset: const Offset(1.5, 1.5),
                                      blurRadius: 2.5,
                                    ),
                                    BoxShadow(
                                      color: isDark
                                          ? const Color(0xFF2C3240).withValues(alpha: 0.40)
                                          : Colors.white,
                                      offset: const Offset(-1, -1),
                                      blurRadius: 1.5,
                                    ),
                                  ],
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.05)
                                        : Colors.white.withValues(alpha: 0.70),
                                    width: 1.0,
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    // Text Label positioned inside the track
                                    AnimatedPositioned(
                                      duration: const Duration(milliseconds: 250),
                                      curve: Curves.easeInOut,
                                      left: isDark ? 7 : null,
                                      right: isDark ? null : 7,
                                      top: 1,
                                      bottom: 1,
                                      child: Center(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            Text(
                                              isDark ? 'DARK' : 'LIGHT',
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 6.8,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 0.5,
                                                height: 1.05,
                                                color: isDark
                                                    ? const Color(0xFF6B778D)
                                                    : const Color(0xFF8A99AD),
                                              ),
                                            ),
                                            Text(
                                              'MODE',
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 6.8,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 0.5,
                                                height: 1.05,
                                                color: isDark
                                                    ? const Color(0xFF6B778D)
                                                    : const Color(0xFF8A99AD),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    // Raised Tactile Neumorphic Sliding Knob
                                    AnimatedAlign(
                                      duration: const Duration(milliseconds: 250),
                                      curve: Curves.easeInOut,
                                      alignment: isDark ? Alignment.centerRight : Alignment.centerLeft,
                                      child: Container(
                                        width: 23,
                                        height: 23,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: isDark
                                                ? [
                                                    const Color(0xFF3B4354),
                                                    const Color(0xFF282E3B),
                                                  ]
                                                : [
                                                    Colors.white,
                                                    const Color(0xFFEDF2F8),
                                                  ],
                                          ),
                                          boxShadow: [
                                            // Raised dual shadows
                                            BoxShadow(
                                              color: isDark
                                                  ? const Color(0xFF4C566C).withValues(alpha: 0.70)
                                                  : Colors.white,
                                              offset: const Offset(-1.5, -1.5),
                                              blurRadius: 3,
                                            ),
                                            BoxShadow(
                                              color: isDark
                                                  ? Colors.black.withValues(alpha: 0.80)
                                                  : const Color(0xFFA0ADC0).withValues(alpha: 0.60),
                                              offset: const Offset(2, 2),
                                              blurRadius: 4,
                                            ),
                                          ],
                                          border: Border.all(
                                            color: isDark
                                                ? Colors.white.withValues(alpha: 0.08)
                                                : Colors.white,
                                            width: 0.8,
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: Icon(
                                          isDark
                                              ? Icons.bedtime_outlined
                                              : Icons.wb_sunny_outlined,
                                          size: 11,
                                          color: isDark
                                              ? const Color(0xFF9BA8B8)
                                              : const Color(0xFF8E9DAF),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Welcome, ${currentUser?.fullName.split(' ').first ?? 'Team Member'}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Track team progress, organize tasks across Kanban boards, and manage sprints in real-time.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            height: 1.45,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 350.ms).slideY(begin: -0.1, end: 0),
            const SizedBox(height: 28),

            // Projects Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Projects',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                // Capsule "New Project" Button (Prominent & Comfortable Size)
                InkWell(
                  onTap: () => CreateProjectDialog.show(context),
                  borderRadius: BorderRadius.circular(100),
                  child: Container(
                    padding: const EdgeInsets.only(left: 16, right: 6, top: 6, bottom: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      color: buttonBgColor,
                      boxShadow: [
                        BoxShadow(
                          color: (isDark ? Colors.white : Colors.black).withValues(alpha: isDark ? 0.20 : 0.25),
                          offset: const Offset(0, 3.5),
                          blurRadius: 10,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'New Project',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14.0,
                            fontWeight: FontWeight.w700,
                            color: buttonTextColor,
                            letterSpacing: 0.15,
                          ),
                        ),
                        const SizedBox(width: 9),
                        // Circular Badge on the Right
                        Container(
                          width: 27,
                          height: 27,
                          decoration: BoxDecoration(
                            color: badgeBgColor,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.add_rounded,
                            size: 16,
                            color: badgeIconColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Projects Grid / List
            projectsAsync.when(
              data: (projects) {
                if (projects.isEmpty) {
                  return NeumorphicContainer(
                    borderRadius: 24,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 38),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Recessed Neumorphic Icon Socket
                          NeumorphicContainer(
                            isPressed: true,
                            width: 68,
                            height: 68,
                            borderRadius: 20,
                            child: Center(
                              child: Icon(
                                Icons.folder_open_rounded,
                                size: 34,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Title
                          Text(
                            'No projects in this workspace yet',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Description
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 300),
                            child: Text(
                              'Create your first project to start tracking tasks and sprints.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                height: 1.45,
                                fontWeight: FontWeight.w500,
                                color: isDark ? const Color(0xFF8E95A5) : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                          const SizedBox(height: 26),
                          // Tactile Neumorphic Button
                          NeumorphicButton(
                            borderRadius: 20,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            onPressed: () => CreateProjectDialog.show(context),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                NeumorphicContainer(
                                  isPressed: true,
                                  shape: BoxShape.circle,
                                  width: 26,
                                  height: 26,
                                  child: Center(
                                    child: Icon(
                                      Icons.add_rounded,
                                      size: 15,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Create First Project',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth > 800 ? 3 : (constraints.maxWidth > 520 ? 2 : 1);

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 18,
                        childAspectRatio: crossAxisCount == 1 ? 1.38 : 1.45,
                      ),
                      itemCount: projects.length,
                      itemBuilder: (context, index) {
                        final project = projects[index];

                        return InkWell(
                          onTap: () {
                            ref.read(activeProjectProvider.notifier).setProject(project);
                            context.go('/projects/${project.id}/kanban');
                          },
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              // Modern Satin-Finish Convex Gradient
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: isDark
                                    ? [
                                        const Color(0xFF1E222D), // Luminous graphite-slate highlight
                                        const Color(0xFF101218), // Velvety deep obsidian base
                                      ]
                                    : [
                                        const Color(0xFFFFFFFF),
                                        const Color(0xFFE8EEF8),
                                      ],
                              ),
                              // Modern 4-Point Specular & Deep Neumorphic Shadows
                              boxShadow: [
                                // 1. Razor-sharp Specular Top-Left Chamfer Highlight
                                BoxShadow(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.14)
                                      : Colors.white.withValues(alpha: 0.95),
                                  offset: const Offset(-1.5, -1.5),
                                  blurRadius: 2.5,
                                  spreadRadius: 0,
                                ),
                                // 2. Soft Ambient Top-Left Bounce Glow
                                BoxShadow(
                                  color: isDark
                                      ? const Color(0xFF2D3546).withValues(alpha: 0.65)
                                      : Colors.white,
                                  offset: const Offset(-7, -7),
                                  blurRadius: 18,
                                  spreadRadius: 0,
                                ),
                                // 3. Deep Obsidian Bottom-Right Cast Shadow
                                BoxShadow(
                                  color: isDark
                                      ? Colors.black.withValues(alpha: 0.95)
                                      : const Color(0xFFA1B0C5).withValues(alpha: 0.55),
                                  offset: const Offset(9, 10),
                                  blurRadius: 22,
                                  spreadRadius: 0,
                                ),
                                // 4. Contact Ambient Shadow
                                BoxShadow(
                                  color: isDark
                                      ? Colors.black.withValues(alpha: 0.40)
                                      : const Color(0xFFCBD5E1).withValues(alpha: 0.35),
                                  offset: const Offset(2, 3),
                                  blurRadius: 6,
                                  spreadRadius: 0,
                                ),
                              ],
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.09)
                                    : Colors.white.withValues(alpha: 0.90),
                                width: 1.2,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Header: Modern Tactile Icon Socket + Inset Task Badge
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Modern Extruded Icon Socket with Radiant Accent
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(14),
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: isDark
                                              ? [
                                                  const Color(0xFF272C3A),
                                                  const Color(0xFF14161F),
                                                ]
                                              : [
                                                  Colors.white,
                                                  const Color(0xFFE2E8F0),
                                                ],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: isDark
                                                ? const Color(0xFF383E4C).withValues(alpha: 0.60)
                                                : Colors.white,
                                            offset: const Offset(-2, -2),
                                            blurRadius: 5,
                                          ),
                                          BoxShadow(
                                            color: isDark
                                                ? Colors.black.withValues(alpha: 0.70)
                                                : const Color(0xFFA3B1C6).withValues(alpha: 0.45),
                                            offset: const Offset(3, 3),
                                            blurRadius: 6,
                                          ),
                                          // Ambient Accent Glow
                                          BoxShadow(
                                            color: (isDark ? const Color(0xFF38BDF8) : const Color(0xFF2563EB)).withValues(alpha: 0.15),
                                            offset: const Offset(0, 2),
                                            blurRadius: 8,
                                          ),
                                        ],
                                        border: Border.all(
                                          color: isDark
                                              ? Colors.white.withValues(alpha: 0.10)
                                              : Colors.white,
                                          width: 1.0,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.dashboard_customize_rounded,
                                        size: 19,
                                        color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF2563EB),
                                      ),
                                    ),

                                    // Neumorphic Inset / Recessed Task Count Pill with Status Indicator
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: isDark
                                              ? [
                                                  const Color(0xFF0C0E13),
                                                  const Color(0xFF171A23),
                                                ]
                                              : [
                                                  const Color(0xFFDCE2EC),
                                                  const Color(0xFFF1F5FA),
                                                ],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: isDark
                                                ? Colors.black.withValues(alpha: 0.70)
                                                : const Color(0xFFA3B1C6).withValues(alpha: 0.55),
                                            offset: const Offset(2, 2),
                                            blurRadius: 4,
                                          ),
                                          BoxShadow(
                                            color: isDark
                                                ? const Color(0xFF282C34).withValues(alpha: 0.45)
                                                : Colors.white,
                                            offset: const Offset(-1, -1),
                                            blurRadius: 3,
                                          ),
                                        ],
                                        border: Border.all(
                                          color: isDark
                                              ? Colors.white.withValues(alpha: 0.05)
                                              : Colors.white.withValues(alpha: 0.65),
                                          width: 1.0,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 6,
                                            height: 6,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF10B981),
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color(0xFF10B981).withValues(alpha: 0.60),
                                                  blurRadius: 4,
                                                  spreadRadius: 1,
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '${project.taskCount} tasks',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                // Project Name & Description
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      project.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.2,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      project.description ?? 'No description provided.',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        height: 1.35,
                                        fontWeight: FontWeight.w500,
                                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),

                                // Modern Neumorphic Sculpted Groove with Radiant Liquid Fill
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'PROGRESS',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.8,
                                            color: isDark ? const Color(0xFF828C9B) : const Color(0xFF64748B),
                                          ),
                                        ),
                                        Text(
                                          '${(project.progressPercentage * 100).toInt()}%',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF2563EB),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    // Sculpted Architectural Groove Trench
                                    Container(
                                      height: 8,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: isDark
                                              ? [
                                                  const Color(0xFF090A0E),
                                                  const Color(0xFF141720),
                                                ]
                                              : [
                                                  const Color(0xFFCCD4E0),
                                                  const Color(0xFFE4EBF4),
                                                ],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: isDark
                                                ? Colors.black.withValues(alpha: 0.85)
                                                : const Color(0xFF94A3B8).withValues(alpha: 0.50),
                                            offset: const Offset(1, 1),
                                            blurRadius: 2,
                                          ),
                                          BoxShadow(
                                            color: isDark
                                                ? const Color(0xFF2E333E).withValues(alpha: 0.35)
                                                : Colors.white,
                                            offset: const Offset(-1, -1),
                                            blurRadius: 1.5,
                                          ),
                                        ],
                                      ),
                                      alignment: Alignment.centerLeft,
                                      child: LayoutBuilder(
                                        builder: (context, barConstraints) {
                                          final fillWidth = barConstraints.maxWidth * project.progressPercentage.clamp(0.0, 1.0);
                                          if (fillWidth <= 0) return const SizedBox.shrink();
                                          return Container(
                                            width: fillWidth,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(10),
                                              gradient: LinearGradient(
                                                begin: Alignment.centerLeft,
                                                end: Alignment.centerRight,
                                                colors: isDark
                                                    ? [
                                                        const Color(0xFF38BDF8), // Electric Cyan
                                                        const Color(0xFF6366F1), // Radiant Indigo
                                                      ]
                                                    : [
                                                        const Color(0xFF2563EB),
                                                        const Color(0xFF4F46E5),
                                                      ],
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: (isDark ? const Color(0xFF38BDF8) : const Color(0xFF2563EB)).withValues(alpha: 0.50),
                                                  offset: const Offset(0, 1),
                                                  blurRadius: 8,
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ).animate().fadeIn(delay: (index * 80).ms).slideY(begin: 0.1, end: 0);
                      },
                    );
                  },
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => Center(child: Text('Error loading projects: $e')),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 0),
    );
  }
}
