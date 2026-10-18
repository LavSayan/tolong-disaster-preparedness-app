import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/clock.dart';
import '../../../core/config/env.dart';
import '../../../core/database/app_database.dart';
import '../../auth/application/session.dart';
import '../../household/data/household_repository.dart';
import '../../prepare/data/checklist_repository.dart';
import '../../supplies/data/supplies_repository.dart';
import '../data/local_records.dart';
import '../data/sync_remote.dart';
import '../data/sync_store.dart';
import '../domain/sync_types.dart';

class SyncRunResult {
  const SyncRunResult({required this.pushed, required this.pulled, required this.applied});

  final int pushed;
  final int pulled;
  final int applied;
}

/// One sync pass: push queued local changes, then pull and merge server changes.
class SyncEngine {
  SyncEngine({required this.store, required this.remote, required this.local, required this.clock});

  final SyncStore store;
  final SyncRemote remote;
  final LocalRecordSource local;
  final DateTime Function() clock;

  Future<SyncRunResult> run(String owner) async {
    final now = clock();

    // 1. Push. Contents are read from the encrypted vault now, so the latest state goes up.
    final due = await store.due(owner, now);
    final records = <RemoteRecord>[];
    for (final e in due) {
      final entity = SyncEntity.values.byName(e.entity);
      final data = e.deleted ? null : await local.read(owner, entity, e.recordId);
      records.add(RemoteRecord(
        entity: entity,
        recordId: e.recordId,
        data: data,
        deleted: e.deleted || data == null,
        clientModifiedAt: e.modifiedAt,
      ));
    }
    if (records.isNotEmpty) {
      try {
        await remote.push(records);
      } on SyncFailure catch (f) {
        for (final e in due) {
          await store.markFailed(e, f.code, now);
        }
        await store.saveState(owner, error: () => f.code);
        rethrow;
      }
      for (final e in due) {
        await store.markPushed(e);
      }
    }

    // 2. Pull and merge with the "newer change wins" rule.
    final state = await store.state(owner);
    final pulled = await remote.pull(since: state?.lastPulledServerAt);
    var cursor = state?.lastPulledServerAt;
    var applied = 0;
    for (final r in pulled) {
      final pending = await store.pendingFor(owner, r.entity, r.recordId);
      final localVersion = await store.version(owner, r.entity, r.recordId);
      if (shouldApplyRemote(remote: r.clientModifiedAt, local: localVersion, pending: pending?.modifiedAt)) {
        await local.apply(owner, r);
        await store.setVersion(owner, r.entity, r.recordId, r.clientModifiedAt);
        applied++;
      }
      final at = r.serverUpdatedAt;
      if (at != null && (cursor == null || at.isAfter(cursor))) cursor = at;
    }
    await store.saveState(owner, pulledServerAt: cursor, successAt: now, error: () => null);
    return SyncRunResult(pushed: records.length, pulled: pulled.length, applied: applied);
  }
}

class SyncStatus {
  const SyncStatus({
    this.enabled = false,
    this.syncing = false,
    this.pending = 0,
    this.lastSuccessAt,
    this.error,
  });

  /// False for guests, on web, and when Supabase isn't configured.
  final bool enabled;
  final bool syncing;
  final int pending;
  final DateTime? lastSuccessAt;

  /// Code of the last failure ('network', 'auth', 'server'), cleared after a successful run.
  final String? error;

  SyncStatus copyWith({bool? syncing, int? pending, DateTime? lastSuccessAt, String? Function()? error}) => SyncStatus(
        enabled: enabled,
        syncing: syncing ?? this.syncing,
        pending: pending ?? this.pending,
        lastSuccessAt: lastSuccessAt ?? this.lastSuccessAt,
        error: error != null ? error() : this.error,
      );
}

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase.open();
  ref.onDispose(db.close);
  return db;
});

final syncStoreProvider = Provider((ref) => SyncStore(ref.watch(appDatabaseProvider)));

/// Null when the build has no Supabase configuration.
final syncRemoteProvider = Provider<SyncRemote?>((ref) => Env.supabaseConfigured ? SupabaseSyncRemote() : null);

/// Connectivity is only a hint that the server may be reachable; a real request decides.
final connectivityProvider = Provider<Stream<bool>>(
  (ref) => Connectivity().onConnectivityChanged.map((r) => !r.contains(ConnectivityResult.none)),
);

final localRecordSourceProvider = Provider((ref) => LocalRecordSource(
      household: ref.watch(householdRepositoryProvider),
      supplies: ref.watch(suppliesRepositoryProvider),
      checklist: ref.watch(checklistRepositoryProvider),
    ));

class SyncController extends Notifier<SyncStatus> {
  Timer? _debounce;
  StreamSubscription<int>? _pendingSub;
  StreamSubscription<bool>? _connectivitySub;

  String? _owner;

  @override
  SyncStatus build() {
    final session = ref.watch(sessionProvider);
    final remote = ref.watch(syncRemoteProvider);
    ref.onDispose(() {
      _debounce?.cancel();
      _pendingSub?.cancel();
      _connectivitySub?.cancel();
    });
    _owner = session.user?.id;
    if (kIsWeb || remote == null || _owner == null) return const SyncStatus();

    final store = ref.watch(syncStoreProvider);
    _pendingSub = store.watchPendingCount(_owner!).listen((n) => state = state.copyWith(pending: n));
    _connectivitySub = ref.read(connectivityProvider).listen((online) {
      if (online) unawaited(syncNow());
    });
    unawaited(_start(store));
    return const SyncStatus(enabled: true);
  }

  Future<void> _start(SyncStore store) async {
    final s = await store.state(_owner!);
    if (!ref.mounted) return;
    state = state.copyWith(lastSuccessAt: s?.lastSuccessAt, error: () => s?.lastError);
    await syncNow();
  }

  /// Called by repositories after every local write by a signed-in user.
  Future<void> recordChange(SyncEntity entity, String recordId, {bool deleted = false}) async {
    if (!state.enabled || _owner == null) return;
    await ref.read(syncStoreProvider).enqueue(_owner!, entity, recordId, deleted: deleted, at: ref.read(clockProvider)());
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 2), () => unawaited(syncNow()));
  }

  Future<void> syncNow() async {
    final owner = _owner;
    final remote = ref.read(syncRemoteProvider);
    if (!state.enabled || state.syncing || owner == null || remote == null) return;
    state = state.copyWith(syncing: true);
    try {
      final result = await SyncEngine(
        store: ref.read(syncStoreProvider),
        remote: remote,
        local: ref.read(localRecordSourceProvider),
        clock: ref.read(clockProvider),
      ).run(owner);
      if (!ref.mounted) return;
      if (result.applied > 0) {
        ref
          ..invalidate(householdProvider)
          ..invalidate(suppliesProvider)
          ..invalidate(checklistStateProvider);
      }
      state = state.copyWith(syncing: false, lastSuccessAt: ref.read(clockProvider)(), error: () => null);
    } on SyncFailure catch (f) {
      if (ref.mounted) state = state.copyWith(syncing: false, error: () => f.code);
    } catch (e) {
      debugPrint('Sync failed: ${e.runtimeType}');
      if (ref.mounted) state = state.copyWith(syncing: false, error: () => 'server');
    }
  }
}

final syncProvider = NotifierProvider<SyncController, SyncStatus>(SyncController.new);
