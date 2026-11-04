import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tolong_flutter/app/router.dart';
import 'package:tolong_flutter/features/demo/application/demo_session.dart';
import 'package:tolong_flutter/features/demo/data/demo_route_service.dart';
import 'package:tolong_flutter/features/demo/domain/demo_models.dart';
import 'package:tolong_flutter/features/safe_places/application/ranking_controller.dart';
import 'package:tolong_flutter/features/safe_places/application/safe_places_controller.dart';
import 'package:tolong_flutter/features/safe_places/data/evacuation_center_repository.dart';
import 'package:tolong_flutter/features/safe_places/domain/evacuation_center.dart';

import 'test_helpers.dart';

Future<void> visit(WidgetTester tester, String route) async {
  final container = ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
  container.read(routerProvider).go(route);
  await tester.pumpAndSettle();
}

ProviderContainer _container(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));

void main() {
  testWidgets('without the demo flag /demo is unreachable and no demo tile exists', (tester) async {
    await pumpApp(tester, prefs: {'guest_mode': true, 'language': 'en'});
    await visit(tester, '/demo');
    // Redirected home: the admin panel never mounts in a normal build.
    expect(find.text('Demo tools'), findsNothing);
    await visit(tester, '/more');
    expect(find.text('Demo tools'), findsNothing);
  });

  testWidgets('with the flag the panel opens from /demo and shows every section', (tester) async {
    await pumpApp(tester, prefs: {'guest_mode': true, 'language': 'en'}, demoTools: true);
    await visit(tester, '/demo');
    expect(find.text('Demo tools'), findsOneWidget);
    await scrollTo(tester, find.text('Batasan Hills'));
    expect(find.text('Batasan Hills'), findsOneWidget);
    await scrollTo(tester, find.text('SIMULATED DISASTER ADVISORY'));
    expect(find.text('SIMULATED DISASTER ADVISORY'), findsOneWidget);
    await scrollTo(tester, find.text('RANKING WEIGHTS'));
    expect(find.text('RANKING WEIGHTS'), findsOneWidget);
    await visit(tester, '/more');
    expect(find.text('Demo tools'), findsOneWidget);
  });

  testWidgets('a location preset re-locates, selects the nearest centre and ranks', (tester) async {
    await pumpApp(tester, prefs: {'guest_mode': true, 'language': 'en'}, demoTools: true);
    final container = _container(tester);
    await visit(tester, '/demo');

    await tester.tap(find.text('Batasan Hills'));
    await tester.pumpAndSettle();

    final place = container.read(safePlacesProvider);
    final override = container.read(demoSessionProvider).locationOverride;
    expect(override, isNotNull);
    expect(place.userPoint, override);
    expect(place.outsideServiceArea, isFalse);
    expect(place.selectedId, isNotNull);
    expect(container.read(rankedCentersProvider).available, isTrue);
  });

  testWidgets('the outside-QC preset produces the outside-service-area state', (tester) async {
    await pumpApp(tester, prefs: {'guest_mode': true, 'language': 'en'}, demoTools: true);
    final container = _container(tester);
    await visit(tester, '/demo');

    await tester.tap(find.text('Outside QC — Manila City Hall'));
    await tester.pumpAndSettle();

    final place = container.read(safePlacesProvider);
    expect(place.userPoint, isNotNull);
    expect(place.outsideServiceArea, isTrue);
  });

  testWidgets('clear override forgets the located point', (tester) async {
    await pumpApp(tester, prefs: {'guest_mode': true, 'language': 'en'}, demoTools: true);
    final container = _container(tester);
    await visit(tester, '/demo');
    await tester.tap(find.text('Fairview'));
    await tester.pumpAndSettle();
    expect(container.read(safePlacesProvider).userPoint, isNotNull);

    await tester.tap(find.text('Clear override'));
    await tester.pumpAndSettle();
    expect(container.read(demoSessionProvider).locationOverride, isNull);
    expect(container.read(safePlacesProvider).userPoint, isNull);
  });

  testWidgets('the simulated advisory shows on Home with its tag, and dismissal resets on change', (tester) async {
    await pumpApp(tester, prefs: {'guest_mode': true, 'language': 'en'}, demoTools: true);
    final container = _container(tester);

    container.read(demoSessionProvider.notifier).setAdvisory(const DemoAdvisory(
          type: DemoDisasterType.earthquake,
          severity: DemoSeverity.severe,
          area: 'Batasan Hills',
        ));
    await visit(tester, '/home');
    expect(find.textContaining('SIMULATED'), findsOneWidget);
    expect(find.textContaining('Severe · Batasan Hills'), findsOneWidget);
    expect(find.byTooltip('Alerts'), findsOneWidget);

    final dismissFinder = find.byIcon(Icons.close_rounded);
    expect(dismissFinder, findsOneWidget);
    await tester.ensureVisible(dismissFinder);
    await tester.pumpAndSettle();
    await tester.tap(dismissFinder);
    await tester.pumpAndSettle();
    expect(container.read(advisoryDismissedRevisionProvider), 1);
    expect(find.textContaining('SIMULATED'), findsNothing);

    container.read(demoSessionProvider.notifier).setAdvisory(const DemoAdvisory(
          type: DemoDisasterType.flood,
          severity: DemoSeverity.warning,
          area: 'Commonwealth',
        ));
    await tester.pumpAndSettle();
    expect(find.textContaining('Warning · Commonwealth'), findsOneWidget);
  });

  testWidgets('a normal build never shows an advisory card', (tester) async {
    await pumpApp(tester, prefs: {'guest_mode': true, 'language': 'en'});
    await visit(tester, '/home');
    expect(find.textContaining('SIMULATED'), findsNothing);
    expect(find.byTooltip('Alerts'), findsNothing);
  });

  testWidgets('fake routes come from the demo wrapper, never the real service', (tester) async {
    await pumpApp(tester, prefs: {'guest_mode': true, 'language': 'en'}, demoTools: true);
    final container = _container(tester);
    await visit(tester, '/demo');

    await tester.tap(find.text('Batasan Hills'));
    await tester.pumpAndSettle();

    final place = container.read(safePlacesProvider);
    final from = place.userPoint!;
    final centers = container.read(evacuationCentersProvider).value ?? const [];
    final nearest = byDistance(centers, from).first.$1;
    // The base fake would answer notConfigured; only the demo wrapper can produce a plan.
    container.read(demoSessionProvider.notifier).setFakeRoute(true);
    await container.read(safePlacesProvider.notifier).requestRoute(nearest);
    await tester.pumpAndSettle();

    final after = container.read(safePlacesProvider);
    expect(after.route, isNotNull);
    expect(after.route!.attribution, demoRouteAttribution);
  });

  testWidgets('switching to baseline weights changes the panel provenance line', (tester) async {
    await pumpApp(tester, prefs: {'guest_mode': true, 'language': 'en'}, demoTools: true);
    final container = _container(tester);
    await visit(tester, '/demo');
    await tester.tap(find.text('Batasan Hills'));
    await tester.pumpAndSettle();

    await scrollTo(tester, find.text('RANKING WEIGHTS'));
    // In tests the weights asset override always reports defaults, so the provenance line is
    // the observable: its reason changes when the baseline mode is picked.
    expect(find.textContaining('test: no trained weights'), findsOneWidget);
    await scrollTo(tester, find.text('Baseline 45/35/20'));
    await tester.tap(find.text('Baseline 45/35/20'));
    await tester.pumpAndSettle();
    expect(container.read(demoSessionProvider).weightsMode, DemoWeightsMode.baseline);
    expect(find.textContaining('demo: hand-set baseline weights'), findsOneWidget);
  });

  testWidgets('the demo banner appears while overrides are active and disappears on reset', (tester) async {
    await pumpApp(tester, prefs: {'guest_mode': true, 'language': 'en'}, demoTools: true);
    final container = _container(tester);
    await visit(tester, '/demo');
    await scrollTo(tester, find.text('UP Diliman'));
    await tester.tap(find.text('UP Diliman'));
    await tester.pumpAndSettle();

    await visit(tester, '/home');
    expect(find.textContaining('Demo overrides active'), findsOneWidget);

    await visit(tester, '/demo');
    await scrollTo(tester, find.text('Reset all demo overrides'));
    await tester.tap(find.text('Reset all demo overrides'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();
    expect(container.read(demoSessionProvider).hasOverrides, isFalse);

    await visit(tester, '/home');
    expect(find.textContaining('Demo overrides active'), findsNothing);
  });

  testWidgets('the panel lays out at 320x568 in Filipino with large text', (tester) async {
    await pumpApp(
      tester,
      prefs: {'guest_mode': true, 'language': 'fil', 'text_size': 'larger'},
      logicalSize: const Size(320, 568),
      demoTools: true,
    );
    await visit(tester, '/demo');
    expect(find.text('Demo tools'), findsOneWidget);
  });
}
