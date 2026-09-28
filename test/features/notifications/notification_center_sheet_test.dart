import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sync_flow/features/notifications/presentation/widgets/notification_center_sheet.dart';

void main() {
  setUpAll(() {
    HttpOverrides.global = _TestHttpOverrides();
  });

  Widget buildTestWidget() {
    return const ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: NotificationCenterSheet(),
        ),
      ),
    );
  }

  testWidgets('NotificationCenterSheet renders triage header, filter chips and time groups',
      (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Title and unread pill
    expect(find.text('Notifications'), findsOneWidget);

    // Filter Chips
    expect(find.text('All'), findsOneWidget);
    expect(find.textContaining('Unread'), findsWidgets);
    expect(find.text('Assigned'), findsOneWidget);
    expect(find.text('Comments'), findsOneWidget);
    expect(find.text('Due soon'), findsOneWidget);

    // Section headers for time grouping
    expect(find.text('TODAY'), findsOneWidget);
    expect(find.text('EARLIER'), findsOneWidget);

    // System alert avatar icon for due-date notification
    expect(find.byIcon(Icons.alarm_rounded), findsWidgets);

    // Explicit deadline text instead of "1d ago"
    expect(find.text('Due in 24h'), findsOneWidget);

    // Mark all as read button
    expect(find.text('Mark all read'), findsOneWidget);
  });

  testWidgets('NotificationCenterSheet filter chips filter items correctly',
      (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Tap "Due soon" filter chip
    await tester.tap(find.text('Due soon'));
    await tester.pumpAndSettle();

    expect(find.text('Due date approaching'), findsOneWidget);
    expect(find.text('Assigned to you'), findsNothing);

    // Tap "Comments" filter chip
    await tester.tap(find.text('Comments'));
    await tester.pumpAndSettle();

    expect(find.text('New comment on task'), findsOneWidget);
    expect(find.text('Due date approaching'), findsNothing);
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
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x0D,
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
