import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:path_provider/path_provider.dart';

import 'hazard_protocol.dart';
import 'map_style.dart';

/// The asset key of the bundled hazard archive, as declared in `pubspec.yaml`.
const String _hazardAssetKey = 'datasets/qc_flood.pmtiles';

/// The file name the archive is extracted to under the app's support directory.
///
/// Part of the update story: if `datasets/qc_flood.pmtiles` is ever replaced with new data,
/// bump this name (for example `qc_flood-2.pmtiles`) so installs that already extracted the
/// old copy re-extract instead of reading it forever.
const String _hazardArchiveFile = 'qc_flood.pmtiles';

/// Prepares the bundled hazard archive for this platform and returns the `pmtiles://` URL the
/// map's source must use, or `null` when the overlay cannot work in this build.
///
/// - **Web** (`flutter run -d chrome` and any static host): registers the `pmtiles://` protocol
///   with MapLibre GL JS against a whole-file source and returns [noahHazardArchive]. The
///   whole-file source is why the dev server works: pmtiles' HTTP `FetchSource` needs the
///   server to honour byte ranges, and it does not.
/// - **Android and iOS**: MapLibre Native reads `pmtiles://` only from a seekable file, and a
///   bundled asset is deflated inside the APK with no filesystem path — so the archive is
///   copied once into the app's support directory and the URL points at that copy.
///
/// **Never let this take the app down.** It runs inside `main()`, before the first frame. Any
/// failure is reported as `null`; the caller records it and the hazard overlay reports itself
/// unavailable. A missing flood layer is an inconvenience; an app that will not launch is a
/// disaster in itself.
Future<String?> prepareHazardArchive() async {
  try {
    if (kIsWeb) {
      await MapLibreMap.ensureWebLibraryLoaded();
      final registered = await registerPmTilesProtocol(hazardArchiveKey);
      return registered ? noahHazardArchive : null;
    }
    final file = await _extractedArchive();
    return '$pmtilesScheme${file.path}';
  } catch (error) {
    debugPrint('Hazard archive unavailable, continuing without it: $error');
    return null;
  }
}

/// The archive as a real file in the app's support directory, extracting it on first run.
///
/// The copy is atomic — write to `.part`, then rename — so an interrupted first run cannot
/// leave a half-written archive that later reads as valid. The extraction runs once per
/// install; see [_hazardArchiveFile] for how data updates re-extract.
Future<File> _extractedArchive() async {
  final support = await getApplicationSupportDirectory();
  final target = File('${support.path}${Platform.pathSeparator}$_hazardArchiveFile');
  if (target.existsSync()) return target;
  final bytes = await rootBundle.load(_hazardAssetKey);
  final part = File('${target.path}.part');
  await part
      .writeAsBytes(bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes), flush: true);
  await part.rename(target.path);
  return target;
}
