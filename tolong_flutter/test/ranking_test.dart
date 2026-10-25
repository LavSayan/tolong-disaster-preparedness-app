import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show ByteData, FlutterError, SynchronousFuture;
import 'package:flutter/services.dart' show AssetBundle, ImmutableBuffer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tolong_flutter/features/safe_places/application/ranking_controller.dart';
import 'package:tolong_flutter/features/safe_places/application/safe_places_controller.dart';
import 'package:tolong_flutter/features/safe_places/data/evacuation_center_repository.dart';
import 'package:tolong_flutter/features/safe_places/data/hazard_bands_repository.dart';
import 'package:tolong_flutter/features/safe_places/data/ranking_weights_repository.dart';
import 'package:tolong_flutter/features/safe_places/data/route_service.dart';
import 'package:tolong_flutter/features/safe_places/domain/evacuation_center.dart';
import 'package:tolong_flutter/features/safe_places/domain/qc_area.dart';
import 'package:tolong_flutter/features/safe_places/domain/ranking.dart';

final _assetJson = File('assets/data/hazard_bands.json').readAsStringSync();

/// Asset stub that only implements asset loading: loadString returns [raw], and a `null`
/// asset throws — how a missing asset surfaces through the real bundle in a test VM.
class _StubBundle implements AssetBundle {
  const _StubBundle(this.raw);

  final String? raw;

  @override
  Future<String> loadString(String key, {bool cache = true}) {
    if (raw == null) throw FlutterError('Unable to load asset: $key');
    return SynchronousFuture<String>(raw!);
  }

  @override
  Future<ByteData> load(String key) =>
      SynchronousFuture<ByteData>(ByteData.view(Uint8List.fromList(utf8.encode(raw ?? '')).buffer));

  @override
  Future<ImmutableBuffer> loadBuffer(String key) => throw UnimplementedError();

  @override
  Future<T> loadStructuredBinaryData<T>(String key, FutureOr<T> Function(ByteData data) parse) async =>
      parse(await load(key));

  @override
  Future<T> loadStructuredData<T>(String key, FutureOr<T> Function(String value) parse) async =>
      parse(await loadString(key));

  @override
  void clear() {}

  @override
  void evict(String key) {}
}

RankingFeatures features({
  required double exposure,
  required double travelSeconds,
  double accessibility = 0.5,
  bool travelEstimated = false,
}) =>
    RankingFeatures(
      exposure: exposure,
      travelSeconds: travelSeconds,
      accessibility: accessibility,
      travelEstimated: travelEstimated,
    );

