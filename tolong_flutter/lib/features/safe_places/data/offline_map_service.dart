import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart' as ml;

import '../domain/evacuation_center.dart';
import '../domain/qc_area.dart';
import 'map_style.dart';

/// Vector tiles stop at zoom 14 and are drawn larger beyond that, so 10–14 covers street level.
const offlineMinZoom = 10;
const offlineMaxZoom = 14;

/// OpenFreeMap's published offline limit per download.
const openFreeMapTileLimit = 3000;

sealed class OfflineMapStatus {
  const OfflineMapStatus();
}

class OfflineUnsupported extends OfflineMapStatus {
  const OfflineUnsupported();
}

class OfflineChecking extends OfflineMapStatus {
  const OfflineChecking();
}

class OfflineNotDownloaded extends OfflineMapStatus {
  const OfflineNotDownloaded();
}

class OfflineDownloading extends OfflineMapStatus {
  const OfflineDownloading(this.fraction);

  /// 0–1.
  final double fraction;
}

class OfflineDownloaded extends OfflineMapStatus {
  const OfflineDownloaded({this.at, this.bytes});
  final DateTime? at;
  final int? bytes;
}

class OfflineFailed extends OfflineMapStatus {
  const OfflineFailed();
}

abstract interface class OfflineMapService {
  Future<OfflineMapStatus> status();

  /// Emits progress, then [OfflineDownloaded] or [OfflineFailed].
  Stream<OfflineMapStatus> download(GeoBounds bounds);
  Future<void> delete();
}

/// MapLibre native offline regions (Android/iOS). The map uses them automatically when offline.
class MapLibreOfflineMapService implements OfflineMapService {
  static const _key = 'tolong_region';
  static const _value = 'quezon_city';

  Future<ml.OfflineRegion?> _region() async {
    final regions = await ml.getListOfRegions();
    for (final r in regions) {
      if (r.metadata[_key] == _value) return r;
    }
    return null;
  }

  @override
  Future<OfflineMapStatus> status() async {
    if (kIsWeb) return const OfflineUnsupported();
    try {
      final region = await _region();
      if (region == null) return const OfflineNotDownloaded();
      final s = await ml.getOfflineRegionStatus(region.id);
      if (!s.isComplete) return const OfflineFailed();
      return OfflineDownloaded(
        at: DateTime.tryParse(region.metadata['downloadedAt']?.toString() ?? ''),
        bytes: s.completedResourceSize,
      );
    } catch (e) {
      debugPrint('Offline status failed: ${e.runtimeType}');
      return const OfflineFailed();
    }
  }

  @override
  Stream<OfflineMapStatus> download(GeoBounds bounds) {
    final out = StreamController<OfflineMapStatus>();
    var bytes = 0;
    Future<void> run() async {
      try {
        final old = await _region();
        if (old != null) await ml.deleteOfflineRegion(old.id);
        await ml.setOfflineTileCountLimit(openFreeMapTileLimit);
        await ml.setOfflineMaxConcurrentRequests(maxRequests: 4, maxRequestsPerHost: 4);
        await ml.setHttpHeaders({'User-Agent': 'TolongApp/0.3 (Quezon City disaster-preparedness student project)'});
        out.add(const OfflineDownloading(0));
        await ml.downloadOfflineRegion(
          ml.OfflineRegionDefinition(
            bounds: ml.LatLngBounds(
              southwest: ml.LatLng(bounds.southwest.lat, bounds.southwest.lng),
              northeast: ml.LatLng(bounds.northeast.lat, bounds.northeast.lng),
            ),
            mapStyleUrl: openFreeMapStyle,
            minZoom: offlineMinZoom.toDouble(),
            maxZoom: offlineMaxZoom.toDouble(),
          ),
          metadata: {_key: _value, 'downloadedAt': DateTime.now().toIso8601String()},
          onEvent: (e) {
            if (out.isClosed) return;
            switch (e) {
              case ml.InProgress(:final progress, :final completedResourceSize):
                bytes = completedResourceSize;
                // The plugin reports 0–100 on some platforms and 0–1 on others.
                out.add(OfflineDownloading(((progress > 1 ? progress / 100 : progress)).clamp(0.0, 1.0)));
              case ml.Success():
                out
                  ..add(OfflineDownloaded(at: DateTime.now(), bytes: bytes))
                  ..close();
              case ml.Error():
                out
                  ..add(const OfflineFailed())
                  ..close();
            }
          },
        );
      } catch (e) {
        debugPrint('Offline download failed: ${e.runtimeType}');
        if (!out.isClosed) {
          out
            ..add(const OfflineFailed())
            ..close();
        }
      }
    }

    unawaited(run());
    return out.stream;
  }

  @override
  Future<void> delete() async {
    final region = await _region();
    if (region != null) await ml.deleteOfflineRegion(region.id);
    await ml.clearAmbientCache();
  }
}

final offlineMapServiceProvider = Provider<OfflineMapService>((ref) => MapLibreOfflineMapService());

class OfflineMapController extends Notifier<OfflineMapStatus> {
  StreamSubscription<OfflineMapStatus>? _sub;

  @override
  OfflineMapStatus build() {
    ref.onDispose(() => _sub?.cancel());
    unawaited(refresh());
    return const OfflineChecking();
  }

  Future<void> refresh() async => state = await ref.read(offlineMapServiceProvider).status();

  void download(QcBoundary boundary) {
    _sub?.cancel();
    _sub = ref.read(offlineMapServiceProvider).download(boundary.bounds).listen((s) => state = s);
  }

  Future<void> delete() async {
    await ref.read(offlineMapServiceProvider).delete();
    state = const OfflineNotDownloaded();
  }
}

final offlineMapProvider = NotifierProvider<OfflineMapController, OfflineMapStatus>(OfflineMapController.new);
