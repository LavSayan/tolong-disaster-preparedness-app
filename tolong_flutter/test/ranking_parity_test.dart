import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tolong_flutter/features/safe_places/domain/ranking.dart';

/// Dart<->Python feature parity (SHELTER_RANKING_ML.md §3, §7): both implementations
/// are pinned to `tools/ranking/data/exposure_parity.json`, which the Python side
/// (`tools/ranking/check_parity.py`) regenerates and self-checks against the asset.
void main() {
  final fixtureBytes = File('../tools/ranking/data/exposure_parity.json').readAsStringSync();
  final fixture = jsonDecode(fixtureBytes) as Map<String, dynamic>;
  final meta = fixture['meta']! as Map<String, dynamic>;
  final tolerance = (meta['tolerance']! as num).toDouble();

  group('Dart formula matches the parity fixture', () {
    test('exposure rows: floodComposite / landslide / exposure agree with the fixture', () {
      for (final row in fixture['exposureRows']! as List<dynamic>) {
        final r = row! as Map<String, dynamic>;
        final bands = r['bands']! as Map<String, dynamic>;
        final dartComputed = exposureFromBands(
          flood100yr: (bands['flood_100yr'] as num?)?.toDouble(),
          flood25yr: (bands['flood_25yr'] as num?)?.toDouble(),
          flood5yr: (bands['flood_5yr'] as num?)?.toDouble(),
          landslideBand: (bands['landslide'] as num?)?.toDouble(),
        );
        expect(r['pythonFloodComposite'] as double?, dartComputed.floodComposite,
            reason: '${r['id']}: floodComposite');
        expect(r['pythonLandslide'] as double?, dartComputed.landslide, reason: '${r['id']}: landslide');
        expect(r['pythonExposure'] as double?, dartComputed.exposure, reason: '${r['id']}: exposure');

        if (r['origin'] == 'asset') {
          // The asset rows also pin Python against the shipped asset (check_parity.py
          // hard-fails first, but the Dart run re-asserts so no one edits the fixture loose).
          expect((r['assetExposure'] as num?)?.toDouble(), dartComputed.exposure,
              reason: '${r['id']}: asset exposure');
        }
      }
    });

    test('asset rows really come from the shipped asset (sha pinned)', () {
      final assetJson = jsonDecode(
        File('assets/data/hazard_bands.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final assetSha = (assetJson['source']! as Map<String, dynamic>)['sha256'] as String;
      final fixtureSha = (meta['source']! as Map<String, dynamic>)['sha256'] as String;
      expect(fixtureSha, assetSha,
          reason: 'the fixture must be regenerated whenever the asset is regenerated');
    });

    test('x_travel cases agree across the 3600 s cap', () {
      for (final c in fixture['travelCases']! as List<dynamic>) {
        final caseRow = c! as Map<String, dynamic>;
        final f = RankingFeatures(
          exposure: 0.0,
          travelSeconds: (caseRow['travelSeconds'] as num).toDouble(),
          accessibility: neutralFeatureValue,
        );
        expect(f.xTravel, closeTo((caseRow['xTravel'] as num).toDouble(), tolerance),
            reason: 'travelSeconds=${caseRow['travelSeconds']}');
      }
    });

    test('x_accessibility is the identity over {0.0, 0.5, 1.0}', () {
      for (final c in fixture['accessibilityCases']! as List<dynamic>) {
        final caseRow = c! as Map<String, dynamic>;
        final f = RankingFeatures(
          exposure: 0.0,
          travelSeconds: 0.0,
          accessibility: (caseRow['accessibility'] as num).toDouble(),
        );
        expect(f.xAccessibility, (caseRow['xAccessibility'] as num).toDouble());
      }
    });

    test('the five shared constants are identical on both sides', () {
      final constants = fixture['constants']! as Map<String, dynamic>;
      final expected = {
        'travelTimeCapSeconds': travelTimeCapSeconds,
        'walkingSpeedMetersPerSecond': walkingSpeedMetersPerSecond,
        'neutralFeatureValue': neutralFeatureValue,
        'totalWeightConstraint': totalWeightConstraint,
        'minExposureWeight': minExposureWeight,
      };
      expect(constants.keys.toSet(), expected.keys.toSet());
      expected.forEach((name, value) => expect((constants[name] as num).toDouble(), value, reason: name));
    });
  });
}
