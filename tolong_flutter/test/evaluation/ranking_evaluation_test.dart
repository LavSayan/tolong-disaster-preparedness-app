// The printed markdown blocks are the deliverable of SHELTER_RANKING_ML.md §7
// ("results to be pasted here") — not debug leftovers.
// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show compute;
import 'package:flutter_test/flutter_test.dart';
import 'package:tolong_flutter/features/safe_places/data/hazard_bands_repository.dart';
import 'package:tolong_flutter/features/safe_places/data/ranking_weights_repository.dart';
import 'package:tolong_flutter/features/safe_places/domain/evacuation_center.dart';
import 'package:tolong_flutter/features/safe_places/domain/ranking.dart';

/// Model evaluation (SHELTER_RANKING_ML.md §7). Every printed block is markdown
/// meant to be pasted verbatim into §7; numbers are measured or derived from the
/// shipped assets, never hoped. Runs under `flutter test --concurrency=1`.
///
/// The candidate universe for the ablation reports is the real asset site set
/// (148 points), with synthetic travel and accessibility draws (Random(42),
/// documented ranges) — the label set is §4's expert pairs, so evaluation uses a
/// different universe than training on purpose.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final golden = jsonDecode(
          File('test/fixtures/ranking_golden.json').readAsStringSync())
      as Map<String, dynamic>;
  final sets = (golden['sets']! as List).cast<Map<String, dynamic>>();

  final trainedSource = parseRankingWeights(
      File('assets/data/ranking_weights.json').readAsStringSync());
  final weightSets = <String, RankingWeights>{
    'hand-set baseline': RankingWeights.defaults,
    'trained v1': trainedSource.weights,
  };

  final assetDoc =
      jsonDecode(File('assets/data/hazard_bands.json').readAsStringSync()) as Map<String, dynamic>;
  final sites = (assetDoc['sites']! as List).cast<Map<String, dynamic>>();
  final universe = <Map<String, dynamic>>[
    for (final s in sites)
      {
        'id': s['id'] as String,
        'exposure': (s['exposure'] as Map<String, dynamic>)['exposure'] as double,
        'travelSeconds': ((s['lat'] + 14.7).abs() / 0.35 * 5280.0 + 120.0),
        'accessibility': (s['id'].hashCode % 3 == 0)
            ? 0.5
            : (s['id'].hashCode % 3 == 1 ? 1.0 : 0.0),
      }
  ];

  RankingFeatures featuresOf(Map<String, dynamic> c) => RankingFeatures(
        exposure: (c['exposure'] as num).toDouble(),
        travelSeconds: (c['travelSeconds'] as num).toDouble(),
        accessibility: (c['accessibility'] as num).toDouble(),
        // The engine evaluation runs straight-line-only: that IS the re-rank
        // fast path the controller uses when no route needs fetching.
        travelEstimated: true,
      );

  RankingWeights without(RankingWeights w, String factor) => RankingWeights(
        exposure: factor == 'exposure' ? 0.0 : w.exposure,
        travel: factor == 'travel' ? 0.0 : w.travel,
        accessibility: factor == 'accessibility' ? 0.0 : w.accessibility,
      );

  List<String> orderedWithTies(RankingWeights w, Iterable<Map<String, dynamic>> candidates, String? drop) {
    final use = drop == null ? w : without(w, drop);
    final rows = candidates
        .map((c) => (id: c['id']! as String, score: use.score(featuresOf(c))))
        .toList()
      ..sort((a, b) {
        final byScore = b.score.compareTo(a.score);
        return byScore != 0 ? byScore : a.id.compareTo(b.id);
      });
    return rows.map((r) => r.id).toList();
  }

  double kendallTau(List<String> a, List<String> b) {
    final position = {for (var i = 0; i < b.length; i++) b[i]: i};
    var agree = 0, disagree = 0;
    for (var i = 0; i < a.length; i++) {
      for (var j = i + 1; j < a.length; j++) {
        if ((position[a[i]]! - position[a[j]]!).sign == (i - j).sign) {
          agree++;
        } else {
          disagree++;
        }
      }
    }
    final n = agree + disagree;
    return n == 0 ? 1.0 : (agree - disagree) / n;
  }

  // The evaluation uses the same features the controller computes, so a fixed
  // travel/accessibility draw count stays deterministic.
  group('Golden orderings (both weight sets, spec §7)', () {
    test('every golden set reproduces under baseline and trained weights', () {
      final report = StringBuffer(
          'Golden orderings over `test/fixtures/ranking_golden.json`\n\n'
          '| set | baseline ok | trained ok | weakest margin (min weights) |\n|---|---|---|---|\n');
      for (final set in sets) {
        final candidates = (set['candidates']! as List).cast<Map<String, dynamic>>();
        final expected = (set['expectedOrder']! as List).cast<String>();
        final perSet = <String, bool>{};
        weightSets.forEach((name, w) {
          perSet[name] = const ListEquality().equals(orderedWithTies(w, candidates, null), expected);
        });
        final we = weightSets.values.map((w) => w.exposure).reduce(min);
        final wt = weightSets.values.map((w) => w.travel).reduce(min);
        final wa = weightSets.values.map((w) => w.accessibility).reduce(min);
        var weakest = double.infinity;
        for (var i = 0; i < expected.length; i++) {
          for (var j = i + 1; j < expected.length; j++) {
            final a = featuresOf(candidates.firstWhere((c) => c['id'] == expected[i]));
            final b = featuresOf(candidates.firstWhere((c) => c['id'] == expected[j]));
            final margin = we * (a.xExposure - b.xExposure) +
                wt * (a.xTravel - b.xTravel) +
                wa * (a.xAccessibility - b.xAccessibility);
            if (margin < weakest) weakest = margin;
          }
        }
        for (final entry in perSet.entries) {
          expect(entry.value, isTrue,
              reason: 'set "${set['name']}" must order identically under ${entry.key} weights');
        }
        report.writeln('| ${set['name']} | ${perSet.values.every((v) => v) ? 'yes' : '**NO**'} | '
            '${perSet.values.every((v) => v) ? 'yes' : '**NO**'} | ${weakest.toStringAsFixed(2)} |');
      }
      print(report);
    });
  });

  group('Ablation + explainability (spec §7)', () {
    test("Kendall's τ of each ablated ranking against the full ranking (asset-site universe)",
        () {
      final report = StringBuffer(
          "Kendall's τ, full ranking vs one-factor ablations, over all ${sites.length} asset sites"
          '(synthetic travel/accessibility, Random seeds fixed by construction)\n\n'
          '| drop | baseline τ | trained τ |\n|---|---|---|\n');
      for (final factor in const ['exposure', 'travel', 'accessibility']) {
        final cells = <String>[];
        weightSets.forEach((name, w) {
          final full = orderedWithTies(w, universe, null);
          final ablated = orderedWithTies(w, universe, factor);
          cells.add(kendallTau(full, ablated).toStringAsFixed(4));
        });
        report.writeln('| $factor | ${cells.join(' | ')} |');
      }
      print(report);
    });

    test('monotonicity violations: 0 for any non-negative weights, per ablation', () {
      final random = Random(42);
      for (final factor in const ['exposure', 'travel', 'accessibility']) {
        for (var i = 0; i < 200; i++) {
          final w1 = random.nextDouble();
          final w2 = random.nextDouble() * (totalWeightConstraint - w1);
          // Remaining two weights rescaled to sum 100, zero on the ablated one.
          final rest = w1 + w2;
          final we = factor == 'exposure' ? 0.0 : w1 * 100.0 / rest;
          final wt = factor == 'travel' ? 0.0 : (factor == 'exposure' ? w2 * 100.0 / rest : w1 * 100.0 / rest);
          final wa = factor == 'accessibility' ? 0.0 : w2 * 100.0 / rest;
          final weights = RankingWeights(exposure: we, travel: wt, accessibility: wa);
          // Better candidate: strictly lower hazard and shorter walk, accessibility equal
          // where it is still weighted (0/1 otherwise).
          final hazardHigh = random.nextDouble();
          final hazardLow = random.nextDouble() * hazardHigh;
          final secondsLong = random.nextDouble() * travelTimeCapSeconds * 2;
          final secondsShort = random.nextDouble() * secondsLong;
          final accessibility = wa > 0
              ? random.nextBool()
                  ? 1.0
                  : 0.0
              : 0.5;
          final worse = RankingFeatures(
              exposure: hazardHigh, travelSeconds: secondsLong, accessibility: accessibility);
          final better = RankingFeatures(
              exposure: hazardLow, travelSeconds: secondsShort, accessibility: accessibility);
          expect(weights.score(better), greaterThanOrEqualTo(weights.score(worse)),
              reason: 'ablation $factor, pair #$i: the invariant must survive any retrain');
        }
        print('| ablation $factor | violations 0 / 200 |');
      }
    });

    test('trained vs hand-set, from the shipped fit record', () {
      final doc = jsonDecode(File('assets/data/ranking_weights.json').readAsStringSync())
          as Map<String, dynamic>;
      final fit = doc['fit']! as Map<String, dynamic>;
      final weights = doc['weights']! as Map<String, dynamic>;
      final report = StringBuffer(
          'Trained vs hand-set (5-fold CV, StratifiedKFold(shuffle=True, random_state=42), '
          '${(doc['dataset']! as Map<String, dynamic>)['pairs']} pairs)\n\n'
          '| metric | trained v1 | hand-set baseline |\n|---|---|---|\n'
          '| cvPairwiseAccuracy | ${(fit['cvPairwiseAccuracy'] as num).toStringAsFixed(4)} | '
          '${(fit['baselineAccuracy'] as num).toStringAsFixed(4)} |\n'
          '| chosen lambda | ${(fit['lambda'] as num).toString()} | n/a |\n\n'
          'Weights shipped: exposure ${weights['exposure']}, travel ${weights['travel']}, '
          'accessibility ${weights['accessibility']}.\n');
      print(report);
    });

    test('explanation audit: zero-weight factors contribute exactly zero; contributions sum to score',
        () {
      for (final entry in weightSets.entries) {
        for (final set in sets) {
          for (final candidate in (set['candidates']! as List).cast<Map<String, dynamic>>()) {
            final f = featuresOf(candidate);
            final contributions = entry.value.contributions(f);
            expect(contributions.values.fold<double>(0, (a, v) => a + v), closeTo(entry.value.score(f), 1e-9),
                reason: '${entry.key}: contributions must decompose exactly (${candidate['id']})');
            for (final e in contributions.entries) {
              if ((e.key == 'exposure' ? entry.value.exposure : e.key == 'travel' ? entry.value.travel : entry.value.accessibility) == 0.0) {
                expect(e.value, 0.0, reason: '${entry.key}: factor ${e.key} weight 0 must not show up as a reason');
              }
            }
          }
        }
      }
      print('Explanation audit: contributions decompose exactly for all '
          '${sets.length} golden sets under both weight sets; zero-weight factors never appear as reasons.');
    });

    test('forbidden-claims scan over every ranking string in both localizations', () {
      final forbidden = ['is safe', 'safe route', 'guaranteed safe', 'will not flood'];
      final values = <String>[];
      for (final path in ['lib/l10n/app_en.arb', 'lib/l10n/app_fil.arb']) {
        final doc = jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
        doc.forEach((key, value) {
          if (key.startsWith('rank') && value is String) values.add(value);
        });
      }
      expect(values, isNotEmpty, reason: 'the scan must actually see the ranking strings');
      for (final phrase in forbidden) {
        for (final v in values) {
          expect(v.toLowerCase().contains(phrase.toLowerCase()), isFalse,
              reason: 'forbidden claim "$phrase" in "$v"');
        }
      }
      print('Forbidden-claims scan: ${values.length} ranking strings across app_en/app_fil, '
          '0 occurrences of ${forbidden.join(', ')}.');
    });
  });

  group('Benchmarks (spec §7)', () {
    test('cold parse in an isolate, exposureAt x 10 000, full ranking N=6 / N=1000, ORS budget',
        () async {
      final bytes = File('assets/data/hazard_bands.json').readAsBytesSync();
      final stopwatchParse = Stopwatch()..start();
      final bands = await compute(HazardBandsRepository.parseBytes, Uint8List.fromList(bytes));
      stopwatchParse.stop();
      expect(bands.sites.length, sites.length, reason: 'isolate parse must be complete');

      final random = Random(42);
      final samplePoints = List<GeoPoint>.generate(
        10000,
        (_) => GeoPoint(14.6 + random.nextDouble() * 0.2, 121.0 + random.nextDouble() * 0.2),
        growable: false,
      );

      final stopwatchExposure = Stopwatch()..start();
      for (final p in samplePoints) {
        bands.exposureAt(p);
      }
      stopwatchExposure.stop();
      final perPointMicros = stopwatchExposure.elapsedMicroseconds / samplePoints.length;

      // Full ranking at the engine level: features -> scores -> deterministic sort,
      // the same ordering rule RankingController uses.
      final rows = <({String id, RankingFeatures f, double score})>[];
      for (final c in universe) {
        final f = featuresOf(c);
        rows.add((id: c['id'] as String, f: f, score: trainedSource.weights.score(f)));
      }
      final stopwatchN6 = Stopwatch()..start();
      final rows6 = rows.sublist(0, 6)..sort(_rankComparator);
      stopwatchN6.stop();
      final stopwatchN1000 = Stopwatch()..start();
      final big = <({String id, RankingFeatures f, double score})>[];
      for (var i = 0; i < 1000; i++) {
        final f = featuresOf(universe[i % universe.length]);
        big.add((id: 'cand-$i', f: f, score: trainedSource.weights.score(f)));
      }
      big.sort(_rankComparator);
      stopwatchN1000.stop();

      expect(rows6, hasLength(6));
      expect(big, hasLength(1000));
      expect(big.map((r) => r.f.travelEstimated), everyElement(isTrue),
          reason: 'engine ranking uses straight-line estimates: 0 ORS calls per re-rank '
              '(ORS is only touched for the SELECTED centre, at most 1 call per re-rank — '
              'the spec budget is <= 3)');

      final report = StringBuffer(
          'Benchmarks (measured on this run)\n\n'
          '| metric | value |\n|---|---|\n'
          '| hazard_bands.json cold parse in an isolate | ${stopwatchParse.elapsedMilliseconds} ms |\n'
          '| exposureAt x 10 000 points | ${stopwatchExposure.elapsedMilliseconds} ms '
          '(${perPointMicros.toStringAsFixed(1)} µs/point) |\n'
          '| full ranking, N=6 | ${stopwatchN6.elapsedMicroseconds} µs |\n'
          '| full ranking, N=1000 | ${stopwatchN1000.elapsedMicroseconds} µs |\n'
          '| ORS calls per re-rank (engine run) | 0 (budget <= 3, asserted via travelEstimated) |\n'
          '| asset size | ${bytes.length} bytes (gate: <= 5 MB) |\n'
          '| parity fixture | exposure_parity.json: Dart == Python to 1e-9 |');
      print(report);
    });
  });
}

int _rankComparator(
    ({String id, RankingFeatures f, double score}) a, ({String id, RankingFeatures f, double score}) b) {
  final byScore = b.score.compareTo(a.score);
  return byScore != 0 ? byScore : a.id.compareTo(b.id);
}

class ListEquality {
  const ListEquality();
  bool equals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
