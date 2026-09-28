import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sync_flow/features/auth/presentation/register_screen.dart';
import 'package:sync_flow/features/auth/presentation/widgets/glossy_3d_icon_tile.dart';

void main() {
  testWidgets('RegisterScreen renders 3D icons, frosted glass card, controls, and sign in link', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: RegisterScreen(),
        ),
      ),
    );

    // Pump initial frames
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // Verify Brand, 3D Icon Header, and Headings
    expect(find.text('SyncFlow'), findsOneWidget);
    expect(find.byType(Glossy3DIconTile), findsWidgets);
    expect(find.text('Create an account'), findsOneWidget);
    expect(find.text('Join collaborative teams and real-time boards'), findsOneWidget);

    // Verify Input Fields
    expect(find.text('Full Name'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);

    // Verify Password visibility toggle
    expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    await tester.tap(find.byIcon(Icons.visibility_off_outlined));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);

    // Verify Primary "Create account" button
    expect(find.text('Create account'), findsOneWidget);

    // Verify "Sign In" link
    expect(find.text('Sign In'), findsOneWidget);

    // Verify Theme mode toggle button
    expect(find.byTooltip('Switch to Light Mode'), findsOneWidget);
  });
}
