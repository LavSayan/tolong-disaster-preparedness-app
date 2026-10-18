import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/evacuation_center.dart';

/// Reads the bundled center list. The dataset carries its own "verified" flag, so swapping in
/// official QC DRRMO data later is a data change, not a code change.
class EvacuationCenterRepository {
  EvacuationCenterRepository(this._bundle);

  final AssetBundle _bundle;

  static const assetPath = 'assets/data/evacuation_centers_dev.json';

  Future<List<EvacuationCenter>> load() async => parse(await _bundle.loadString(assetPath));

  static List<EvacuationCenter> parse(String raw) {
    final json = jsonDecode(raw) as Map<String, Object?>;
    final source = json['dataset'] as String? ?? 'Unknown source';
    final verified = json['verified'] == true;
    return (json['centers'] as List)
        .map((e) => EvacuationCenter.fromJson(e as Map<String, Object?>, source: source, verified: verified))
        .toList();
  }
}

final evacuationCenterRepositoryProvider = Provider((ref) => EvacuationCenterRepository(rootBundle));

final evacuationCentersProvider =
    FutureProvider<List<EvacuationCenter>>((ref) => ref.watch(evacuationCenterRepositoryProvider).load());