void main() {
  group('RankingWeights structural rules (spec §5)', () {
    test('the hand-set defaults satisfy the constraint set exactly', () {
      const w = RankingWeights.defaults;
      expect(w.satisfiesConstraints(), isTrue, reason: 'the baseline is always admissible');
      expect(w.exposure + w.travel + w.accessibility, 100.0);
      expect(w.exposure, greaterThanOrEqualTo(minExposureWeight));
      expect(w.accessibility, greaterThanOrEqualTo(0.0));
    });

    test('violations are detected, not silently normalized', () {
      expect(const RankingWeights(exposure: 50, travel: 35, accessibility: 20).satisfiesConstraints(), isFalse,
          reason: 'the sum must be exactly 100');
      expect(const RankingWeights(exposure: 29, travel: 71, accessibility: 0).satisfiesConstraints(), isFalse,
          reason: 'exposure ≥ 30 prevents a distance-only model');
      expect(const RankingWeights(exposure: 40, travel: -1, accessibility: 61).satisfiesConstraints(), isFalse,
          reason: 'w ≥ 0 preserves monotonicity');
    });

    test('walking mode renormalizes 45/35/20 → 56.25/43.75 and stays admissible', () {
      final w = RankingWeights.defaults.withoutAccessibility;
      expect(w.accessibility, 0.0);
      expect(w.exposure, closeTo(56.25, 1e-9));
      expect(w.travel, closeTo(43.75, 1e-9));
      expect(w.satisfiesConstraints(), isTrue, reason: 'renormalization cannot break the safety set');
    });
  });

  group('RankingFeatures (spec §3 exact)', () {
    test('x_exposure is the complement of hazard-facing exposure', () {
      expect(features(exposure: 0.7, travelSeconds: 0).xExposure, closeTo(0.3, 1e-9));
      expect(features(exposure: 1.0, travelSeconds: 0).xExposure, 0.0);
      expect(features(exposure: 0.0, travelSeconds: 0).xExposure, 1.0);
    });

    test('x_travel normalizes against the fixed T_max and floors past an hour', () {
      expect(features(exposure: 0, travelSeconds: 1800).xTravel, closeTo(0.5, 1e-12));
      expect(features(exposure: 0, travelSeconds: 3600).xTravel, 0.0);
      expect(features(exposure: 0, travelSeconds: 7200).xTravel, 0.0,
          reason: 'past T_max floors to 0 — the pair is separated by exposure alone');
      expect(features(exposure: 0, travelSeconds: -1).xTravel, closeTo(1.0, 1e-12), reason: 'clamped');
    });

    test('the straight-line estimate divides metres by the walking speed', () {
      expect(estimateTravelSeconds(1200), closeTo(1000, 1e-9),
          reason: '1200 m ÷ 1.2 m/s; the UI labels this "estimated"');
    });

    test('factorValues come out in the parity order [exposure, travel, accessibility]', () {
      final v = features(exposure: 0.5, travelSeconds: 900).factorValues;
      expect(v[0], closeTo(0.5, 1e-9));
      expect(v[1], closeTo(0.75, 1e-9));
      expect(v[2], 0.5);
    });
  });

  group('scoring and pairwise form (spec §2)', () {
    test('matches a hand-computed example, contributions inclusive', () {
      const weights = RankingWeights.defaults;
      final features4535 = features(exposure: 0.2, travelSeconds: 900, accessibility: 0.5);
      // x = (0.8, 0.75, 0.5) → 45·0.8 + 35·0.75 + 20·0.5 = 36 + 26.25 + 10 = 72.25
      expect(weights.score(features4535), closeTo(72.25, 1e-9));
      final c = weights.contributions(features4535);
      expect(c['exposure'], closeTo(36.0, 1e-9));
      expect(c['travel'], closeTo(26.25, 1e-9));
      expect(c['accessibility'], closeTo(10.0, 1e-9));
      expect(c['exposure']! + c['travel']! + c['accessibility']!, closeTo(weights.score(features4535), 1e-9),
          reason: 'contributions reconcile to the whole score (spec §7 audit)');
    });

    test('the pairwise decision mirrors the score difference', () {
      final preferred = features(exposure: 0.1, travelSeconds: 600);
      final other = features(exposure: 0.9, travelSeconds: 2400);
      final d = RankingWeights.defaults.score(preferred) - RankingWeights.defaults.score(other);
      expect(RankingWeights.defaults.probabilityPreferred(preferred, other), closeTo(1 / (1 + exp(-d)), 1e-12));
      expect(RankingWeights.defaults.probabilityPreferred(preferred, preferred), 0.5);
    });

    test('monotonicity: strictly lower exposure and travel never rank below, any admissible weights',
        () {
      // The structural invariant of spec §3, sampled across the full interior of the
      // constraint set including the corners where one weight is 0. Accessibility is held
      // equal per pair: a verified route (1.0) legitimately beats a failed one (0.0), so the
      // invariant is over the two features the user's situation actually orders.
      final random = Random(42);
      for (var i = 0; i < 200; i++) {
        final e = minExposureWeight + random.nextDouble() * (totalWeightConstraint - minExposureWeight);
        final t = random.nextDouble() * (totalWeightConstraint - e);
        final weights = RankingWeights(exposure: e, travel: t, accessibility: totalWeightConstraint - e - t);
        expect(weights.satisfiesConstraints(), isTrue, reason: 'sampled weights must be admissible');

        final hazardHigh = random.nextDouble();
        final hazardLow = random.nextDouble() * hazardHigh; // strictly ≤; < when hazardHigh > 0
        final secondsLong = random.nextDouble() * travelTimeCapSeconds * 2;
        final secondsShort = random.nextDouble() * secondsLong; // strictly ≤; < when secondsLong > 0
        final accessibility = random.nextDouble();
        final worse = features(exposure: hazardHigh, travelSeconds: secondsLong, accessibility: accessibility);
        final better = features(exposure: hazardLow, travelSeconds: secondsShort, accessibility: accessibility);
        expect(weights.score(better), closeTo(
          weights.score(worse) +
              weights.exposure * (hazardHigh - hazardLow) +
              weights.travel *
                  ((1 - secondsShort / travelTimeCapSeconds).clamp(0.0, 1.0) -
                      (1 - secondsLong / travelTimeCapSeconds).clamp(0.0, 1.0)),
          1e-9,
        ), reason: 'score delta decomposes into non-negative contributions (pair #$i)');
        expect(weights.score(better) >= weights.score(worse), isTrue,
            reason: 'the better-situated candidate can never rank below (pair #$i, e=$e t=$t)');
        if (hazardHigh > 0 && secondsLong > 0) {
          expect(weights.probabilityPreferred(better, worse), greaterThan(0.5),
              reason: 'the pairwise direction must agree (pair #$i)');
        }
      }
    });
  });

  group('HazardBands asset contract (Phase 1 gate)', () {
    late HazardBands bands;

    setUpAll(() {
      bands = HazardBands.parse(_assetJson);
    });

    test('the asset gates under 5 MB (spec §7 Phase 1 gate)', () {
      expect(File('assets/data/hazard_bands.json').lengthSync(), lessThanOrEqualTo(5 * 1024 * 1024));
    });

    test('describes all 148 sites: 142 barangay proxies + 6 demo centres', () {
      expect(bands.sites, hasLength(148));
      expect(bands.sites.where((s) => s.kind == 'barangay'), hasLength(142));
      expect(bands.sites.where((s) => s.kind == 'demo'), hasLength(6));
      final byId = bands.byId;
      for (final id in ['demo-01', 'demo-06', 'bgy-000', 'bgy-141']) {
        expect(byId[id], isNotNull, reason: id);
      }
      expect(bands.version, 1);
      expect(bands.sourceSha256, hasLength(64), reason: 'provenance must pin the source archive');
      expect(bands.notes, isNotEmpty, reason: 'the extractor records global exclusions as notes');
    });

    test('every stored exposure block is internally consistent', () {
      for (final site in bands.sites) {
        expect(site.exposureValue, inInclusiveRange(0.0, 1.0), reason: '${site.id} exposure');
        expect(site.exposureValue, closeTo(max(site.floodComposite, site.landslide), 1e-9),
            reason: '${site.id}: exposure == max(floodComposite, landslide)');
        expect(site.floodComposite, inInclusiveRange(0.0, 1.0), reason: '${site.id} floodComposite');
        expect(site.landslide, inInclusiveRange(0.0, 1.0), reason: '${site.id} landslide');
      }
    });

    test('storm surge is null per site, with the exclusion recorded as a note', () {
      for (final site in bands.sites) {
        expect(site.bands.containsKey('storm_surge'), isTrue, reason: site.id);
        expect(site.bands['storm_surge'], isNull, reason: site.id);
      }
      expect(
        bands.notes.firstWhere((n) => n.contains('storm_surge'), orElse: () => ''),
        contains('never per site'),
      );
    });

    test('exposureAt returns the nearest site within the radius, else unknown', () {
      // Exact centre: distance ~0, exposure matches the stored site value.
      final demo01 = bands.byId['demo-01']!;
      final local = bands.exposureAt(demo01.location)!;
      expect(local.distanceMeters, lessThan(0.01), reason: 'the sampled point itself');
      expect(local.exposure, demo01.exposureValue);

      // Unknown points are honest: outside the match radius the feature is simply null.
      final random = Random(7);
      for (var i = 0; i < 50; i++) {
        final p = GeoPoint(14.59 + random.nextDouble() * 0.185, 120.985 + random.nextDouble() * 0.15);
        final match = bands.exposureAt(p);
        HazardSite? nearest;
        var nearestMeters = double.infinity;
        for (final site in bands.sites) {
          final d = p.distanceKm(site.location) * 1000;
          if (d < nearestMeters) {
            nearestMeters = d;
            nearest = site;
          }
        }
        if (nearestMeters > bandMatchRadiusMeters) {
          expect(match, isNull, reason: 'nearest site ${nearest?.id} is ${nearestMeters.toStringAsFixed(1)} m away');
        } else {
          expect(match!.site.id, nearest!.id, reason: 'no closer site may win the match');
          expect(match.exposure, nearest.exposureValue);
        }
      }
    });
  });

  group('RankingWeightsRepository contract (spec §6)', () {
    const validWeightsJson = '''
    {"version": 1,
     "method": "pairwise-logistic-slsqp",
     "factors": ["exposure", "travel", "accessibility"],
     "weights": {"exposure": 47.5, "travel": 32.5, "accessibility": 20.0},
     "constraints": {"sum": 100, "nonNegative": true, "minExposure": 30},
     "dataset": {"path": "tools/ranking/data/pairs.jsonl", "sha256": "abc", "pairs": 142},
     "fit": {"cvPairwiseAccuracy": 0.62, "cvLogLoss": 0.51, "baselineAccuracy": 0.6, "lambda": 0.1}}
    ''';

    Map<String, String> invalidWeights() => {
          'corrupt json': '{not json',
          'unknown asset type': '{"asset": "other"}',
          'unsupported version': '{"version": 2, "method": "pairwise-logistic-slsqp", '
              '"factors": ["exposure", "travel", "accessibility"], '
              '"weights": {"exposure": 45, "travel": 35, "accessibility": 20}, '
              '"dataset": {"path": "x", "sha256": "s", "pairs": 1}}',
          'factor set mismatch': '{"version": 1, "method": "pairwise-logistic-slsqp", '
              '"factors": ["travel", "exposure", "accessibility"], '
              '"weights": {"exposure": 45, "travel": 35, "accessibility": 20}, '
              '"dataset": {"path": "x", "sha256": "s", "pairs": 1}}',
          'sum constraint violated': '{"version": 1, "method": "pairwise-logistic-slsqp", '
              '"factors": ["exposure", "travel", "accessibility"], '
              '"weights": {"exposure": 80, "travel": 35, "accessibility": 20}, '
              '"dataset": {"path": "x", "sha256": "s", "pairs": 1}}',
          'negative weight': '{"version": 1, "method": "pairwise-logistic-slsqp", '
              '"factors": ["exposure", "travel", "accessibility"], '
              '"weights": {"exposure": 120, "travel": -20, "accessibility": 0}, '
              '"dataset": {"path": "x", "sha256": "s", "pairs": 1}}',
          'exposure below floor': '{"version": 1, "method": "pairwise-logistic-slsqp", '
              '"factors": ["exposure", "travel", "accessibility"], '
              '"weights": {"exposure": 20, "travel": 80, "accessibility": 0}, '
              '"dataset": {"path": "x", "sha256": "s", "pairs": 1}}',
          'missing dataset provenance': '{"version": 1, "method": "pairwise-logistic-slsqp", '
              '"factors": ["exposure", "travel", "accessibility"], '
              '"weights": {"exposure": 45, "travel": 35, "accessibility": 20}}',
        };

    test('a valid trained export loads with dataset provenance', () {
      final source = parseRankingWeights(validWeightsJson);
      expect(source, isA<TrainedWeights>());
      final trained = source as TrainedWeights;
      expect(trained.weights.exposure, 47.5);
      expect(trained.datasetSha256, 'abc');
      expect(trained.pairCount, 142);
      expect(source.isTrained, isTrue);
    });

    invalidWeights().forEach((name, json) {
      test('parse rejects: $name', () {
        expect(() => parseRankingWeights(json), throwsFormatException, reason: name);
      });
    });

    test('a missing asset falls back to defaults with the failure reason surfaced', () async {
      final source = await RankingWeightsRepository(const _StubBundle(null)).load();
      expect(source.isTrained, isFalse);
      expect(source.weights, equals(RankingWeights.defaults));
      expect((source as RankingDefaults).reason, isNotEmpty);
    });

    test('corrupt content falls back to defaults, never to a partial model', () async {
      final source = await RankingWeightsRepository(const _StubBundle('{not json')).load();
      expect(source.isTrained, isFalse);
      expect(source.weights, equals(RankingWeights.defaults));
      expect((source as RankingDefaults).reason, isNotEmpty);
    });

    test('constraint-violating content falls back to defaults at runtime', () async {
      final source =
          await RankingWeightsRepository(_StubBundle(invalidWeights()['sum constraint violated']!)).load();
      expect(source.isTrained, isFalse);
      expect(source.weights, equals(RankingWeights.defaults));
    });
  });

  group('shipped trained weights (spec §5-§6)', () {
    late TrainedWeights trained;

    setUpAll(() {
      final document = File('assets/data/ranking_weights.json').readAsStringSync();
      final source = parseRankingWeights(document);
      expect(source, isA<TrainedWeights>(), reason: 'the shipped file must be a trained export');
      trained = source as TrainedWeights;
    });

    test('the shipped weights satisfy the constraint set: sum 100, non-negative, exposure floor', () {
      expect(trained.weights.satisfiesConstraints(), isTrue,
          reason: 'spec §5: constraints are safety requirements, not tuning knobs');
    });

    test('dataset provenance is pinned and the pair count matches the gates', () {
      expect(trained.pairCount, inInclusiveRange(100, 150), reason: 'spec §4 total pairs');
      expect(trained.datasetSha256, hasLength(64), reason: 'the dataset sha is the provenance contract');
    });

    test('monotonicity under the shipped weights (200 seeded candidate pairs)', () {
      // Same invariant as the defaults property, but with the real trained weights:
      // a retrain that learns "worse hazard, longer walk is better" fails here first.
      final random = Random(7);
      for (var i = 0; i < 200; i++) {
        final hazardHigh = random.nextDouble();
        final hazardLow = random.nextDouble() * hazardHigh;
        final secondsLong = random.nextDouble() * travelTimeCapSeconds * 2;
        final secondsShort = random.nextDouble() * secondsLong;
        final accessibility = random.nextDouble();
        final worse = RankingFeatures(
            exposure: hazardHigh, travelSeconds: secondsLong, accessibility: accessibility);
        final better = RankingFeatures(
            exposure: hazardLow, travelSeconds: secondsShort, accessibility: accessibility);
        expect(trained.weights.score(better), greaterThanOrEqualTo(trained.weights.score(worse)),
            reason: 'better-situated can never rank below (pair #$i)');
        if (hazardHigh > hazardLow && secondsShort < secondsLong) {
          expect(trained.weights.probabilityPreferred(better, worse), greaterThan(0.5),
              reason: 'pairwise direction agrees (pair #$i)');
        }
      }
    });
  });

  group('RankingController (Phase 2 integration, spec §6-§8)', () {
    ProviderContainer container() {
      final c = ProviderContainer(overrides: [
        evacuationCentersProvider
            .overrideWith((ref) async => EvacuationCenterRepository.parse(File(EvacuationCenterRepository.assetPath).readAsStringSync())),
        hazardBandsProvider.overrideWith((ref) async => HazardBands.parse(_assetJson)),
        rankingWeightsProvider.overrideWith((ref) async => const RankingDefaults(reason: 'test: defaults')),
      ]);
      return c;
    }

    Future<RankingState> readyRanking(ProviderContainer c) async {
      await c.read(evacuationCentersProvider.future);
      await c.read(hazardBandsProvider.future);
      await c.read(rankingWeightsProvider.future);
      return c.read(rankedCentersProvider);
    }

    test('no reference point: ranking stays inactive, no invented numbers', () async {
      final c = container();
      final ranking = await readyRanking(c);
      expect(ranking.available, isFalse, reason: 'a user-less list has no situation to rank for');
      expect(ranking.ranked, isEmpty);
    });

    test('hazard bands unavailable: ranking unavailable, plain distance order remains', () async {
      final c = ProviderContainer(overrides: [
        rankingWeightsProvider.overrideWith((ref) async => const RankingDefaults(reason: 'test')),
        hazardBandsProvider.overrideWith((ref) async => null),
        evacuationCentersProvider
            .overrideWith((ref) async => EvacuationCenterRepository.parse(File(EvacuationCenterRepository.assetPath).readAsStringSync())),
      ]);
      await c.read(evacuationCentersProvider.future);
      await c.read(rankingWeightsProvider.future);
      c.read(safePlacesProvider.notifier)
          .setBarangay(const Barangay(name: 'Batasan Hills', psgc: null, center: GeoPoint(14.706, 121.091)));
      final ranking = c.read(rankedCentersProvider);
      expect(ranking.available, isFalse, reason: 'spec §3: asset failure → fallback, never invented exposure');
      expect(ranking.ranked, isEmpty);
      expect(ranking.weights, equals(RankingWeights.defaults));
    });

    test('with a reference point, centers acquire rank, known exposure and estimated travel', () async {
      final c = container();
      await c.read(evacuationCentersProvider.future);
      await c.read(hazardBandsProvider.future);
      await c.read(rankingWeightsProvider.future);
      c.read(safePlacesProvider.notifier).setBarangay(const Barangay(name: 'Batasan Hills', psgc: null, center: GeoPoint(14.706, 121.091)));
      final ranking = c.read(rankedCentersProvider);
      expect(ranking.available, isTrue);
      expect(ranking.ranked, hasLength(6));
      expect(ranking.weightsTrained, isFalse);
      for (var i = 1; i < ranking.ranked.length; i++) {
        expect(ranking.ranked[i].score, lessThanOrEqualTo(ranking.ranked[i - 1].score),
            reason: 'rows must come score-descending');
        expect(ranking.ranked[i].rank, i + 1);
      }
      final first = ranking.ranked.first;
      // demo centres ship exact coordinates in the asset: no exposure unknowns among them.
      expect(ranking.ranked.any((r) => r.exposureUnknown), isFalse, reason: 'all 6 demo ids are in the asset');
      expect(first.features.travelEstimated, isTrue, reason: 'no route fetched yet → always the estimate');
    });

    test('walking mode excludes accessibility by renormalization, all-or-nothing', () async {
      final c = container();
      await c.read(evacuationCentersProvider.future);
      await c.read(hazardBandsProvider.future);
      await c.read(rankingWeightsProvider.future);
      c.read(safePlacesProvider.notifier)
          .setBarangay(const Barangay(name: 'Batasan Hills', psgc: null, center: GeoPoint(14.706, 121.091)));
      final walking = c.read(rankedCentersProvider);
      expect(walking.available, isTrue);
      expect(walking.weights.exposure, closeTo(56.25, 1e-9));
      expect(walking.weights.accessibility, 0.0);
      c.read(safePlacesProvider.notifier).setProfile(RouteProfile.wheelchair);
      final wheelchair = c.read(rankedCentersProvider);
      expect(wheelchair.weights, equals(RankingWeights.defaults), reason: 'wheelchair keeps all three factors');
    });
  });
}
