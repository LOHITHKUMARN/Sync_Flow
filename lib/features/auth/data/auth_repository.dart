import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../domain/user_model.dart';

abstract class AuthRepository {
  Stream<AppUser?> get authStateChanges;
  AppUser? get currentUser;
  Future<AppUser> signIn({required String email, required String password});
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String fullName,
  });
  Future<void> signOut();
}

class SupabaseAuthRepository implements AuthRepository {
  final sb.SupabaseClient _client;
  final _controller = StreamController<AppUser?>.broadcast();

  SupabaseAuthRepository(this._client) {
    _client.auth.onAuthStateChange.listen((data) {
      final user = data.session?.user;
      if (user != null) {
        _controller.add(AppUser(
          id: user.id,
          email: user.email ?? '',
          fullName: user.userMetadata?['full_name'] as String? ?? 'Team Member',
          roleTitle: 'Product Lead',
          createdAt: DateTime.tryParse(user.createdAt) ?? DateTime.now(),
        ));
      } else {
        _controller.add(null);
      }
    });
  }

  @override
  Stream<AppUser?> get authStateChanges => _controller.stream;

  @override
  AppUser? get currentUser {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    return AppUser(
      id: user.id,
      email: user.email ?? '',
      fullName: user.userMetadata?['full_name'] as String? ?? 'Team Member',
      roleTitle: 'Product Lead',
      createdAt: DateTime.tryParse(user.createdAt) ?? DateTime.now(),
    );
  }

  @override
  Future<AppUser> signIn({required String email, required String password}) async {
    final res = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    final user = res.user!;
    return AppUser(
      id: user.id,
      email: user.email ?? '',
      fullName: user.userMetadata?['full_name'] as String? ?? 'Team Member',
      roleTitle: 'Product Lead',
      createdAt: DateTime.tryParse(user.createdAt) ?? DateTime.now(),
    );
  }

  @override
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final res = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );
    final user = res.user!;
    return AppUser(
      id: user.id,
      email: user.email ?? '',
      fullName: fullName,
      roleTitle: 'Product Lead',
      createdAt: DateTime.tryParse(user.createdAt) ?? DateTime.now(),
    );
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}

/// Fallback / Demo Auth Repository for instant verification without network block
class MockAuthRepository implements AuthRepository {
  final _controller = StreamController<AppUser?>.broadcast();
  AppUser? _user;

  MockAuthRepository({AppUser? initialUser}) {
    _user = initialUser;
  }

  void setCurrentUser(AppUser? user) {
    _user = user;
    _controller.add(user);
  }

  @override
  Stream<AppUser?> get authStateChanges => _controller.stream;

  @override
  AppUser? get currentUser => _user;

  @override
  Future<AppUser> signIn({required String email, required String password}) async {
    await Future.delayed(const Duration(milliseconds: 600));
    _user = AppUser(
      id: 'demo-user-001',
      email: email,
      fullName: email.split('@').first.replaceAll('.', ' ').toUpperCase(),
      roleTitle: 'Product Manager',
      createdAt: DateTime.now(),
    );
    _controller.add(_user);
    return _user!;
  }

  @override
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    _user = AppUser(
      id: 'demo-user-${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      fullName: fullName,
      roleTitle: 'Member',
      createdAt: DateTime.now(),
    );
    _controller.add(_user);
    return _user!;
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _user = null;
    _controller.add(null);
  }
}
