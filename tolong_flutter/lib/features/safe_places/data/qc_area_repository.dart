import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/qc_area.dart';

/// Bundled OSM-derived data, so the boundary and barangay search work offline.
class QcAreaRepository {
  QcAreaRepository(this._bundle);

  final AssetBundle _bundle;

  static const boundaryPath = 'assets/data/qc_boundary.json';
  static const barangaysPath = 'assets/data/qc_barangays.json';

  Future<QcBoundary> boundary() async => parseBoundary(await _bundle.loadString(boundaryPath));

  Future<List<Barangay>> barangays() async => parseBarangays(await _bundle.loadString(barangaysPath));

  static QcBoundary parseBoundary(String raw) => QcBoundary.fromJson(jsonDecode(raw) as Map<String, Object?>);

  static List<Barangay> parseBarangays(String raw) => [
        for (final b in (jsonDecode(raw) as Map<String, Object?>)['barangays'] as List)
          Barangay.fromJson(b as Map<String, Object?>),
      ];
}

final qcAreaRepositoryProvider = Provider((ref) => QcAreaRepository(rootBundle));

final qcBoundaryProvider = FutureProvider<QcBoundary>((ref) => ref.watch(qcAreaRepositoryProvider).boundary());

final barangaysProvider = FutureProvider<List<Barangay>>((ref) => ref.watch(qcAreaRepositoryProvider).barangays());
