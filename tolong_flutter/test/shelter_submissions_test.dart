import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tolong_flutter/features/auth/data/auth_repository.dart';
import 'package:tolong_flutter/features/safe_places/data/location_service.dart';
import 'package:tolong_flutter/features/safe_places/data/shelter_review_repository.dart';
import 'package:tolong_flutter/features/safe_places/data/shelter_submission_repository.dart';
import 'package:tolong_flutter/features/safe_places/data/validated_shelter_repository.dart';
import 'package:tolong_flutter/features/safe_places/domain/evacuation_center.dart';
import 'package:tolong_flutter/features/safe_places/domain/qc_area.dart';
import 'package:tolong_flutter/features/safe_places/domain/shelter_submission.dart';

import 'test_helpers.dart';

const _barangays = [Barangay(name: 'Batasan Hills', psgc: '1381300139', center: GeoPoint(14.682456, 121.097416))];

EvacuationCenter _center(String id, GeoPoint p) => EvacuationCenter(
      id: id,
      name: 'Center $id',
      location: p,
      facilityType: FacilityType.school,
      source: 's',
      verified: false,
    );

ShelterSubmissionDraft _draft({GeoPoint? at, String name = 'Sto. Domingo ES', String barangay = 'Batasan Hills'}) =>
    ShelterSubmissionDraft(
      name: name,
      location: at ?? const GeoPoint(14.7270, 121.0425),
      facilityType: FacilityType.school,
      barangay: barangay,
    );

class FakeSubmissions implements ShelterSubmissionRepository {
  final submitted = <ShelterSubmissionDraft>[];
  final edited = <(String, ShelterSubmissionDraft)>[];
  final withdrawn = <String>[];
  SubmissionFailure? failNext;

  List<ShelterSubmission> mineRows = [];

  @override
  Future<ShelterSubmission> submit(ShelterSubmissionDraft draft) async {
    if (failNext != null) {
      final f = failNext!;
      failNext = null;
      throw f;
    }
    submitted.add(draft);
    return ShelterSubmission(
      id: 'sub-${submitted.length}',
      submittedBy: 'user-1',
      submittedAt: fixedNow,
      status: SubmissionStatus.pending,
      draft: draft,
    );
  }

  @override
  Future<void> edit(String id, ShelterSubmissionDraft draft) async => edited.add((id, draft));

  @override
  Future<void> withdraw(String id) async => withdrawn.add(id);

  @override
  Future<List<ShelterSubmission>> mine() async => mineRows;
}

class FakeReview implements ShelterReviewRepository {
  final approved = <(String, ShelterSubmissionDraft?)>[];
  final rejected = <(String, String)>[];
  final edited = <(String, ShelterSubmissionDraft)>[];
  List<ShelterSubmission> queue = [];

  @override
  Future<List<ShelterSubmission>> pendingQueue() async => queue;

  @override
  Future<void> applyEdit(String id, ShelterSubmissionDraft draft) async => edited.add((id, draft));

  @override
  Future<void> approve(String id, {ShelterSubmissionDraft? edits}) async => approved.add((id, edits));

  @override
  Future<void> reject(String id, {required String reason}) async => rejected.add((id, reason));
}

