import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Synchronous access to SharedPreferences across the entire application.
/// Initialized in main() before runApp and provided via ProviderScope override.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be initialized in main() and overridden in ProviderScope');
});
