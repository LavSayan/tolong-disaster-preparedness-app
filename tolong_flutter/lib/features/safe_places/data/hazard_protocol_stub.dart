/// Non-web stand-in. MapLibre Native resolves `pmtiles://` on its own, so there is nothing to
/// register on Android or iOS: `hazard_archive.dart` extracts the bundled archive to a real
/// file and the scheme reads it from there. Kept so callers never need a `kIsWeb` check.
Future<bool> registerPmTilesProtocol(String archiveKey) async => true;
