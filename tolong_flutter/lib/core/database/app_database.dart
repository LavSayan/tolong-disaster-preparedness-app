import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// One pending change per record. Rows hold only *which* record changed, never its contents,
/// so no personal data sits in this (unencrypted) SQLite file; the encrypted vault stays the
/// source of truth and is read at push time.
@DataClassName('QueueEntry')
class SyncQueue extends Table {
  TextColumn get owner => text()();
  TextColumn get entity => text()();
  TextColumn get recordId => text()();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();

  /// When the user made the change on this device. Used for "newer change wins".
  DateTimeColumn get modifiedAt => dateTime()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get nextAttemptAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {owner, entity, recordId};
}

/// Last known change time of each local record (kept after the queue entry is pushed),
/// so a pull can tell whether the server copy is newer.
@DataClassName('RecordVersion')
class RecordVersions extends Table {
  TextColumn get owner => text()();
  TextColumn get entity => text()();
  TextColumn get recordId => text()();
  DateTimeColumn get modifiedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {owner, entity, recordId};
}

@DataClassName('SyncStateRow')
class SyncStates extends Table {
  TextColumn get owner => text()();
  DateTimeColumn get lastPulledServerAt => dateTime().nullable()();
  DateTimeColumn get lastSuccessAt => dateTime().nullable()();
  TextColumn get lastError => text().nullable()();

  @override
  Set<Column> get primaryKey => {owner};
}

@DriftDatabase(tables: [SyncQueue, RecordVersions, SyncStates])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// The on-device database file (Android/iOS). Not used on web.
  factory AppDatabase.open() => AppDatabase(driftDatabase(name: 'tolong'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(onCreate: (m) => m.createAll());
}
