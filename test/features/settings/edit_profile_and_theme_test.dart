import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sync_flow/core/theme/app_theme.dart';
import 'package:sync_flow/features/auth/domain/user_model.dart';
import 'package:sync_flow/features/auth/presentation/auth_providers.dart';
import 'package:sync_flow/features/settings/presentation/edit_profile_screen.dart';
import 'package:sync_flow/features/settings/presentation/settings_screen.dart';

void main() {
  setUpAll(() {
    HttpOverrides.global = _TestHttpOverrides();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Edit Profile & Accent Color Tests', () {
    test('AccentColorNotifier updates and defaults to Electric Blue', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(accentColorProvider), AccentColorNotifier.defaultAccentColor);

      await container.read(accentColorProvider.notifier).setAccentColor(const Color(0xFF10B981));
      expect(container.read(accentColorProvider), const Color(0xFF10B981));
    });

    test('CurrentUserNotifier updateProfile saves name, email and role title', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(currentUserProvider.notifier).setUser(
            AppUser(
              id: 'test-id',
              email: 'alex@syncflow.dev',
              fullName: 'Alex Rivera',
              roleTitle: 'Architect',
              createdAt: DateTime.now(),
            ),
          );

      await container.read(currentUserProvider.notifier).updateProfile(
            fullName: 'Alex Updated',
            email: 'alex.new@syncflow.dev',
            roleTitle: 'Lead Designer',
            avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
          );

      final user = container.read(currentUserProvider);
      expect(user?.fullName, 'Alex Updated');
      expect(user?.email, 'alex.new@syncflow.dev');
      expect(user?.roleTitle, 'Lead Designer');
      expect(user?.avatarUrl, contains('unsplash'));
    });

    testWidgets('EditProfileScreen renders form fields and save button', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(currentUserProvider.notifier).setUser(
            AppUser(
              id: 'test-id',
              email: 'member@syncflow.dev',
              fullName: 'Test User',
              roleTitle: 'Developer',
              createdAt: DateTime.now(),
            ),
          );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.buildDarkTheme(AccentColorNotifier.defaultAccentColor),
            home: const EditProfileScreen(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Edit Profile'), findsOneWidget);
      expect(find.text('OR CHOOSE A PRESET AVATAR'), findsOneWidget);
      expect(find.text('PERSONAL DETAILS'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
      expect(find.text('Change Photo'), findsOneWidget);
    });

    testWidgets('SettingsScreen shows Edit Profile action and Buttons & Lines Color options',
        (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(currentUserProvider.notifier).setUser(
            AppUser(
              id: 'test-id',
              email: 'member@syncflow.dev',
              fullName: 'Demo Member',
              roleTitle: 'Developer',
              createdAt: DateTime.now(),
            ),
          );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.buildDarkTheme(AccentColorNotifier.defaultAccentColor),
            home: const SettingsScreen(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 500));

      // Check edit profile entry point
      expect(find.text('Edit Profile'), findsOneWidget);

      // Scroll to Buttons & Lines section and check items
      await tester.ensureVisible(find.text('Buttons & Lines Color'));
      await tester.pumpAndSettle();

      expect(find.text('Buttons & Lines Color'), findsOneWidget);
      expect(find.text('LIVE PREVIEW: BUTTONS & LINES'), findsOneWidget);
      expect(find.text('Button'), findsOneWidget);
      expect(find.text('Outline'), findsOneWidget);

      // Tap Outline to switch style
      await tester.ensureVisible(find.text('Outline'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Outline'));
      await tester.pumpAndSettle();
      expect(container.read(buttonStyleProvider), AppButtonStyle.outlined);

      // Tap Button to switch back to filled
      await tester.ensureVisible(find.text('Button'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Button'));
      await tester.pumpAndSettle();
      expect(container.read(buttonStyleProvider), AppButtonStyle.filled);
    });
  });
}

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _MockHttpClient();
  }
}

class _MockHttpClient implements HttpClient {
  @override
  dynamic noSuchMethod(Invocation invocation) => _MockHttpClientRequest();
}

class _MockHttpClientRequest implements HttpClientRequest {
  @override
  dynamic noSuchMethod(Invocation invocation) => _MockHttpClientResponse();
}

class _MockHttpClientResponse implements HttpClientResponse {
  static final _kTransparentImage = <int>[
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
    0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
    0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
    0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
  ];

  @override
  int get statusCode => 200;

  @override
  int get contentLength => _kTransparentImage.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(void Function(List<int>)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    return Stream<List<int>>.fromIterable([_kTransparentImage]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