void main() {
  group('validateShelterSubmission', () {
    test('accepts a valid draft', () {
      expect(validateShelterSubmission(_draft(), knownBarangays: _barangays, existingCenters: const []), isNull);
    });

    test('rejects an empty or over-long name', () {
      expect(
        validateShelterSubmission(_draft(name: ''), knownBarangays: _barangays, existingCenters: const []),
        SubmissionErrorCode.invalidFields,
      );
      expect(
        validateShelterSubmission(
          _draft(name: 'x' * 121),
          knownBarangays: _barangays,
          existingCenters: const [],
        ),
        SubmissionErrorCode.invalidFields,
      );
    });

    test('rejects an implausible capacity', () {
      const d = ShelterSubmissionDraft(
        name: 'n',
        location: GeoPoint(14.7270, 121.0425),
        facilityType: FacilityType.school,
        barangay: 'Batasan Hills',
        capacity: 0,
      );
      expect(validateShelterSubmission(d, knownBarangays: _barangays, existingCenters: const []),
          SubmissionErrorCode.invalidFields);
    });

    test('rejects a pin outside Quezon City', () {
      expect(
        validateShelterSubmission(
          _draft(at: const GeoPoint(14.5, 121.2)),
          knownBarangays: _barangays,
          existingCenters: const [],
        ),
        SubmissionErrorCode.outsideQc,
      );
    });

    test('rejects a barangay not in the PSGC list', () {
      expect(
        validateShelterSubmission(
          _draft(barangay: 'Nowhere'),
          knownBarangays: _barangays,
          existingCenters: const [],
        ),
        SubmissionErrorCode.unknownBarangay,
      );
    });

    test('rejects a duplicate within the 100 m radius', () {
      const pin = GeoPoint(14.7270, 121.0425);
      final existing = _center('a', const GeoPoint(14.7270, 121.0427)); // ~78 m away
      expect(
        validateShelterSubmission(_draft(at: pin), knownBarangays: _barangays, existingCenters: [existing]),
        SubmissionErrorCode.duplicateShelter,
      );
    });
  });

  group('mergeCenters', () {
    test('appends validated shelters and lets them win on id collision', () {
      final bundled = [_center('a', const GeoPoint(14.7, 121.0)), _center('b', const GeoPoint(14.71, 121.0))];
      final validated = [_center('b', const GeoPoint(14.72, 121.0)), _center('c', const GeoPoint(14.73, 121.0))];
      final merged = mergeCenters(bundled, validated);
      expect(merged.map((c) => c.id).toSet(), {'a', 'b', 'c'});
      expect(merged.firstWhere((c) => c.id == 'b').location.lat, 14.72);
    });
  });

  testWidgets('a government reviewer sees the review tile, a user does not', (tester) async {
    await pumpApp(
      tester,
      prefs: {'language': 'en', 'onboarding_complete:user-1': true},
      auth: FakeAuthRepository(role: AppUserRole.government),
      review: FakeReview(),
      admin: UnconfiguredAdminAccountRepository(),
    );
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    expect(find.text('Review shelter submissions'), findsOneWidget);

    await pumpApp(
      tester,
      prefs: {'language': 'en', 'onboarding_complete:user-1': true},
      auth: FakeAuthRepository(role: AppUserRole.user),
      review: FakeReview(),
      admin: UnconfiguredAdminAccountRepository(),
    );
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    expect(find.text('Review shelter submissions'), findsNothing);
  });

  testWidgets('a signed-in user can submit a shelter', (tester) async {
    final submissions = FakeSubmissions();
    await pumpApp(
      tester,
      prefs: {'language': 'en', 'onboarding_complete:user-1': true},
      auth: FakeAuthRepository(),
      location: FakeLocationService(const Located(GeoPoint(14.7000, 121.1100))),
      submissions: submissions,
    );

    await tester.tap(find.text('Safe places').last);
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('Add a shelter'));
    await tester.tap(find.text('Add a shelter'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'Sto. Domingo ES');

    await scrollTo(tester, find.text('Use my location'));
    await tester.tap(find.text('Use my location'));
    await tester.pumpAndSettle();

    final barangayField = find.byType(DropdownButtonFormField<Barangay>);
    await scrollTo(tester, barangayField);
    await tester.tap(barangayField);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alicia').last);
    await tester.pumpAndSettle();

    await scrollTo(tester, find.text('Send for review'));
    await tester.tap(find.text('Send for review'));
    await tester.pumpAndSettle();

    expect(submissions.submitted, hasLength(1));
    expect(submissions.submitted.first.name, 'Sto. Domingo ES');
    expect(submissions.submitted.first.location.lat, closeTo(14.7000, 1e-4));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  });
}
