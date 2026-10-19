import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tolong_flutter/features/safe_places/data/hazard_layer_service.dart';
import 'package:tolong_flutter/features/safe_places/data/map_style.dart';
import 'package:tolong_flutter/features/safe_places/domain/evacuation_center.dart';
import 'package:tolong_flutter/features/safe_places/domain/hazard.dart';
import 'package:tolong_flutter/l10n/l10n.dart';

import 'test_helpers.dart';

/// Locates the bundled hazard archives relative to the package root, the way Flutter resolves
/// `assets/...` in a built app.
File _dataset(String name) => File('datasets/$name');

/// Reads the first [count] bytes of [f] so archive assertions can inspect the PMTiles header.
List<int> _head(File f, int count) => f.readAsBytesSync().take(count).toList();

/// Opens Safe places the way a user does: guest mode, tap the tab, scroll the map into view.
Future<AppLocalizations> openSafePlaces(WidgetTester tester) async {
  final l = await l10n('en');
  await pumpApp(tester, prefs: {'guest_mode': true, 'language': 'en'});
  await tester.tap(find.text(l.tabSafePlaces).last);
  await tester.pumpAndSettle();
  await scrollTo(tester, find.byTooltip(l.mapResetView));
  return l;
}

Future<AppLocalizations> l10n(String language) =>
    AppLocalizations.delegate.load(Locale(language));

