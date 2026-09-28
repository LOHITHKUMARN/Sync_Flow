import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../data/auth_repository.dart';
import '../domain/user_model.dart';
import '../../../core/config/env_config.dart';
import '../../../core/config/shared_prefs_provider.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (EnvConfig.hasLiveSupabaseConfig) {
    return SupabaseAuthRepository(sb.Supabase.instance.client);
  }
  return MockAuthRepository();
});

final authStateProvider = StreamProvider<AppUser?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges;
});

const _kSessionUserIdKey = 'syncflow_session_user_id';
const _kSessionEmailKey = 'syncflow_session_email';
const _kSessionFullNameKey = 'syncflow_session_fullname';
const _kSessionRoleKey = 'syncflow_session_roletitle';
const _kSessionAvatarKey = 'syncflow_session_avatarurl';
const _kSessionIsLoggedInKey = 'syncflow_session_is_logged_in';

class CurrentUserNotifier extends Notifier<AppUser?> {
  @override
  AppUser? build() {
    // 1. Check live auth repository
    final baseUser = ref.watch(authRepositoryProvider).currentUser;
    if (baseUser != null) {
      _persistSession(baseUser);
      return baseUser;
    }

    // 2. Check synchronous SharedPreferences for active saved session
    try {
      final prefs = ref.watch(sharedPreferencesProvider);
      final isLoggedIn = prefs.getBool(_kSessionIsLoggedInKey) ?? false;
      if (isLoggedIn) {
        final id = prefs.getString(_kSessionUserIdKey);
        final email = prefs.getString(_kSessionEmailKey);
        final name = prefs.getString(_kSessionFullNameKey);
        final role = prefs.getString(_kSessionRoleKey);
        final avatar = prefs.getString(_kSessionAvatarKey);

        if (id != null && id.isNotEmpty && email != null && email.isNotEmpty) {
          final restoredUser = AppUser(
            id: id,
            email: email,
            fullName: (name != null && name.isNotEmpty) ? name : 'Alex Rivera',
            roleTitle: (role != null && role.isNotEmpty) ? role : 'Product Lead',
            avatarUrl: avatar,
            createdAt: DateTime.now(),
          );

          // Synchronize mock repository if in mock mode
          final repo = ref.read(authRepositoryProvider);
          if (repo is MockAuthRepository) {
            repo.setCurrentUser(restoredUser);
          }

          return restoredUser;
        }
      }
    } catch (_) {}

    return null;
  }

  void setUser(AppUser? user) {
    state = user;
    if (user != null) {
      _persistSession(user);
      final repo = ref.read(authRepositoryProvider);
      if (repo is MockAuthRepository) {
        repo.setCurrentUser(user);
      }
    } else {
      _clearSession();
    }
  }

  void _persistSession(AppUser user) {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      prefs.setBool(_kSessionIsLoggedInKey, true);
      prefs.setString(_kSessionUserIdKey, user.id);
      prefs.setString(_kSessionEmailKey, user.email);
      prefs.setString(_kSessionFullNameKey, user.fullName);
      prefs.setString(_kSessionRoleKey, user.roleTitle);
      if (user.avatarUrl != null && user.avatarUrl!.isNotEmpty) {
        prefs.setString(_kSessionAvatarKey, user.avatarUrl!);
      } else {
        prefs.remove(_kSessionAvatarKey);
      }
    } catch (_) {}
  }

  void _clearSession() {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      prefs.setBool(_kSessionIsLoggedInKey, false);
      prefs.remove(_kSessionUserIdKey);
      prefs.remove(_kSessionEmailKey);
      prefs.remove(_kSessionFullNameKey);
      prefs.remove(_kSessionRoleKey);
      prefs.remove(_kSessionAvatarKey);
    } catch (_) {}
  }

  Future<void> updateProfile({
    required String fullName,
    String? email,
    required String roleTitle,
    String? avatarUrl,
  }) async {
    final current = state;
    if (current == null) return;

    final updated = current.copyWith(
      fullName: fullName.trim(),
      email: (email != null && email.trim().isNotEmpty) ? email.trim() : current.email,
      roleTitle: roleTitle.trim(),
      avatarUrl: (avatarUrl == null || avatarUrl.trim().isEmpty) ? null : avatarUrl.trim(),
    );

    state = updated;
    _persistSession(updated);

    if (EnvConfig.hasLiveSupabaseConfig) {
      try {
        await sb.Supabase.instance.client.auth.updateUser(
          sb.UserAttributes(
            email: updated.email,
            data: {
              'full_name': updated.fullName,
              'role_title': updated.roleTitle,
              if (updated.avatarUrl != null) 'avatar_url': updated.avatarUrl,
            },
          ),
        );
      } catch (_) {}
    }
  }
}

final currentUserProvider = NotifierProvider<CurrentUserNotifier, AppUser?>(CurrentUserNotifier.new);

class AuthNotifier extends Notifier<AsyncValue<AppUser?>> {
  @override
  AsyncValue<AppUser?> build() {
    final current = ref.watch(currentUserProvider);
    return AsyncValue.data(current ?? ref.watch(authRepositoryProvider).currentUser);
  }

  Future<void> signIn(String email, String password) async {
    final repo = ref.read(authRepositoryProvider);
    state = const AsyncValue.loading();
    try {
      final user = await repo.signIn(email: email, password: password);
      ref.read(currentUserProvider.notifier).setUser(user);
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> signUp(String email, String password, String fullName) async {
    final repo = ref.read(authRepositoryProvider);
    state = const AsyncValue.loading();
    try {
      final user = await repo.signUp(email: email, password: password, fullName: fullName);
      ref.read(currentUserProvider.notifier).setUser(user);
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> signOut() async {
    final repo = ref.read(authRepositoryProvider);
    state = const AsyncValue.loading();
    await repo.signOut();
    ref.read(currentUserProvider.notifier).setUser(null);
    state = const AsyncValue.data(null);
  }
}

final authNotifierProvider = NotifierProvider<AuthNotifier, AsyncValue<AppUser?>>(AuthNotifier.new);
