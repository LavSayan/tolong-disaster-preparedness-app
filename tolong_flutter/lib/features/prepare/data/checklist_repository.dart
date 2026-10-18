import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/clock.dart';
import '../../../core/storage/secure_vault.dart';
import '../../auth/application/session.dart';
import '../../sync/application/sync_engine.dart';
import '../../sync/domain/sync_types.dart';
import '../domain/checklist.dart';

class ChecklistRepository {
  ChecklistRepository(this._vault);

  final SecureVault _vault;

  Future<ChecklistState> load(String owner) async {
    final raw = await _vault.read('checklist:$owner');
    return raw == null ? const ChecklistState() : ChecklistState.fromJson(jsonDecode(raw) as Map<String, Object?>);
  }

  Future<void> save(String owner, ChecklistState state) =>
      _vault.write('checklist:$owner', jsonEncode(state.toJson()));

  Future<void> clear(String owner) => _vault.delete('checklist:$owner');
}

final checklistRepositoryProvider = Provider((ref) => ChecklistRepository(ref.watch(secureVaultProvider)));

/// Every change is written immediately (local-first); there is no separate save step.
class ChecklistController extends AsyncNotifier<ChecklistState> {
  @override
  Future<ChecklistState> build() async {
    final owner = ref.watch(sessionProvider.select((s) => s.owner));
    if (owner == null) return const ChecklistState();
    return ref.read(checklistRepositoryProvider).load(owner);
  }

  ChecklistState get _s => state.value ?? const ChecklistState();

  Future<void> toggle(ChecklistItemView item, bool done) {
    if (item.isCustom) {
      return _write(_s.templates, [for (final c in _s.custom) c.id == item.id ? c.copyWith(done: done) : c]);
    }
    final prev = _s.templates[item.id];
    return _write({..._s.templates, item.id: TemplateItemState(done: done, editedTitle: prev?.editedTitle)}, _s.custom);
  }

  Future<void> addCustom(String title, ChecklistCategory category) => _write(_s.templates, [
        ..._s.custom,
        CustomChecklistItem(
          id: 'c${ref.read(clockProvider)().microsecondsSinceEpoch}',
          title: title,
          category: category,
        ),
      ]);

  /// Template items keep their id, so a renamed template item still follows template updates.
  Future<void> rename(ChecklistItemView item, String title, ChecklistCategory category) {
    if (item.isCustom) {
      return _write(_s.templates, [
        for (final c in _s.custom) c.id == item.id ? c.copyWith(title: title, category: category) : c,
      ]);
    }
    final prev = _s.templates[item.id];
    return _write({..._s.templates, item.id: TemplateItemState(done: prev?.done ?? false, editedTitle: title)}, _s.custom);
  }

  Future<void> removeCustom(String id) => _write(_s.templates, [for (final c in _s.custom) if (c.id != id) c]);

  /// Unchecks everything but keeps custom items and edited titles.
  Future<void> resetProgress() => _write(
        _s.templates.map((k, v) => MapEntry(k, TemplateItemState(editedTitle: v.editedTitle))),
        [for (final c in _s.custom) c.copyWith(done: false)],
      );

  Future<void> _write(Map<String, TemplateItemState> templates, List<CustomChecklistItem> custom) async {
    final owner = ref.read(sessionProvider).owner;
    if (owner == null) return;
    final next = ChecklistState(templates: templates, custom: custom, updatedAt: ref.read(clockProvider)());
    await ref.read(checklistRepositoryProvider).save(owner, next);
    state = AsyncData(next);
    unawaited(ref.read(syncProvider.notifier).recordChange(SyncEntity.checklist, owner));
  }
}

final checklistStateProvider = AsyncNotifierProvider<ChecklistController, ChecklistState>(ChecklistController.new);
