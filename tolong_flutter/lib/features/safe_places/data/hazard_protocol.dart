/// Registration of the `pmtiles://` protocol, split by platform.
///
/// Android and iOS resolve `pmtiles://` inside MapLibre Native and need nothing from Dart. Only
/// web has to hand MapLibre GL JS the archive, and that needs `dart:js_interop`, which cannot be
/// compiled into a mobile build at all — hence the conditional import.
library;

export 'hazard_protocol_stub.dart' if (dart.library.js_interop) 'hazard_protocol_web.dart';