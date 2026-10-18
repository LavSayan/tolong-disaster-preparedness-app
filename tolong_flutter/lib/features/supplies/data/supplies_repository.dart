import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/secure_vault.dart';
import '../../auth/application/session.dart';
import '../../sync/application/sync_engine.dart';
import '../../sync/domain/sync_types.dart';
import '../domain/supplies.dart';

/// Inventory is kept encrypted per owner, because medicines can reveal health information.
class SuppliesRepository {
  SuppliesRepository(this._vault);

  final SecureVault _vault;

  Future<List<InventoryItem>> load(String owner) async {
    final raw = await _vault.read('supplies:$owner');
    if (raw == null) return [];
    return (jsonDecode(raw) as List).map((e) => InventoryItem.fromJson(e as Map<String, Object?>)).toList();
  }

  Future<void> save(String owner, List<InventoryItem> items) =>
      _vault.write('supplies:$owner', jsonEncode(items.map((i) => i.toJson()).toList()));

  Future<void> clear(String owner) => _vault.delete('supplies:$owner');
}

final suppliesRepositoryProvider = Provider((ref) => SuppliesRepository(ref.watch(secureVaultProvider)));

class SuppliesController extends AsyncNotifier<List<InventoryItem>> {
  @override
  Future<List<InventoryItem>> build() async {
    final owner = ref.watch(sessionProvider.select((s) => s.owner));
    if (owner == null) return [];
    return ref.read(suppliesRepositoryProvider).load(owner);
  }

  Future<void> upsert(InventoryItem item) async {
    final current = state.value ?? const [];
    final exists = current.any((i) => i.id == item.id);
    await _write(exists ? [for (final i in current) i.id == item.id ? item : i] : [...current, item]);
    unawaited(ref.read(syncProvider.notifier).recordChange(SyncEntity.supply, item.id));
  }

  Future<void> remove(String id) async {
    await _write([for (final i in state.value ?? const <InventoryItem>[]) if (i.id != id) i]);
    unawaited(ref.read(syncProvider.notifier).recordChange(SyncEntity.supply, id, deleted: true));
  }

  Future<void> _write(List<InventoryItem> items) async {
    final owner = ref.read(sessionProvider).owner;
    if (owner == null) return;
    await ref.read(suppliesRepositoryProvider).save(owner, items);
    state = AsyncData(items);
  }
}

final suppliesProvider = AsyncNotifierProvider<SuppliesController, List<InventoryItem>>(SuppliesController.new);
