/// Which basemap the map draws underneath the hazard overlay.
///
/// Today the app uses the hosted OpenFreeMap style: no API key, no download, and the tiles
/// arrive from a CDN. The repo also carries a clipped Quezon City basemap at
/// `datasets/qc_base.pmtiles` (30 MB, z0-15, bounds 120.9697,14.5691 -> 121.1538,14.7964), which
/// would let the app draw streets with no connection at all.
///
/// Switching is deliberately one value: change [BasemapStyle.current] and re-run. Everything
/// downstream asks for a style URL rather than hard-coding one, so no map widget needs to change
/// when the choice does.
///
/// The local file is a Protomaps basemap derived from OpenStreetMap, so it carries its own ODbL
/// attribution requirement wherever it is used.
enum BasemapStyle {
  /// OpenFreeMap "Positron": a light, low-contrast style that suits the app's pastel look.
  /// Free, no API key, commercial use allowed. MapLibre shows its required attribution.
  openFreeMap('https://tiles.openfreemap.org/styles/positron'),

  /// Bundled Protomaps basemap clipped to Quezon City. Fully offline once installed.
  ///
  /// **Not yet usable on web.** On web this would resolve relative to the *page*, not to a
  /// Flutter asset, so the path is a guess until someone confirms it in a browser. On Android and
  /// iOS MapLibre Native resolves bundled assets, though the exact form is also unverified.
  /// Kept so the option is visible, not so it can be flipped blindly.
  localPmtiles('pmtiles:///assets/datasets/qc_base.pmtiles');

  const BasemapStyle(this.styleUrl);

  final String styleUrl;

  /// The basemap the app uses today. Switching to [BasemapStyle.localPmtiles] needs the bundled
  /// asset URL verified on each platform first; see `docs/design/MAP_OPTIONS.md`.
  static const current = BasemapStyle.openFreeMap;
}

/// The scheme MapLibre uses for a PMTiles archive.
const String pmtilesScheme = 'pmtiles://';

/// The web path the flood archive is served from, after the `pmtiles://` prefix.
///
/// `pubspec.yaml` bundles the archive under the asset key `datasets/qc_flood.pmtiles`, and
/// Flutter's web build serves every bundled asset under `/assets/`, so the archive sits at
/// exactly this URL. The same string is the key the archive is registered under on web (the
/// `FileSource`'s file name — see `hazard_archive.dart`).
const String hazardArchiveKey = '/assets/datasets/qc_flood.pmtiles';

/// How the pmtiles library matches a style source to a registered archive.
///
/// This is why the URL below has **three** slashes. The library strips a fixed ten characters
/// — the length of `pmtiles://` — off the style's source URL and looks the remainder up by the
/// key used at registration. So:
///
/// ```text
///   style source        pmtiles:///assets/datasets/qc_flood.pmtiles
///   after strip(10)   -> /assets/datasets/qc_flood.pmtiles
///   registered key    -> /assets/datasets/qc_flood.pmtiles   ✓ same
/// ```
///
/// Writing `pmtiles://assets/...` would leave the key as `assets/...` and miss, making the
/// library quietly construct a *second* archive instance and re-fetch 51 MB. Keep
/// [hazardArchiveKey] and this constant identical, including the leading slash.
///
/// NOAH / Project NOAH hazard overlays, bundled so the map can show modelled hazard with no
/// connection. The archive is the 5.17 GB national file reduced to Quezon City: 169 tiles, z0-14,
/// bounds 120.9697,14.5691 -> 121.1538,14.7964.
///
/// The web value is registered in `main()` via `prepareHazardArchive` and used by the map's
/// `addSource` (through `hazardArchiveUrl`), so the two cannot drift apart. On Android and iOS
/// the URL points at the archive extracted into the app's support directory instead — still
/// `pmtiles://` plus an absolute path, still looked up the same way.
///
/// **Modelled scenarios, not live conditions.** The UI must never call a route or an area "safe"
/// because of this layer; it may only describe "lower known flood exposure".
const String noahHazardArchive = '$pmtilesScheme$hazardArchiveKey';