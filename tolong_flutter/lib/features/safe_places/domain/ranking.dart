/// The shelter-ranking model, and exactly nothing else.
///
/// One score per evacuation centre, one pairwise decision per labelled pair — see
/// `docs/design/SHELTER_RANKING_ML.md` §2-§3 for the formulas this file implements
/// (`docs` is the source of truth; keep the two in lockstep):
///
/// - `S(c) = Σ_f w_f · x_f(c)` — weights sum to 100, `x ∈ [0,1]`, so `S ∈ [0,100]`.
/// - `P(A ≻ B) = σ(S(A) − S(B))` — the same weights decide labelled pairs (training side).
///
/// `S` says nothing about live conditions and must never be called a safety score.
library;

import 'dart:math';

/// `T_max` in `x_travel = clamp(1 − t/3600, 0, 1)`: a fixed constant, deliberately not
/// normalized against the current candidate list (spec §3 — pairwise training needs features
/// that depend only on the candidate). Roughly an hour's walk ≈ 5 km.
const travelTimeCapSeconds = 3600.0;

/// Straight-line travel estimate when no route duration is available. The spec's honest
/// placeholder; anything slower (wheelchair, crowds) is underestimated — disclosed in §10.
const walkingSpeedMetersPerSecond = 1.2;

/// Neutral value for a feature a candidate *has no data for* (spec §3: per-candidate unknowns
/// use neutral 0.5 + an explicit gap in the UI — never a per-candidate bonus or penalty).
const neutralFeatureValue = 0.5;

/// Structural constraint set the model can never escape (spec §5): weights are non-negative,
/// sum to exactly 100, and exposure is floored at 30 so no retrain can become distance-only.
const totalWeightConstraint = 100.0;
const minExposureWeight = 30.0;

/// Feature vector for one candidate, in the exact §3 definitions.
/// Both the Dart engine and the Python trainer derive every `x` from this shape.
class RankingFeatures {
  const RankingFeatures({
    required this.exposure,
    required this.travelSeconds,
    required this.accessibility,
    this.travelEstimated = false,
  });

  /// Hazard-facing `exposure ∈ [0,1]` — higher means the candidate sits in worse hazard.
  /// The *feature* is its complement (`x_exposure = 1 − exposure`), computed below.
  ///
  /// No data for this candidate? Pass [neutralFeatureValue] and let the UI shape the gap —
  /// the engine must not invent a per-candidate imputation rule.
  final double exposure;

  /// Travel time in seconds: real route duration when fetched, otherwise a straight-line
  /// estimate via [walkingSpeedMetersPerSecond].
  final double travelSeconds;

  /// 1.0 / 0.5 / 0.0 (spec §3): route verified, not checked (neutral + gap), or failed.
  final double accessibility;

  /// True when [travelSeconds] is the straight-line estimate rather than a fetched route.
  /// Purely for honest labelling in the UI; the feature math is identical.
  final bool travelEstimated;

  double get xExposure => 1.0 - exposure;

  double get xTravel => (1.0 - travelSeconds / travelTimeCapSeconds).clamp(0.0, 1.0);

  double get xAccessibility => accessibility;

  /// `x` in the fixed factor order used by parity fixtures and the trainer's dataset.
  List<double> get factorValues => [xExposure, xTravel, xAccessibility];
}

/// Walking-mode placeholder travel time when no route exists at all.
double estimateTravelSeconds(double meters) => meters / walkingSpeedMetersPerSecond;

/// Flood composite from integer severity bands (spec §3): `0.5·(b100/3) + 0.3·(b25/3) + 0.2·(b5/3)`.
/// An absent band (stored as `null` in the asset) contributes 0; complete absence of all three
/// flood layers is reported upstream, not here.
double floodCompositeFrom({required double? flood100yr, required double? flood25yr, required double? flood5yr}) =>
    0.5 * ((flood100yr ?? 0.0) / 3.0) +
    0.3 * ((flood25yr ?? 0.0) / 3.0) +
    0.2 * ((flood5yr ?? 0.0) / 3.0);

