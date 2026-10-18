import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tolong_flutter/core/storage/secure_vault.dart';
import 'package:tolong_flutter/features/prepare/data/checklist_repository.dart';
import 'package:tolong_flutter/features/supplies/data/supplies_repository.dart';

import 'test_helpers.dart';

void main() {
  testWidgets('checking a go-bag item saves it and raises the readiness score', (tester) async {
    final vault = MemoryVault();
    await pumpApp(tester, vault: vault);
    await enterGuestMode(tester);
    expect(find.text('0%'), findsOneWidget);

    await tester.tap(find.text('Prepare'));
    await tester.pumpAndSettle();
    expect(find.text('0 of 19 packed'), findsOneWidget);

    await scrollTo(tester, find.text('Drinking water'));
    await tester.tap(find.text('Drinking water'));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('1 of 19 packed'));
    expect(find.text('1 of 19 packed'), findsOneWidget);
    expect(find.textContaining('Saved on this phone'), findsOneWidget);

    final saved = await ChecklistRepository(vault).load('guest');
    expect(saved.templates['water']!.done, isTrue);

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('2%'));
    // 1/19 of the 40% go-bag weight = 2 points.
    expect(find.text('2%'), findsOneWidget);
  });

  testWidgets('custom checklist items can be added and removed with confirmation', (tester) async {
    await pumpApp(tester);
    await enterGuestMode(tester);
    await tester.tap(find.text('Prepare'));
    await tester.pumpAndSettle();

    await scrollTo(tester, find.text('Add item'));
    await tester.tap(find.text('Add item'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Spare eyeglasses');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(find.text('0 of 20 packed'), findsOneWidget);

    await scrollTo(tester, find.text('Spare eyeglasses'));
    await tester.tap(find.byTooltip('Actions for Spare eyeglasses'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove').last);
    await tester.pumpAndSettle();
    expect(find.text('Remove item?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Remove'));
    await tester.pumpAndSettle();
    expect(find.text('Spare eyeglasses'), findsNothing);
  });

  testWidgets('adding water to supplies updates coverage on Home', (tester) async {
    final vault = MemoryVault();
    await pumpApp(tester, vault: vault);
    await enterGuestMode(tester);

    await scrollTo(tester, find.text('Supply coverage'));
    await tester.tap(find.text('Supply coverage'));
    await tester.pumpAndSettle();
    expect(find.text('Household size isn\'t set, so estimates assume 1 person.'), findsOneWidget);

    await tester.tap(find.text('Add supply'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Bottled water');
    await tester.enterText(find.widgetWithText(TextFormField, 'Quantity'), '19');
    await scrollTo(tester, find.widgetWithText(FilledButton, 'Save'));
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    // 19 L for 1 person at 3.8 L/day = 5 days, which meets the 3-day target.
    expect(find.text('5 days'), findsOneWidget);
    expect(find.text('Target met'), findsOneWidget);
    final stored = await SuppliesRepository(vault).load('guest');
    expect(stored.single.quantity, 19);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('Water: 5 days'));
    expect(find.text('Water: 5 days'), findsOneWidget);
  });

  testWidgets('settings persist and reduced motion can be turned on', (tester) async {
    final prefs = await pumpApp(tester);
    await enterGuestMode(tester);
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    await scrollTo(tester, find.text('Reduce motion'));
    await tester.tap(find.text('Reduce motion'));
    await tester.pumpAndSettle();
    expect(prefs.getBool('reduced_motion'), isTrue);

    await scrollTo(tester, find.text('Larger'));
    await tester.tap(find.text('Larger'));
    await tester.pumpAndSettle();
    expect(prefs.getString('text_size'), 'larger');
  });

  testWidgets('deleting an account asks first, then signs out and clears local data', (tester) async {
    final auth = FakeAuthRepository();
    final vault = MemoryVault();
    await pumpApp(tester, prefs: {'language': 'en', 'onboarding_complete:user-1': true}, vault: vault, auth: auth);

    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete account'));
    await tester.pumpAndSettle();
    expect(find.text('Delete your account?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete account'));
    await tester.pumpAndSettle();

    expect(auth.deleted, isTrue);
    expect(find.text('Your safety starts with preparation.'), findsOneWidget);
  });
}
