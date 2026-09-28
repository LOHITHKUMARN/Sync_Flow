import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/shared_prefs_provider.dart';
import '../constants/app_colors.dart';

const _kThemePrefKey = 'syncflow_theme_mode';
const _kAccentColorPrefKey = 'syncflow_accent_color';

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    try {
      final prefs = ref.watch(sharedPreferencesProvider);
      final saved = prefs.getString(_kThemePrefKey);
      if (saved == 'light') return ThemeMode.light;
      if (saved == 'dark') return ThemeMode.dark;
    } catch (_) {}
    return ThemeMode.dark;
  }

  Future<void> toggleTheme() async {
    final newMode = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    state = newMode;
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setString(_kThemePrefKey, newMode == ThemeMode.light ? 'light' : 'dark');
    } catch (_) {}
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setString(_kThemePrefKey, mode == ThemeMode.light ? 'light' : 'dark');
    } catch (_) {}
  }
}

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

class AccentColorOption {
  final String id;
  final String name;
  final Color color;

  const AccentColorOption({
    required this.id,
    required this.name,
    required this.color,
  });
}

class AccentColorNotifier extends Notifier<Color> {
  static const Color defaultAccentColor = Color(0xFF3B82F6); // Electric Blue

  static const List<AccentColorOption> presetOptions = [
    AccentColorOption(id: 'blue', name: 'Electric Blue', color: Color(0xFF3B82F6)),
    AccentColorOption(id: 'cyan', name: 'Neon Cyan', color: Color(0xFF06B6D4)),
    AccentColorOption(id: 'emerald', name: 'Emerald', color: Color(0xFF10B981)),
    AccentColorOption(id: 'purple', name: 'Cyber Violet', color: Color(0xFF8B5CF6)),
    AccentColorOption(id: 'amber', name: 'Amber Glow', color: Color(0xFFF59E0B)),
    AccentColorOption(id: 'rose', name: 'Crimson Rose', color: Color(0xFFF43F5E)),
    AccentColorOption(id: 'monochrome', name: 'Crisp White', color: Color(0xFFFFFFFF)),
    AccentColorOption(id: 'gold', name: 'Solar Gold', color: Color(0xFFEAB308)),
  ];

  @override
  Color build() {
    try {
      final prefs = ref.watch(sharedPreferencesProvider);
      final value = prefs.getInt(_kAccentColorPrefKey);
      if (value != null) return Color(value);
    } catch (_) {}
    return defaultAccentColor;
  }

  Future<void> setAccentColor(Color color) async {
    state = color;
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setInt(_kAccentColorPrefKey, color.toARGB32());
    } catch (_) {}
  }
}

final accentColorProvider =
    NotifierProvider<AccentColorNotifier, Color>(AccentColorNotifier.new);

enum AppButtonStyle { filled, outlined }

const _kButtonStylePrefKey = 'syncflow_button_style';

class ButtonStyleNotifier extends Notifier<AppButtonStyle> {
  @override
  AppButtonStyle build() {
    try {
      final prefs = ref.watch(sharedPreferencesProvider);
      final saved = prefs.getString(_kButtonStylePrefKey);
      if (saved == 'outlined') return AppButtonStyle.outlined;
      if (saved == 'filled') return AppButtonStyle.filled;
    } catch (_) {}
    return AppButtonStyle.filled;
  }

  Future<void> setStyle(AppButtonStyle style) async {
    state = style;
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setString(
          _kButtonStylePrefKey, style == AppButtonStyle.outlined ? 'outlined' : 'filled');
    } catch (_) {}
  }
}

final buttonStyleProvider =
    NotifierProvider<ButtonStyleNotifier, AppButtonStyle>(ButtonStyleNotifier.new);

class AppTheme {
  AppTheme._();

