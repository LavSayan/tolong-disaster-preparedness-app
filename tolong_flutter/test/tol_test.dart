import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tolong_flutter/core/storage/secure_vault.dart';
import 'package:tolong_flutter/features/household/domain/models.dart';
import 'package:tolong_flutter/features/tol/data/tol_service.dart';
import 'package:tolong_flutter/features/tol/domain/offline_guide.dart';
import 'package:tolong_flutter/features/tol/domain/tol_models.dart';

import 'test_helpers.dart';

Future<void> openTol(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Chat with Tol'));
  await tester.pumpAndSettle();
}

void main() {
  group('offline intent matching', () {
    TolIntent intent(String q) => detectIntent(q).intent;

    test('danger always wins, in English and Filipino', () {
      expect(intent('Help, we are trapped by the flood'), TolIntent.emergency);
      expect(intent('Nalulunod kami, baha na sa loob'), TolIntent.emergency);
      expect(intent('my father is injured'), TolIntent.emergency);
    });

    test('questions about what is happening now go to official sources', () {
      expect(intent('May baha ba ngayon sa amin?'), TolIntent.alerts);
      expect(intent('Is there a typhoon signal today?'), TolIntent.alerts);
    });

    test('app topics', () {
      expect(intent('What should I pack in my go-bag?'), TolIntent.goBag);
      expect(intent('Ilang araw ang tubig namin?'), TolIntent.water);
      expect(intent('Ano ang mag-e-expire?'), TolIntent.expiry);
      expect(intent('What should I do first to get ready?'), TolIntent.readiness);
      expect(intent('Where is the nearest evacuation center?'), TolIntent.evacuation);
      expect(intent('How do I prepare for a flood?'), TolIntent.guide);
      expect(detectIntent('First aid for burns').guideId, 'first_aid');
      expect(detectIntent('Paano maghanda sa lindol').guideId, 'earthquake');
      expect(intent('Kumusta Tol'), TolIntent.greeting);
      expect(intent('What is the capital of France?'), TolIntent.unknown);
    });
  });

  test('the household summary never includes names, phone numbers or contacts', () {
    final s = householdSummary(
      household: const HouseholdProfile(adults: 2, children: 1, hasPets: true, assistanceNeeds: 'wheelchair'),
      profile: const UserProfile(fullName: 'Maria Santos', age: 34, barangay: 'Batasan Hills'),
      readiness: null,
    );
    final text = s.toString();
    expect(s['householdSize'], 3);
    expect(s['hasChildren'], isTrue);
    expect(s['hasAssistanceNeeds'], isTrue);
    expect(s['barangay'], 'Batasan Hills');
    expect(text.contains('Maria'), isFalse);
    expect(text.contains('wheelchair'), isFalse, reason: 'only whether there are needs, not what they are');
    expect(s.containsKey('age'), isFalse);
  });

  test('only recent messages are sent to the AI, in API roles', () {
    final msgs = [
      for (var i = 0; i < 20; i++)
        TolMessage(id: '$i', role: i.isEven ? TolRole.user : TolRole.tol, text: 'm$i', createdAt: DateTime(2026)),
    ];
    final api = conversationForApi(msgs);
    expect(api.length, 12);
    expect(api.last, {'role': 'assistant', 'content': 'm19'});
  });

  testWidgets('without an account Tol answers offline from saved data, clearly labelled', (tester) async {
    await pumpApp(tester, prefs: {'guest_mode': true, 'language': 'en'}, tol: FakeTolService());
    await openTol(tester);

    expect(find.text('Offline guidance'), findsOneWidget);
    expect(find.textContaining('Online AI needs an account'), findsOneWidget);
    await tester.tap(find.text('What should I pack in my go-bag?'));
    await tester.pumpAndSettle();

    expect(find.textContaining('0 of 19 items packed'), findsOneWidget);
    expect(find.text('Offline guidance from data saved on this phone'), findsOneWidget);
  });

  testWidgets('the Tol button is hidden on the map so it never covers map controls', (tester) async {
    await pumpApp(tester, prefs: {'guest_mode': true, 'language': 'en'});
    expect(find.byTooltip('Chat with Tol'), findsOneWidget);
    await tester.tap(find.text('Safe places').last);
    await tester.pumpAndSettle();
    expect(find.byTooltip('Chat with Tol'), findsNothing);
  });

  testWidgets('signed in: online AI reply is labelled, and household context needs consent', (tester) async {
    final tol = FakeTolService();
    await pumpApp(
      tester,
      prefs: {'language': 'en', 'onboarding_complete:user-1': true},
      auth: FakeAuthRepository(),
      tol: tol,
    );
    await openTol(tester);
    expect(find.text('Online AI'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'What should we pack?');
    await tester.tap(find.byTooltip('Send'));
    await tester.pumpAndSettle();

    expect(find.text('Pack water, food and a flashlight.'), findsOneWidget);
    expect(find.text('AI-generated · may be wrong · not an official advisory'), findsOneWidget);
    expect(tol.calls.single.context, isNull, reason: 'consent is off by default');
    expect(tol.calls.single.language, 'en');

    // Turn consent on from the chat menu, then ask again.
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Let Tol use my household summary'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'And for the kids?');
    await tester.tap(find.byTooltip('Send'));
    await tester.pumpAndSettle();
    expect(tol.calls.last.context, isNotNull);
    expect(tol.calls.last.conversation.first['content'], 'What should we pack?');
  });

  testWidgets('if online Tol fails it falls back to offline guidance with a retry', (tester) async {
    final tol = FakeTolService()..failNext = const TolFailure(TolErrorCode.network);
    final vault = MemoryVault();
    await pumpApp(
      tester,
      prefs: {'language': 'en', 'onboarding_complete:user-1': true},
      auth: FakeAuthRepository(),
      tol: tol,
      vault: vault,
    );
    await openTol(tester);
    await tester.enterText(find.byType(TextField), 'Is there a flood alert today?');
    await tester.tap(find.byTooltip('Send'));
    await tester.pumpAndSettle();

    expect(find.text('Couldn\'t reach Tol online, so this is offline guidance.'), findsOneWidget);
    expect(find.textContaining('I don\'t have live weather or hazard alerts'), findsOneWidget);

    await tester.tap(find.text('Try online again'));
    await tester.pumpAndSettle();
    expect(find.text('Pack water, food and a flashlight.'), findsOneWidget);
    expect(await TolHistoryRepository(vault).load('user-1'), hasLength(3));

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear conversation'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear conversation').last);
    await tester.pumpAndSettle();
    expect(find.text('Pack water, food and a flashlight.'), findsNothing);
    expect(await TolHistoryRepository(vault).load('user-1'), isEmpty);
  });

  testWidgets('Tol speaks Filipino when the app is in Filipino', (tester) async {
    await pumpApp(tester, prefs: {'guest_mode': true, 'language': 'fil'});
    await tester.tap(find.byTooltip('Makipag-chat kay Tol'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ano ang dapat kong ilagay sa go-bag?'));
    await tester.pumpAndSettle();
    expect(find.textContaining('0 sa 19 na bagay ang nasa iyong go-bag'), findsOneWidget);
  });
}
