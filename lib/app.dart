import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';

class SyncFlowApp extends ConsumerWidget {
  const SyncFlowApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    ThemeMode themeMode = ThemeMode.dark;
    try {
      themeMode = ref.watch(themeModeProvider);
    } catch (_) {
      themeMode = ThemeMode.dark;
    }

    Color accentColor = AccentColorNotifier.defaultAccentColor;
    try {
      accentColor = ref.watch(accentColorProvider);
    } catch (_) {
      accentColor = AccentColorNotifier.defaultAccentColor;
    }

    AppButtonStyle buttonStyle = AppButtonStyle.filled;
    try {
      buttonStyle = ref.watch(buttonStyleProvider);
    } catch (_) {
      buttonStyle = AppButtonStyle.filled;
    }

    return MaterialApp.router(
      title: 'SyncFlow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.buildLightTheme(accentColor, buttonStyle: buttonStyle),
      darkTheme: AppTheme.buildDarkTheme(accentColor, buttonStyle: buttonStyle),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