  static ThemeData buildDarkTheme(Color accentColor, {AppButtonStyle buttonStyle = AppButtonStyle.filled}) {
    final textTheme = GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme);
    final onAccentColor = accentColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;
    final isOutlined = buttonStyle == AppButtonStyle.outlined;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBg,
      primaryColor: accentColor,
      colorScheme: ColorScheme.dark(
        primary: accentColor,
        onPrimary: onAccentColor,
        secondary: accentColor,
        surface: AppColors.darkCard,
        error: Colors.white,
        outline: accentColor.withValues(alpha: isOutlined ? 0.75 : 0.35),
        outlineVariant: accentColor.withValues(alpha: isOutlined ? 0.45 : 0.18),
      ),
      textTheme: textTheme.apply(
        bodyColor: AppColors.darkText,
        displayColor: AppColors.darkText,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkBg,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.darkText,
        ),
        iconTheme: const IconThemeData(color: AppColors.darkText),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: accentColor.withValues(alpha: isOutlined ? 0.70 : 0.25),
            width: isOutlined ? 1.8 : 1.0,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.plusJakartaSans(
          color: AppColors.darkTextMuted,
          fontSize: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: accentColor.withValues(alpha: isOutlined ? 0.70 : 0.25),
            width: isOutlined ? 1.8 : 1.0,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: accentColor.withValues(alpha: isOutlined ? 0.70 : 0.25),
            width: isOutlined ? 1.8 : 1.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accentColor, width: 2.0),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: accentColor.withValues(alpha: isOutlined ? 0.80 : 0.30),
            width: isOutlined ? 2.0 : 1.2,
          ),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          side: BorderSide(
            color: accentColor.withValues(alpha: isOutlined ? 0.80 : 0.30),
            width: isOutlined ? 2.0 : 1.2,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: isOutlined ? AppColors.darkCard : accentColor,
        foregroundColor: isOutlined ? accentColor : onAccentColor,
        elevation: isOutlined ? 0 : 4,
        focusElevation: isOutlined ? 0 : 4,
        hoverElevation: isOutlined ? 0 : 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: isOutlined
              ? BorderSide(color: accentColor, width: 2.0)
              : BorderSide.none,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: isOutlined
            ? ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: accentColor.withValues(alpha: 0.10),
                foregroundColor: accentColor,
                side: BorderSide(color: accentColor, width: 2.0),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              )
            : ElevatedButton.styleFrom(
                elevation: 2,
                backgroundColor: accentColor,
                foregroundColor: onAccentColor,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accentColor,
          backgroundColor: accentColor.withValues(alpha: 0.10),
          side: BorderSide(color: accentColor, width: 2.0),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: accentColor.withValues(alpha: isOutlined ? 0.70 : 0.28),
            width: isOutlined ? 1.5 : 1.0,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: accentColor.withValues(alpha: isOutlined ? 0.65 : 0.22),
        thickness: isOutlined ? 1.8 : 1.0,
      ),
    );
  }

  static ThemeData buildLightTheme(Color accentColor, {AppButtonStyle buttonStyle = AppButtonStyle.filled}) {
    // In light mode, map crisp white to crisp black for high contrast buttons & lines
    final effectiveAccent = (accentColor.toARGB32() == const Color(0xFFFFFFFF).toARGB32())
        ? const Color(0xFF09090B)
        : accentColor;

    final textTheme = GoogleFonts.plusJakartaSansTextTheme(ThemeData.light().textTheme);
    final onAccentColor = effectiveAccent.computeLuminance() > 0.5 ? Colors.black : Colors.white;
    final isOutlined = buttonStyle == AppButtonStyle.outlined;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBg,
      primaryColor: effectiveAccent,
      colorScheme: ColorScheme.light(
        primary: effectiveAccent,
        onPrimary: onAccentColor,
        secondary: effectiveAccent,
        surface: AppColors.lightCard,
        error: Colors.black,
        outline: effectiveAccent.withValues(alpha: isOutlined ? 0.75 : 0.35),
        outlineVariant: effectiveAccent.withValues(alpha: isOutlined ? 0.45 : 0.18),
      ),
      textTheme: textTheme.apply(
        bodyColor: AppColors.lightText,
        displayColor: AppColors.lightText,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightBg,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.lightText,
        ),
        iconTheme: const IconThemeData(color: AppColors.lightText),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: effectiveAccent.withValues(alpha: isOutlined ? 0.70 : 0.25),
            width: isOutlined ? 1.8 : 1.0,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.plusJakartaSans(
          color: AppColors.lightTextMuted,
          fontSize: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: effectiveAccent.withValues(alpha: isOutlined ? 0.70 : 0.25),
            width: isOutlined ? 1.8 : 1.0,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: effectiveAccent.withValues(alpha: isOutlined ? 0.70 : 0.25),
            width: isOutlined ? 1.8 : 1.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: effectiveAccent, width: 2.0),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.lightCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: effectiveAccent.withValues(alpha: isOutlined ? 0.80 : 0.28),
            width: isOutlined ? 2.0 : 1.2,
          ),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.lightCard,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          side: BorderSide(
            color: effectiveAccent.withValues(alpha: isOutlined ? 0.80 : 0.28),
            width: isOutlined ? 2.0 : 1.2,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: isOutlined ? AppColors.lightCard : effectiveAccent,
        foregroundColor: isOutlined ? effectiveAccent : onAccentColor,
        elevation: isOutlined ? 0 : 4,
        focusElevation: isOutlined ? 0 : 4,
        hoverElevation: isOutlined ? 0 : 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: isOutlined
              ? BorderSide(color: effectiveAccent, width: 2.0)
              : BorderSide.none,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: isOutlined
            ? ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: effectiveAccent.withValues(alpha: 0.08),
                foregroundColor: effectiveAccent,
                side: BorderSide(color: effectiveAccent, width: 2.0),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              )
            : ElevatedButton.styleFrom(
                elevation: 2,
                backgroundColor: effectiveAccent,
                foregroundColor: onAccentColor,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: effectiveAccent,
          backgroundColor: effectiveAccent.withValues(alpha: 0.06),
          side: BorderSide(color: effectiveAccent, width: 2.0),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: effectiveAccent.withValues(alpha: isOutlined ? 0.70 : 0.28),
            width: isOutlined ? 1.5 : 1.0,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: effectiveAccent.withValues(alpha: isOutlined ? 0.65 : 0.22),
        thickness: isOutlined ? 1.8 : 1.0,
      ),
    );
  }

  static ThemeData get darkTheme => buildDarkTheme(AccentColorNotifier.defaultAccentColor);
  static ThemeData get lightTheme => buildLightTheme(AccentColorNotifier.defaultAccentColor);
}
