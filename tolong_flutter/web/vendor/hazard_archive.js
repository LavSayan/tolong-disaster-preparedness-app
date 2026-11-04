// Loads the bundled PMTiles hazard archive over HTTP into memory and registers it with
// MapLibre GL JS as a whole-file source.
//
// Why not pmtiles' HTTP FetchSource: it needs the server to honour HTTP byte ranges (206
// responses), and neither Flutter's dev server nor a plain static file server does - a range
// request comes back as a 200 carrying the whole archive, which FetchSource rejects
// ("Check that your storage backend supports HTTP Byte Serving"). Reading the archive into a
// File once and handing pmtiles a FileSource needs no byte serving at all, so the overlay
// works in `flutter run -d chrome` and on any static host.
//
// The File is named [key] because pmtiles' FileSource.getKey() is the file name: MapLibre asks
// for `pmtiles://<key>` (it strips the ten-character scheme off the style's source URL), so
// the name must match the source URL character for character - see map_style.dart.
//
// Resolves `true` when the archive is registered; resolves `false` (after a console error) on
// any failure. Dart awaits this once from main(); a `false` makes the hazard overlay report
// itself unavailable instead of drawing nothing.
window.tolongLoadHazardArchive = function (key) {
  return fetch(key)
    .then(function (response) {
      if (!response.ok) throw new Error('HTTP ' + response.status + ' for ' + key);
      return response.arrayBuffer();
    })
    .then(function (bytes) {
      var protocol = new pmtiles.Protocol();
      maplibregl.addProtocol('pmtiles', protocol.tile);
      protocol.add(new pmtiles.PMTiles(new pmtiles.FileSource(new File([bytes], key))));
      return true;
    })
    .catch(function (error) {
      console.error('Hazard archive could not be loaded:', error);
      return false;
    });
};
