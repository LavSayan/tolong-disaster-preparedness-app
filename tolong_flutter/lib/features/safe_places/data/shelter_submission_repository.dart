import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env.dart';
import '../domain/evacuation_center.dart';
import '../domain/shelter_submission.dart';

/// User-facing shelter submissions. The government side (review queue, decisions) is
/// `ShelterReviewRepository`; account management is `AdminAccountRepository`.
abstract interface class ShelterSubmissionRepository {
  /// Creates a pending submission. The server re-runs every validation the client did,
  /// plus the dedupe trigger and the pending cap, so a crafted request still cannot land
  /// a duplicate or absurd payload.
  Future<ShelterSubmission> submit(ShelterSubmissionDraft draft);

  /// Edits the fields of the caller's own pending submission (the server grant excludes
  /// status columns, so a submitter can never transition their own row).
  Future<void> edit(String id, ShelterSubmissionDraft draft);

  Future<void> withdraw(String id);

  /// The caller's own submissions, newest first — the "My submissions" list.
  Future<List<ShelterSubmission>> mine();
}

/// A submission-as-payload: exactly the columns the user-side grants allow.
Map<String, Object?> shelterSubmissionPayload(String submittedBy, ShelterSubmissionDraft d) => {
      'submitted_by': submittedBy,
      'name': d.name.trim(),
      'lat': d.location.lat,
      'lng': d.location.lng,
      'facility_type': d.facilityType.name,
      'barangay': d.barangay,
      'address': _trimmedOrNull(d.address),
      'accessibility': _trimmedOrNull(d.accessibility),
      'capacity': d.capacity,
      'facilities': [for (final f in d.facilities) f.trim()],
    };

/// Nulls are omitted so the server's field-wise corrections can tell "absent" from
/// "cleared" (empty strings clear; absent keys keep the existing value).
Map<String, Object?> shelterEditPayload(ShelterSubmissionDraft d) {
  final full = shelterSubmissionPayload('', d);
  full.remove('submitted_by');
  return full;
}

String? _trimmedOrNull(String? v) {
  final t = v?.trim();
  return t == null || t.isEmpty ? null : t;
}

ShelterSubmission shelterSubmissionFromJson(Map<String, Object?> j) => ShelterSubmission(
      id: j['id'] as String,
      submittedBy: (j['submitted_by'] as String?) ?? '',
      submittedAt: DateTime.tryParse(j['created_at'] as String? ?? '') ?? DateTime.utc(0),
      status: SubmissionStatus.values.asNameMap()[j['status']] ?? SubmissionStatus.pending,
      rejectionReason: j['rejection_reason'] as String?,
      shelterId: j['shelter_id'] as String?,
      draft: _draftFromRow(j),
    );

ShelterSubmissionDraft _draftFromRow(Map<String, Object?> j) => ShelterSubmissionDraft(
      name: j['name'] as String? ?? '',
      location: GeoPoint(
        (j['lat'] as num?)?.toDouble() ?? 0,
        (j['lng'] as num?)?.toDouble() ?? 0,
      ),
      facilityType: FacilityType.values.asNameMap()[j['facility_type']] ?? FacilityType.other,
      barangay: j['barangay'] as String? ?? '',
      address: j['address'] as String?,
      accessibility: j['accessibility'] as String?,
      capacity: (j['capacity'] as num?)?.toInt(),
      facilities: (j['facilities'] as List?)?.cast<String>() ?? const [],
    );

/// Maps server-side constraint failures to codes the UI can translate. The DB's own
/// error codes stay authoritative: dedupe violations carry SQLSTATE 23514.
SubmissionErrorCode submissionFaultFrom(Exception e) {
  if (e is PostgrestException) {
    if (e.code == '23514') {
      final m = e.message.toLowerCase();
      if (m.contains('duplicate')) return SubmissionErrorCode.duplicateShelter;
      if (m.contains('check')) return SubmissionErrorCode.invalidFields;
    }
    if (e.code == '23503') return SubmissionErrorCode.unknownBarangay; // barangay FK
    if (e.code == '22P02') return SubmissionErrorCode.invalidFields;
  }
  return SubmissionErrorCode.unknown;
}

class SupabaseShelterSubmissionRepository implements ShelterSubmissionRepository {
  @override
  Future<ShelterSubmission> submit(ShelterSubmissionDraft draft) async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) throw const SubmissionFailure(SubmissionErrorCode.notAuthenticated);
    final rows = await _run(() => Supabase.instance.client
        .from('shelter_submissions')
        .insert(shelterSubmissionPayload(uid, draft))
        .select());
    if (rows.isEmpty) throw const SubmissionFailure(SubmissionErrorCode.unknown);
    return shelterSubmissionFromJson(rows.first as Map<String, Object?>);
  }

  @override
  Future<void> edit(String id, ShelterSubmissionDraft draft) =>
      _run(() => Supabase.instance.client
          .from('shelter_submissions')
          .update(shelterEditPayload(draft))
          .eq('id', id));

  @override
  Future<void> withdraw(String id) =>
      _run(() => Supabase.instance.client.from('shelter_submissions').delete().eq('id', id));

  @override
  Future<List<ShelterSubmission>> mine() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) throw const SubmissionFailure(SubmissionErrorCode.notAuthenticated);
    final rows = await _run(() => Supabase.instance.client
        .from('shelter_submissions')
        .select()
        .eq('submitted_by', uid)
        .order('created_at', ascending: false)
        .limit(50));
    return [for (final r in rows) shelterSubmissionFromJson(r as Map<String, Object?>)];
  }

  Future<T> _run<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on PostgrestException catch (e) {
      throw SubmissionFailure(submissionFaultFrom(e));
    } on AuthException {
      throw const SubmissionFailure(SubmissionErrorCode.network);
    } catch (e) {
      debugPrint('Submission error: ${e.runtimeType}');
      throw const SubmissionFailure(SubmissionErrorCode.unknown);
    }
  }
}

/// Honest failure when the app is built without a Supabase configuration.
class UnconfiguredShelterSubmissionRepository implements ShelterSubmissionRepository {
  static const _failure = SubmissionFailure(SubmissionErrorCode.notConfigured);

  @override
  Future<ShelterSubmission> submit(ShelterSubmissionDraft draft) async => throw _failure;

  @override
  Future<void> edit(String id, ShelterSubmissionDraft draft) async => throw _failure;

  @override
  Future<void> withdraw(String id) async => throw _failure;

  @override
  Future<List<ShelterSubmission>> mine() async => throw _failure;
}

final shelterSubmissionRepositoryProvider = Provider<ShelterSubmissionRepository>(
  (ref) =>
      Env.supabaseConfigured ? SupabaseShelterSubmissionRepository() : UnconfiguredShelterSubmissionRepository(),
);
