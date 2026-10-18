import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tolong_flutter/core/database/app_database.dart';
import 'package:tolong_flutter/features/sync/data/sync_store.dart';
import 'package:tolong_flutter/features/sync/domain/sync_types.dart';

void main() {
  late AppDatabase db;
  late SyncStore store;
  final t0 = DateTime.utc(2026, 10, 18, 9);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    store = SyncStore(db);
  });
  tearDown(() => db.close());

  test('repeated changes to one record coalesce into a single queue entry', () async {
    await store.enqueue('u1', SyncEntity.contact, 'c1', deleted: false, at: t0);
    await store.enqueue('u1', SyncEntity.contact, 'c1', deleted: true, at: t0.add(const Duration(minutes: 1)));
    await store.enqueue('u1', SyncEntity.supply, 's1', deleted: false, at: t0);
    expect(await store.pendingCount('u1'), 2);
    final c1 = await store.pendingFor('u1', SyncEntity.contact, 'c1');
    expect(c1!.deleted, isTrue);
    expect((await store.version('u1', SyncEntity.contact, 'c1'))!.isAtSameMomentAs(t0.add(const Duration(minutes: 1))), isTrue);
    expect(await store.pendingCount('other'), 0);
  });

  test('a push only clears the entry if it was not changed again meanwhile', () async {
    await store.enqueue('u1', SyncEntity.household, 'u1', deleted: false, at: t0);
    final pushed = (await store.due('u1', t0)).single;
    await store.enqueue('u1', SyncEntity.household, 'u1', deleted: false, at: t0.add(const Duration(seconds: 5)));
    await store.markPushed(pushed);
    expect(await store.pendingCount('u1'), 1, reason: 'the newer edit still needs pushing');
  });

  test('failed pushes back off and are retried later', () async {
    await store.enqueue('u1', SyncEntity.checklist, 'u1', deleted: false, at: t0);
    final e = (await store.due('u1', t0)).single;
    await store.markFailed(e, 'network', t0);
    expect(await store.due('u1', t0.add(const Duration(seconds: 10))), isEmpty);
    expect(await store.due('u1', t0.add(const Duration(seconds: 31))), hasLength(1));
  });

  test('state and clearing per owner', () async {
    await store.saveState('u1', successAt: t0, pulledServerAt: t0);
    expect((await store.state('u1'))!.lastSuccessAt!.isAtSameMomentAs(t0), isTrue);
    await store.enqueue('u1', SyncEntity.profile, 'u1', deleted: false, at: t0);
    await store.clearOwner('u1');
    expect(await store.pendingCount('u1'), 0);
    expect(await store.state('u1'), isNull);
  });

  test('conflict rule: newer change wins, ties keep the local copy', () {
    final local = t0;
    expect(shouldApplyRemote(remote: t0.add(const Duration(seconds: 1)), local: local), isTrue);
    expect(shouldApplyRemote(remote: t0, local: local), isFalse);
    expect(shouldApplyRemote(remote: t0.subtract(const Duration(minutes: 1)), local: local), isFalse);
    expect(shouldApplyRemote(remote: t0.add(const Duration(minutes: 1)), pending: t0.add(const Duration(minutes: 2))), isFalse);
    expect(shouldApplyRemote(remote: t0), isTrue, reason: 'nothing local yet');
  });

  test('retry delay doubles and caps at one hour', () {
    expect(retryDelay(1), const Duration(seconds: 30));
    expect(retryDelay(2), const Duration(minutes: 1));
    expect(retryDelay(4), const Duration(minutes: 4));
    expect(retryDelay(20), const Duration(hours: 1));
  });
}
