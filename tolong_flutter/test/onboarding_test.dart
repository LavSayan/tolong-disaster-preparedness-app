import 'package:flutter_test/flutter_test.dart';
import 'package:tolong_flutter/core/storage/secure_vault.dart';
import 'package:tolong_flutter/features/household/data/household_repository.dart';
import 'package:tolong_flutter/features/household/domain/models.dart';

import 'test_helpers.dart';

void main() {
  testWidgets('a new account completes onboarding and is greeted by name', (tester) async {
    final vault = MemoryVault();
    final auth = FakeAuthRepository();
    final prefs = await pumpApp(tester, vault: vault, auth: auth);

    // Step 1 is prefilled from sign-up metadata.
    expect(find.text('Tell us about you.'), findsOneWidget);
    expect(find.text('Maria Santos'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    // Step 2: add a child.
    expect(find.text('Who lives with you?'), findsOneWidget);
    await tester.tap(find.byTooltip('More Children'));
    await tester.pump();
    expect(find.text('Household size: 2'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    // Step 3: contacts are optional.
    await tester.tap(find.text('Skip for now'));
    await tester.pumpAndSettle();

    // Step 4: preferences.
    expect(find.text('Your preferences.'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to TolongApp, Maria!'), findsOneWidget);
    await tester.tap(find.text('Continue to dashboard'));
    await tester.pumpAndSettle();

    expect(find.text('Good morning, Maria.'), findsOneWidget);
    expect(prefs.getBool('onboarding_complete:user-1'), isTrue);
    expect(auth.synced?.barangay, 'Batasan Hills');

    final saved = await HouseholdRepository(vault).load('user-1');
    expect(saved.household!.children, 1);

    // A household with children gets the child-specific checklist suggestions.
    await tester.tap(find.text('Prepare'));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('Diapers, milk or formula for infants'));
    expect(find.text('For children'), findsWidgets);
  });

  testWidgets('choosing Filipino during onboarding switches the app language', (tester) async {
    final auth = FakeAuthRepository();
    final prefs = await pumpApp(tester, auth: auth);

    await tester.tap(find.text(AppLanguage.filipino.label));
    await tester.pumpAndSettle();
    expect(find.text('Kilalanin ka namin.'), findsOneWidget);
    expect(prefs.getString('language'), 'fil');
  });
}
