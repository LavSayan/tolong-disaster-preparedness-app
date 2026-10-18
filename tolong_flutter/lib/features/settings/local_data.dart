import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/application/session.dart';
import '../household/data/household_repository.dart';
import '../sync/application/sync_engine.dart';
import '../prepare/data/checklist_repository.dart';
import '../supplies/data/supplies_repository.dart';

/// Deletes everything stored on this phone for one owner (account id or guest).
///
/// Storage only: callers that sit below the session (screens) should use [LocalData.clear],
/// which also reloads the providers. The session controller must not invalidate them itself,
/// because they depend on it; its own state change already rebuilds them.
Future<void> wipeLocalData(Ref ref, String owner, {bool keepProfile = true}) async {
  final household = ref.read(householdRepositoryProvider);
  final profile = keepProfile ? (await household.load(owner)).profile : null;
  await household.clear(owner);
  if (profile != null) await household.saveProfile(owner, profile);
  await ref.read(suppliesRepositoryProvider).clear(owner);
  await ref.read(checklistRepositoryProvider).clear(owner);
  // Sync bookkeeping exists only where sync can run (signed-in, configured, not web).
  if (!kIsWeb && ref.read(syncRemoteProvider) != null && owner != guestOwner) {
    await ref.read(syncStoreProvider).clearOwner(owner);
  }
}

final localDataProvider = Provider<LocalData>(LocalData.new);

class LocalData {
  LocalData(this._ref);

  final Ref _ref;

  Future<void> clear(String owner, {bool keepProfile = true}) async {
    await wipeLocalData(_ref, owner, keepProfile: keepProfile);
    _ref
      ..invalidate(householdProvider)
      ..invalidate(suppliesProvider)
      ..invalidate(checklistStateProvider);
  }
}
