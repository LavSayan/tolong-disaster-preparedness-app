/// Non-web stand-in. MapLibre Native resolves `pmtiles://` on its own, so there is nothing to
/// register on Android or iOS. Kept so callers never need a `kIsWeb` check.
bool registerPmTilesProtocol(String archiveUrl) => true;