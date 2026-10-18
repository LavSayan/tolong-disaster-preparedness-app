// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SyncQueueTable extends SyncQueue
    with TableInfo<$SyncQueueTable, QueueEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _ownerMeta = const VerificationMeta('owner');
  @override
  late final GeneratedColumn<String> owner = GeneratedColumn<String>(
      'owner', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _entityMeta = const VerificationMeta('entity');
  @override
  late final GeneratedColumn<String> entity = GeneratedColumn<String>(
      'entity', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _recordIdMeta =
      const VerificationMeta('recordId');
  @override
  late final GeneratedColumn<String> recordId = GeneratedColumn<String>(
      'record_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _deletedMeta =
      const VerificationMeta('deleted');
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
      'deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("deleted" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _modifiedAtMeta =
      const VerificationMeta('modifiedAt');
  @override
  late final GeneratedColumn<DateTime> modifiedAt = GeneratedColumn<DateTime>(
      'modified_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _attemptsMeta =
      const VerificationMeta('attempts');
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
      'attempts', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lastErrorMeta =
      const VerificationMeta('lastError');
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
      'last_error', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _nextAttemptAtMeta =
      const VerificationMeta('nextAttemptAt');
  @override
  late final GeneratedColumn<DateTime> nextAttemptAt =
      GeneratedColumn<DateTime>('next_attempt_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        owner,
        entity,
        recordId,
        deleted,
        modifiedAt,
        attempts,
        lastError,
        nextAttemptAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue';
  @override
  VerificationContext validateIntegrity(Insertable<QueueEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('owner')) {
      context.handle(
          _ownerMeta, owner.isAcceptableOrUnknown(data['owner']!, _ownerMeta));
    } else if (isInserting) {
      context.missing(_ownerMeta);
    }
    if (data.containsKey('entity')) {
      context.handle(_entityMeta,
          entity.isAcceptableOrUnknown(data['entity']!, _entityMeta));
    } else if (isInserting) {
      context.missing(_entityMeta);
    }
    if (data.containsKey('record_id')) {
      context.handle(_recordIdMeta,
          recordId.isAcceptableOrUnknown(data['record_id']!, _recordIdMeta));
    } else if (isInserting) {
      context.missing(_recordIdMeta);
    }
    if (data.containsKey('deleted')) {
      context.handle(_deletedMeta,
          deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta));
    }
    if (data.containsKey('modified_at')) {
      context.handle(
          _modifiedAtMeta,
          modifiedAt.isAcceptableOrUnknown(
              data['modified_at']!, _modifiedAtMeta));
    } else if (isInserting) {
      context.missing(_modifiedAtMeta);
    }
    if (data.containsKey('attempts')) {
      context.handle(_attemptsMeta,
          attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta));
    }
    if (data.containsKey('last_error')) {
      context.handle(_lastErrorMeta,
          lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta));
    }
    if (data.containsKey('next_attempt_at')) {
      context.handle(
          _nextAttemptAtMeta,
          nextAttemptAt.isAcceptableOrUnknown(
              data['next_attempt_at']!, _nextAttemptAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {owner, entity, recordId};
  @override
  QueueEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QueueEntry(
      owner: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}owner'])!,
      entity: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity'])!,
      recordId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}record_id'])!,
      deleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}deleted'])!,
      modifiedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}modified_at'])!,
      attempts: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}attempts'])!,
      lastError: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_error']),
      nextAttemptAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}next_attempt_at']),
    );
  }

  @override
  $SyncQueueTable createAlias(String alias) {
    return $SyncQueueTable(attachedDatabase, alias);
  }
}

class QueueEntry extends DataClass implements Insertable<QueueEntry> {
  final String owner;
  final String entity;
  final String recordId;
  final bool deleted;

