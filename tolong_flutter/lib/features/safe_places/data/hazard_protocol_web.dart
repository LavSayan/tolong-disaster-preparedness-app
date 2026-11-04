import 'dart:js_interop';

/// Registers the bundled PMTiles hazard archive with MapLibre GL JS.
///
/// The actual work happens in `web/vendor/hazard_archive.js`, loaded by `index.html` next to
/// the vendored pmtiles library: it fetches the archive once over HTTP, wraps the bytes in a
/// `File`-backed pmtiles `FileSource` named [archiveKey], and hands the protocol to
/// `maplibregl.addProtocol`. Naming the `File` [archiveKey] is what makes MapLibre's lookups
/// hit this archive — the library strips the ten-character `pmtiles://` scheme off the style's
/// source URL and matches the remainder against the source's key — see `map_style.dart`.
///
/// A whole-file source is deliberate: pmtiles' HTTP `FetchSource` needs the server to honour
/// byte ranges, and Flutter's dev server — like any plain static file server — answers a
/// `Range` request with a 200 and the entire archive, which the library rejects. Reading the
/// archive into a `File` once needs no byte serving at all, so the overlay works in
/// `flutter run -d chrome` and on any static host.
///
/// Returns `true` when the archive is registered and the overlay can be drawn.
///
/// **Never let this take the app down.** It runs inside `main()`, before the first frame, and
/// an `@JS()` call against a missing global throws. If the vendored script failed to load, or
/// `maplibregl` is not ready (call this from `main()` *after*
/// `MapLibreMap.ensureWebLibraryLoaded()`), that must not stop the app from starting: the
/// caller records the failure and the hazard overlay simply reports itself unavailable. A
/// missing flood layer is an inconvenience; an app that will not launch is a disaster in
/// itself.
Future<bool> registerPmTilesProtocol(String archiveKey) async {
  try {
    final registered = await _loadHazardArchive(archiveKey).toDart;
    return registered?.toDart ?? false;
  } catch (_) {
    // Deliberately swallowed: see the doc comment above. The caller decides how to report it.
    return false;
  }
}

/// `window.tolongLoadHazardArchive(archiveKey)` — resolves `true`/`false`, never rejects.
@JS('tolongLoadHazardArchive')
external JSPromise<JSBoolean?> _loadHazardArchive(String archiveKey);
