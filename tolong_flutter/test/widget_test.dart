import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

void main() {
  testWidgets('without Supabase config the app lands on Welcome and says accounts are unavailable', (tester) async {
    await pumpApp(tester);
    expect(find.text('Your safety starts with preparation.'), findsOneWidget);
    expect(find.textContaining('are not configured in this build'), findsOneWidget);
  });

  testWidgets('login shows an honest error when accounts are not configured', (tester) async {
    await pumpApp(tester);
    await scrollTo(tester, find.text('Log in'));
    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'mia@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'secret123');
    await scrollTo(tester, find.widgetWithText(FilledButton, 'Log in'));
    await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Online accounts are not configured'), findsOneWidget);
  });

  testWidgets('emergency access opens the dashboard and every tab renders', (tester) async {
    await pumpApp(tester);
    await enterGuestMode(tester);

    expect(find.textContaining('not signed in'), findsOneWidget);
    expect(find.text('Good morning.'), findsOneWidget);
    expect(find.text('Let\'s get started.'), findsOneWidget);

    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    expect(find.text('Profile & household'), findsOneWidget);

    await tester.tap(find.text('Prepare'));
    await tester.pumpAndSettle();
    expect(find.text('Make your kit easy to grab'), findsOneWidget);

    await tester.tap(find.text('Safe places'));
    await tester.pumpAndSettle();
    expect(find.text('DEMO DATA · CENTERS NOT VERIFIED'), findsOneWidget);
  });

  testWidgets('guest mode is remembered across launches', (tester) async {
    await pumpApp(tester, prefs: {'guest_mode': true, 'language': 'en'});
    expect(find.textContaining('not signed in'), findsOneWidget);
  });

  testWidgets('switching to Filipino translates the whole UI and is remembered', (tester) async {
    final prefs = await pumpApp(tester);
    await tester.tap(find.text('FIL'));
    await tester.pumpAndSettle();
    expect(find.text('Nagsisimula sa paghahanda ang iyong kaligtasan.'), findsOneWidget);
    expect(prefs.getString('language'), 'fil');

    await scrollTo(tester, find.text('Emergency access nang walang account'));
    await tester.tap(find.text('Emergency access nang walang account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Magpatuloy nang walang account'));
    await tester.pumpAndSettle();

    expect(find.text('Magandang umaga.'), findsOneWidget);
    expect(find.text('Tahanan'), findsWidgets);
    expect(find.text('Mga Ligtas na Lugar'), findsOneWidget);
  });
}
