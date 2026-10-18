import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tolong_flutter/core/database/app_database.dart';
import 'package:tolong_flutter/features/guidebook/data/guidebook_repository.dart';
import 'package:tolong_flutter/features/guidebook/domain/guidebook.dart';
import 'package:tolong_flutter/features/sync/data/sync_store.dart';

import 'test_helpers.dart';

void main() {
  group('guidebook data', () {
    test('ships the five categories with both languages and no unreviewed content', () {
      final cats = GuidebookRepository.parse(File(GuidebookRepository.assetPath).readAsStringSync());
      expect(cats.map((c) => c.id), ['flood', 'earthquake', 'fire', 'typhoon', 'first_aid']);
      for (final c in cats) {
        expect(c.title.of('fil'), isNotEmpty);
        expect(c.hasContent, isFalse);
      }
    });

    test('sections without a cited source are dropped', () {
      final c = GuideCategory.fromJson({
        'id': 'flood',
        'title': {'en': 'Flood'},
        'summary': {'en': ''},
        'sections': [
          {
            'id': 'a',
            'phase': 'before',
            'title': {'en': 'Sourced'},
            'steps': [
              {
                'text': {'en': 'Step one', 'fil': 'Unang hakbang'},
              },
            ],
            'source': {'name': 'QC DRRMO', 'retrieved': '2026-10-18'},
          },
          {
            'id': 'b',
            'phase': 'during',
            'title': {'en': 'Unsourced'},
            'steps': const [],
          },
        ],
      });
      expect(c.sections.single.id, 'a');
      expect(c.sections.single.steps.single.text.of('fil'), 'Unang hakbang');
      expect(const LocalizedText(en: 'Hi').of('fil'), 'Hi', reason: 'falls back to English');
    });
  });

  testWidgets('guidebook opens from Prepare and shows an honest empty state', (tester) async {
    await pumpApp(tester, prefs: {'guest_mode': true, 'language': 'en'});
    await tester.tap(find.text('Prepare'));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('Disaster guidebook'));
    await tester.tap(find.text('Flood'));
    await tester.pumpAndSettle();

    expect(find.text('Flood preparedness guide coming soon.'), findsOneWidget);
    expect(find.textContaining('works offline'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('See all'));
    await tester.pumpAndSettle();
    expect(find.text('Coming soon'), findsNWidgets(5));
  });

  testWidgets('offline readiness center opens from the header and tells the truth', (tester) async {
    await pumpApp(tester, prefs: {'guest_mode': true, 'language': 'en'});
    await tester.tap(find.byTooltip('Offline status'));
    await tester.pumpAndSettle();

    expect(find.text('Offline readiness'), findsOneWidget);
    expect(find.text('2 of 8 ready offline'), findsOneWidget);
    expect(find.textContaining('Development sample only'), findsOneWidget);
    expect(find.textContaining('No alert source is connected'), findsOneWidget);
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
