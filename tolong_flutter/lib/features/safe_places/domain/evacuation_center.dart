import 'dart:math';

class GeoPoint {
  const GeoPoint(this.lat, this.lng);

  final double lat;
  final double lng;

  /// Great-circle ("straight-line") distance in kilometers. Not a walking distance.
  double distanceKm(GeoPoint other) {
    const r = 6371.0;
    double rad(double d) => d * pi / 180;
    final dLat = rad(other.lat - lat);
    final dLng = rad(other.lng - lng);
    final a = sin(dLat / 2) * sin(dLat / 2) + cos(rad(lat)) * cos(rad(other.lat)) * sin(dLng / 2) * sin(dLng / 2);
    return 2 * r * asin(sqrt(a));
  }
}

class GeoBounds {
  const GeoBounds(this.southwest, this.northeast);

  final GeoPoint southwest;
  final GeoPoint northeast;

  bool contains(GeoPoint p) =>
      p.lat >= southwest.lat && p.lat <= northeast.lat && p.lng >= southwest.lng && p.lng <= northeast.lng;

  GeoPoint get center => GeoPoint((southwest.lat + northeast.lat) / 2, (southwest.lng + northeast.lng) / 2);
}

/// APPROXIMATE rectangle around Quezon City, used only to frame the map and to warn users who
/// seem to be outside the city. It is not the official boundary, which comes in a later step.
const qcApproxBounds = GeoBounds(GeoPoint(14.590, 120.985), GeoPoint(14.775, 121.135));

/// Wider limit for panning, so the map stays focused on Metro Manila around Quezon City.
const metroPanBounds = GeoBounds(GeoPoint(14.45, 120.85), GeoPoint(14.90, 121.25));

enum FacilityType { school, coveredCourt, barangayHall, other }

/// Fields that need verification stay null until an official source provides them.
class EvacuationCenter {
  const EvacuationCenter({
    required this.id,
    required this.name,
    required this.location,
    required this.facilityType,
    required this.source,
    required this.verified,
    this.barangay,
    this.address,
    this.accessibility,
    this.capacity,
    this.facilities = const [],
    this.status,
    this.lastVerified,
  });

  final String id;
  final String name;
  final GeoPoint location;
  final FacilityType facilityType;
  final String? barangay;
  final String? address;
  final String? accessibility;
  final int? capacity;
  final List<String> facilities;
  final String? status;
  final String source;
  final DateTime? lastVerified;

  /// False for development data. The UI labels unverified centers everywhere they appear.
  final bool verified;

  factory EvacuationCenter.fromJson(Map<String, Object?> j, {required String source, required bool verified}) =>
      EvacuationCenter(
        id: j['id'] as String,
        name: j['name'] as String,
        location: GeoPoint((j['lat'] as num).toDouble(), (j['lng'] as num).toDouble()),
        facilityType: FacilityType.values.asNameMap()[j['facilityType']] ?? FacilityType.other,
        barangay: j['barangay'] as String?,
        address: j['address'] as String?,
        accessibility: j['accessibility'] as String?,
        capacity: (j['capacity'] as num?)?.toInt(),
        facilities: (j['facilities'] as List?)?.cast<String>() ?? const [],
        status: j['status'] as String?,
        lastVerified: j['lastVerified'] == null ? null : DateTime.tryParse(j['lastVerified'] as String),
        source: source,
        verified: verified && j['verified'] != false,
      );
}

/// Shortest distance in meters from [p] to the polyline [line]. Uses a local flat projection,
/// which is accurate to well under a meter at city scale.
double distanceToPolylineMeters(GeoPoint p, List<GeoPoint> line) {
  if (line.isEmpty) return double.infinity;
  if (line.length == 1) return p.distanceKm(line.first) * 1000;
  final kx = 111320 * cos(p.lat * pi / 180);
  const ky = 110540.0;
  (double, double) xy(GeoPoint g) => ((g.lng - p.lng) * kx, (g.lat - p.lat) * ky);
  var best = double.infinity;
  for (var i = 0; i < line.length - 1; i++) {
    final (ax, ay) = xy(line[i]);
    final (bx, by) = xy(line[i + 1]);
    final dx = bx - ax, dy = by - ay;
    final len2 = dx * dx + dy * dy;
    final t = len2 == 0 ? 0.0 : ((-ax * dx - ay * dy) / len2).clamp(0.0, 1.0);
    final cx = ax + t * dx, cy = ay + t * dy;
    best = min(best, sqrt(cx * cx + cy * cy));
  }
  return best;
}

GeoBounds boundsOf(List<GeoPoint> points) {
  var s = points.first.lat, n = s, w = points.first.lng, e = w;
  for (final p in points) {
    s = min(s, p.lat);
    n = max(n, p.lat);
    w = min(w, p.lng);
    e = max(e, p.lng);
  }
  return GeoBounds(GeoPoint(s, w), GeoPoint(n, e));
}

/// Ground meters covered by one screen pixel at [zoom] (MapLibre's 512-px tiles) and [lat].
double metersPerPixel(double lat, double zoom) => 78271.517 * cos(lat * pi / 180) / pow(2, zoom);

/// The center nearest to [tap] if it lies within [pixels] screen pixels at [zoom].
EvacuationCenter? nearestWithinPixels(List<EvacuationCenter> centers, GeoPoint tap, double zoom, double pixels) {
  if (centers.isEmpty) return null;
  final (center, km) = byDistance(centers, tap).first;
  return km * 1000 <= pixels * metersPerPixel(tap.lat, zoom) ? center : null;
}

/// Centers sorted by straight-line distance from [from].
List<(EvacuationCenter, double)> byDistance(List<EvacuationCenter> centers, GeoPoint from) =>
    [for (final c in centers) (c, from.distanceKm(c.location))]..sort((a, b) => a.$2.compareTo(b.$2));
