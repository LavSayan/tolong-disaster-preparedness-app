import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env.dart';
import '../../../core/storage/secure_vault.dart';
import '../domain/evacuation_center.dart';

/// The government-validated shelter list. Every row was approved through
/// `review_submission`, so the app trusts it with `verified: true` and the UI labels it
/// as government-verified rather than demo data.
abstract interface class ValidatedShelterSource {
  Future<List<EvacuationCenter>> fetchApproved();
}

class SupabaseValidatedShelterSource implements ValidatedShelterSource {
  @override
  Future<List<EvacuationCenter>> fetchApproved() async {
    final rows = await Supabase.instance.client
        .from('shelters')
        .select()
        .order('created_at', ascending: true)
        .limit(200);
    return [for (final r in rows) validatedCenterFromJson(r as Map<String, Object?>)];
  }
}

/// Used when the build has no Supabase configuration: callers treat a null/empty result
/// plus the bundled asset as the complete picture (as before this feature existed).
class UnconfiguredValidatedShelterSource implements ValidatedShelterSource {
  @override
  Future<List<EvacuationCenter>> fetchApproved() async => const [];
}

EvacuationCenter validatedCenterFromJson(Map<String, Object?> j) => EvacuationCenter(
      id: j['id'] as String,
      name: j['name'] as String,
      location: GeoPoint(
        (j['lat'] as num?)?.toDouble() ?? 0,
        (j['lng'] as num?)?.toDouble() ?? 0,
      ),
      facilityType: FacilityType.values.asNameMap()[j['facility_type']] ?? FacilityType.other,
      barangay: j['barangay'] as String?,
      address: j['address'] as String?,
      accessibility: j['accessibility'] as String?,
      capacity: (j['capacity'] as num?)?.toInt(),
      facilities: (j['facilities'] as List?)?.cast<String>() ?? const [],
      status: j['status'] as String?,
      source: j['source'] as String? ?? 'Government-verified',
      lastVerified: DateTime.tryParse(j['approved_at'] as String? ?? ''),
      verified: true,
    );

/// Offline copy of the validated list: same encoded shape written to the encrypted
/// vault, so the ranked list still includes approved shelters without connectivity.
/// Not personal data (public locations), so no per-user keying.
class ValidatedShelterCache {
  ValidatedShelterCache(this._vault);

  final SecureVault _vault;

  static const key = 'validated_shelters_v1';

  Future<List<EvacuationCenter>> load() async {
    final raw = await _vault.read(key);
    if (raw == null) return const [];
    try {
      final json = jsonDecode(raw) as Map<String, Object?>;
      return [
        for (final c in (json['shelters'] as List?) ?? const [])
          EvacuationCenter.fromJson(c as Map<String, Object?>, source: 'Government-verified', verified: true),
      ];
    } catch (e) {
      debugPrint('Validated shelter cache unreadable: ${e.runtimeType}');
      return const [];
    }
  }

  Future<void> save(List<EvacuationCenter> centers) async {
    final json = jsonEncode({
      'savedAt': DateTime.now().toUtc().toIso8601String(),
      'shelters': [for (final c in centers) validatedCentertoJson(c)],
    });
    await _vault.write(key, json);
  }
}

Map<String, Object?> validatedCentertoJson(EvacuationCenter c) => {
      'id': c.id,
      'name': c.name,
      'lat': c.location.lat,
      'lng': c.location.lng,
      'facilityType': c.facilityType.name,
      'barangay': c.barangay,
      'address': c.address,
      'accessibility': c.accessibility,
      'capacity': c.capacity,
      'facilities': c.facilities,
      'status': c.status,
      'source': c.source,
      'lastVerified': c.lastVerified?.toUtc().toIso8601String(),
      'verified': true,
    };

/// Bundled asset first, validated rows second. Dedupe is unneeded in practice (server
/// ids are uuids, the asset uses `demo-##`/`bgy-###`), but merging by id keeps the
/// operation idempotent across repeated loads.
List<EvacuationCenter> mergeCenters(List<EvacuationCenter> bundled, List<EvacuationCenter> validated) {
  final merged = <String, EvacuationCenter>{for (final c in bundled) c.id: c};
  for (final c in validated) {
    merged[c.id] = c; // validated row wins if ids ever collide
  }
  return merged.values.toList();
}

final validatedShelterSourceProvider = Provider<ValidatedShelterSource>(
  (ref) => Env.supabaseConfigured ? SupabaseValidatedShelterSource() : UnconfiguredValidatedShelterSource(),
);

final validatedShelterCacheProvider = Provider<ValidatedShelterCache>((ref) => ValidatedShelterCache(ref.watch(secureVaultProvider)));

