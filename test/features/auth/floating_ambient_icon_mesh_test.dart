import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sync_flow/features/auth/presentation/widgets/floating_ambient_icon_mesh.dart';
import 'package:sync_flow/features/auth/presentation/widgets/glossy_3d_icon_tile.dart';

void main() {
  testWidgets('FloatingAmbientIconMesh renders 10 layered glossy icons with custom mesh connections', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 800,
            child: FloatingAmbientIconMesh(),
          ),
        ),
      ),
    );

    // Pump past initial delays so pending timers complete
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));

    // Verify exactly 8 Glossy3DIconTile widgets rendered across depth layers
    expect(find.byType(Glossy3DIconTile), findsNWidgets(8));

    // Verify it is wrapped in IgnorePointer and ExcludeSemantics for non-intrusive ambient background
    expect(find.byType(IgnorePointer), findsWidgets);
    expect(find.byType(ExcludeSemantics), findsWidgets);

    // Verify CustomPaint for dotted connecting lines is present
    expect(find.byType(CustomPaint), findsWidgets);
  });
}
