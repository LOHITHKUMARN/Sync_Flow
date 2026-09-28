class EnvConfig {
  EnvConfig._();

  // You can set these via dart-define or override in settings:
  // flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
  static const String defaultSupabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const String defaultSupabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static bool get hasLiveSupabaseConfig =>
      defaultSupabaseUrl.isNotEmpty &&
      defaultSupabaseAnonKey.isNotEmpty &&
      !defaultSupabaseUrl.contains('your-project');
}
