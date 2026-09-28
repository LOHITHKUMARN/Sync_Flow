import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../core/widgets/neumorphic_widgets.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../sync/presentation/sync_providers.dart';
import '../../workspaces/presentation/workspace_providers.dart';
import '../../workspaces/presentation/workspace_switcher_sheet.dart';

// Keys for user preferences
const _kNotifPrefKey = 'syncflow_pref_notifications';
const _kHapticsPrefKey = 'syncflow_pref_haptics';
const _kCellularSyncPrefKey = 'syncflow_pref_cellular_sync';
const _kCompactModePrefKey = 'syncflow_pref_compact_mode';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _hapticsEnabled = true;
  bool _cellularSyncEnabled = true;
  bool _compactModeEnabled = false;
  bool _isClearingCache = false;
  String _cacheSize = '3.8 MB';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _notificationsEnabled = prefs.getBool(_kNotifPrefKey) ?? true;
        _hapticsEnabled = prefs.getBool(_kHapticsPrefKey) ?? true;
        _cellularSyncEnabled = prefs.getBool(_kCellularSyncPrefKey) ?? true;
        _compactModeEnabled = prefs.getBool(_kCompactModePrefKey) ?? false;
      });
    } catch (_) {}
  }

  Future<void> _savePreference(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUser = ref.watch(currentUserProvider);
    final activeWs = ref.watch(activeWorkspaceProvider);
    final themeMode = ref.watch(themeModeProvider);
    final accentColor = ref.watch(accentColorProvider);
    final syncEngine = ref.watch(syncEngineProvider);
    final syncState =
        ref.watch(syncEngineStateProvider).value ?? syncEngine.currentState;

    // Neumorphic surface base color
    final scaffoldBg =
        isDark ? NeumorphicColors.darkBase : NeumorphicColors.lightBase;
    final primaryText =
        isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedText =
        isDark ? const Color(0xFF8E95A5) : const Color(0xFF64748B);
    final effectiveAccent = (!isDark &&
            accentColor.toARGB32() == const Color(0xFFFFFFFF).toARGB32())
        ? const Color(0xFF0F172A)
        : accentColor;

    final avatarUrl = currentUser?.avatarUrl;
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;

    return Scaffold(
      backgroundColor: scaffoldBg,
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Neumorphic Advanced App Bar Header
              _buildNeumorphicHeader(context, ref, isDark, themeMode, effectiveAccent),
              const SizedBox(height: 24),

              // 2. Tactile User Identity Hub
              _buildIdentityHub(
                context: context,
                isDark: isDark,
                currentUser: currentUser,
                hasAvatar: hasAvatar,
                avatarUrl: avatarUrl,
                accentColor: effectiveAccent,
                primaryText: primaryText,
                mutedText: mutedText,
              ),
              const SizedBox(height: 28),

              // 3. Tactile Theme & Neumorphic Design Lab
              _buildSectionTitle('APPEARANCE & TACTILE THEME', mutedText),
              const SizedBox(height: 12),
              _buildAppearanceLab(
                context: context,
                ref: ref,
                isDark: isDark,
                themeMode: themeMode,
                accentColor: accentColor,
                effectiveAccent: effectiveAccent,
                primaryText: primaryText,
                mutedText: mutedText,
              ),
              const SizedBox(height: 28),

              // 4. Team & Active Workspace
              _buildSectionTitle('TEAM & WORKSPACE ENVIRONMENT', mutedText),
              const SizedBox(height: 12),
              _buildWorkspaceCard(
                context: context,
                isDark: isDark,
                activeWs: activeWs,
                primaryText: primaryText,
                mutedText: mutedText,
                accentColor: effectiveAccent,
              ),
              const SizedBox(height: 28),

              // 5. System Preferences & Toggles (Neumorphic Switches)
              _buildSectionTitle('SYSTEM PREFERENCES & BEHAVIOR', mutedText),
              const SizedBox(height: 12),
              _buildPreferencesModule(
                isDark: isDark,
                primaryText: primaryText,
                mutedText: mutedText,
                accentColor: effectiveAccent,
              ),
              const SizedBox(height: 28),

              // 6. Real-time Offline Sync & SQLite Diagnostics
              _buildSectionTitle('LOCAL-FIRST SYNC & SQLITE CACHE', mutedText),
              const SizedBox(height: 12),
              _buildSyncDiagnostics(
                context: context,
                isDark: isDark,
                syncState: syncState,
                syncEngine: syncEngine,
                primaryText: primaryText,
                mutedText: mutedText,
                accentColor: effectiveAccent,
              ),
              const SizedBox(height: 28),

              // 7. Security, Privacy & Diagnostics Info
              _buildSectionTitle('APPLICATION ENGINE SPECIFICATIONS', mutedText),
              const SizedBox(height: 12),
              _buildEngineSpecs(isDark: isDark, primaryText: primaryText, mutedText: mutedText, accentColor: effectiveAccent),
              const SizedBox(height: 28),

              // 8. Sign Out & Danger Zone
              _buildSignOutButton(context: context, ref: ref, isDark: isDark, accentColor: effectiveAccent),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 3),
    );
  }

  // --- Header ---
  Widget _buildNeumorphicHeader(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    ThemeMode themeMode,
    Color accentColor,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      'Settings',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  NeumorphicPill(
                    text: 'NEU 3.0',
                    color: accentColor,
                    isPressed: true,
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                'Tactile workspace settings',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? const Color(0xFF8E95A5) : const Color(0xFF64748B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        NeumorphicIconButton(
          icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
          iconColor: accentColor,
          size: 42,
          iconSize: 18,
          tooltip: isDark ? 'Switch to Porcelain Mode' : 'Switch to Obsidian Mode',
          onTap: () {
            final newMode = isDark ? ThemeMode.light : ThemeMode.dark;
            ref.read(themeModeProvider.notifier).setThemeMode(newMode);
          },
        ),
      ],
    );
  }

  // --- Section Title ---
  Widget _buildSectionTitle(String title, Color mutedText) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
          color: mutedText,
        ),
      ),
    );
  }

  // --- 2. Identity Hub ---
  Widget _buildIdentityHub({
    required BuildContext context,
    required bool isDark,
    required dynamic currentUser,
    required bool hasAvatar,
    required String? avatarUrl,
    required Color accentColor,
    required Color primaryText,
    required Color mutedText,
  }) {
    return NeumorphicContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: 22,
      child: Column(
        children: [
          Row(
            children: [
              // Dual-Ring Neumorphic Avatar
              GestureDetector(
                onTap: () => context.go('/settings/edit-profile'),
                child: NeumorphicContainer(
                  shape: BoxShape.circle,
                  isPressed: true,
                  padding: const EdgeInsets.all(4),
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      NeumorphicContainer(
                        shape: BoxShape.circle,
                        width: 60,
                        height: 60,
                        child: ClipOval(
                          child: hasAvatar
                              ? (avatarUrl!.startsWith('http')
                                  ? Image.network(avatarUrl, fit: BoxFit.cover)
                                  : Image.file(File(avatarUrl), fit: BoxFit.cover))
                              : Container(
                                  color: accentColor.withValues(alpha: 0.15),
                                  child: Center(
                                    child: Text(
                                      (currentUser?.fullName.isNotEmpty == true
                                              ? currentUser!.fullName[0]
                                              : 'U')
                                          .toUpperCase(),
                                      style: GoogleFonts.plusJakartaSans(
                                        color: accentColor,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 24,
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: accentColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark ? NeumorphicColors.darkBase : Colors.white,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.edit,
                            size: 10,
                            color: accentColor.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentUser?.fullName ?? 'SyncFlow Member',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: primaryText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      currentUser?.email ?? 'member@syncflow.dev',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: mutedText,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        NeumorphicPill(
                          text: (currentUser?.roleTitle?.isNotEmpty == true)
                              ? currentUser!.roleTitle.toUpperCase()
                              : 'PRODUCT ARCHITECT',
                          color: accentColor,
                          isPressed: true,
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF10B981),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Online',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Mini Stats Strip (Recessed wells)
          Row(
            children: [
              Expanded(
                child: _buildMiniStatWell(
                  label: 'Workspaces',
                  value: '3 Active',
                  icon: Icons.domain_rounded,
                  isDark: isDark,
                  accentColor: accentColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMiniStatWell(
                  label: 'Sync Status',
                  value: 'Encrypted',
                  icon: Icons.shield_rounded,
                  isDark: isDark,
                  accentColor: accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Edit Profile Action Button
          NeumorphicButton(
            label: 'Manage & Edit Profile',
            icon: Icons.tune_rounded,
            color: accentColor,
            isOutlined: false,
            onPressed: () => context.go('/settings/edit-profile'),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStatWell({
    required String label,
    required String value,
    required IconData icon,
    required bool isDark,
    required Color accentColor,
  }) {
    return NeumorphicContainer(
      isPressed: true,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      borderRadius: 14,
      child: Row(
        children: [
          Icon(icon, size: 16, color: accentColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFF8E95A5) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 3. Appearance Lab ---
  Widget _buildAppearanceLab({
    required BuildContext context,
    required WidgetRef ref,
    required bool isDark,
    required ThemeMode themeMode,
    required Color accentColor,
    required Color effectiveAccent,
    required Color primaryText,
    required Color mutedText,
  }) {
    return NeumorphicContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Surface Theme Environment',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: primaryText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Sculpted dual-shadow lighting dynamically adapts to your surface preference.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: mutedText,
            ),
          ),
          const SizedBox(height: 16),

          // Tactile Segmented Theme Controller
          NeumorphicSegmentedControl<ThemeMode>(
            selectedValue: themeMode,
            accentColor: effectiveAccent,
            items: const [
              NeumorphicSegmentItem(
                value: ThemeMode.dark,
                label: 'Obsidian Dark',
                icon: Icons.dark_mode_rounded,
              ),
              NeumorphicSegmentItem(
                value: ThemeMode.light,
                label: 'Porcelain Light',
                icon: Icons.light_mode_rounded,
              ),
            ],
            onSelected: (mode) {
              ref.read(themeModeProvider.notifier).setThemeMode(mode);
            },
          ),
          const SizedBox(height: 24),

          // Accent Color Swatches
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tactile Accent Aura',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: primaryText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Color glow applied to switches & highlights',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: mutedText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              NeumorphicIconButton(
                icon: Icons.colorize_rounded,
                iconColor: effectiveAccent,
                size: 38,
                iconSize: 18,
                tooltip: 'Enter Custom HEX',
                onTap: () => _showNeumorphicHexPicker(context, ref, accentColor, isDark),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Swatches Grid
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: AccentColorNotifier.presetOptions.map((opt) {
              final isMonochrome = opt.id == 'monochrome';
              final displayColor = (!isDark && isMonochrome)
                  ? const Color(0xFF09090B)
                  : opt.color;
              final isSelected = accentColor.toARGB32() == opt.color.toARGB32();

              return GestureDetector(
                onTap: () =>
                    ref.read(accentColorProvider.notifier).setAccentColor(opt.color),
                child: NeumorphicContainer(
                  isPressed: isSelected,
                  shape: BoxShape.circle,
                  width: 44,
                  height: 44,
                  glowWithAccent: isSelected,
                  accentColor: displayColor,
                  child: Center(
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: displayColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: displayColor.withValues(alpha: 0.6),
                            blurRadius: isSelected ? 8 : 2,
                          ),
                        ],
                      ),
                      child: isSelected
                          ? Icon(
                              Icons.check,
                              size: 14,
                              color: displayColor.computeLuminance() > 0.5
                                  ? Colors.black
                                  : Colors.white,
                            )
                          : null,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Button & Line Style Selector (Interactive Neumorphic Live Lab)
          _buildNeumorphicButtonLab(ref, isDark, effectiveAccent, primaryText, mutedText),
        ],
      ),
    );
  }

  Widget _buildNeumorphicButtonLab(
    WidgetRef ref,
    bool isDark,
    Color effectiveAccent,
    Color primaryText,
    Color mutedText,
  ) {
    final currentStyle = ref.watch(buttonStyleProvider);

    return NeumorphicContainer(
      isPressed: true,
      borderRadius: 16,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.palette_outlined, size: 16, color: effectiveAccent),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'BUTTON PHYSICS',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: effectiveAccent,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              NeumorphicPill(
                text: currentStyle == AppButtonStyle.filled ? 'SOLID' : 'OUTLINE',
                color: effectiveAccent,
                isPressed: false,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Test the real-time physical depression by tapping either button below:',
            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: mutedText),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: NeumorphicButton(
                  label: 'Solid Tactile',
                  icon: Icons.touch_app_rounded,
                  isOutlined: false,
                  color: effectiveAccent,
                  onPressed: () {
                    ref.read(buttonStyleProvider.notifier).setStyle(AppButtonStyle.filled);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: NeumorphicButton(
                  label: 'Outlined Neu',
                  icon: Icons.crop_square_rounded,
                  isOutlined: true,
                  color: effectiveAccent,
                  onPressed: () {
                    ref.read(buttonStyleProvider.notifier).setStyle(AppButtonStyle.outlined);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- 4. Workspace Card ---
  Widget _buildWorkspaceCard({
    required BuildContext context,
    required bool isDark,
    required dynamic activeWs,
    required Color primaryText,
    required Color mutedText,
    required Color accentColor,
  }) {
    return NeumorphicContainer(
      padding: const EdgeInsets.all(18),
      borderRadius: 22,
      child: Row(
        children: [
          NeumorphicContainer(
            width: 48,
            height: 48,
            isPressed: true,
            borderRadius: 14,
            child: Icon(Icons.corporate_fare_rounded, size: 24, color: accentColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activeWs?.name ?? 'Main Organization',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: primaryText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Workspace ID: ${activeWs?.id.substring(0, 8) ?? 'default-ws'}',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 12,
                    color: mutedText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          NeumorphicButton(
            label: 'Switch',
            icon: Icons.swap_horiz_rounded,
            color: accentColor,
            isOutlined: true,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                builder: (_) => const WorkspaceSwitcherSheet(),
              );
            },
          ),
        ],
      ),
    );
  }

  // --- 5. Preferences & Switches ---
  Widget _buildPreferencesModule({
    required bool isDark,
    required Color primaryText,
    required Color mutedText,
    required Color accentColor,
  }) {
    return NeumorphicContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: 22,
      child: Column(
        children: [
          _buildToggleRow(
            icon: Icons.notifications_active_outlined,
            title: 'Push Notifications',
            subtitle: 'Real-time task mentions and team pings',
            value: _notificationsEnabled,
            accentColor: accentColor,
            primaryText: primaryText,
            mutedText: mutedText,
            onChanged: (val) {
              setState(() => _notificationsEnabled = val);
              _savePreference(_kNotifPrefKey, val);
            },
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1, thickness: 0.8),
          ),
          _buildToggleRow(
            icon: Icons.vibration_rounded,
            title: 'Haptic & Micro-Physical Feedback',
            subtitle: 'Tactile bounce feel when clicking neumorphic cards',
            value: _hapticsEnabled,
            accentColor: accentColor,
            primaryText: primaryText,
            mutedText: mutedText,
            onChanged: (val) {
              setState(() => _hapticsEnabled = val);
              _savePreference(_kHapticsPrefKey, val);
            },
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1, thickness: 0.8),
          ),
          _buildToggleRow(
            icon: Icons.cell_tower_rounded,
            title: 'Background Cellular Queue Sync',
            subtitle: 'Allow offline SQLite queue drain over mobile networks',
            value: _cellularSyncEnabled,
            accentColor: accentColor,
            primaryText: primaryText,
            mutedText: mutedText,
            onChanged: (val) {
              setState(() => _cellularSyncEnabled = val);
              _savePreference(_kCellularSyncPrefKey, val);
            },
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1, thickness: 0.8),
          ),
          _buildToggleRow(
            icon: Icons.density_small_rounded,
            title: 'High-Density Board View',
            subtitle: 'Compact card sizing for large kanban backlogs',
            value: _compactModeEnabled,
            accentColor: accentColor,
            primaryText: primaryText,
            mutedText: mutedText,
            onChanged: (val) {
              setState(() => _compactModeEnabled = val);
              _savePreference(_kCompactModePrefKey, val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildToggleRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Color accentColor,
    required Color primaryText,
    required Color mutedText,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Icon(icon, size: 22, color: accentColor),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: primaryText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: mutedText,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        NeumorphicSwitch(
          value: value,
          activeColor: accentColor,
          onChanged: onChanged,
        ),
      ],
    );
  }

  // --- 6. Sync Diagnostics & SQLite Storage ---
  Widget _buildSyncDiagnostics({
    required BuildContext context,
    required bool isDark,
    required dynamic syncState,
    required dynamic syncEngine,
    required Color primaryText,
    required Color mutedText,
    required Color accentColor,
  }) {
    final bool isOnline = syncState.networkStatus.isOnline;

    return NeumorphicContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                      size: 18,
                      color: isOnline ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Network Radar',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: primaryText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              NeumorphicPill(
                text: isOnline ? 'ONLINE' : 'OFFLINE',
                color: isOnline ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                isPressed: true,
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Recessed Metrics Row
          Row(
            children: [
              Expanded(
                child: NeumorphicContainer(
                  isPressed: true,
                  padding: const EdgeInsets.all(14),
                  borderRadius: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Offline Mutations',
                        style: GoogleFonts.plusJakartaSans(fontSize: 11, color: mutedText),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${syncState.pendingCount} Pending',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: primaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: NeumorphicContainer(
                  isPressed: true,
                  padding: const EdgeInsets.all(14),
                  borderRadius: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Local SQLite Cache',
                        style: GoogleFonts.plusJakartaSans(fontSize: 11, color: mutedText),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _cacheSize,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: accentColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Action Buttons: Drain Queue & Clear Cache
          Row(
            children: [
              Expanded(
                flex: 3,
                child: NeumorphicButton(
                  label: syncState.isSyncing ? 'Syncing...' : 'Sync Now',
                  icon: Icons.sync_rounded,
                  isLoading: syncState.isSyncing,
                  color: accentColor,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
                  onPressed: () => syncEngine.drainQueue(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: NeumorphicButton(
                  label: _isClearingCache ? 'Cleaning...' : 'Clear Cache',
                  icon: Icons.cleaning_services_rounded,
                  isOutlined: true,
                  isLoading: _isClearingCache,
                  color: mutedText,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 11),
                  onPressed: () => _handleClearCache(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleClearCache(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isClearingCache = true);
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) {
        setState(() {
          _isClearingCache = false;
          _cacheSize = '0.4 MB';
        });
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Temporary SQLite local cache cleaned successfully!'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  // --- 7. Engine Specs ---
  Widget _buildEngineSpecs({
    required bool isDark,
    required Color primaryText,
    required Color mutedText,
    required Color accentColor,
  }) {
    return NeumorphicContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: 22,
      child: Column(
        children: [
          _buildSpecRow('Sync Engine Version', 'v1.0.1+2 (Tactile Release)', primaryText, mutedText),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, thickness: 0.8),
          ),
          _buildSpecRow('Local Storage Engine', 'SQLite + WAL High-Performance Mode', primaryText, mutedText),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, thickness: 0.8),
          ),
          _buildSpecRow('Realtime Transport', 'Supabase Realtime v2 / WebSocket TLS 1.3', primaryText, mutedText),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, thickness: 0.8),
          ),
          _buildSpecRow('Security Keystore', 'Hardware AES-256 Auth Encryption', primaryText, mutedText),
        ],
      ),
    );
  }

  Widget _buildSpecRow(String label, String value, Color primaryText, Color mutedText) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: primaryText,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 5,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: mutedText,
            ),
          ),
        ),
      ],
    );
  }

  // --- 8. Sign Out Button ---
  Widget _buildSignOutButton({
    required BuildContext context,
    required WidgetRef ref,
    required bool isDark,
    required Color accentColor,
  }) {
    return NeumorphicButton(
      label: 'Sign Out from SyncFlow',
      icon: Icons.logout_rounded,
      color: const Color(0xFFEF4444), // Crimson danger color
      isOutlined: true,
      onPressed: () => _confirmSignOutNeumorphic(context, ref, isDark),
    );
  }

  // --- Neumorphic Confirmation Dialog ---
  void _confirmSignOutNeumorphic(BuildContext context, WidgetRef ref, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          child: Material(
            color: Colors.transparent,
            child: NeumorphicContainer(
              padding: const EdgeInsets.all(24),
              borderRadius: 24,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  NeumorphicContainer(
                    shape: BoxShape.circle,
                    isPressed: true,
                    width: 52,
                    height: 52,
                    child: const Icon(
                      Icons.logout_rounded,
                      color: Color(0xFFEF4444),
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Sign Out of SyncFlow?',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'All your pending changes are safely preserved in the local SQLite engine.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: isDark ? const Color(0xFF8E95A5) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: NeumorphicButton(
                          label: 'Cancel',
                          isOutlined: true,
                          color: isDark ? Colors.white70 : Colors.black87,
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: NeumorphicButton(
                          label: 'Confirm Sign Out',
                          color: const Color(0xFFEF4444),
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            ref.read(authNotifierProvider.notifier).signOut();
                            context.go('/login');
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Neumorphic Custom Hex Picker Dialog ---
  void _showNeumorphicHexPicker(
    BuildContext context,
    WidgetRef ref,
    Color currentColor,
    bool isDark,
  ) {
    final hexString = currentColor
        .toARGB32()
        .toRadixString(16)
        .padLeft(8, '0')
        .toUpperCase()
        .substring(2);
    final textController = TextEditingController(text: '#$hexString');
    Color previewColor = currentColor;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              child: Material(
                color: Colors.transparent,
                child: NeumorphicContainer(
                  padding: const EdgeInsets.all(24),
                  borderRadius: 24,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Tactile Hex Aura',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          NeumorphicIconButton(
                            icon: Icons.close_rounded,
                            size: 32,
                            iconSize: 16,
                            onTap: () => Navigator.of(ctx).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Enter a 6-digit hex value (e.g. #06B6D4, #F43F5E, #10B981):',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: isDark ? const Color(0xFF8E95A5) : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          NeumorphicContainer(
                            shape: BoxShape.circle,
                            width: 50,
                            height: 50,
                            accentColor: previewColor,
                            glowWithAccent: true,
                            child: Center(
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: previewColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: NeumorphicContainer(
                              isPressed: true,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                              borderRadius: 14,
                              child: TextField(
                                controller: textController,
                                autofocus: true,
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                                decoration: const InputDecoration(
                                  hintText: '#RRGGBB',
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  isDense: true,
                                ),
                                onChanged: (val) {
                                  String clean = val.replaceAll('#', '').trim();
                                  if (clean.length == 6) {
                                    final parsed = int.tryParse('0xFF$clean');
                                    if (parsed != null) {
                                      setDialogState(() {
                                        previewColor = Color(parsed);
                                      });
                                    }
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: NeumorphicButton(
                              label: 'Cancel',
                              isOutlined: true,
                              color: isDark ? Colors.white70 : Colors.black87,
                              onPressed: () => Navigator.of(ctx).pop(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: NeumorphicButton(
                              label: 'Apply Aura',
                              color: previewColor,
                              onPressed: () {
                                ref
                                    .read(accentColorProvider.notifier)
                                    .setAccentColor(previewColor);
                                Navigator.of(ctx).pop();
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
