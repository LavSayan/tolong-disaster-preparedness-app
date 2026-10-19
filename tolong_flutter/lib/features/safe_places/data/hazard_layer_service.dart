import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/hazard.dart';
import 'map_style.dart';

/// The archive is bundled, so there is nothing to download; this reports whether MapLibre can
/// read it yet.
sealed class HazardLayerStatus {
  const HazardLayerStatus();
}

/// The protocol is registered and the overlay can be drawn.
class HazardBundled extends HazardLayerStatus {
  const HazardBundled();
}

/// MapLibre cannot read a `pmtiles://` archive in this build, most likely because `pmtiles.js`
/// did not load. The overlay is off; the rest of the map is unaffected.
class HazardProtocolMissing extends HazardLayerStatus {
  const HazardProtocolMissing();
}

/// Which hazard group the map is currently overlaying. `null` means the overlay is off.
class HazardOverlayController extends Notifier<HazardGroup?> {
  @override
  HazardGroup? build() => null;

  void select(HazardGroup? group) => state = group;

  void toggle(HazardGroup group) => state = state == group ? null : group;
}

final hazardOverlayProvider = NotifierProvider<HazardOverlayController, HazardGroup?>(
  HazardOverlayController.new,
);

/// Set by `main()` once the `pmtiles://` protocol has been registered with MapLibre.
///
/// On web this is the only thing standing between the app and a map that cannot read the bundled
/// archive. `registerPmTilesProtocol` never throws — it reports success instead — so this flag is
/// the honest signal the UI renders from, rather than a platform guess.
bool _pmTilesRegistered = false;

/// Records the outcome of protocol registration. Called once from `main()`.
void setPmTilesRegistered(bool value) => _pmTilesRegistered = value;

/// Whether the hazard overlay can actually be drawn right now.
///
/// Deliberately a recorded fact, not `!kIsWeb`: a build with no backend and a build whose
/// `pmtiles.js` failed to load are both "unsupported", and the app must be able to say so
/// honestly instead of hiding the control and leaving the user to wonder.
///
/// Synchronous on purpose. `main()` records the registration outcome *before* `runApp`, so the
/// answer is final by the time any widget reads it — an async provider would only introduce a
/// window where the picker has to guess.
final Provider<HazardLayerStatus> hazardLayerStatusProvider = Provider((ref) {
  return _pmTilesRegistered ? const HazardBundled() : const HazardProtocolMissing();
});

/// Convenience for screens: true when the overlay is known to be drawable.
bool hazardOverlayAvailable() => _pmTilesRegistered;

/// The style layers the map should add for [group], described without touching MapLibre so the
/// grouping stays testable without a platform map view.
List<HazardLayerSpec> hazardLayerSpecs(HazardGroup? group) {
  if (group == null) return const [];
  final out = <HazardLayerSpec>[];
  for (final layer in group.sourceLayers) {
    for (final band in group.severityBands) {
      out.add(HazardLayerSpec(
        sourceLayer: layer,
        attribute: group.severityAttribute,
        band: band,
        opacity: _opacityFor(group, band.level),
      ));
    }
  }
  return out;
}

/// Keep the overlay readable over the pastel basemap: light classes stay translucent so streets
/// underneath remain visible, and only the top band firms up.
double _opacityFor(HazardGroup group, int level) {
  final max = group.severityBands.length;
  if (level >= max) return 0.55;
  if (level == 1) return 0.22;
  return 0.32;
}

/// One fill layer to add to the map: "this source layer, this severity code, this colour".
class HazardLayerSpec {
  const HazardLayerSpec({
    required this.sourceLayer,
    required this.attribute,
    required this.band,
    required this.opacity,
  });

  final String sourceLayer;
  final String attribute;
  final HazardSeverityBand band;
  final double opacity;

  /// MapLibre layer id. Stable so a rebuild updates the same layer instead of stacking copies.
  String get id => 'hazard-$sourceLayer-$attribute${band.code}';

  /// Source id registered once per map, in `map_style.dart`.
  static const sourceId = 'noah-hazard';
}

/// The style filter for [spec]: keep only the features whose severity attribute equals this
/// band's code.
///
/// Without it every band layer of a source layer would paint *all* of that layer's features, so
/// the severity colours would collapse into whichever fill was added last and the legend would
/// lie about what is drawn.
///
/// Returned as a plain MapLibre expression list (`jsonEncode`d for Android, passed straight to
/// MapLibre GL JS on web, both inside maplibre_gl). It is a pure value on purpose: the grouping
/// and filtering logic stays testable without a platform map view.
List<Object> hazardFilterExpression(HazardLayerSpec spec) =>
    <Object>['==', <Object>['get', spec.attribute], spec.band.code];

/// Convenience for screens: the archive URL, so registration and map wiring cannot disagree.
String get hazardArchiveUrl => noahHazardArchive;