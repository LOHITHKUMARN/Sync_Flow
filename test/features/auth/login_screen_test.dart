import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sync_flow/features/auth/presentation/login_screen.dart';
import 'package:sync_flow/features/auth/presentation/widgets/glossy_3d_icon_tile.dart';

void main() {
  testWidgets('LoginScreen renders modern 3D header, controls, toggles password visibility, and opens forgot password dialog', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );

    // Pump initial frames
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // Verify Brand, 3D Icon Header, Heading, and Subtitle
    expect(find.text('SyncFlow'), findsOneWidget);
    expect(find.byType(Glossy3DIconTile), findsWidgets);
    expect(find.text("Let's sign you in"), findsOneWidget);
    expect(find.text("Welcome back, your team's been busy"), findsOneWidget);

    // Verify "Create one" link
    expect(find.text('Create one'), findsOneWidget);

    // Verify "Remember me" checkbox
    expect(find.text('Remember me'), findsOneWidget);
    expect(find.byType(Checkbox), findsOneWidget);

    // Verify "Forgot password?"
    expect(find.text('Forgot password?'), findsOneWidget);

    // Verify Primary "Sign in" button
    expect(find.text('Sign in'), findsOneWidget);

    // Verify Google SSO and Biometrics buttons
    expect(find.text('Google SSO'), findsOneWidget);
    expect(find.byIcon(Icons.fingerprint_rounded), findsOneWidget);

    // Verify Password show/hide toggle
    expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    await tester.tap(find.byIcon(Icons.visibility_off_outlined));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);

    // Verify tapping "Forgot password?" opens reset dialog
    await tester.tap(find.text('Forgot password?'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Reset Password'), findsOneWidget);
    expect(find.text('Send Link'), findsOneWidget);

    // Close dialog
    await tester.tap(find.text('Cancel'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Reset Password'), findsNothing);

    // Verify tapping theme toggle button toggles to Light Mode and back
    final themeToggleFinder = find.byTooltip('Switch to Light Mode');
    expect(themeToggleFinder, findsOneWidget);
    await tester.tap(themeToggleFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Now it should be in Light Mode, showing "Switch to Dark Mode"
    expect(find.byTooltip('Switch to Dark Mode'), findsOneWidget);

    // Tap again to switch back to Dark Mode
    await tester.tap(find.byTooltip('Switch to Dark Mode'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byTooltip('Switch to Light Mode'), findsOneWidget);
  });
}
