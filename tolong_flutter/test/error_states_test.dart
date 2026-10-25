import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tolong_flutter/app/router.dart';
import 'package:tolong_flutter/features/safe_places/data/offline_map_service.dart';

import 'test_helpers.dart';

/// What the user sees when bundled data can't be read or a download fails.
/// (Route, location, Tol and sync failures are covered in their own test files.)
Future<void> visit(WidgetTester tester, String route) async {
  final container = ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
  container.read(routerProvider).go(route);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('unreadable evacuation center data shows an error instead of an empty list', (tester) async {
    await pumpApp(tester, prefs: {'guest_mode': true, 'language': 'en'}, failCenters: true);
    await visit(tester, '/safe-places');

    expect(find.text("Couldn't read saved data."), findsOneWidget);
    expect(find.textContaining('pin '), findsNothing);
    expect(find.text('Search barangay'), findsOneWidget, reason: 'the rest of the screen stays usable');
  });

  testWidgets('a failed offline map download explains why and offers a retry', (tester) async {
    final offline = FakeOfflineMapService();
    await pumpApp(tester, prefs: {'guest_mode': true, 'language': 'en'}, offline: offline);
    await visit(tester, '/offline-map');

    await tester.tap(find.text('Download Quezon City map'));
    await tester.pump();
    offline.progress.add(const OfflineDownloading(0.3));
    await tester.pump();
    offline.progress.add(const OfflineFailed());
    await tester.pump();

    expect(find.textContaining("The download didn't finish"), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    expect(find.text('Delete offline map'), findsNothing);
  });
}
