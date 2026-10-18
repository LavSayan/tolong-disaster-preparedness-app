import 'dart:math';

import 'evacuation_center.dart';

/// Quezon City outline from OpenStreetMap (relation 106569), simplified to ~11 m.
/// Community-mapped, so it is a good service-area check but not a legal survey.
class QcBoundary {
  const QcBoundary({required this.rings, required this.source});

  /// Outer rings as closed lists of points.
  final List<List<GeoPoint>> rings;
  final String source;

  /// Ray-casting point-in-polygon test (inside any outer ring).
  bool contains(GeoPoint p) {
    for (final ring in rings) {
      var inside = false;
      for (var i = 0, j = ring.length - 1; i < ring.length; j = i++) {
        final a = ring[i], b = ring[j];
        if ((a.lat > p.lat) != (b.lat > p.lat) &&
            p.lng < (b.lng - a.lng) * (p.lat - a.lat) / (b.lat - a.lat) + a.lng) {
          inside = !inside;
        }
      }
      if (inside) return true;
    }
    return false;
  }

  GeoBounds get bounds => boundsOf([for (final r in rings) ...r]);

  factory QcBoundary.fromJson(Map<String, Object?> j) => QcBoundary(
        source: j['source'] as String? ?? 'OpenStreetMap',
        rings: [
          for (final r in j['rings'] as List)
            [for (final p in (r as List).cast<List>()) GeoPoint((p[0] as num).toDouble(), (p[1] as num).toDouble())],
        ],
      );
}

class Barangay {
  const Barangay({required this.name, required this.psgc, required this.center});

  final String name;
  final String? psgc;

  /// Approximate center of the barangay polygon (from OSM), good for map framing.
  final GeoPoint center;

  factory Barangay.fromJson(Map<String, Object?> j) => Barangay(
        name: j['name'] as String,
        psgc: j['psgc']?.toString(),
        center: GeoPoint((j['lat'] as num).toDouble(), (j['lng'] as num).toDouble()),
      );
}

const _accents = {'ñ': 'n', 'Ñ': 'n', 'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u'};

/// Lower-case, accent-free, letters and digits only: "Sto. Niño" → "stonino".
String searchKey(String s) {
  final b = StringBuffer();
  for (final ch in s.split('')) {
    final c = (_accents[ch] ?? ch).toLowerCase();
    if (RegExp(r'[a-z0-9]').hasMatch(c)) b.write(c);
  }
  return b.toString();
}

/// Common short forms people type for barangay names.
String _expandAbbreviations(String q) => q
    .replaceAll(RegExp(r'^sto(?=[a-z])'), 'santo')
    .replaceAll(RegExp(r'^sta(?=[a-z])'), 'santa')
    .replaceAll(RegExp(r'^brgy'), '');

/// Barangays whose name contains the query, best matches (prefix) first.
List<Barangay> searchBarangays(List<Barangay> all, String query) {
  final q = _expandAbbreviations(searchKey(query));
  if (q.isEmpty) return all;
  final hits = all.where((b) => searchKey(b.name).contains(q)).toList();
  hits.sort((a, b) {
    final ap = searchKey(a.name).startsWith(q) ? 0 : 1;
    final bp = searchKey(b.name).startsWith(q) ? 0 : 1;
    return ap != bp ? ap - bp : a.name.compareTo(b.name);
  });
  return hits;
}

/// The barangay whose name matches [input], ignoring case, accents and punctuation.
Barangay? findBarangay(List<Barangay> all, String input) {
  final k = searchKey(input);
  if (k.isEmpty) return null;
  for (final b in all) {
    if (searchKey(b.name) == k) return b;
  }
  return null;
}

/// Number of standard 256-px web-map tiles covering [b] from [minZoom] to [maxZoom].
int estimateTileCount(GeoBounds b, int minZoom, int maxZoom) {
  int x(double lng, int z) => ((lng + 180) / 360 * (1 << z)).floor();
  int y(double lat, int z) {
    final r = lat * pi / 180;
    return ((1 - log(tan(r) + 1 / cos(r)) / pi) / 2 * (1 << z)).floor();
  }

  var total = 0;
  for (var z = minZoom; z <= maxZoom; z++) {
    final cols = x(b.northeast.lng, z) - x(b.southwest.lng, z) + 1;
    final rows = y(b.southwest.lat, z) - y(b.northeast.lat, z) + 1;
    total += cols * rows;
  }
  return total;
}
