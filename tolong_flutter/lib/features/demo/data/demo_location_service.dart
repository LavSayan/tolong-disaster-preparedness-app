import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../safe_places/data/location_service.dart';
import '../../safe_places/domain/evacuation_center.dart';
import '../application/demo_session.dart';

/// Sits in front of the real location service only in demo builds. While an override is
/// set, both [current] and [watch] return that exact point, so Safe Places, the ranked list
/// and turn-by-turn navigation all see the simulated position; with no override the build is
/// fully real.
class DemoLocationService implements LocationService {
  DemoLocationService(this._ref, this._base);

  final Ref _ref;
  final LocationService _base;

  GeoPoint? get _override => _ref.read(demoSessionProvider.select((s) => s.locationOverride));

  @override
  Future<LocationResult> current() async {
    final point = _override;
    if (point != null) return Located(point);
    return _base.current();
  }

  @override
  Stream<GeoPoint> watch() {
    final point = _override;
    if (point != null) {
      // One emission and close: a fixed fake position never moves, and navigation's stream
      // contract only needs updates on change.
      return Stream.value(point);
    }
    return _base.watch();
  }

  @override
  Future<void> openAppSettings() => _base.openAppSettings();

  @override
  Future<void> openLocationSettings() => _base.openLocationSettings();
}
