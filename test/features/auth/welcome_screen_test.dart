import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sync_flow/features/auth/presentation/welcome_screen.dart';
import 'package:sync_flow/features/auth/presentation/widgets/glossy_3d_icon_tile.dart';

void main() {
  testWidgets('WelcomeScreen renders floating 3D collage, branding, Get started, and account link', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: WelcomeScreen(),
        ),
      ),
    );

    // Pump initial frames
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // Verify 3D collage icons
    expect(find.byType(Glossy3DIconTile), findsWidgets);

    // Verify SyncFlow branding and tagline
    expect(find.text('SyncFlow'), findsOneWidget);
    expect(find.text('Real-time collaborative workspace for teams'), findsOneWidget);

    // Verify Primary "Get started" button
    expect(find.text('Get started'), findsOneWidget);

    // Verify Secondary "I already have an account" link
    expect(find.text('I already have an account'), findsOneWidget);

    // Verify Theme mode toggle button
    expect(find.byTooltip('Switch to Dark Mode'), findsOneWidget);
  });
}
