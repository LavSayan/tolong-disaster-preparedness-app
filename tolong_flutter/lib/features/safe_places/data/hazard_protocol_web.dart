import 'dart:js_interop';

/// Registers the `pmtiles://` protocol with MapLibre GL JS and points it at [archiveUrl].
///
/// Returns `true` when the archive is registered and the overlay can be drawn.
///
/// Android and iOS need none of this: MapLibre Native resolves `pmtiles://` internally (see
/// `hazard_protocol_stub.dart`). On web the plugin loads MapLibre GL JS itself, so `maplibregl`
/// does not exist while `index.html` is being parsed — call this from `main()` *after*
/// `MapLibreMap.ensureWebLibraryLoaded()`.
///
/// **Never let this take the app down.** It runs inside `main()`, before the first frame, and an
/// `@JS()` call against a missing global throws. If `pmtiles.js` failed to load, or `maplibregl`
/// is not ready, that must not stop the app from starting: the caller records the failure and
/// the hazard overlay simply reports itself unavailable. A missing flood layer is an
/// inconvenience; an app that will not launch is a disaster in itself.
///
/// [archiveUrl] must be exactly the URL the style's source uses after the `pmtiles://` prefix.
/// The library keys registered archives by the string handed to `FetchSource`, so the two must
/// match character for character — see `map_style.dart`.
bool registerPmTilesProtocol(String archiveUrl) {
  try {
    final protocol = _Protocol();
    _addProtocol('pmtiles', protocol.tile);
    protocol.add(_PmTiles(_FetchSource(archiveUrl)));
    return true;
  } catch (_) {
    // Deliberately swallowed: see the doc comment above. The caller decides how to report it.
    return false;
  }
}

@JS('maplibregl.addProtocol')
external void _addProtocol(String customProtocol, JSFunction loadFn);

/// `new pmtiles.Protocol()`. `tile` is the load callback MapLibre expects; pmtiles defines it
/// as a bound arrow-function property, so it has to be handed over detached.
@JS('pmtiles.Protocol')
extension type _Protocol._(JSObject _) implements JSObject {
  external _Protocol();

  external JSFunction get tile;

  external void add(_PmTiles archive);
}

@JS('pmtiles.PMTiles')
extension type _PmTiles._(JSObject _) implements JSObject {
  external _PmTiles(_FetchSource source);
}

@JS('pmtiles.FetchSource')
extension type _FetchSource._(JSObject _) implements JSObject {
  external _FetchSource(String url);
}