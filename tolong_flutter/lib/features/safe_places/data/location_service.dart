import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../domain/evacuation_center.dart';

sealed class LocationResult {
  const LocationResult();
}

class Located extends LocationResult {
  const Located(this.point);
  final GeoPoint point;
}

class LocationServiceOff extends LocationResult {
  const LocationServiceOff();
}

class LocationDenied extends LocationResult {
  const LocationDenied();
}

class LocationDeniedForever extends LocationResult {
  const LocationDeniedForever();
}

class LocationFailed extends LocationResult {
  const LocationFailed();
}

abstract interface class LocationService {
  /// Asks for permission if needed, then reads one position. Never throws.
  Future<LocationResult> current();

  /// Live position updates (about every 10 m of movement). Call only after [current] succeeded.
  Stream<GeoPoint> watch();
  Future<void> openAppSettings();
  Future<void> openLocationSettings();
}

class GeolocatorLocationService implements LocationService {
  @override
  Future<LocationResult> current() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return const LocationServiceOff();
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return const LocationDenied();
      if (permission == LocationPermission.deniedForever) return const LocationDeniedForever();
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 20)),
      );
      return Located(GeoPoint(p.latitude, p.longitude));
    } catch (e) {
      debugPrint('Location failed: ${e.runtimeType}');
      return const LocationFailed();
    }
  }

  @override
  Stream<GeoPoint> watch() => Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10),
      ).map((p) => GeoPoint(p.latitude, p.longitude));

  @override
  Future<void> openAppSettings() => Geolocator.openAppSettings();

  @override
  Future<void> openLocationSettings() => Geolocator.openLocationSettings();
}

final locationServiceProvider = Provider<LocationService>((ref) => GeolocatorLocationService());
