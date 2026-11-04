import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tolong_flutter/features/safe_places/data/evacuation_center_repository.dart';
import 'package:tolong_flutter/features/safe_places/data/location_service.dart';
import 'package:tolong_flutter/features/safe_places/data/offline_map_service.dart';
import 'package:tolong_flutter/features/safe_places/data/qc_area_repository.dart';
import 'package:tolong_flutter/features/safe_places/domain/evacuation_center.dart';
import 'package:tolong_flutter/features/safe_places/domain/qc_area.dart';

import 'test_helpers.dart';

final boundary = QcAreaRepository.parseBoundary(File(QcAreaRepository.boundaryPath).readAsStringSync());
final barangays = QcAreaRepository.parseBarangays(File(QcAreaRepository.barangaysPath).readAsStringSync());

void main() {
  group('Quezon City boundary', () {
    test('contains well-known QC places', () {
      expect(boundary.contains(const GeoPoint(14.6537, 121.0685)), isTrue, reason: 'UP Diliman');
      expect(boundary.contains(const GeoPoint(14.6517, 121.0494)), isTrue, reason: 'Quezon Memorial Circle');
      expect(boundary.contains(const GeoPoint(14.7330, 121.0445)), isTrue, reason: 'Novaliches');
    });

    test('excludes neighbouring cities, including ones inside the old rectangle', () {
      expect(boundary.contains(const GeoPoint(14.5547, 121.0244)), isFalse, reason: 'Makati');
      expect(boundary.contains(const GeoPoint(14.6019, 121.0355)), isFalse, reason: 'San Juan');
      expect(boundary.contains(const GeoPoint(14.6507, 121.1029)), isFalse, reason: 'Marikina City Hall');
      // Inside the old approximate rectangle, but not in Quezon City.
      const pasigCorner = GeoPoint(14.6000, 121.1300);
      expect(qcApproxBounds.contains(pasigCorner), isTrue);
      expect(boundary.contains(pasigCorner), isFalse);
    });

    test('all demo centers lie inside the real boundary', () {
      final centers =
          EvacuationCenterRepository.parse(File(EvacuationCenterRepository.assetPath).readAsStringSync());
      for (final c in centers) {
        expect(boundary.contains(c.location), isTrue, reason: c.id);
      }
    });

    test('offline download of QC stays within OpenFreeMap\'s tile limit', () {
      final tiles = estimateTileCount(boundary.bounds, offlineMinZoom, offlineMaxZoom);
      expect(tiles, greaterThan(0));
      expect(tiles, lessThan(openFreeMapTileLimit));
    });
  });

  group('barangays', () {
    test('142 unique barangays with PSGC codes, matching PSA', () {
      expect(barangays.length, 142);
      expect(barangays.map((b) => b.name).toSet().length, 142);
      expect(barangays.every((b) => b.psgc != null), isTrue);
    });

    test('names and codes match the official PSGC fixture exactly', () {
      final fixture = jsonDecode(File('test/fixtures/psgc_qc_official.json').readAsStringSync())
          as Map<String, dynamic>;
      final official = {
        for (final b in fixture['barangays'] as List)
          (b as Map<String, dynamic>)['psgc']! as String: b['name']! as String,
      };
      final actual = {for (final b in barangays) b.psgc!: b.name};
      expect(actual, official);
    });

    test('search ignores case, accents, punctuation and common abbreviations', () {
      expect(searchBarangays(barangays, 'santo nino').first.name, 'Santo Niño');
      expect(searchBarangays(barangays, 'Sto. Niño').first.name, 'Santo Niño');
      expect(searchBarangays(barangays, 'bagong pag asa').first.name, 'Bagong Pag-asa');
      expect(searchBarangays(barangays, 'batasan').first.name, 'Batasan Hills');
      expect(searchBarangays(barangays, 'xyz'), isEmpty);
    });

    test('findBarangay returns the canonical spelling', () {
      expect(findBarangay(barangays, 'up campus')?.name, 'U.P. Campus');
      expect(findBarangay(barangays, 'Atlantis'), isNull);
    });
  });

  testWidgets('a point inside the old rectangle but outside QC is reported as outside', (tester) async {
    await pumpApp(
      tester,
      prefs: {'guest_mode': true, 'language': 'en'},
      location: FakeLocationService(const Located(GeoPoint(14.6000, 121.1300))),
    );
    await tester.tap(find.text('Safe places').last);
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('DEMO DATA · CENTERS NOT VERIFIED'));
    expect(find.text('qc-outline'), findsOneWidget);
    await tester.tap(find.byTooltip('Show my location'));
    await tester.pumpAndSettle();
    expect(find.textContaining('outside Quezon City'), findsOneWidget);
  });

  testWidgets('searching a barangay frames the map there and sorts centers from it', (tester) async {
    final map = FakeMap();
    await pumpApp(tester, prefs: {'guest_mode': true, 'language': 'en'}, map: map);
    await tester.tap(find.text('Safe places').last);
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('Search barangay'));
    await tester.tap(find.text('Search barangay'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'batasan');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Batasan Hills'));
    await tester.pumpAndSettle();

    expect(find.text('Barangay Batasan Hills'), findsOneWidget);
    final b = barangays.firstWhere((x) => x.name == 'Batasan Hills');
    expect(map.calls.last, 'focus ${b.center.lat},${b.center.lng}');
    await scrollTo(tester, find.textContaining('measured from the center of Barangay Batasan Hills'));

    await scrollTo(tester, find.byTooltip('Clear barangay'));
    await tester.tap(find.byTooltip('Clear barangay'));
    await tester.pumpAndSettle();
    expect(find.text('Search barangay'), findsOneWidget);
  });

  testWidgets('the profile form only accepts Quezon City barangays', (tester) async {
    await pumpApp(tester, prefs: {'guest_mode': true, 'language': 'en'});
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profile & household'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit').first);
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Maria Santos');
    await tester.enterText(find.widgetWithText(TextFormField, 'Age'), '34');
    await tester.enterText(find.widgetWithText(TextFormField, 'Barangay'), 'Atlantis');
    await scrollTo(tester, find.widgetWithText(FilledButton, 'Save'));
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(find.text('Choose a barangay from the Quezon City list.'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Barangay'), 'santo nino');
    await tester.pumpAndSettle();
    await scrollTo(tester, find.widgetWithText(FilledButton, 'Save'));
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(find.text('Santo Niño'), findsOneWidget);
  });

  testWidgets('offline map: download with progress, then delete with confirmation', (tester) async {
    final offline = FakeOfflineMapService();
    await pumpApp(tester, prefs: {'guest_mode': true, 'language': 'en'}, offline: offline);
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('Offline maps'));
    await tester.tap(find.text('Offline maps'));
    await tester.pumpAndSettle();

    expect(find.text('Not downloaded'), findsOneWidget);
    expect(find.textContaining('OpenFreeMap allows up to 3,000'), findsOneWidget);
    await tester.tap(find.text('Download Quezon City map'));
    await tester.pump();
    expect(offline.requestedBounds, isNotNull);

    offline.progress.add(const OfflineDownloading(0.42));
    await tester.pump();
    expect(find.text('Downloading… 42%'), findsOneWidget);

    offline.progress.add(OfflineDownloaded(at: DateTime(2026, 10, 18), bytes: 6 * 1024 * 1024));
    await tester.pump();
    expect(find.text('Downloaded Oct 18, 2026 · 6 MB'), findsOneWidget);

    await tester.tap(find.text('Delete offline map'));
    await tester.pumpAndSettle();
    expect(find.text('Delete the offline map?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Remove'));
    await tester.pumpAndSettle();
    expect(offline.deletes, 1);
    expect(find.text('Not downloaded'), findsOneWidget);
  });
}
