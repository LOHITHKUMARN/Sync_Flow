import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'core/config/env_config.dart';
import 'core/config/shared_prefs_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Pre-load SharedPreferences synchronously for instant auth & theme restoration
  final prefs = await SharedPreferences.getInstance();

  // Initialize Supabase if live credentials are provided
  if (EnvConfig.hasLiveSupabaseConfig) {
    // ignore: deprecated_member_use
    await Supabase.initialize(
      url: EnvConfig.defaultSupabaseUrl,
      // ignore: deprecated_member_use
      anonKey: EnvConfig.defaultSupabaseAnonKey,
    );
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const SyncFlowApp(),
    ),
  );
}
