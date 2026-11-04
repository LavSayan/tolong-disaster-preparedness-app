import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/shelter_submission.dart';
import 'shelter_submission_repository.dart';

/// The government reviewer's side of the pipeline: the pending queue and the decisions.
/// Every method calls the `review_submission` RPC, which re-validates and gates on the
/// server-side role, so the client can never promote itself.
abstract interface class ShelterReviewRepository {
  /// Pending submissions, oldest first (first-in-first-out for reviewers).
  Future<List<ShelterSubmission>> pendingQueue();

  /// Saves corrections on a pending submission without deciding.
  Future<void> applyEdit(String id, ShelterSubmissionDraft draft);

  /// Approves. Any non-null [edits] fields are corrected by the reviewer before the row
  /// is certified into `shelters`. The server validates the corrected data itself.
  Future<void> approve(String id, {ShelterSubmissionDraft? edits});

  /// Rejects, with a reason the submitter will see. Required by the server.
  Future<void> reject(String id, {required String reason});
}

class SupabaseShelterReviewRepository implements ShelterReviewRepository {
  Future<void> _review(String id, String action, {Object? edits, String? reason}) async {
    try {
      await Supabase.instance.client.rpc('review_submission', params: {
        'p_id': id,
        'p_action': action,
        'p_edits': edits,
        'p_rejection_reason': reason,
      });
    } on PostgrestException catch (e) {
      throw SubmissionFailure(_fault(e));
    } catch (e) {
      debugPrint('Review error: ${e.runtimeType}');
      throw const SubmissionFailure(SubmissionErrorCode.unknown);
    }
  }

  SubmissionErrorCode _fault(PostgrestException e) {
    if (e.code == '42501') return SubmissionErrorCode.notAuthenticated; // not a reviewer
    return SubmissionErrorCode.unknown;
  }

  @override
  Future<List<ShelterSubmission>> pendingQueue() async {
    try {
      final rows = await Supabase.instance.client
          .from('shelter_submissions')
          .select()
          .eq('status', 'pending')
          .order('created_at', ascending: true)
          .limit(200);
      return [for (final r in rows) shelterSubmissionFromJson(r as Map<String, Object?>)];
    } on PostgrestException catch (e) {
      throw SubmissionFailure(_fault(e));
    } catch (e) {
      debugPrint('Queue fetch error: ${e.runtimeType}');
      throw const SubmissionFailure(SubmissionErrorCode.unknown);
    }
  }

  @override
  Future<void> applyEdit(String id, ShelterSubmissionDraft draft) =>
      _review(id, 'edit', edits: shelterEditPayload(draft));

  @override
  Future<void> approve(String id, {ShelterSubmissionDraft? edits}) =>
      _review(id, 'approve', edits: edits == null ? null : shelterEditPayload(edits));

  @override
  Future<void> reject(String id, {required String reason}) =>
      _review(id, 'reject', reason: reason.trim());
}

class UnconfiguredShelterReviewRepository implements ShelterReviewRepository {
  static const _failure = SubmissionFailure(SubmissionErrorCode.notConfigured);

  @override
  Future<List<ShelterSubmission>> pendingQueue() async => throw _failure;

  @override
  Future<void> applyEdit(String id, ShelterSubmissionDraft draft) async => throw _failure;

  @override
  Future<void> approve(String id, {ShelterSubmissionDraft? edits}) async => throw _failure;

  @override
  Future<void> reject(String id, {required String reason}) async => throw _failure;
}

/// An account as the admin screen sees it.
class AdminAccount {
  const AdminAccount({required this.id, required this.email, required this.fullName, required this.role});

  final String id;
  final String? email;
  final String? fullName;
  final AppUserRole? role;
}

enum AdminErrorCode { notConfigured, notAdmin, network, unknown }

class AdminFailure implements Exception {
  const AdminFailure(this.code);

  final AdminErrorCode code;

  @override
  String toString() => 'AdminFailure($code)';
}

/// Admin account management: only admins list accounts and grant/revoke the
/// government role — the same gate the server's `set_role` / `admin_directory`
/// functions enforce.
abstract interface class AdminAccountRepository {
  Future<List<AdminAccount>> directory({String? emailQuery});
  Future<void> setRole(String userId, AppUserRole role);
}

class SupabaseAdminAccountRepository implements AdminAccountRepository {
  @override
  Future<List<AdminAccount>> directory({String? emailQuery}) async {
    try {
      final rows = await Supabase.instance.client
          .rpc('admin_directory', params: {'p_email_query': emailQuery?.trim() ?? ''});
      return [for (final r in rows) _account(r as Map<String, Object?>)];
    } on PostgrestException catch (e) {
      throw AdminFailure(e.code == '42501' ? AdminErrorCode.notAdmin : AdminErrorCode.unknown);
    } catch (e) {
      debugPrint('Directory error: ${e.runtimeType}');
      throw const AdminFailure(AdminErrorCode.unknown);
    }
  }

  @override
  Future<void> setRole(String userId, AppUserRole role) async {
    try {
      await Supabase.instance.client.rpc('set_role', params: {
        'p_target': userId,
        'p_role': role.name,
      });
    } on PostgrestException catch (e) {
      throw AdminFailure(e.code == '42501' ? AdminErrorCode.notAdmin : AdminErrorCode.unknown);
    } catch (e) {
      debugPrint('Set role error: ${e.runtimeType}');
      throw const AdminFailure(AdminErrorCode.unknown);
    }
  }

  AdminAccount _account(Map<String, Object?> j) => AdminAccount(
        id: j['id'] as String,
        email: j['email'] as String?,
        fullName: j['full_name'] as String?,
        role: appUserRoleFrom(j['role'] as String?),
      );
}

class UnconfiguredAdminAccountRepository implements AdminAccountRepository {
  static const _failure = AdminFailure(AdminErrorCode.notConfigured);

  @override
  Future<List<AdminAccount>> directory({String? emailQuery}) async => throw _failure;

  @override
  Future<void> setRole(String userId, AppUserRole role) async => throw _failure;
}

final shelterReviewRepositoryProvider = Provider<ShelterReviewRepository>(
  (ref) => Env.supabaseConfigured ? SupabaseShelterReviewRepository() : UnconfiguredShelterReviewRepository(),
);

final adminAccountRepositoryProvider = Provider<AdminAccountRepository>(
  (ref) => Env.supabaseConfigured ? SupabaseAdminAccountRepository() : UnconfiguredAdminAccountRepository(),
);
