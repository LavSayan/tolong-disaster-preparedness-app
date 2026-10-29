import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/session.dart';
import '../data/evacuation_center_repository.dart';
import '../data/qc_area_repository.dart';
import '../data/shelter_review_repository.dart';
import '../data/shelter_submission_repository.dart';
import '../domain/shelter_submission.dart';

/// The signed-in user's own submissions, newest first. Invalidated after every
/// submit/edit/withdraw so status changes are visible on the next read.
final mySubmissionsProvider = FutureProvider<List<ShelterSubmission>>(
  (ref) => ref.watch(shelterSubmissionRepositoryProvider).mine(),
);

/// The government reviewer's pending queue. invalidated after every decision.
final pendingQueueProvider = FutureProvider<List<ShelterSubmission>>(
  (ref) => ref.watch(shelterReviewRepositoryProvider).pendingQueue(),
);

/// The submit flow: local validation first (fast, offline-safe), then the server, which
/// revalidates everything. Throws [SubmissionFailure] with a user-facing code.
class SubmitShelterService {
  SubmitShelterService(this._ref);

  final Ref _ref;

  SubmissionErrorCode? localChecks(ShelterSubmissionDraft draft) => validateShelterSubmission(
        draft,
        knownBarangays: _ref.read(barangaysProvider).value ?? const [],
        existingCenters: _ref.read(evacuationCentersProvider).value ?? const [],
      );

  /// The server also caps pending submissions at 5; checking the same rule here is
  /// what lets the app show a targeted message instead of a generic failure.
  Future<SubmissionErrorCode?> pendingCap() async {
    final mine = await _ref.read(mySubmissionsProvider.future).catchError((_) => const <ShelterSubmission>[]);
    return mine.where((s) => s.status == SubmissionStatus.pending).length >= 5
        ? SubmissionErrorCode.tooManyPending
        : null;
  }

  Future<void> submit(ShelterSubmissionDraft draft) async {
    final local = localChecks(draft);
    if (local != null) throw SubmissionFailure(local);
    final cap = await pendingCap();
    if (cap != null) throw SubmissionFailure(cap);
    final session = _ref.read(sessionProvider);
    if (!session.signedIn) throw const SubmissionFailure(SubmissionErrorCode.notAuthenticated);
    await _ref.read(shelterSubmissionRepositoryProvider).submit(draft);
  }

  Future<void> edit(String id, ShelterSubmissionDraft draft) async {
    final local = localChecks(draft);
    if (local != null) throw SubmissionFailure(local);
    await _ref.read(shelterSubmissionRepositoryProvider).edit(id, draft);
  }

  Future<void> withdraw(String id) => _ref.read(shelterSubmissionRepositoryProvider).withdraw(id);

  /// Reviewer actions: corrections are validated the same way before being sent.
  Future<void> applyEdit(String id, ShelterSubmissionDraft draft) async {
    final local = localChecks(draft);
    if (local != null) throw SubmissionFailure(local);
    await _ref.read(shelterReviewRepositoryProvider).applyEdit(id, draft);
  }

  Future<void> approve(String id, {ShelterSubmissionDraft? edits}) async {
    if (edits != null) {
      final local = localChecks(edits);
      if (local != null) throw SubmissionFailure(local);
    }
    await _ref.read(shelterReviewRepositoryProvider).approve(id, edits: edits);
  }

  Future<void> reject(String id, {required String reason}) => _ref
      .read(shelterReviewRepositoryProvider)
      .reject(id, reason: reason);
}

final submitShelterServiceProvider = Provider((ref) => SubmitShelterService(ref));
