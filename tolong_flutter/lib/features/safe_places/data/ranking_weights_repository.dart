import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/ranking.dart';

/// Loads trained ranking weights from `assets/data/ranking_weights.json` (spec §6) — with the
/// contract that **any** problem (missing file, corrupt JSON, unsupported version, wrong factor
/// set, constraint violation) yields [RankingDefaults] instead of a crash or a partial model.
class RankingWeightsRepository {
  RankingWeightsRepository(this._bundle);

  final AssetBundle _bundle;

  static const assetPath = 'assets/data/ranking_weights.json';

  Future<RankingWeightsSource> load() async {
    try {
      final raw = await _bundle.loadString(assetPath);
      return parseRankingWeights(raw);
    } catch (e) {
      debugPrint('Trained weights unavailable ($e); using the hand-set default weights.');
      return RankingDefaults.fromError(e.toString());
    }
  }
}

/// What the scorer will actually use, packaged with the provenance the UI shows (spec §6:
/// trained-vs-default provenance is visible, not assumed).
sealed class RankingWeightsSource {
  const RankingWeightsSource();

  RankingWeights get weights;
}

class TrainedWeights extends RankingWeightsSource {
  const TrainedWeights(this.weights, {required this.datasetSha256, required this.pairCount});

  @override
  final RankingWeights weights;

  /// SHA-256 of `tools/ranking/data/pairs.jsonl` at fit time (spec §6 export schema).
  final String datasetSha256;
  final int pairCount;
}

class RankingDefaults extends RankingWeightsSource {
  const RankingDefaults({required this.reason});

  factory RankingDefaults.fromError(String error) => RankingDefaults(reason: error);

  @override
  RankingWeights get weights => RankingWeights.defaults;

  /// Why defaults are active, for the card's provenance line. Empty string never occurs
  /// except in tests: shipping defaults without saying why would hide the failure.
  final String reason;
}

extension RankingWeightsSourceFeatures on RankingWeightsSource {
  bool get isTrained => this is TrainedWeights;
}

/// Parse + validation, kept static and bundle-free for tests.
@visibleForTesting
RankingWeightsSource parseRankingWeights(String raw) {
  final root = jsonDecode(raw) as Map<String, Object?>;
  final version = (root['version'] as num?)?.toInt() ?? 0;
  if (version != 1) throw const FormatException('unsupported ranking_weights version');
  if ((root['method'] as String?) != 'pairwise-logistic-slsqp') {
    throw const FormatException('unknown training method');
  }
  final factors = root['factors'];
  if (factors is! List ||
      factors.length != 3 ||
      factors[0] != 'exposure' ||
      factors[1] != 'travel' ||
      factors[2] != 'accessibility') {
    throw const FormatException('factor set mismatch');
  }
  final w = (root['weights'] ?? const <String, Object?>{}) as Map<String, Object?>;
  final dataset = (root['dataset'] ?? const <String, Object?>{}) as Map<String, Object?>;
  final weights = RankingWeights(
    exposure: (w['exposure'] as num?)?.toDouble() ?? -1,
    travel: (w['travel'] as num?)?.toDouble() ?? -1,
    accessibility: (w['accessibility'] as num?)?.toDouble() ?? -1,
  );
  if (!weights.satisfiesConstraints()) {
    throw const FormatException('trained weights violate the constraint set');
  }
  final datasetPath = dataset['path'] as String?;
  final datasetSha256 = dataset['sha256'] as String?;
  final pairCount = (dataset['pairs'] as num?)?.toInt() ?? 0;
  if (datasetPath == null || datasetPath.isEmpty || datasetSha256 == null || datasetSha256.isEmpty) {
    throw const FormatException('trained weights lack dataset provenance');
  }
  return TrainedWeights(weights, datasetSha256: datasetSha256, pairCount: pairCount);
}

final rankingWeightsRepositoryProvider =
    Provider((ref) => RankingWeightsRepository(rootBundle));

final rankingWeightsProvider =
    FutureProvider<RankingWeightsSource>((ref) => ref.watch(rankingWeightsRepositoryProvider).load());
