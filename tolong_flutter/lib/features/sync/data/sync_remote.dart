import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/sync_types.dart';

class SyncFailure implements Exception {
  const SyncFailure(this.code);

  /// 'network', 'auth' or 'server'.
  final String code;

  @override
  String toString() => 'SyncFailure($code)';
}

abstract interface class SyncRemote {
  /// Upserts records; the server keeps whichever copy has the later client change time.
  Future<void> push(List<RemoteRecord> records);

  /// Records the server stored after [since] (server time), oldest first.
  Future<List<RemoteRecord>> pull({DateTime? since});
}

/// Talks to the `sync_records` table (RLS: each user sees only their rows) and the
/// `sync_push` function from supabase/migrations/20261020000000_sync_records.sql.
class SupabaseSyncRemote implements SyncRemote {
  SupabaseClient get _db => Supabase.instance.client;

  @override
  Future<void> push(List<RemoteRecord> records) => _guard(() async {
        if (records.isEmpty) return;
        await _db.rpc('sync_push', params: {'records': [for (final r in records) r.toJson()]});
      });

  @override
  Future<List<RemoteRecord>> pull({DateTime? since}) => _guard(() async {
        var q = _db.from('sync_records').select('entity,record_id,data,deleted,client_modified_at,server_updated_at');
        if (since != null) q = q.gt('server_updated_at', since.toUtc().toIso8601String());
        final rows = await q.order('server_updated_at').limit(1000);
        return [
          for (final r in rows)
            if (RemoteRecord.fromJson(r) case final rec?) rec,
        ];
      });

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on AuthException {
      throw const SyncFailure('auth');
    } on PostgrestException catch (e) {
      debugPrint('Sync server error: ${e.code}');
      throw SyncFailure(e.code == 'PGRST301' || e.code == '42501' ? 'auth' : 'server');
    } catch (e) {
      debugPrint('Sync network error: ${e.runtimeType}');
      throw const SyncFailure('network');
    }
  }
}