  /// When the user made the change on this device. Used for "newer change wins".
  final DateTime modifiedAt;
  final int attempts;
  final String? lastError;
  final DateTime? nextAttemptAt;
  const QueueEntry(
      {required this.owner,
      required this.entity,
      required this.recordId,
      required this.deleted,
      required this.modifiedAt,
      required this.attempts,
      this.lastError,
      this.nextAttemptAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['owner'] = Variable<String>(owner);
    map['entity'] = Variable<String>(entity);
    map['record_id'] = Variable<String>(recordId);
    map['deleted'] = Variable<bool>(deleted);
    map['modified_at'] = Variable<DateTime>(modifiedAt);
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    if (!nullToAbsent || nextAttemptAt != null) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt);
    }
    return map;
  }

  SyncQueueCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueCompanion(
      owner: Value(owner),
      entity: Value(entity),
      recordId: Value(recordId),
      deleted: Value(deleted),
      modifiedAt: Value(modifiedAt),
      attempts: Value(attempts),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      nextAttemptAt: nextAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextAttemptAt),
    );
  }

  factory QueueEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QueueEntry(
      owner: serializer.fromJson<String>(json['owner']),
      entity: serializer.fromJson<String>(json['entity']),
      recordId: serializer.fromJson<String>(json['recordId']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      modifiedAt: serializer.fromJson<DateTime>(json['modifiedAt']),
      attempts: serializer.fromJson<int>(json['attempts']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      nextAttemptAt: serializer.fromJson<DateTime?>(json['nextAttemptAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'owner': serializer.toJson<String>(owner),
      'entity': serializer.toJson<String>(entity),
      'recordId': serializer.toJson<String>(recordId),
      'deleted': serializer.toJson<bool>(deleted),
      'modifiedAt': serializer.toJson<DateTime>(modifiedAt),
      'attempts': serializer.toJson<int>(attempts),
      'lastError': serializer.toJson<String?>(lastError),
      'nextAttemptAt': serializer.toJson<DateTime?>(nextAttemptAt),
    };
  }

  QueueEntry copyWith(
          {String? owner,
          String? entity,
          String? recordId,
          bool? deleted,
          DateTime? modifiedAt,
          int? attempts,
          Value<String?> lastError = const Value.absent(),
          Value<DateTime?> nextAttemptAt = const Value.absent()}) =>
      QueueEntry(
        owner: owner ?? this.owner,
        entity: entity ?? this.entity,
        recordId: recordId ?? this.recordId,
        deleted: deleted ?? this.deleted,
        modifiedAt: modifiedAt ?? this.modifiedAt,
        attempts: attempts ?? this.attempts,
        lastError: lastError.present ? lastError.value : this.lastError,
        nextAttemptAt:
            nextAttemptAt.present ? nextAttemptAt.value : this.nextAttemptAt,
      );
  QueueEntry copyWithCompanion(SyncQueueCompanion data) {
    return QueueEntry(
      owner: data.owner.present ? data.owner.value : this.owner,
      entity: data.entity.present ? data.entity.value : this.entity,
      recordId: data.recordId.present ? data.recordId.value : this.recordId,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      modifiedAt:
          data.modifiedAt.present ? data.modifiedAt.value : this.modifiedAt,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      nextAttemptAt: data.nextAttemptAt.present
          ? data.nextAttemptAt.value
          : this.nextAttemptAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QueueEntry(')
          ..write('owner: $owner, ')
          ..write('entity: $entity, ')
          ..write('recordId: $recordId, ')
          ..write('deleted: $deleted, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError, ')
          ..write('nextAttemptAt: $nextAttemptAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(owner, entity, recordId, deleted, modifiedAt,
      attempts, lastError, nextAttemptAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QueueEntry &&
          other.owner == this.owner &&
          other.entity == this.entity &&
          other.recordId == this.recordId &&
          other.deleted == this.deleted &&
          other.modifiedAt == this.modifiedAt &&
          other.attempts == this.attempts &&
          other.lastError == this.lastError &&
          other.nextAttemptAt == this.nextAttemptAt);
}

class SyncQueueCompanion extends UpdateCompanion<QueueEntry> {
  final Value<String> owner;
  final Value<String> entity;
  final Value<String> recordId;
  final Value<bool> deleted;
  final Value<DateTime> modifiedAt;
  final Value<int> attempts;
  final Value<String?> lastError;
  final Value<DateTime?> nextAttemptAt;
  final Value<int> rowid;
  const SyncQueueCompanion({
    this.owner = const Value.absent(),
    this.entity = const Value.absent(),
    this.recordId = const Value.absent(),
    this.deleted = const Value.absent(),
    this.modifiedAt = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncQueueCompanion.insert({
    required String owner,
    required String entity,
    required String recordId,
    this.deleted = const Value.absent(),
    required DateTime modifiedAt,
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : owner = Value(owner),
        entity = Value(entity),
        recordId = Value(recordId),
        modifiedAt = Value(modifiedAt);
  static Insertable<QueueEntry> custom({
    Expression<String>? owner,
    Expression<String>? entity,
    Expression<String>? recordId,
    Expression<bool>? deleted,
    Expression<DateTime>? modifiedAt,
    Expression<int>? attempts,
    Expression<String>? lastError,
    Expression<DateTime>? nextAttemptAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (owner != null) 'owner': owner,
      if (entity != null) 'entity': entity,
      if (recordId != null) 'record_id': recordId,
      if (deleted != null) 'deleted': deleted,
      if (modifiedAt != null) 'modified_at': modifiedAt,
      if (attempts != null) 'attempts': attempts,
      if (lastError != null) 'last_error': lastError,
      if (nextAttemptAt != null) 'next_attempt_at': nextAttemptAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncQueueCompanion copyWith(
      {Value<String>? owner,
      Value<String>? entity,
      Value<String>? recordId,
      Value<bool>? deleted,
      Value<DateTime>? modifiedAt,
      Value<int>? attempts,
      Value<String?>? lastError,
      Value<DateTime?>? nextAttemptAt,
      Value<int>? rowid}) {
    return SyncQueueCompanion(
      owner: owner ?? this.owner,
      entity: entity ?? this.entity,
      recordId: recordId ?? this.recordId,
      deleted: deleted ?? this.deleted,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      attempts: attempts ?? this.attempts,
      lastError: lastError ?? this.lastError,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (owner.present) {
      map['owner'] = Variable<String>(owner.value);
    }
    if (entity.present) {
      map['entity'] = Variable<String>(entity.value);
    }
    if (recordId.present) {
      map['record_id'] = Variable<String>(recordId.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (modifiedAt.present) {
      map['modified_at'] = Variable<DateTime>(modifiedAt.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (nextAttemptAt.present) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueCompanion(')
          ..write('owner: $owner, ')
          ..write('entity: $entity, ')
          ..write('recordId: $recordId, ')
          ..write('deleted: $deleted, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RecordVersionsTable extends RecordVersions
    with TableInfo<$RecordVersionsTable, RecordVersion> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecordVersionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _ownerMeta = const VerificationMeta('owner');
  @override
  late final GeneratedColumn<String> owner = GeneratedColumn<String>(
      'owner', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _entityMeta = const VerificationMeta('entity');
  @override
  late final GeneratedColumn<String> entity = GeneratedColumn<String>(
      'entity', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _recordIdMeta =
      const VerificationMeta('recordId');
  @override
  late final GeneratedColumn<String> recordId = GeneratedColumn<String>(
      'record_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _modifiedAtMeta =
      const VerificationMeta('modifiedAt');
  @override
  late final GeneratedColumn<DateTime> modifiedAt = GeneratedColumn<DateTime>(
      'modified_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [owner, entity, recordId, modifiedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'record_versions';
  @override
  VerificationContext validateIntegrity(Insertable<RecordVersion> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('owner')) {
      context.handle(
          _ownerMeta, owner.isAcceptableOrUnknown(data['owner']!, _ownerMeta));
    } else if (isInserting) {
      context.missing(_ownerMeta);
    }
    if (data.containsKey('entity')) {
      context.handle(_entityMeta,
          entity.isAcceptableOrUnknown(data['entity']!, _entityMeta));
    } else if (isInserting) {
      context.missing(_entityMeta);
    }
    if (data.containsKey('record_id')) {
      context.handle(_recordIdMeta,
          recordId.isAcceptableOrUnknown(data['record_id']!, _recordIdMeta));
    } else if (isInserting) {
      context.missing(_recordIdMeta);
    }
    if (data.containsKey('modified_at')) {
      context.handle(
          _modifiedAtMeta,
          modifiedAt.isAcceptableOrUnknown(
              data['modified_at']!, _modifiedAtMeta));
    } else if (isInserting) {
      context.missing(_modifiedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {owner, entity, recordId};
  @override
  RecordVersion map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecordVersion(
      owner: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}owner'])!,
      entity: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity'])!,
      recordId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}record_id'])!,
      modifiedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}modified_at'])!,
    );
  }

  @override
  $RecordVersionsTable createAlias(String alias) {
    return $RecordVersionsTable(attachedDatabase, alias);
  }
}

class RecordVersion extends DataClass implements Insertable<RecordVersion> {
  final String owner;
  final String entity;
  final String recordId;
  final DateTime modifiedAt;
  const RecordVersion(
      {required this.owner,
      required this.entity,
      required this.recordId,
      required this.modifiedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['owner'] = Variable<String>(owner);
    map['entity'] = Variable<String>(entity);
    map['record_id'] = Variable<String>(recordId);
    map['modified_at'] = Variable<DateTime>(modifiedAt);
    return map;
  }

  RecordVersionsCompanion toCompanion(bool nullToAbsent) {
    return RecordVersionsCompanion(
      owner: Value(owner),
      entity: Value(entity),
      recordId: Value(recordId),
      modifiedAt: Value(modifiedAt),
    );
  }

  factory RecordVersion.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecordVersion(
      owner: serializer.fromJson<String>(json['owner']),
      entity: serializer.fromJson<String>(json['entity']),
      recordId: serializer.fromJson<String>(json['recordId']),
      modifiedAt: serializer.fromJson<DateTime>(json['modifiedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'owner': serializer.toJson<String>(owner),
      'entity': serializer.toJson<String>(entity),
      'recordId': serializer.toJson<String>(recordId),
      'modifiedAt': serializer.toJson<DateTime>(modifiedAt),
    };
  }

  RecordVersion copyWith(
          {String? owner,
          String? entity,
          String? recordId,
          DateTime? modifiedAt}) =>
      RecordVersion(
        owner: owner ?? this.owner,
        entity: entity ?? this.entity,
        recordId: recordId ?? this.recordId,
        modifiedAt: modifiedAt ?? this.modifiedAt,
      );
  RecordVersion copyWithCompanion(RecordVersionsCompanion data) {
    return RecordVersion(
      owner: data.owner.present ? data.owner.value : this.owner,
      entity: data.entity.present ? data.entity.value : this.entity,
      recordId: data.recordId.present ? data.recordId.value : this.recordId,
      modifiedAt:
          data.modifiedAt.present ? data.modifiedAt.value : this.modifiedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecordVersion(')
          ..write('owner: $owner, ')
          ..write('entity: $entity, ')
          ..write('recordId: $recordId, ')
          ..write('modifiedAt: $modifiedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(owner, entity, recordId, modifiedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecordVersion &&
          other.owner == this.owner &&
          other.entity == this.entity &&
          other.recordId == this.recordId &&
          other.modifiedAt == this.modifiedAt);
}

class RecordVersionsCompanion extends UpdateCompanion<RecordVersion> {
  final Value<String> owner;
  final Value<String> entity;
  final Value<String> recordId;
  final Value<DateTime> modifiedAt;
  final Value<int> rowid;
  const RecordVersionsCompanion({
    this.owner = const Value.absent(),
    this.entity = const Value.absent(),
    this.recordId = const Value.absent(),
    this.modifiedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecordVersionsCompanion.insert({
    required String owner,
    required String entity,
    required String recordId,
    required DateTime modifiedAt,
    this.rowid = const Value.absent(),
  })  : owner = Value(owner),
        entity = Value(entity),
        recordId = Value(recordId),
        modifiedAt = Value(modifiedAt);
  static Insertable<RecordVersion> custom({
    Expression<String>? owner,
    Expression<String>? entity,
    Expression<String>? recordId,
    Expression<DateTime>? modifiedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (owner != null) 'owner': owner,
      if (entity != null) 'entity': entity,
      if (recordId != null) 'record_id': recordId,
      if (modifiedAt != null) 'modified_at': modifiedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecordVersionsCompanion copyWith(
      {Value<String>? owner,
      Value<String>? entity,
      Value<String>? recordId,
      Value<DateTime>? modifiedAt,
      Value<int>? rowid}) {
    return RecordVersionsCompanion(
      owner: owner ?? this.owner,
      entity: entity ?? this.entity,
      recordId: recordId ?? this.recordId,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (owner.present) {
      map['owner'] = Variable<String>(owner.value);
    }
    if (entity.present) {
      map['entity'] = Variable<String>(entity.value);
    }
    if (recordId.present) {
      map['record_id'] = Variable<String>(recordId.value);
    }
    if (modifiedAt.present) {
      map['modified_at'] = Variable<DateTime>(modifiedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecordVersionsCompanion(')
          ..write('owner: $owner, ')
          ..write('entity: $entity, ')
          ..write('recordId: $recordId, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncStatesTable extends SyncStates
    with TableInfo<$SyncStatesTable, SyncStateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _ownerMeta = const VerificationMeta('owner');
  @override
  late final GeneratedColumn<String> owner = GeneratedColumn<String>(
      'owner', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _lastPulledServerAtMeta =
      const VerificationMeta('lastPulledServerAt');
  @override
  late final GeneratedColumn<DateTime> lastPulledServerAt =
      GeneratedColumn<DateTime>('last_pulled_server_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _lastSuccessAtMeta =
      const VerificationMeta('lastSuccessAt');
  @override
  late final GeneratedColumn<DateTime> lastSuccessAt =
      GeneratedColumn<DateTime>('last_success_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _lastErrorMeta =
      const VerificationMeta('lastError');
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
      'last_error', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [owner, lastPulledServerAt, lastSuccessAt, lastError];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_states';
  @override
  VerificationContext validateIntegrity(Insertable<SyncStateRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('owner')) {
      context.handle(
          _ownerMeta, owner.isAcceptableOrUnknown(data['owner']!, _ownerMeta));
    } else if (isInserting) {
      context.missing(_ownerMeta);
    }
    if (data.containsKey('last_pulled_server_at')) {
      context.handle(
          _lastPulledServerAtMeta,
          lastPulledServerAt.isAcceptableOrUnknown(
              data['last_pulled_server_at']!, _lastPulledServerAtMeta));
    }
    if (data.containsKey('last_success_at')) {
      context.handle(
          _lastSuccessAtMeta,
          lastSuccessAt.isAcceptableOrUnknown(
              data['last_success_at']!, _lastSuccessAtMeta));
    }
    if (data.containsKey('last_error')) {
      context.handle(_lastErrorMeta,
          lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {owner};
  @override
  SyncStateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncStateRow(
      owner: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}owner'])!,
      lastPulledServerAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}last_pulled_server_at']),
      lastSuccessAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_success_at']),
      lastError: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_error']),
    );
  }

  @override
  $SyncStatesTable createAlias(String alias) {
    return $SyncStatesTable(attachedDatabase, alias);
  }
}

class SyncStateRow extends DataClass implements Insertable<SyncStateRow> {
  final String owner;
  final DateTime? lastPulledServerAt;
  final DateTime? lastSuccessAt;
  final String? lastError;
  const SyncStateRow(
      {required this.owner,
      this.lastPulledServerAt,
      this.lastSuccessAt,
      this.lastError});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['owner'] = Variable<String>(owner);
    if (!nullToAbsent || lastPulledServerAt != null) {
      map['last_pulled_server_at'] = Variable<DateTime>(lastPulledServerAt);
    }
    if (!nullToAbsent || lastSuccessAt != null) {
      map['last_success_at'] = Variable<DateTime>(lastSuccessAt);
    }
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    return map;
  }

  SyncStatesCompanion toCompanion(bool nullToAbsent) {
    return SyncStatesCompanion(
      owner: Value(owner),
      lastPulledServerAt: lastPulledServerAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPulledServerAt),
      lastSuccessAt: lastSuccessAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSuccessAt),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
    );
  }

  factory SyncStateRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncStateRow(
      owner: serializer.fromJson<String>(json['owner']),
      lastPulledServerAt:
          serializer.fromJson<DateTime?>(json['lastPulledServerAt']),
      lastSuccessAt: serializer.fromJson<DateTime?>(json['lastSuccessAt']),
      lastError: serializer.fromJson<String?>(json['lastError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'owner': serializer.toJson<String>(owner),
      'lastPulledServerAt': serializer.toJson<DateTime?>(lastPulledServerAt),
      'lastSuccessAt': serializer.toJson<DateTime?>(lastSuccessAt),
      'lastError': serializer.toJson<String?>(lastError),
    };
  }

  SyncStateRow copyWith(
          {String? owner,
          Value<DateTime?> lastPulledServerAt = const Value.absent(),
          Value<DateTime?> lastSuccessAt = const Value.absent(),
          Value<String?> lastError = const Value.absent()}) =>
      SyncStateRow(
        owner: owner ?? this.owner,
        lastPulledServerAt: lastPulledServerAt.present
            ? lastPulledServerAt.value
            : this.lastPulledServerAt,
        lastSuccessAt:
            lastSuccessAt.present ? lastSuccessAt.value : this.lastSuccessAt,
        lastError: lastError.present ? lastError.value : this.lastError,
      );
  SyncStateRow copyWithCompanion(SyncStatesCompanion data) {
    return SyncStateRow(
      owner: data.owner.present ? data.owner.value : this.owner,
      lastPulledServerAt: data.lastPulledServerAt.present
          ? data.lastPulledServerAt.value
          : this.lastPulledServerAt,
      lastSuccessAt: data.lastSuccessAt.present
          ? data.lastSuccessAt.value
          : this.lastSuccessAt,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateRow(')
          ..write('owner: $owner, ')
          ..write('lastPulledServerAt: $lastPulledServerAt, ')
          ..write('lastSuccessAt: $lastSuccessAt, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(owner, lastPulledServerAt, lastSuccessAt, lastError);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncStateRow &&
          other.owner == this.owner &&
          other.lastPulledServerAt == this.lastPulledServerAt &&
          other.lastSuccessAt == this.lastSuccessAt &&
          other.lastError == this.lastError);
}

class SyncStatesCompanion extends UpdateCompanion<SyncStateRow> {
  final Value<String> owner;
  final Value<DateTime?> lastPulledServerAt;
  final Value<DateTime?> lastSuccessAt;
  final Value<String?> lastError;
  final Value<int> rowid;
  const SyncStatesCompanion({
    this.owner = const Value.absent(),
    this.lastPulledServerAt = const Value.absent(),
    this.lastSuccessAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncStatesCompanion.insert({
    required String owner,
    this.lastPulledServerAt = const Value.absent(),
    this.lastSuccessAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : owner = Value(owner);
  static Insertable<SyncStateRow> custom({
    Expression<String>? owner,
    Expression<DateTime>? lastPulledServerAt,
    Expression<DateTime>? lastSuccessAt,
    Expression<String>? lastError,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (owner != null) 'owner': owner,
      if (lastPulledServerAt != null)
        'last_pulled_server_at': lastPulledServerAt,
      if (lastSuccessAt != null) 'last_success_at': lastSuccessAt,
      if (lastError != null) 'last_error': lastError,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncStatesCompanion copyWith(
      {Value<String>? owner,
      Value<DateTime?>? lastPulledServerAt,
      Value<DateTime?>? lastSuccessAt,
      Value<String?>? lastError,
      Value<int>? rowid}) {
    return SyncStatesCompanion(
      owner: owner ?? this.owner,
      lastPulledServerAt: lastPulledServerAt ?? this.lastPulledServerAt,
      lastSuccessAt: lastSuccessAt ?? this.lastSuccessAt,
      lastError: lastError ?? this.lastError,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (owner.present) {
      map['owner'] = Variable<String>(owner.value);
    }
    if (lastPulledServerAt.present) {
      map['last_pulled_server_at'] =
          Variable<DateTime>(lastPulledServerAt.value);
    }
    if (lastSuccessAt.present) {
      map['last_success_at'] = Variable<DateTime>(lastSuccessAt.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncStatesCompanion(')
          ..write('owner: $owner, ')
          ..write('lastPulledServerAt: $lastPulledServerAt, ')
          ..write('lastSuccessAt: $lastSuccessAt, ')
          ..write('lastError: $lastError, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SyncQueueTable syncQueue = $SyncQueueTable(this);
  late final $RecordVersionsTable recordVersions = $RecordVersionsTable(this);
  late final $SyncStatesTable syncStates = $SyncStatesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [syncQueue, recordVersions, syncStates];
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$SyncQueueTableCreateCompanionBuilder = SyncQueueCompanion Function({
  required String owner,
  required String entity,
  required String recordId,
  Value<bool> deleted,
  required DateTime modifiedAt,
  Value<int> attempts,
  Value<String?> lastError,
  Value<DateTime?> nextAttemptAt,
  Value<int> rowid,
});
typedef $$SyncQueueTableUpdateCompanionBuilder = SyncQueueCompanion Function({
  Value<String> owner,
  Value<String> entity,
  Value<String> recordId,
  Value<bool> deleted,
  Value<DateTime> modifiedAt,
  Value<int> attempts,
  Value<String?> lastError,
  Value<DateTime?> nextAttemptAt,
  Value<int> rowid,
});

class $$SyncQueueTableFilterComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get owner => $composableBuilder(
      column: $table.owner, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entity => $composableBuilder(
      column: $table.entity, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get recordId => $composableBuilder(
      column: $table.recordId, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get deleted => $composableBuilder(
      column: $table.deleted, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get modifiedAt => $composableBuilder(
      column: $table.modifiedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get attempts => $composableBuilder(
      column: $table.attempts, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastError => $composableBuilder(
      column: $table.lastError, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get nextAttemptAt => $composableBuilder(
      column: $table.nextAttemptAt, builder: (column) => ColumnFilters(column));
}

class $$SyncQueueTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get owner => $composableBuilder(
      column: $table.owner, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entity => $composableBuilder(
      column: $table.entity, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get recordId => $composableBuilder(
      column: $table.recordId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get deleted => $composableBuilder(
      column: $table.deleted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get modifiedAt => $composableBuilder(
      column: $table.modifiedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get attempts => $composableBuilder(
      column: $table.attempts, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastError => $composableBuilder(
      column: $table.lastError, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get nextAttemptAt => $composableBuilder(
      column: $table.nextAttemptAt,
      builder: (column) => ColumnOrderings(column));
}

class $$SyncQueueTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get owner =>
      $composableBuilder(column: $table.owner, builder: (column) => column);

  GeneratedColumn<String> get entity =>
      $composableBuilder(column: $table.entity, builder: (column) => column);

  GeneratedColumn<String> get recordId =>
      $composableBuilder(column: $table.recordId, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<DateTime> get modifiedAt => $composableBuilder(
      column: $table.modifiedAt, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<DateTime> get nextAttemptAt => $composableBuilder(
      column: $table.nextAttemptAt, builder: (column) => column);
}

class $$SyncQueueTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SyncQueueTable,
    QueueEntry,
    $$SyncQueueTableFilterComposer,
    $$SyncQueueTableOrderingComposer,
    $$SyncQueueTableAnnotationComposer,
    $$SyncQueueTableCreateCompanionBuilder,
    $$SyncQueueTableUpdateCompanionBuilder,
    (QueueEntry, BaseReferences<_$AppDatabase, $SyncQueueTable, QueueEntry>),
    QueueEntry,
    PrefetchHooks Function()> {
  $$SyncQueueTableTableManager(_$AppDatabase db, $SyncQueueTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncQueueTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> owner = const Value.absent(),
            Value<String> entity = const Value.absent(),
            Value<String> recordId = const Value.absent(),
            Value<bool> deleted = const Value.absent(),
            Value<DateTime> modifiedAt = const Value.absent(),
            Value<int> attempts = const Value.absent(),
            Value<String?> lastError = const Value.absent(),
            Value<DateTime?> nextAttemptAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncQueueCompanion(
            owner: owner,
            entity: entity,
            recordId: recordId,
            deleted: deleted,
            modifiedAt: modifiedAt,
            attempts: attempts,
            lastError: lastError,
            nextAttemptAt: nextAttemptAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String owner,
            required String entity,
            required String recordId,
            Value<bool> deleted = const Value.absent(),
            required DateTime modifiedAt,
            Value<int> attempts = const Value.absent(),
            Value<String?> lastError = const Value.absent(),
            Value<DateTime?> nextAttemptAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncQueueCompanion.insert(
            owner: owner,
            entity: entity,
            recordId: recordId,
            deleted: deleted,
            modifiedAt: modifiedAt,
            attempts: attempts,
            lastError: lastError,
            nextAttemptAt: nextAttemptAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$SyncQueueTable, QueueEntry>(table),
                    BaseReferences<_$AppDatabase, $SyncQueueTable, QueueEntry>(
                        db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SyncQueueTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SyncQueueTable,
    QueueEntry,
    $$SyncQueueTableFilterComposer,
    $$SyncQueueTableOrderingComposer,
    $$SyncQueueTableAnnotationComposer,
    $$SyncQueueTableCreateCompanionBuilder,
    $$SyncQueueTableUpdateCompanionBuilder,
    (QueueEntry, BaseReferences<_$AppDatabase, $SyncQueueTable, QueueEntry>),
    QueueEntry,
    PrefetchHooks Function()>;
typedef $$RecordVersionsTableCreateCompanionBuilder = RecordVersionsCompanion
    Function({
  required String owner,
  required String entity,
  required String recordId,
  required DateTime modifiedAt,
  Value<int> rowid,
});
typedef $$RecordVersionsTableUpdateCompanionBuilder = RecordVersionsCompanion
    Function({
  Value<String> owner,
  Value<String> entity,
  Value<String> recordId,
  Value<DateTime> modifiedAt,
  Value<int> rowid,
});

class $$RecordVersionsTableFilterComposer
    extends Composer<_$AppDatabase, $RecordVersionsTable> {
  $$RecordVersionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get owner => $composableBuilder(
      column: $table.owner, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entity => $composableBuilder(
      column: $table.entity, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get recordId => $composableBuilder(
      column: $table.recordId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get modifiedAt => $composableBuilder(
      column: $table.modifiedAt, builder: (column) => ColumnFilters(column));
}

class $$RecordVersionsTableOrderingComposer
    extends Composer<_$AppDatabase, $RecordVersionsTable> {
  $$RecordVersionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get owner => $composableBuilder(
      column: $table.owner, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entity => $composableBuilder(
      column: $table.entity, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get recordId => $composableBuilder(
      column: $table.recordId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get modifiedAt => $composableBuilder(
      column: $table.modifiedAt, builder: (column) => ColumnOrderings(column));
}

class $$RecordVersionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecordVersionsTable> {
  $$RecordVersionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get owner =>
      $composableBuilder(column: $table.owner, builder: (column) => column);

  GeneratedColumn<String> get entity =>
      $composableBuilder(column: $table.entity, builder: (column) => column);

  GeneratedColumn<String> get recordId =>
      $composableBuilder(column: $table.recordId, builder: (column) => column);

  GeneratedColumn<DateTime> get modifiedAt => $composableBuilder(
      column: $table.modifiedAt, builder: (column) => column);
}

class $$RecordVersionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RecordVersionsTable,
    RecordVersion,
    $$RecordVersionsTableFilterComposer,
    $$RecordVersionsTableOrderingComposer,
    $$RecordVersionsTableAnnotationComposer,
    $$RecordVersionsTableCreateCompanionBuilder,
    $$RecordVersionsTableUpdateCompanionBuilder,
    (
      RecordVersion,
      BaseReferences<_$AppDatabase, $RecordVersionsTable, RecordVersion>
    ),
    RecordVersion,
    PrefetchHooks Function()> {
  $$RecordVersionsTableTableManager(
      _$AppDatabase db, $RecordVersionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecordVersionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecordVersionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecordVersionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> owner = const Value.absent(),
            Value<String> entity = const Value.absent(),
            Value<String> recordId = const Value.absent(),
            Value<DateTime> modifiedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RecordVersionsCompanion(
            owner: owner,
            entity: entity,
            recordId: recordId,
            modifiedAt: modifiedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String owner,
            required String entity,
            required String recordId,
            required DateTime modifiedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              RecordVersionsCompanion.insert(
            owner: owner,
            entity: entity,
            recordId: recordId,
            modifiedAt: modifiedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$RecordVersionsTable, RecordVersion>(table),
                    BaseReferences<_$AppDatabase, $RecordVersionsTable,
                        RecordVersion>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$RecordVersionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $RecordVersionsTable,
    RecordVersion,
    $$RecordVersionsTableFilterComposer,
    $$RecordVersionsTableOrderingComposer,
    $$RecordVersionsTableAnnotationComposer,
    $$RecordVersionsTableCreateCompanionBuilder,
    $$RecordVersionsTableUpdateCompanionBuilder,
    (
      RecordVersion,
      BaseReferences<_$AppDatabase, $RecordVersionsTable, RecordVersion>
    ),
    RecordVersion,
    PrefetchHooks Function()>;
typedef $$SyncStatesTableCreateCompanionBuilder = SyncStatesCompanion Function({
  required String owner,
  Value<DateTime?> lastPulledServerAt,
  Value<DateTime?> lastSuccessAt,
  Value<String?> lastError,
  Value<int> rowid,
});
typedef $$SyncStatesTableUpdateCompanionBuilder = SyncStatesCompanion Function({
  Value<String> owner,
  Value<DateTime?> lastPulledServerAt,
  Value<DateTime?> lastSuccessAt,
  Value<String?> lastError,
  Value<int> rowid,
});

class $$SyncStatesTableFilterComposer
    extends Composer<_$AppDatabase, $SyncStatesTable> {
  $$SyncStatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get owner => $composableBuilder(
      column: $table.owner, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastPulledServerAt => $composableBuilder(
      column: $table.lastPulledServerAt,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastSuccessAt => $composableBuilder(
      column: $table.lastSuccessAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastError => $composableBuilder(
      column: $table.lastError, builder: (column) => ColumnFilters(column));
}

class $$SyncStatesTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncStatesTable> {
  $$SyncStatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get owner => $composableBuilder(
      column: $table.owner, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastPulledServerAt => $composableBuilder(
      column: $table.lastPulledServerAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastSuccessAt => $composableBuilder(
      column: $table.lastSuccessAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastError => $composableBuilder(
      column: $table.lastError, builder: (column) => ColumnOrderings(column));
}

class $$SyncStatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncStatesTable> {
  $$SyncStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get owner =>
      $composableBuilder(column: $table.owner, builder: (column) => column);

  GeneratedColumn<DateTime> get lastPulledServerAt => $composableBuilder(
      column: $table.lastPulledServerAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSuccessAt => $composableBuilder(
      column: $table.lastSuccessAt, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);
}

class $$SyncStatesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SyncStatesTable,
    SyncStateRow,
    $$SyncStatesTableFilterComposer,
    $$SyncStatesTableOrderingComposer,
    $$SyncStatesTableAnnotationComposer,
    $$SyncStatesTableCreateCompanionBuilder,
    $$SyncStatesTableUpdateCompanionBuilder,
    (
      SyncStateRow,
      BaseReferences<_$AppDatabase, $SyncStatesTable, SyncStateRow>
    ),
    SyncStateRow,
    PrefetchHooks Function()> {
  $$SyncStatesTableTableManager(_$AppDatabase db, $SyncStatesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncStatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncStatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncStatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> owner = const Value.absent(),
            Value<DateTime?> lastPulledServerAt = const Value.absent(),
            Value<DateTime?> lastSuccessAt = const Value.absent(),
            Value<String?> lastError = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncStatesCompanion(
            owner: owner,
            lastPulledServerAt: lastPulledServerAt,
            lastSuccessAt: lastSuccessAt,
            lastError: lastError,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String owner,
            Value<DateTime?> lastPulledServerAt = const Value.absent(),
            Value<DateTime?> lastSuccessAt = const Value.absent(),
            Value<String?> lastError = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncStatesCompanion.insert(
            owner: owner,
            lastPulledServerAt: lastPulledServerAt,
            lastSuccessAt: lastSuccessAt,
            lastError: lastError,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$SyncStatesTable, SyncStateRow>(table),
                    BaseReferences<_$AppDatabase, $SyncStatesTable,
                        SyncStateRow>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SyncStatesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SyncStatesTable,
    SyncStateRow,
    $$SyncStatesTableFilterComposer,
    $$SyncStatesTableOrderingComposer,
    $$SyncStatesTableAnnotationComposer,
    $$SyncStatesTableCreateCompanionBuilder,
    $$SyncStatesTableUpdateCompanionBuilder,
    (
      SyncStateRow,
      BaseReferences<_$AppDatabase, $SyncStatesTable, SyncStateRow>
    ),
    SyncStateRow,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SyncQueueTableTableManager get syncQueue =>
      $$SyncQueueTableTableManager(_db, _db.syncQueue);
  $$RecordVersionsTableTableManager get recordVersions =>
      $$RecordVersionsTableTableManager(_db, _db.recordVersions);
  $$SyncStatesTableTableManager get syncStates =>
      $$SyncStatesTableTableManager(_db, _db.syncStates);
}
