import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tolong_flutter/app/router.dart';

import 'test_helpers.dart';

/// Worst realistic case: the narrowest common phone width, Filipino (longest strings) and the
/// largest in-app text size. Any RenderFlex overflow fails the test automatically.
const narrowTall = Size(320, 2400); // tall so lazy lists build every item
const smallPhone = Size(320, 568);
const worstCase = {'language': 'fil', 'text_size': 'larger'};

const guestRoutes = [
  '/home',
  '/prepare',
  '/safe-places',
  '/more',
  '/profile',
  '/supplies',
  '/readiness',
  '/settings',
  '/offline-map',
  '/offline-readiness',
  '/tol',
];

const publicRoutes = ['/welcome', '/login', '/register', '/forgot-password'];

Future<void> visit(WidgetTester tester, String route) async {
  final container = ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
  container.read(routerProvider).go(route);
  await tester.pumpAndSettle();
}

void main() {
  for (final size in [narrowTall, smallPhone]) {
    final label = '${size.width.toInt()}x${size.height.toInt()}';

    for (final route in guestRoutes) {
      testWidgets('$route lays out at $label (Filipino, large text)', (tester) async {
        await pumpApp(tester, prefs: {...worstCase, 'guest_mode': true}, logicalSize: size);
        await visit(tester, route);
      });
    }

    for (final route in publicRoutes) {
      testWidgets('$route lays out at $label (Filipino, large text)', (tester) async {
        await pumpApp(tester, prefs: worstCase, logicalSize: size);
        await visit(tester, route);
      });
    }

    testWidgets('all onboarding steps lay out at $label (Filipino, large text)', (tester) async {
      await pumpApp(tester, prefs: worstCase, auth: FakeAuthRepository(), logicalSize: size);
      for (var step = 0; step < 4; step++) {
        final next = find.text(step == 2 ? 'Laktawan muna' : 'Susunod');
        await tester.ensureVisible(next);
        await tester.tap(next);
        await tester.pumpAndSettle();
      }
      expect(find.text('Tumuloy sa dashboard'), findsOneWidget);
    });
  }

  testWidgets('supply editor and checklist item sheet fit a small phone', (tester) async {
    await pumpApp(tester, prefs: {...worstCase, 'guest_mode': true}, logicalSize: smallPhone);
    await visit(tester, '/supplies');
    await tester.tap(find.text('Magdagdag ng suplay'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Pumili ng petsa'), findsOneWidget);

    await visit(tester, '/prepare');
    await scrollTo(tester, find.text('Magdagdag'));
    await tester.tap(find.text('Magdagdag'));
    await tester.pumpAndSettle();
    expect(find.text('Magdagdag ng item'), findsOneWidget);
  });
}
