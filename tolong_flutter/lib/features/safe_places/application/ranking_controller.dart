import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/evacuation_center_repository.dart';
import '../data/hazard_bands_repository.dart';
import '../data/ranking_weights_repository.dart';
import '../data/route_service.dart';
import '../domain/evacuation_center.dart';
import '../domain/ranking.dart';
import 'safe_places_controller.dart';

/// One evacuation centre as the ranking engine sees it (spec §2 `S(c)`, one row per candidate).
class RankedCenter {
  const RankedCenter({
    required this.center,
    required this.features,
    required this.score,
    required this.rank,
  });

  final EvacuationCenter center;
  final RankingFeatures features;
  final double score;

  /// 1-based position in the ranked list. Higher rank value = lower in the list.
  final int rank;

  /// True when no hazard reading could be matched to this centre, so the neutral 0.5 stands
  /// in for exposure and the UI must show the gap (spec §3: never a per-candidate bonus).
  bool get exposureUnknown => features.exposure == neutralFeatureValue;
}

/// The ranked candidate list plus everything the UI needs to disclose why. When
/// [available] is false the app shows the pre-ranking behaviour: plain distance order,
/// and says nothing about exposure it doesn't have (spec §3 — asset failure must never
/// turn into invented per-candidate exposure).
class RankingState {
  const RankingState({
    required this.available,
    required this.weights,
    required this.weightsTrained,
    this.weightsFallbackReason,
    this.ranked = const [],
  });

  final bool available;

  /// The weights actually applied — walking mode excludes accessibility and renormalizes.
  final RankingWeights weights;

  /// Whether the weights came from a training run (provenance shown on the card).
  final bool weightsTrained;

  /// Non-empty only when defaults are active because the trained asset failed to load.
  final String? weightsFallbackReason;

  /// Score-desc, deterministic ties (straight-line distance, then id): the same inputs
  /// must always produce the same order.
  final List<RankedCenter> ranked;
}

/// Recomputes whenever its inputs change: centers, hazard bands, trained weights, and the
/// safe-places state (reference point, travel profile, the verified route).
///
/// Scale note: the demo ships 6 centres and the asset's site table covers 148 points, so
/// a synchronous rebuild is cheap (spec §7 still benchmarks N=1000 before the real QC list).
class RankingController extends Notifier<RankingState> {
  @override
  RankingState build() {
    final weightsRaw = ref.watch(rankingWeightsProvider).value;
    final weightsSource = weightsRaw ?? (const RankingDefaults(reason: 'weights not loaded yet') as RankingWeightsSource);
    final centers = ref.watch(evacuationCentersProvider).value ?? const [];
    final bands = ref.watch(hazardBandsProvider).value;
    final place = ref.watch(safePlacesProvider);
    final reference = place.reference;

    if (bands == null || reference == null || centers.isEmpty) {
      return RankingState(
        available: false,
        weights: weightsSource.weights,
        weightsTrained: weightsSource.isTrained,
        weightsFallbackReason: weightsSource is RankingDefaults ? weightsSource.reason : null,
      );
    }

    // All-or-nothing factor exclusion (spec §3): walking drops accessibility entirely and
    // renormalizes; wheelchair mode keeps all three factors with the neutral/gap semantics.
    final weights = place.profile == RouteProfile.wheelchair
        ? weightsSource.weights
        : weightsSource.weights.withoutAccessibility;

    final scored = <(EvacuationCenter, RankingFeatures)>[
      for (final center in centers) (center, featuresFor(center, bands, place))
    ];
    final ordered = _orderedByScore(scored, reference, weights);
    final ranked = [
      for (final (i, row) in ordered.indexed)
        RankedCenter(center: row.$1, features: row.$2, score: weights.score(row.$2), rank: i + 1)
    ];
    return RankingState(
      available: true,
      weights: weights,
      weightsTrained: weightsSource.isTrained,
      weightsFallbackReason: weightsSource is RankingDefaults ? weightsSource.reason : null,
      ranked: ranked,
    );
  }

  /// Feature vector for one centre:
  /// - exposure: the matched site's sampled value, or the neutral constant when no site lies
  ///   within the match radius (spec §3 — per-candidate unknowns are neutral, never guessed).
  /// - travel: the real route duration only when a route for this exact centre still applies
  ///   (same profile it was planned for), else the straight-line estimate at 1.2 m/s.
  /// - accessibility in wheelchair mode: verified → 1.0, failed attempt for this centre → 0.0,
  ///   not checked → neutral 0.5 with a gap. Walking mode never reads this factor (weight 0),
  ///   so the neutral placeholder cannot move the score.
  RankingFeatures featuresFor(
    EvacuationCenter center,
    HazardBands bands,
    SafePlacesState place,
  ) {
    final reference = place.reference!;
    final routeApplies = place.route != null &&
        place.selectedId == center.id &&
        place.route!.profile == place.profile;
    final travelSeconds = routeApplies
        ? place.route!.durationSeconds
        : estimateTravelSeconds(reference.distanceKm(center.location) * 1000);
    final double accessibility;
    if (place.profile != RouteProfile.wheelchair) {
      accessibility = neutralFeatureValue;
    } else if (routeApplies) {
      accessibility = 1.0;
    } else if (place.routeError != null && place.selectedId == center.id) {
      accessibility = 0.0;
    } else {
      accessibility = neutralFeatureValue;
    }
    final site = bands.exposureAt(center.location);
    return RankingFeatures(
      exposure: site?.exposure ?? neutralFeatureValue,
      travelSeconds: travelSeconds,
      accessibility: accessibility,
      travelEstimated: !routeApplies,
    );
  }

  /// Score-descending order; scored ties break by straight-line distance, then id, so the
  /// same inputs always yield the same list (spec §7 N=6 and N=1000 determinism checks).
  List<(EvacuationCenter, RankingFeatures)> _orderedByScore(
    List<(EvacuationCenter, RankingFeatures)> rows,
    GeoPoint reference,
    RankingWeights weights,
  ) {
    final copy = [...rows];
    copy.sort((a, b) {
      final sa = weights.score(a.$2);
      final sb = weights.score(b.$2);
      if (sa != sb) return sb.compareTo(sa);
      final dax = reference.distanceKm(a.$1.location);
      final dbx = reference.distanceKm(b.$1.location);
      return dax.compareTo(dbx) != 0 ? dax.compareTo(dbx) : a.$1.id.compareTo(b.$1.id);
    });
    return copy;
  }
}

final rankedCentersProvider = NotifierProvider<RankingController, RankingState>(RankingController.new);
