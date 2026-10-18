import 'dart:math';

/// Kinds of records that sync to the account. Names are stored in the database and on the
/// server, so never rename them.
enum SyncEntity { profile, household, contact, supply, checklist }

/// A record as it travels to and from the server.
class RemoteRecord {
  const RemoteRecord({
    required this.entity,
    required this.recordId,
    required this.data,
    required this.deleted,
    required this.clientModifiedAt,
    this.serverUpdatedAt,
  });

  final SyncEntity entity;
  final String recordId;

  /// Record contents as JSON; null for deletions (tombstones).
  final Map<String, Object?>? data;
  final bool deleted;

  /// When the change was made on the device that made it.
  final DateTime clientModifiedAt;

  /// When the server stored it; used as the pull cursor.
  final DateTime? serverUpdatedAt;

  Map<String, Object?> toJson() => {
        'entity': entity.name,
        'record_id': recordId,
        'data': data,
        'deleted': deleted,
        'client_modified_at': clientModifiedAt.toUtc().toIso8601String(),
      };

  static RemoteRecord? fromJson(Map<String, Object?> j) {
    final entity = SyncEntity.values.asNameMap()[j['entity']];
    if (entity == null) return null;
    return RemoteRecord(
      entity: entity,
      recordId: j['record_id'] as String,
      data: (j['data'] as Map?)?.cast<String, Object?>(),
      deleted: j['deleted'] == true,
      clientModifiedAt: DateTime.parse(j['client_modified_at'] as String),
      serverUpdatedAt: j['server_updated_at'] == null ? null : DateTime.parse(j['server_updated_at'] as String),
    );
  }
}

/// Conflict rule ("newer change wins"), applied the same way on server and device:
/// a pulled record replaces the local one only if it was changed later than the local copy
/// and later than any local change still waiting to be pushed. Ties keep the local copy,
/// which is then pushed and settles the tie on the server.
bool shouldApplyRemote({required DateTime remote, DateTime? local, DateTime? pending}) {
  if (pending != null && !remote.isAfter(pending)) return false;
  if (local != null && !remote.isAfter(local)) return false;
  return true;
}

/// Retry delay after [attempts] failed pushes: 30 s, 1 min, 2 min … capped at 1 hour.
Duration retryDelay(int attempts) => Duration(seconds: min(30 * pow(2, max(0, attempts - 1)).toInt(), 3600));
