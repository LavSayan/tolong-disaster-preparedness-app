import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/sync_types.dart';

/// Queue, record versions and sync bookkeeping, per owner (account id).
class SyncStore {
  SyncStore(this._db);

  final AppDatabase _db;

  /// Records a local change. A second change to the same record replaces the first
  /// (so the queue never holds duplicates) and resets its retry schedule.
  Future<void> enqueue(String owner, SyncEntity entity, String recordId, {required bool deleted, required DateTime at}) =>
      _db.transaction(() async {
        await _db.into(_db.syncQueue).insertOnConflictUpdate(SyncQueueCompanion.insert(
              owner: owner,
              entity: entity.name,
              recordId: recordId,
              deleted: Value(deleted),
              modifiedAt: at,
              attempts: const Value(0),
              lastError: const Value(null),
              nextAttemptAt: const Value(null),
            ));
        await setVersion(owner, entity, recordId, at);
      });

  /// Entries due now, oldest change first.
  Future<List<QueueEntry>> due(String owner, DateTime now) => (_db.select(_db.syncQueue)
        ..where((q) => q.owner.equals(owner) & (q.nextAttemptAt.isNull() | q.nextAttemptAt.isSmallerOrEqualValue(now)))
        ..orderBy([(q) => OrderingTerm.asc(q.modifiedAt)]))
      .get();

  Future<int> pendingCount(String owner) async {
    final c = _db.syncQueue.recordId.count();
    final row = await (_db.selectOnly(_db.syncQueue)
          ..addColumns([c])
          ..where(_db.syncQueue.owner.equals(owner)))
        .getSingle();
    return row.read(c) ?? 0;
  }

  Stream<int> watchPendingCount(String owner) {
    final c = _db.syncQueue.recordId.count();
    return (_db.selectOnly(_db.syncQueue)
          ..addColumns([c])
          ..where(_db.syncQueue.owner.equals(owner)))
        .watchSingle()
        .map((r) => r.read(c) ?? 0);
  }

  Future<QueueEntry?> pendingFor(String owner, SyncEntity entity, String recordId) => (_db.select(_db.syncQueue)
        ..where((q) => q.owner.equals(owner) & q.entity.equals(entity.name) & q.recordId.equals(recordId)))
      .getSingleOrNull();

  /// Removes an entry only if it wasn't changed again while it was being pushed.
  Future<void> markPushed(QueueEntry e) => (_db.delete(_db.syncQueue)
        ..where((q) =>
            q.owner.equals(e.owner) &
            q.entity.equals(e.entity) &
            q.recordId.equals(e.recordId) &
            q.modifiedAt.equals(e.modifiedAt)))
      .go();

  Future<void> markFailed(QueueEntry e, String error, DateTime now) => (_db.update(_db.syncQueue)
        ..where((q) =>
            q.owner.equals(e.owner) &
            q.entity.equals(e.entity) &
            q.recordId.equals(e.recordId) &
            q.modifiedAt.equals(e.modifiedAt)))
      .write(SyncQueueCompanion(
        attempts: Value(e.attempts + 1),
        lastError: Value(error),
        nextAttemptAt: Value(now.add(retryDelay(e.attempts + 1))),
      ));

  Future<DateTime?> version(String owner, SyncEntity entity, String recordId) async => (await (_db.select(
                  _db.recordVersions)
                ..where((v) => v.owner.equals(owner) & v.entity.equals(entity.name) & v.recordId.equals(recordId)))
              .getSingleOrNull())
          ?.modifiedAt;

  Future<void> setVersion(String owner, SyncEntity entity, String recordId, DateTime at) =>
      _db.into(_db.recordVersions).insertOnConflictUpdate(
            RecordVersionsCompanion.insert(owner: owner, entity: entity.name, recordId: recordId, modifiedAt: at),
          );

  Future<SyncStateRow?> state(String owner) =>
      (_db.select(_db.syncStates)..where((s) => s.owner.equals(owner))).getSingleOrNull();

  Future<void> saveState(String owner, {DateTime? pulledServerAt, DateTime? successAt, String? Function()? error}) async {
    final current = await state(owner);
    await _db.into(_db.syncStates).insertOnConflictUpdate(SyncStatesCompanion.insert(
          owner: owner,
          lastPulledServerAt: Value(pulledServerAt ?? current?.lastPulledServerAt),
          lastSuccessAt: Value(successAt ?? current?.lastSuccessAt),
          lastError: Value(error != null ? error() : current?.lastError),
        ));
  }

  /// Forgets everything for [owner] (account deletion or clearing local data).
  Future<void> clearOwner(String owner) => _db.transaction(() async {
        await (_db.delete(_db.syncQueue)..where((q) => q.owner.equals(owner))).go();
        await (_db.delete(_db.recordVersions)..where((v) => v.owner.equals(owner))).go();
        await (_db.delete(_db.syncStates)..where((s) => s.owner.equals(owner))).go();
      });
}
