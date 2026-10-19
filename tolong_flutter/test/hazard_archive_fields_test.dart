import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tolong_flutter/features/safe_places/domain/hazard.dart';

final _fixture = jsonDecode(
        File('test/fixtures/hazard_archive_fields.json').readAsStringSync())
    as Map<String, dynamic>;

final _fields = (_fixture['fields'] as Map<String, dynamic>)
    .map((layer, value) => MapEntry(layer, value as Map<String, dynamic>));

List<int> _valuesOf(String layer) =>
    (_fields[layer]!['values'] as List).cast<int>();

/// The map overlay must compare the attribute values the archive really stores. Both the
/// attribute name (`Var`/`HAZ`) and the severity codes are pinned to this fixture, which
/// `tools/hazard_archive_check/hazard_fields.py` regenerates by decoding every tile in
/// `datasets/qc_flood.pmtiles`. If the archive is ever rebuilt, run that tool's `--extract`
/// alongside it so the pinned values cannot drift from reality.
void main() {
  test('the fixture describes the committed qc_flood archive', () {
    expect(_fixture['archive'], 'tolong_flutter/datasets/qc_flood.pmtiles');
    expect(_fixture['sha256'], hasLength(64), reason: 'provenance must pin the exact archive');
    // The QC extract is 169 tiles; the national NOAH archive is 81,712 and 5.17 GB.
    expect(_fixture['tiles'], 169);
    expect(_fields, hasLength(9), reason: 'all nine NOAH layers must be described');
    expect(File('datasets/qc_flood.pmtiles').lengthSync(), _fixture['size_bytes'],
        reason: 'the pinned archive is the committed one');
  });

  for (final g in HazardGroup.values) {
    group('severity data for ${g.name}', () {
      final attribute = g.severityAttribute;

      test('the severity attribute exists as a number in every source layer of the group', () {
        for (final layer in g.sourceLayers) {
          expect(_fields[layer], isNotNull, reason: '$layer is not described by the fixture');
          expect(_fields[layer]!['attribute'], attribute, reason: layer);
          expect(_fields[layer]!['type'], 'number', reason: '$layer must store $attribute numerically');
          expect(_valuesOf(layer), everyElement(isA<int>()),
              reason: '$layer carries $attribute as integers');
        }
      });

      test('every code the data carries has a declared severity band', () {
        // The inverse (a declared band with no data) is deliberately not asserted: the legend
        // shows the full scale for groups whose bundled extract only uses part of it —
        // debris_flow observes only 3..4 here, storm surge only 1..3 on inland QC.
        final declared = g.severityBands.map((b) => b.code).toSet();
        for (final layer in g.sourceLayers) {
          for (final value in _valuesOf(layer)) {
            expect(declared.contains(value), isTrue,
                reason: '$layer carries $attribute=$value but no legend band describes it');
          }
        }
      });

      test('the declared codes are ints, matching how the archive stores them', () {
        // Regression guard for the silent failure class: the filter once compared String codes
        // against the numeric tile attribute, matched nothing, and drew no colours — without
        // throwing anywhere (MapLibre's == compares types strictly).
        expect(_valuesOf(g.sourceLayers.first).first, isA<int>());
        for (final band in g.severityBands) {
          expect(band.code, isA<int>(), reason: 'band ${band.level} of ${g.name}');
        }
      });
    });
  }
}
