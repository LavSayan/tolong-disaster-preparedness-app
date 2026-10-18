import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tolong_flutter/features/safe_places/data/evacuation_center_repository.dart';
import 'package:tolong_flutter/features/safe_places/data/location_service.dart';
import 'package:tolong_flutter/features/safe_places/domain/evacuation_center.dart';

import 'test_helpers.dart';

Future<void> openSafePlaces(WidgetTester tester, {FakeMap? map, LocationService? location}) async {
  await pumpApp(tester, prefs: {'guest_mode': true, 'language': 'en'}, map: map, location: location);
  await tester.tap(find.text('Safe places').last);
  await tester.pumpAndSettle();
  // The map card sits below the hero; bring all four map controls into view like a user would.
  await scrollTo(tester, find.text('DEMO DATA · CENTERS NOT VERIFIED'));
}

void main() {
  group('domain', () {
    test('straight-line distance uses the haversine formula', () {
      const a = GeoPoint(14.0, 121.0);
      const b = GeoPoint(15.0, 121.0);
      expect(a.distanceKm(b), closeTo(111.19, 0.05));
      expect(a.distanceKm(a), 0);
    });

    test('centers sort by distance from the user', () {
      const near = EvacuationCenter(
          id: 'n', name: 'N', location: GeoPoint(14.65, 121.05), facilityType: FacilityType.school, source: 's', verified: false);
      const far = EvacuationCenter(
          id: 'f', name: 'F', location: GeoPoint(14.75, 121.05), facilityType: FacilityType.school, source: 's', verified: false);
      expect(byDistance([far, near], const GeoPoint(14.651, 121.05)).first.$1.id, 'n');
    });

    test('approximate QC area includes Diliman and excludes Makati', () {
      expect(qcApproxBounds.contains(const GeoPoint(14.6537, 121.0685)), isTrue);
      expect(qcApproxBounds.contains(const GeoPoint(14.5547, 121.0244)), isFalse);
    });

    test('the bundled dataset is marked unverified and lies inside the QC area', () {
      final centers =
          EvacuationCenterRepository.parse(File(EvacuationCenterRepository.assetPath).readAsStringSync());
      expect(centers, isNotEmpty);
      for (final c in centers) {
        expect(c.verified, isFalse, reason: c.id);
        expect(qcApproxBounds.contains(c.location), isTrue, reason: c.id);
        expect(c.capacity, isNull);
      }
    });
  });

  testWidgets('shows the map with demo labels, controls, and the center list', (tester) async {
    final map = FakeMap();
    await openSafePlaces(tester, map: map);

    expect(find.text('DEMO DATA · CENTERS NOT VERIFIED'), findsOneWidget);
    expect(find.byKey(const ValueKey('marker-demo-01')), findsOneWidget);
    await tester.tap(find.byTooltip('Zoom in'));
    await tester.tap(find.byTooltip('Show all of Quezon City'));
    await tester.pump();
    expect(map.calls, containsAll(['zoomIn', 'bounds']));

    await scrollTo(tester, find.text('EVACUATION CENTERS'));
    expect(find.textContaining('not real evacuation centers'), findsOneWidget);
  });

  testWidgets('tapping a marker selects the center, moves the camera, and shows unverified fields', (tester) async {
    final map = FakeMap();
    await openSafePlaces(tester, map: map);

    await tester.tap(find.byKey(const ValueKey('marker-demo-02')));
    await tester.pumpAndSettle();
    expect(map.calls.last, 'focus 14.6869,121.1003');

    await scrollTo(tester, find.text('SELECTED CENTER'));
    expect(find.text('NOT REAL DATA'), findsOneWidget);
    expect(find.text('Not verified'), findsWidgets);
    expect(find.text('TolongApp development sample'), findsOneWidget);

    // Without a route service the app says so instead of pretending to route.
    await scrollTo(tester, find.text('Show route'));
    expect(find.text('Start navigation'), findsNothing);
  });

  testWidgets('finding the user inside QC picks the nearest center with a straight-line distance', (tester) async {
    final map = FakeMap();
    await openSafePlaces(tester, map: map, location: FakeLocationService(const Located(GeoPoint(14.7270, 121.0425))));

    await tester.tap(find.byTooltip('Show my location'));
    await tester.pumpAndSettle();

    expect(find.text('user-dot'), findsOneWidget);
    expect(map.calls.last, 'focus 14.727,121.0425');
    await scrollTo(tester, find.text('NEAREST CENTER'));
    expect(find.text('Demo center 3'), findsWidgets);
    expect(find.textContaining('straight line (not a walking route)'), findsOneWidget);
  });

  testWidgets('outside Quezon City the app says so and does not recommend a center', (tester) async {
    await openSafePlaces(tester, location: FakeLocationService(const Located(GeoPoint(14.5547, 121.0244))));
    await tester.tap(find.byTooltip('Show my location'));
    await tester.pumpAndSettle();

    expect(find.textContaining('outside Quezon City'), findsOneWidget);
    expect(find.text('NEAREST CENTER'), findsNothing);
  });

  testWidgets('permission denied keeps the map usable', (tester) async {
    await openSafePlaces(tester, location: FakeLocationService(const LocationDenied()));
    await tester.tap(find.byTooltip('Show my location'));
    await tester.pumpAndSettle();
    expect(find.textContaining('You can still browse the map'), findsOneWidget);
  });

  testWidgets('blocked permission and location-off offer the right settings shortcut', (tester) async {
    final location = FakeLocationService(const LocationDeniedForever());
    await openSafePlaces(tester, location: location);
    await tester.tap(find.byTooltip('Show my location'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open settings'));
    expect(location.settingsOpened, 1);

    location.result = const LocationServiceOff();
    await tester.tap(find.byTooltip('Show my location'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Turn on'));
    expect(location.settingsOpened, 2);
  });
}