/// Landslide component from its severity band: `b/4` (spec §3). `null` means no landslide
/// data at this point — treated as absent by the caller.
double landslideFrom(double? band) => band == null ? 0.0 : band / 4.0;

/// Exposure block per spec §3: `exposure = max(floodComposite, landslide)`; 0.0 when no layer
/// reported anything at all (a sampled point with no data is a *verified clean* point, not
/// an unknown — unknowns come only from being off any sampled site, via the match radius).
/// Fractions are rounded to 9 decimals exactly like the Python extractor ships them, so the
/// parity fixture can compare values to 1e-9 on both sides.
({double? floodComposite, double? landslide, double? exposure}) exposureFromBands({
  required double? flood100yr,
  required double? flood25yr,
  required double? flood5yr,
  required double? landslideBand,
}) {
  final hasFlood = flood100yr != null || flood25yr != null || flood5yr != null;
  final composite =
      hasFlood ? round9(floodCompositeFrom(flood100yr: flood100yr, flood25yr: flood25yr, flood5yr: flood5yr)) : null;
  final hasLandslide = landslideBand != null;
  final landslide = hasLandslide ? round9(landslideFrom(landslideBand)) : null;
  final candidates = [composite, landslide].whereType<double>().toList();
  final exposure = candidates.isEmpty ? null : round9(candidates.reduce(max));
  return (floodComposite: composite, landslide: landslide, exposure: exposure);
}

/// `x` rounding used by the extractor (`round(x, 9)`) so parity is exact, not near-exact.
double round9(double value) => (value * 1e9).roundToDouble() / 1e9;

/// Weight triple over `[exposure, travel, accessibility]`. Never persists through shared
/// mutable state; load trained weights via `data/ranking_weights_repository.dart`, which
/// falls back to [defaults] on any problem (spec §6: never a crash, never a partial model).
class RankingWeights {
  const RankingWeights({
    required this.exposure,
    required this.travel,
    required this.accessibility,
  });

  /// Hand-set baseline shipped before (and even without) any training run (spec §1).
  static const defaults = RankingWeights(exposure: 45.0, travel: 35.0, accessibility: 20.0);

  final double exposure;
  final double travel;
  final double accessibility;

  /// Score for [f]: higher is a better match for the user's situation, on a 0-100 scale.
  /// Not a safety score and never worded as one (spec §8).
  double score(RankingFeatures f) => exposure * f.xExposure + travel * f.xTravel + accessibility * f.xAccessibility;

  /// Per-factor contributions to [score], used for explanation audit (spec §7): every displayed
  /// reason must trace to a non-zero entry here. Entries sum to exactly [score].
  Map<String, double> contributions(RankingFeatures f) => {
        'exposure': exposure * f.xExposure,
        'travel': travel * f.xTravel,
        'accessibility': accessibility * f.xAccessibility,
      };

  /// Pairwise decision for the labelled-pair view of the model (spec §2): probability that
  /// [a] is preferred over [b].
  double probabilityPreferred(RankingFeatures a, RankingFeatures b) {
    final d = score(a) - score(b);
    return 1.0 / (1.0 + exp(-d));
  }

  /// The strict constraint set of spec §5, evaluated numerically:
  /// sum exactly 100 (within 1e-9), all weights ≥ 0, exposure ≥ 30.
  bool satisfiesConstraints() =>
      (exposure + travel + accessibility - totalWeightConstraint).abs() <= 1e-9 &&
      exposure >= 0 && travel >= 0 && accessibility >= 0 &&
      exposure >= minExposureWeight;

  /// Weights with the accessibility factor excluded and the remainder renormalized to sum 100
  /// (spec §3 walking mode: all-or-nothing exclusion, never per-candidate).
  ///
  /// The result keeps every safety property: non-negative, sum 100, exposure ≥ 30 —
  /// since exposure started ≥ 30 and only grows when renormalizing upward.
  RankingWeights get withoutAccessibility {
    final rest = exposure + travel;
    return RankingWeights(exposure: exposure * 100.0 / rest, travel: travel * 100.0 / rest, accessibility: 0.0);
  }
}
