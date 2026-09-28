import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sync_flow/features/projects/presentation/create_project_dialog.dart';
import 'package:sync_flow/core/widgets/primary_button.dart';

void main() {
  testWidgets('CreateProjectDialog renders as mobile bottom sheet with pill handle and stacked actions',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => CreateProjectDialog.show(context),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );

    // Tap Open to trigger the sheet
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // Verify Title
    expect(find.text('Create New Project'), findsOneWidget);

    // Verify Fields
    expect(find.text('Project Name'), findsOneWidget);
    expect(find.text('Description'), findsOneWidget);
    expect(find.text('Color Theme'), findsOneWidget);

    // Verify drag handle pill (width: 40, height: 4, neutral-600 Color(0xFF52525B))
    final dragHandleFinder = find.byWidgetPredicate((widget) {
      if (widget is Container && widget.decoration is BoxDecoration) {
        final box = widget.decoration as BoxDecoration;
        return box.color == const Color(0xFF52525B) &&
            widget.constraints?.maxWidth == 40 &&
            widget.constraints?.maxHeight == 4;
      }
      return false;
    });
    expect(dragHandleFinder, findsOneWidget);

    // Verify Action Buttons: Create Project and Cancel
    final createBtn = find.widgetWithText(PrimaryButton, 'Create Project');
    final cancelBtn = find.widgetWithText(TextButton, 'Cancel');
    expect(createBtn, findsOneWidget);
    expect(cancelBtn, findsOneWidget);

    // Verify Action Buttons are stacked (Create Project is above Cancel)
    final createBtnOffset = tester.getTopLeft(createBtn);
    final cancelBtnOffset = tester.getTopLeft(cancelBtn);
    expect(createBtnOffset.dy < cancelBtnOffset.dy, isTrue);

    // Tap Cancel to dismiss
    await tester.tap(cancelBtn);
    await tester.pumpAndSettle();

    expect(find.text('Create New Project'), findsNothing);
  });
}
