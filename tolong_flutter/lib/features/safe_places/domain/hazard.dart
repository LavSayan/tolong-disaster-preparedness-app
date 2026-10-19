/// Modelled hazard types carried by the bundled NOAH archive.
///
/// The archive holds nine source layers; they are grouped here by the hazard a person actually
/// has to prepare for, so the map offers four choices rather than nine cryptic ones. Grouping
/// also keeps the wording aligned with `assets/guidebook/guidebook.json`, which is organised
/// around the same hazard taxonomy (storm surge folds into the typhoon category).
///
/// **NOAH does not cover every hazard.** There is no earthquake layer and no fire layer. Those
/// gaps are stated in the UI rather than left as a silent absence, and the earthquake gap is why
/// a seismic dataset would be a separate addition.
enum HazardGroup {
  /// `flood_5yr`, `flood_25yr`, `flood_100yr` — 5-, 25- and 100-year rainfall return periods.
  flood,

  /// `landslide` — susceptibility class.
  landslide,

  /// `storm_surge_ssa1` … `ssa4` — storm surge advisory levels 1-4. Coastal only; Quezon City is
  /// inland, so this group legitimately has no data here.
  stormSurge,

  /// `debris_flow` — lahar and debris-flow susceptibility. Sparse.
  debrisFlow;

  /// Source layers in the archive, in draw order (widest first, so narrower bands sit on top).
  List<String> get sourceLayers => switch (this) {
        HazardGroup.flood => const ['flood_5yr', 'flood_25yr', 'flood_100yr'],
        HazardGroup.landslide => const ['landslide'],
        HazardGroup.stormSurge => const [
            'storm_surge_ssa1',
            'storm_surge_ssa2',
            'storm_surge_ssa3',
            'storm_surge_ssa4',
          ],
        HazardGroup.debrisFlow => const ['debris_flow'],
      };

  /// The attribute carrying the ordinal severity class in these layers.
  ///
  /// The flood layers use `Var`; the rest use `HAZ`. Neither carries a human-readable label in the
  /// tile, only a code, which is why [severityBands] has to spell the meaning out.
  String get severityAttribute => switch (this) {
        HazardGroup.flood => 'Var',
        _ => 'HAZ',
      };
}

/// One step on a hazard group's severity scale.
class HazardSeverityBand {
  const HazardSeverityBand(this.code, this.level);

  /// The value in the archive's severity attribute, as a string for the style expression.
  final String code;

  /// How many bands the scale has, so the UI can render a legend without hard-coding counts.
  final int level;

  /// Fill colour, kept inside the app's WCAG AA palette so contrast tests keep passing.
  String get color => switch (level) {
        1 => '#7FA8B8', // pale blue, low
        2 => '#4A7486', // blue, moderate
        3 => '#C9944F', // amber, elevated
        4 => '#BD7357', // terracotta, high
        _ => '#5C6B63', // muted, unreachable
      };
}

extension HazardGroupSeverity on HazardGroup {
  /// Severity bands for this group, ordered from the archive's lowest code upwards.
  List<HazardSeverityBand> get severityBands => switch (this) {
        // Var: 1..3 — 5-year, 25-year and 100-year bands share one attribute, so the same three
        // severity steps are used for all three return periods.
        HazardGroup.flood => const [
            HazardSeverityBand('1', 1),
            HazardSeverityBand('2', 2),
            HazardSeverityBand('3', 3),
          ],
        // HAZ: 1..4
        _ => const [
            HazardSeverityBand('1', 1),
            HazardSeverityBand('2', 2),
            HazardSeverityBand('3', 3),
            HazardSeverityBand('4', 4),
          ],
      };
}