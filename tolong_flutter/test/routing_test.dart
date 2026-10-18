import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tolong_flutter/features/safe_places/data/location_service.dart';
import 'package:tolong_flutter/features/safe_places/data/route_service.dart';
import 'package:tolong_flutter/features/safe_places/domain/evacuation_center.dart';

import 'test_helpers.dart';

const userInQc = GeoPoint(14.7270, 121.0425);

// A short made-up line from the user toward demo center 3 (14.7268, 121.0420).
const plan = RoutePlan(
  profile: RouteProfile.walking,
  distanceMeters: 1240,
  durationSeconds: 900,
  points: [GeoPoint(14.7270, 121.0425), GeoPoint(14.7269, 121.0423), GeoPoint(14.7268, 121.0420)],
  attribution: 'Routing © openrouteservice.org by HeiGIT',
);

Future<void> openCenter(
  WidgetTester tester, {
  required FakeLocationService location,
  required FakeRouteService routes,
  String marker = 'demo-03',
}) async {
  await pumpApp(tester, prefs: {'guest_mode': true, 'language': 'en'}, location: location, routes: routes);
  await tester.tap(find.text('Safe places').last);
  await tester.pumpAndSettle();
  await scrollTo(tester, find.text('DEMO DATA · CENTERS NOT VERIFIED'));
  await tester.tap(find.byKey(ValueKey('marker-$marker')));
  await tester.pumpAndSettle();
  await scrollTo(tester, find.text('Show route'));
}

void main() {
  group('route parsing and geometry', () {
    test('parses the Edge Function response into lat/lng points', () {
      final r = parseRouteResponse({
        'distance_m': 1520.4,
        'duration_s': 1094.7,
        'points': [
          [14.65, 121.05],
          [14.66, 121.06],
        ],
        'attribution': 'ORS',
      }, RouteProfile.walking);
      expect(r, isA<RouteFound>());
      final p = (r as RouteFound).plan;
      expect(p.points.last.lat, 14.66);
      expect(p.distanceMeters, 1520.4);
    });

    test('maps server error codes to user-facing errors', () {
      expect(errorFromCode('no_route', 404), RouteErrorCode.noRoute);
      expect(errorFromCode('quota_exceeded', 429), RouteErrorCode.quota);
      expect(errorFromCode('outside_area', 400), RouteErrorCode.outsideArea);
      expect(errorFromCode(null, 404), RouteErrorCode.notConfigured);
      expect(errorFromCode(null, 500), RouteErrorCode.unknown);
    });

    test('distance to a route line measures to the nearest segment, not just vertices', () {
      const line = [GeoPoint(14.65, 121.05), GeoPoint(14.65, 121.06)];
      // ~0.001° north of the middle of an east-west segment ≈ 110 m.
      expect(distanceToPolylineMeters(const GeoPoint(14.651, 121.055), line), closeTo(110.5, 1));
      expect(distanceToPolylineMeters(const GeoPoint(14.65, 121.055), line), closeTo(0, 0.01));
    });

    test('a map tap counts as a marker tap only within the pixel radius', () {
      const c = EvacuationCenter(
          id: 'x', name: 'X', location: GeoPoint(14.65, 121.05), facilityType: FacilityType.school, source: 's', verified: false);
      // At zoom 14 one pixel is ~4.6 m, so 28 px ≈ 130 m.
      expect(nearestWithinPixels([c], const GeoPoint(14.6505, 121.05), 14, 28)?.id, 'x');
      expect(nearestWithinPixels([c], const GeoPoint(14.6550, 121.05), 14, 28), isNull);
    });
  });

  testWidgets('a found route is drawn with distance, time, disclaimer and a navigation button', (tester) async {
    final location = FakeLocationService(const Located(userInQc));
    final routes = FakeRouteService(const RouteFound(plan));
    await openCenter(tester, location: location, routes: routes);

    await tester.tap(find.text('Show route'));
    await tester.pumpAndSettle();

    expect(routes.requests.single.$3, RouteProfile.walking);
    expect(find.text('route-line 3'), findsOneWidget);
    await scrollTo(tester, find.text('Start navigation'));
    expect(find.text('1.2 km · about 15 min'), findsOneWidget);
    expect(find.textContaining('does not know about current floods'), findsOneWidget);
  });

  testWidgets('choosing wheelchair asks for the wheelchair profile and explains its limits', (tester) async {
    final routes = FakeRouteService(const RouteFound(plan));
    await openCenter(tester, location: FakeLocationService(const Located(userInQc)), routes: routes);

    await scrollTo(tester, find.text('Wheelchair'));
    await tester.tap(find.text('Wheelchair'));
    await tester.pumpAndSettle();
    expect(find.textContaining('accessibility tags'), findsOneWidget);
    await scrollTo(tester, find.text('Show route'));
    await tester.tap(find.text('Show route'));
    await tester.pumpAndSettle();
    expect(routes.requests.single.$3, RouteProfile.wheelchair);
  });

  testWidgets('route errors are explained and nothing is drawn', (tester) async {
    final routes = FakeRouteService(const RouteFailed(RouteErrorCode.noRoute));
    await openCenter(tester, location: FakeLocationService(const Located(userInQc)), routes: routes);
    await tester.tap(find.text('Show route'));
    await tester.pumpAndSettle();
    expect(find.textContaining('No route found'), findsOneWidget);
    expect(find.textContaining('route-line'), findsNothing);
    expect(find.text('Start navigation'), findsNothing);
  });

  testWidgets('asking for a route without location permission explains why', (tester) async {
    final routes = FakeRouteService(const RouteFound(plan));
    await openCenter(tester, location: FakeLocationService(const LocationDenied()), routes: routes);
    await tester.tap(find.text('Show route'));
    await tester.pumpAndSettle();
    expect(routes.requests, isEmpty);
    expect(find.textContaining('Allow your location'), findsOneWidget);
  });

  testWidgets('navigation follows live location: off route, then arrived, then ends', (tester) async {
    final location = FakeLocationService(const Located(userInQc));
    await openCenter(tester, location: location, routes: FakeRouteService(const RouteFound(plan)));
    await tester.tap(find.text('Show route'));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('Start navigation'));
    await tester.tap(find.text('Start navigation'));
    await tester.pumpAndSettle();

    expect(find.text('Navigation'), findsOneWidget);
    expect(find.textContaining('not turn-by-turn'), findsOneWidget);

    location.positions.add(const GeoPoint(14.7300, 121.0425)); // ~330 m north of the line
    await tester.pumpAndSettle();
    expect(find.textContaining('off the route'), findsOneWidget);

    location.positions.add(const GeoPoint(14.7268, 121.0421)); // at the center
    await tester.pumpAndSettle();
    expect(find.text('You\'ve arrived near Demo center 3.'), findsOneWidget);

    await tester.tap(find.text('End navigation'));
    await tester.pumpAndSettle();
    expect(find.text('Navigation'), findsNothing);
  });
}
