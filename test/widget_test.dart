import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sync_flow/app.dart';
import 'package:sync_flow/features/auth/data/auth_repository.dart';
import 'package:sync_flow/features/auth/domain/user_model.dart';
import 'package:sync_flow/features/auth/presentation/auth_providers.dart';

class TestAuthRepository extends MockAuthRepository {
  @override
  AppUser? get currentUser => AppUser(
        id: 'test-user',
        email: 'test@syncflow.dev',
        fullName: 'Test User',
        avatarUrl: null,
        roleTitle: 'Developer',
        createdAt: DateTime.now(),
      );
}

void main() {
  testWidgets('SyncFlowApp renders smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(TestAuthRepository()),
        ],
        child: const SyncFlowApp(),
      ),
    );

    // Pump frames to complete initial build and animation intro
    await tester.pumpAndSettle();

    expect(find.byType(SyncFlowApp), findsOneWidget);
  });
}