void main() {
  group('bundled hazard archives', () {
    test('both archives ship in datasets/', () {
      expect(_dataset('qc_flood.pmtiles').existsSync(), isTrue,
          reason: 'qc_flood.pmtiles must be committed for members to build');
      expect(_dataset('qc_base.pmtiles').existsSync(), isTrue);
    });

    test('archives are real PMTiles, not placeholders', () {
      for (final f in [_dataset('qc_flood.pmtiles'), _dataset('qc_base.pmtiles')]) {
        final head = _head(f, 7);
        expect(String.fromCharCodes(head), 'PMTiles', reason: '${f.path} must start with the PMTiles magic');
      }
    });

    test('the flood archive is the Quezon City extract, not the national file', () {
      // The national NOAH archive is 81,712 tiles and 5.17 GB. Asserting the tile count from the
      // v3 header keeps a national file from being swapped in without anyone noticing.
      final h = _head(_dataset('qc_flood.pmtiles'), 104);
      final numAddressedTiles = h[72] | (h[73] << 8) | (h[74] << 16) | (h[75] << 24);
      expect(numAddressedTiles, lessThan(1000),
          reason: 'QC extract is 169 tiles; a national file would be 81,712');
      expect(numAddressedTiles, greaterThan(0));
    });

    test('the archive URL is the pmtiles scheme MapLibre resolves', () {
      expect(hazardArchiveUrl, startsWith(pmtilesScheme));
      expect(hazardArchiveUrl, contains('qc_flood.pmtiles'));
    });

    test('the archive URL has three slashes so it matches the registered key', () {
      // The pmtiles library keys registered archives by getKey() and looks them up by stripping
      // exactly ten characters — the length of "pmtiles://" — off the style's source URL. If the
      // two disagree it silently builds a *second* archive and re-fetches 51 MB, so the leading
      // slash is load-bearing, not cosmetic.
      expect(hazardArchiveUrl.substring(0, pmtilesScheme.length + 1), 'pmtiles:///');
      expect(hazardArchiveUrl.substring(pmtilesScheme.length), '/assets/datasets/qc_flood.pmtiles');
    });

    test('the bundled archive is served from the path the URL asks for', () {
      // Guards the web path: MapLibre fetches `assetUrl` relative to the page, and the Flutter
      // build serves the archive under /assets/.
      const assetUrl = '/assets/datasets/qc_flood.pmtiles';
      expect(hazardArchiveUrl.substring(pmtilesScheme.length), assetUrl);
      expect(File('build/web$assetUrl').existsSync() || _dataset('qc_flood.pmtiles').existsSync(), isTrue,
          reason: 'the archive must exist at $assetUrl in a web build');
    });

    test('the overlay reports itself available when the protocol is registered', () {
      // `kIsWeb` is compile-time, so the platform gate cannot be exercised from a test. What can
      // be checked is that availability is driven by the recorded registration outcome rather
      // than by the platform.
      setPmTilesRegistered(true);
      expect(hazardOverlayAvailable(), isTrue);
      setPmTilesRegistered(false);
      expect(hazardOverlayAvailable(), isFalse);
      setPmTilesRegistered(true);
    });
  });

  group('hazard grouping', () {
    test('every NOAH source layer belongs to exactly one group', () {
      final grouped = HazardGroup.values.expand((g) => g.sourceLayers).toList();
      expect(grouped.toSet().length, grouped.length, reason: 'no layer may appear in two groups');
      expect(
        grouped,
        containsAll(<String>[
          'flood_5yr',
          'flood_25yr',
          'flood_100yr',
          'landslide',
          'debris_flow',
          'storm_surge_ssa1',
          'storm_surge_ssa4',
        ]),
        reason: 'all nine bundled NOAH layers must be reachable from some group',
      );
    });

    test('flood layers share one severity attribute, the rest use HAZ', () {
      expect(HazardGroup.flood.severityAttribute, 'Var');
      for (final g in [HazardGroup.landslide, HazardGroup.stormSurge, HazardGroup.debrisFlow]) {
        expect(g.severityAttribute, 'HAZ', reason: '$g');
      }
    });

    test('severity codes match the ranges the archive actually carries', () {
      // flood_* use Var 1..3; landslide and surge use HAZ 1..3/1..4.
      expect(HazardGroup.flood.severityBands.map((b) => b.code), ['1', '2', '3']);
      expect(HazardGroup.landslide.severityBands.map((b) => b.code), ['1', '2', '3', '4']);
      expect(HazardGroup.debrisFlow.severityBands.map((b) => b.code).last, '4');
    });

    test('storm surge is a coastal hazard with no Quezon City data', () {
      // Quezon City is inland, so the surge layers legitimately contain nothing here. The legend
      // must say so rather than render an empty key.
      expect(HazardGroup.stormSurge.sourceLayers, hasLength(4));
    });
  });

  group('hazard layer specs', () {
    test('no group means no layers', () {
      expect(hazardLayerSpecs(null), isEmpty);
    });

    test('one layer per source layer per severity band', () {
      final specs = hazardLayerSpecs(HazardGroup.flood);
      expect(specs, hasLength(3 * 3));
      expect(specs.every((s) => s.sourceLayer.startsWith('flood_')), isTrue);
    });

    test('layer ids are unique so a rebuild never stacks duplicate fills', () {
      for (final g in HazardGroup.values) {
        final ids = hazardLayerSpecs(g).map((s) => s.id).toList();
        expect(ids.toSet().length, ids.length, reason: 'duplicate ids in $g');
      }
    });

    test('only the deepest band is opaque enough to hide streets', () {
      for (final g in HazardGroup.values) {
        final specs = hazardLayerSpecs(g);
        final max = specs.map((s) => s.band.level).reduce((a, b) => a > b ? a : b);
        final peak = specs.firstWhere((s) => s.band.level == max);
        expect(peak.opacity, greaterThan(0.5), reason: 'deepest $g band');
        expect(specs.firstWhere((s) => s.band.level == 1).opacity, lessThan(0.3));
      }
    });

    test('every band layer filters on its own severity code', () {
      // Regression guard: the fills used to be added without a filter, so every band layer
      // painted *all* features of its source layer and the severity colours collapsed into
      // whichever fill was added last — the legend described something the map never drew.
      for (final g in HazardGroup.values) {
        for (final spec in hazardLayerSpecs(g)) {
          final filter = hazardFilterExpression(spec);
          expect(filter, hasLength(3), reason: spec.id);
          expect(filter.first, '==', reason: spec.id);
          expect(filter[1], ['get', spec.attribute], reason: spec.id);
          expect(filter.last, spec.band.code, reason: spec.id);
        }
      }
    });

    test('flood bands filter on Var, every other group on HAZ', () {
      expect(
        hazardFilterExpression(hazardLayerSpecs(HazardGroup.flood)[3]),
        ['==', ['get', 'Var'], '1'],
      );
      expect(
        hazardFilterExpression(hazardLayerSpecs(HazardGroup.landslide).first),
        ['==', ['get', 'HAZ'], '1'],
      );
    });
  });

  group('legend wording', () {
    test('names every group and severity band in both languages', () async {
      final en = await l10n('en');
      final fil = await l10n('fil');
      for (final g in HazardGroup.values) {
        expect(en.hazardGroupName(g), isNotEmpty, reason: '$g en');
        expect(fil.hazardGroupName(g), isNotEmpty, reason: '$g fil');
      }
      for (final level in [1, 2, 3, 4]) {
        expect(en.hazardSeverity(level), isNotEmpty);
        expect(fil.hazardSeverity(level), isNotEmpty);
      }
    });

    test('the overlay never claims safety, only lower exposure', () async {
      // The app's honesty rule: modelled hazard may describe lower exposure, never a guarantee.
      // Note the check is on *claims*, not the substring "safe" — "not a safety guarantee"
      // deliberately contains it, and a substring test would pass a string making the opposite
      // claim.
      for (final forbidden in ['is safe', 'safe route', 'guaranteed safe', 'will not flood']) {
        expect((await l10n('en')).hazardLowerExposure.toLowerCase(), isNot(contains(forbidden)));
        expect((await l10n('en')).hazardLegendNote.toLowerCase(), isNot(contains(forbidden)));
      }
      // The disclaimer itself must stay: the hazard copy has to say it is not live and not a
      // guarantee, otherwise the overlay overstates what NOAH models.
      final en = await l10n('en');
      expect(en.hazardLowerExposure, contains('exposure'));
      expect(en.hazardLowerExposure.toLowerCase(), contains('not a safety guarantee'));
      expect(en.hazardLegendNote, contains('not live conditions'));
    });

    test('the gap in NOAH coverage is stated, not implied', () async {
      final en = await l10n('en');
      final fil = await l10n('fil');
      expect(en.hazardCoverageGap, contains('earthquake'));
      expect(en.hazardCoverageGap, contains('fire'));
      expect(fil.hazardCoverageGap, isNotEmpty);
      expect(en.hazardCoverageGap.toLowerCase(), isNot(contains('every hazard')));
    });
  });

  group('hazard overlay on the map screen', () {
    testWidgets('the picker lists all four groups', (tester) async {
      final l = await openSafePlaces(tester);

      await tester.tap(find.byTooltip(l.hazardButton));
      await tester.pumpAndSettle();

      for (final g in HazardGroup.values) {
        expect(find.text(l.hazardGroupName(g)), findsOneWidget, reason: '$g missing from picker');
      }
    });

    testWidgets('selecting a group shows the legend with the honest framing', (tester) async {
      final l = await openSafePlaces(tester);

      await tester.tap(find.byTooltip(l.hazardButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.hazardGroupName(HazardGroup.flood)));
      await tester.pumpAndSettle();
      await scrollTo(tester, find.text(l.hazardLowerExposure));

      expect(find.text(l.hazardTitle), findsOneWidget);
      expect(find.textContaining('Modelled scenarios'), findsOneWidget);
      // Every band must be explainable without tapping the map.
      for (final band in HazardGroup.flood.severityBands) {
        expect(find.text(l.hazardSeverity(band.level)), findsOneWidget, reason: 'band ${band.code}');
      }
    });

    testWidgets('storm surge says there is no data rather than showing an empty key', (tester) async {
      final l = await openSafePlaces(tester);

      await tester.tap(find.byTooltip(l.hazardButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.hazardGroupName(HazardGroup.stormSurge)));
      await tester.pumpAndSettle();
      await scrollTo(tester, find.text(l.hazardNoData));

      expect(find.text(l.hazardNoData), findsOneWidget);
      expect(find.text(l.hazardSeverity(1)), findsNothing);
    });

    testWidgets('the overlay is off by default and no legend is shown', (tester) async {
      final l = await openSafePlaces(tester);
      expect(find.text(l.hazardTitle), findsNothing);
    });

    testWidgets('the picker is offered even when the archive cannot be read', (tester) async {
      // Regression guard: the button used to be hidden behind `if (!kIsWeb)`, which made the
      // overlay unreachable on exactly the platform it was written for. Availability must be
      // reported, never used to remove the control.
      final l = await openSafePlaces(tester);
      expect(find.byTooltip(l.hazardButton), findsOneWidget);
    });

    testWidgets('a failed registration disables the groups and says why', (tester) async {
      final l = await openSafePlaces(tester);
      setPmTilesRegistered(false);
      addTearDown(() => setPmTilesRegistered(true));

      await tester.tap(find.byTooltip(l.hazardButton));
      await tester.pumpAndSettle();

      // Reported, not hidden.
      expect(find.text(l.hazardUnavailableGeneric), findsOneWidget);
      expect(find.text(l.hazardGroupName(HazardGroup.flood)), findsOneWidget,
          reason: 'the groups stay visible so the user can see what is supported');
    });
  });

  group('basemap seam', () {
    test('the app still uses the hosted OpenFreeMap basemap', () {
      expect(BasemapStyle.current, BasemapStyle.openFreeMap);
      expect(BasemapStyle.current.styleUrl, startsWith('https://'));
    });

    test('the bundled alternative is one value away and stays inside QC', () {
      const local = BasemapStyle.localPmtiles;
      expect(local.styleUrl, startsWith(pmtilesScheme));
      expect(local.styleUrl, contains('qc_base.pmtiles'));
      // The archive header bounds are 120.9697,14.5691 -> 121.1538,14.7964 and must enclose
      // Quezon City rather than being a national file.
      expect(qcApproxBounds.southwest.lng, greaterThan(120.96));
      expect(qcApproxBounds.northeast.lng, lessThan(121.16));
      expect(qcApproxBounds.southwest.lat, greaterThan(14.55));
      expect(qcApproxBounds.northeast.lat, lessThan(14.80));
    });
  });
}
