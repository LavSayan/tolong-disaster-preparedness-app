import 'evacuation_center.dart';
import 'qc_area.dart';

/// Lifecycle of a community-submitted shelter. `pending` rows are visible to their
/// submitter and to government reviewers only; `approved` rows are certified into the
/// shelter list the app ranks.
enum SubmissionStatus { pending, approved, rejected }

/// Error codes, not text, so the UI can show them in the user's language (same pattern
/// as AuthErrorCode / RouteErrorCode).
enum SubmissionErrorCode {
  notConfigured,
  notAuthenticated,
  outsideQc,
  unknownBarangay,
  duplicateShelter,
  tooManyPending,
  invalidFields,
  network,
  unknown,
}

class SubmissionFailure implements Exception {
  const SubmissionFailure(this.code);

  final SubmissionErrorCode code;

  @override
  String toString() => 'SubmissionFailure($code)';
}

/// What a user submits (or edits while their submission is still pending). Reviews may
/// correct any field server-side; this draft never carries review fields (status, reason).
class ShelterSubmissionDraft {
  const ShelterSubmissionDraft({
    required this.name,
    required this.location,
    required this.facilityType,
    required this.barangay,
    this.address,
    this.accessibility,
    this.capacity,
    this.facilities = const [],
  });

  final String name;
  final GeoPoint location;
  final FacilityType facilityType;
  final String barangay;
  final String? address;
  final String? accessibility;

  /// Optional in v1: the ranking does not use capacity, but officials measuring it
  /// during review can fill it in.
  final int? capacity;
  final List<String> facilities;

  ShelterSubmissionDraft copyWith({
    String? name,
    GeoPoint? location,
    FacilityType? facilityType,
    String? barangay,
    String? Function()? address,
    String? Function()? accessibility,
    int? Function()? capacity,
    List<String>? facilities,
  }) =>
      ShelterSubmissionDraft(
        name: name ?? this.name,
        location: location ?? this.location,
        facilityType: facilityType ?? this.facilityType,
        barangay: barangay ?? this.barangay,
        address: address != null ? address() : this.address,
        accessibility: accessibility != null ? accessibility() : this.accessibility,
        capacity: capacity != null ? capacity() : this.capacity,
        facilities: facilities ?? this.facilities,
      );
}

/// One submission as it lives on the server.
class ShelterSubmission {
  const ShelterSubmission({
    required this.id,
    required this.submittedBy,
    required this.submittedAt,
    required this.status,
    required this.draft,
    this.rejectionReason,
    this.shelterId,
  });

  final String id;

  /// The submitter's account id. Reviewers see the tail only; the UI never names people.
  final String submittedBy;
  final DateTime submittedAt;
  final SubmissionStatus status;

  /// Set only for `rejected`; free-form text from the reviewing official, capped by the
  /// server at 300 characters.
  final String? rejectionReason;

  /// Set only for `approved`: the certified shelter row this submission became.
  final String? shelterId;

  final ShelterSubmissionDraft draft;
}

/// Straight-line radius under which a new submission counts as a duplicate of an
/// existing shelter or pending submission. Mirrors the DB trigger's 100 m value — one
/// guard the user sees immediately, one that still holds for a crafted request. Both
/// use the same haversine great-circle distance ([GeoPoint.distanceKm]).
const duplicateRadiusMeters = 100.0;

/// Local validation mirroring the server's CHECKs, so the obvious failures surface in
/// the form instead of after a network round trip. The reviewer remains the human gate;
/// this is only the machine gate's client-side mirror. Returns the first failure, else
/// `null`.
SubmissionErrorCode? validateShelterSubmission(
  ShelterSubmissionDraft draft, {
  required List<Barangay> knownBarangays,
  required List<EvacuationCenter> existingCenters,
}) {
  final name = draft.name.trim();
  if (name.isEmpty || name.length > 120) return SubmissionErrorCode.invalidFields;
  final address = draft.address?.trim();
  if (address != null && address.length > 200) return SubmissionErrorCode.invalidFields;
  final accessibility = draft.accessibility?.trim();
  if (accessibility != null && accessibility.length > 200) return SubmissionErrorCode.invalidFields;
  final capacity = draft.capacity;
  if (capacity != null && (capacity < 1 || capacity > 100000)) {
    return SubmissionErrorCode.invalidFields;
  }
  if (!qcApproxBounds.contains(draft.location)) return SubmissionErrorCode.outsideQc;
  if (!knownBarangays.any((b) => b.name == draft.barangay)) {
    return SubmissionErrorCode.unknownBarangay;
  }
  for (final c in existingCenters) {
    if (draft.location.distanceKm(c.location) * 1000 <= duplicateRadiusMeters) {
      return SubmissionErrorCode.duplicateShelter;
    }
  }
  return null;
}
