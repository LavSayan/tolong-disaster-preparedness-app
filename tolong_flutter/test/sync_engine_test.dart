import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tolong_flutter/core/database/app_database.dart';
import 'package:tolong_flutter/core/storage/secure_vault.dart';
import 'package:tolong_flutter/features/household/data/household_repository.dart';
import 'package:tolong_flutter/features/household/domain/models.dart';
import 'package:tolong_flutter/features/prepare/data/checklist_repository.dart';
import 'package:tolong_flutter/features/supplies/data/supplies_repository.dart';
import 'package:tolong_flutter/features/supplies/domain/supplies.dart';
import 'package:tolong_flutter/features/sync/application/sync_engine.dart';
import 'package:tolong_flutter/features/sync/data/local_records.dart';
import 'package:tolong_flutter/features/sync/data/sync_remote.dart';
import 'package:tolong_flutter/features/sync/data/sync_store.dart';
import 'package:tolong_flutter/features/sync/domain/sync_types.dart';

import 'test_helpers.dart';

void main() {
  late AppDatabase db;
  late SyncStore store;
  late FakeSyncRemote remote;
  late HouseholdRepository household;
  late SuppliesRepository supplies;
  late SyncEngine engine;
  var now = DateTime.utc(2026, 10, 18, 9);
  const owner = 'user-1';
  const ana = EmergencyContact(id: 'c1', name: 'Ana', relationship: 'Sister', phone: '09171234567');

  setUp(() {
    now = DateTime.utc(2026, 10, 18, 9);
    db = AppDatabase(NativeDatabase.memory());
    store = SyncStore(db);
    remote = FakeSyncRemote();
    final vault = MemoryVault();
    household = HouseholdRepository(vault);
    supplies = SuppliesRepository(vault);
    engine = SyncEngine(
      store: store,
      remote: remote,
      local: LocalRecordSource(household: household, supplies: supplies, checklist: ChecklistRepository(vault)),
      clock: () => now,
    );
  });
  tearDown(() => db.close());

  test('pushes the current contents of changed records and empties the queue', () async {
    await household.saveContacts(owner, const [ana]);
    await store.enqueue(owner, SyncEntity.contact, 'c1', deleted: false, at: now);

    final result = await engine.run(owner);

    expect(result.pushed, 1);
    expect(remote.rows['contact/c1']!.data!['name'], 'Ana');
    expect(await store.pendingCount(owner), 0);
  });

  test('deletions go up as tombstones without contents', () async {
    await store.enqueue(owner, SyncEntity.supply, 's1', deleted: true, at: now);
    await engine.run(owner);
    expect(remote.rows['supply/s1']!.deleted, isTrue);
    expect(remote.rows['supply/s1']!.data, isNull);
  });

  test('a newer change from another device is merged into the encrypted vault', () async {
    remote.seed(RemoteRecord(
      entity: SyncEntity.supply,
      recordId: 's9',
      data: const InventoryItem(id: 's9', name: 'Water jug', category: SupplyCategory.water, quantity: 5, unit: SupplyUnit.gallons)
          .toJson(),
      deleted: false,
      clientModifiedAt: now.subtract(const Duration(hours: 1)),
    ));

    final result = await engine.run(owner);

    expect(result.applied, 1);
    expect((await supplies.load(owner)).single.name, 'Water jug');
  });

  test('an older server copy never overwrites a newer local edit', () async {
    await household.saveContacts(owner, const [ana]);
    await store.enqueue(owner, SyncEntity.contact, 'c1', deleted: false, at: now);
    await engine.run(owner);

    // Another device later pushes an edit it made *before* ours.
    remote.rows.remove('contact/c1');
    remote.seed(RemoteRecord(
      entity: SyncEntity.contact,
      recordId: 'c1',
      data: ana.toJson()..['name'] = 'Old name',
      deleted: false,
      clientModifiedAt: now.subtract(const Duration(minutes: 5)),
    ));
    now = now.add(const Duration(minutes: 1));
    final result = await engine.run(owner);

    expect(result.applied, 0);
    expect((await household.load(owner)).contacts.single.name, 'Ana');
  });

  test('a remote deletion removes the record locally', () async {
    await household.saveContacts(owner, const [ana]);
    remote.seed(RemoteRecord(
      entity: SyncEntity.contact,
      recordId: 'c1',
      data: null,
      deleted: true,
      clientModifiedAt: now,
    ));
    await engine.run(owner);
    expect((await household.load(owner)).contacts, isEmpty);
  });

  test('when the server is unreachable, changes stay queued and retry later', () async {
    await household.saveContacts(owner, const [ana]);
    await store.enqueue(owner, SyncEntity.contact, 'c1', deleted: false, at: now);
    remote.failNext = const SyncFailure('network');

    await expectLater(engine.run(owner), throwsA(isA<SyncFailure>()));
    expect(await store.pendingCount(owner), 1);
    expect((await store.state(owner))!.lastError, 'network');

    now = now.add(const Duration(minutes: 1));
    await engine.run(owner);
    expect(await store.pendingCount(owner), 0);
    expect((await store.state(owner))!.lastError, isNull);
  });

  test('the pull cursor advances so records are not downloaded twice', () async {
    remote.seed(RemoteRecord(
      entity: SyncEntity.household,
      recordId: owner,
      data: const HouseholdProfile(adults: 2).toJson(),
      deleted: false,
      clientModifiedAt: now,
    ));
    expect((await engine.run(owner)).pulled, 1);
    expect((await engine.run(owner)).pulled, 0);
  });
}
