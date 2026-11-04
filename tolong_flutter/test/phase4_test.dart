import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tolong_flutter/core/database/app_database.dart';
import 'package:tolong_flutter/features/sync/data/sync_store.dart';

import 'test_helpers.dart';

void main() {
  testWidgets('offline readiness center opens from the header and tells the truth', (tester) async {
    await pumpApp(tester, prefs: {'guest_mode': true, 'language': 'en'});
    await tester.tap(find.byTooltip('Offline status'));
    await tester.pumpAndSettle();

    expect(find.text('Offline readiness'), findsOneWidget);
    // Guest: street map not downloaded, area data ready, sample centres partial, household
    // ready, backup off — and the guidebook/alerts/Tol placeholder rows are gone.
    expect(find.text('2 of 5 ready offline'), findsOneWidget);
    expect(find.textContaining('Development sample only'), findsOneWidget);
    expect(find.textContaining('Hazard alerts'), findsNothing);
    expect(find.textContaining('Disaster guidebook'), findsNothing);
    await scrollTo(tester, find.textContaining('data stays on this phone and is not backed up'));
    expect(find.text('Back up now'), findsNothing);
  });

  testWidgets('a signed-in change is queued and backed up automatically', (tester) async {
    final remote = FakeSyncRemote();
    final db = AppDatabase(NativeDatabase.memory());
    await pumpApp(
      tester,
      prefs: {'language': 'en', 'onboarding_complete:user-1': true},
      auth: FakeAuthRepository(),
      syncRemote: remote,
      database: db,
    );

    await tester.tap(find.text('Prepare'));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('Drinking water'));
    await tester.tap(find.text('Drinking water'));
    await tester.pumpAndSettle();

    // The queue records the change; the debounced sync uploads it 2 s later.
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump(const Duration(seconds: 3));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pumpAndSettle();

    expect(remote.rows['checklist/user-1'], isNotNull);
    expect((remote.rows['checklist/user-1']!.data!['templates'] as Map)['water'], {'done': true, 'editedTitle': null});
    expect(await tester.runAsync(() => SyncStore(db).pendingCount('user-1')), 0);

    await tester.tap(find.byTooltip('Offline status'));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('Back up now'));
    expect(find.textContaining('Everything is backed up.'), findsOneWidget);

    // Drift cancels its stream queries with a zero-length timer; let it run before teardown.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
  });
}
