import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tolong_flutter/app/router.dart';

import 'test_helpers.dart';

/// Flutter's built-in accessibility checks on the main screens:
/// - tap targets at least 48x48 dp (Android guideline)
/// - every tappable element has a label for screen readers
/// - text contrast meets WCAG AA (4.5:1, or 3:1 for large text)
const screens = ['/home', '/prepare', '/safe-places', '/more', '/supplies', '/readiness', '/settings', '/tol'];

Future<void> visit(WidgetTester tester, String route) async {
  final container = ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
  container.read(routerProvider).go(route);
  await tester.pumpAndSettle();
}

void main() {
  for (final route in screens) {
    testWidgets('$route meets tap-target, label and contrast guidelines', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpApp(tester, prefs: {'guest_mode': true, 'language': 'en'});
      await visit(tester, route);

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      semantics.dispose();
    });
  }

  for (final route in ['/welcome', '/login', '/register']) {
    testWidgets('$route meets tap-target, label and contrast guidelines', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpApp(tester);
      await visit(tester, route);

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      semantics.dispose();
    });
  }
}
