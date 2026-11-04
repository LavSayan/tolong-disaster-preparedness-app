import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/evacuation_center.dart';
import '../domain/ranking.dart';

/// Loading of `assets/data/hazard_bands.json` — per-site hazard bands that
/// `tools/ranking/extract_bands.py` sampled from the bundled NOAH archive.
///
/// This asset is the *exposure feature's* only source (spec `SHELTER_RANKING_ML.md` §3): if it
/// cannot be loaded or parsed, ranking is unavailable and the app falls back to the plain
/// distance list — the failure is returned as `null`, never synthesized from thin air.
class HazardBandsRepository {
  HazardBandsRepository(this._bundle);

  final AssetBundle _bundle;

  static const assetPath = 'assets/data/hazard_bands.json';

  /// Parses off the main thread: the JSON holds 148 sites and must not stall the first paint
  /// of the list it reorders. Benchmarked in `test/evaluation` (spec §7: cold-parse reported).
  Future<HazardBands?> load() async {
    try {
      final bytes = (await _bundle.load(assetPath)).buffer.asUint8List();
      return await compute(HazardBandsRepository.parseBytes, bytes);
    } catch (e) {
      debugPrint('Hazard bands unavailable ($e); ranking falls back to distance order.');
      return null;
    }
  }

  /// Full parse from bytes: UTF-8 decode → JSON → validated value objects.
  @visibleForTesting
  static HazardBands parseBytes(Uint8List bytes) => HazardBands.parse(utf8.decode(bytes));
}

/// One site's sampled hazard bands and the derived exposure block, exactly as written by
/// the extractor. `version`-checked on load; the shape is owned by `tools/ranking/`.
class HazardBands {
  HazardBands._({
    required this.version,
    required this.sites,
    required this.sourceSha256,
    required this.notes,
  });

  factory HazardBands.parse(String raw) {
    final root = jsonDecode(raw) as Map<String, Object?>;
    if ((root['asset'] as String?) != 'hazard_bands') {
      throw const FormatException('not a hazard_bands asset');
    }
    final version = (root['version'] as num?)?.toInt() ?? 0;
    if (version > 1) throw const FormatException('unsupported hazard_bands version');
    if (version != 1) throw const FormatException('missing hazard_bands version');
    final siteList = (root['sites'] as List?) ?? const [];
    final sites = [for (final s in siteList) HazardSite.fromJson(s as Map<String, Object?>)];
    return HazardBands._(
      version: version,
      sites: sites,
      sourceSha256: (((root['source'] ?? const <String, Object?>{}) as Map<String, Object?>)['sha256'] as String?) ?? '',
      notes: [for (final n in (root['notes'] as List?) ?? const []) n as String],
    );
  }

  final int version;

  /// Sites in asset order: barangay repositories are 'bgy-###', demo centres 'demo-##'.
  final List<HazardSite> sites;

  /// The SHA-256 of the PMTiles archive the bands were sampled from, surfacing provenance
  /// (which map data the readings describe) in the UI instead of leaving it implied.
  final String sourceSha256;

  /// Global notes from the extractor — e.g. storm surge excluded as national-resolution.
  /// Nothing here is per-candidate; the UI can show them once.
  final List<String> notes;

  Map<String, HazardSite> get byId => {for (final s in sites) s.id: s};

  /// The site whose sampled band describes [point], within the mandatory
  /// [bandMatchRadiusMeters] of a match — else `null`, i.e. the exposure feature is
  /// **unknown** for this candidate (spec §3: neutral + a gap; never a bonus, never a guess).
  ///
  /// Nearest-site scan; 148 sites make the O(n) call cheap (`exposureAt` × 10 000 is
  /// benchmarked, spec §7) and keep zero mutable state behind it.
  HazardSiteMatch? exposureAt(GeoPoint point) {
    HazardSite? best;
    var bestDistance = double.infinity;
    for (final site in sites) {
      final d = point.distanceKm(site.location) * 1000;
      if (d < bestDistance) {
        bestDistance = d;
        best = site;
      }
    }
    if (best == null || bestDistance > bandMatchRadiusMeters) return null;
    return HazardSiteMatch(site: best, distanceMeters: bestDistance);
  }
}

/// A candidate counts as "matched" only inside this radius of a sampled site's authoritative
/// point. 250 m is generous for coordinate round-off between dataset authors, and far smaller
/// than the spacing where hazard geometry genuinely differs — beyond it, reporting the
/// neighbour's band as if it were this candidate's would be dishonest precision.
const bandMatchRadiusMeters = 250.0;

class HazardSiteMatch {
  const HazardSiteMatch({required this.site, required this.distanceMeters});

  final HazardSite site;
  final double distanceMeters;

  /// Hazard-facing exposure from the sampled bands (spec §3 formula, precomputed by the
  /// extractor so Dart and Python cannot drift: `max(floodComposite, landslide)`).
  double get exposure => site.exposureValue;
}

class HazardSite {
  const HazardSite({
    required this.id,
    required this.name,
    required this.kind,
    required this.location,
    required this.exposureValue,
    required this.floodComposite,
    required this.landslide,
    required this.bands,
  });

  final String id;
  final String name;

  /// `'barangay'` for the 142 proxy sites, `'demo'` for the six demo centres.
  final String kind;
  final GeoPoint location;

  final double exposureValue;
  final double floodComposite;
  final double landslide;

  /// Raw band per source layer (`flood_100yr`…, `landslide`, `debris_flow`,
  /// `storm_surge` always null — see the asset's notes), already max-aggregated over the
  /// 5 sampling points by the extractor. Kept for explanation parity; the feature only
  /// consumes the derived exposure block.
  final Map<String, int?> bands;

  factory HazardSite.fromJson(Map<String, Object?> j) {
    final bands = <String, int?>{};
    for (final entry in ((j['bands'] as Map<String, Object?>?) ?? const <String, Object?>{}).entries) {
      bands[entry.key] = (entry.value as num?)?.toInt();
    }
    final exposure = (j['exposure'] ?? const <String, Object?>{}) as Map<String, Object?>;
    return HazardSite(
      id: j['id'] as String,
      name: j['name'] as String? ?? j['id'] as String,
      kind: j['kind'] as String? ?? 'barangay',
      location: GeoPoint((j['lat'] as num).toDouble(), (j['lng'] as num).toDouble()),
      exposureValue: (exposure['exposure'] as num?)?.toDouble() ?? neutralFeatureValue,
      floodComposite: (exposure['floodComposite'] as num?)?.toDouble() ?? 0,
      landslide: (exposure['landslide'] as num?)?.toDouble() ?? 0,
      bands: bands,
    );
  }
}

final hazardBandsRepositoryProvider = Provider((ref) => HazardBandsRepository(rootBundle));

/// `null` means "hazard bands unavailable" — consumers fall back to plain distance order and
/// surface that fact, per spec §3; they never rank with invented exposure values.
final hazardBandsProvider = FutureProvider<HazardBands?>((ref) => ref.watch(hazardBandsRepositoryProvider).load());
