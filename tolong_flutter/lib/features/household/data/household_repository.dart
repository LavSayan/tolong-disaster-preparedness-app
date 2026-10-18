import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/secure_vault.dart';
import '../../auth/application/session.dart';
import '../../sync/application/sync_engine.dart';
import '../../sync/domain/sync_types.dart';
import '../domain/models.dart';

/// Stores profile, household and contacts on-device, encrypted, scoped per owner
/// (a Supabase user id, or "guest" for emergency access).
class HouseholdRepository {
  HouseholdRepository(this._vault);

  final SecureVault _vault;

  String _key(String kind, String owner) => '$kind:$owner';

  Future<HouseholdData> load(String owner) async {
    Map<String, Object?>? decode(String? raw) => raw == null ? null : jsonDecode(raw) as Map<String, Object?>;

    final profile = decode(await _vault.read(_key('profile', owner)));
    final household = decode(await _vault.read(_key('household', owner)));
    final contactsRaw = await _vault.read(_key('contacts', owner));
    final contacts = contactsRaw == null
        ? <EmergencyContact>[]
        : (jsonDecode(contactsRaw) as List)
            .map((e) => EmergencyContact.fromJson(e as Map<String, Object?>))
            .toList();

    return HouseholdData(
      profile: profile == null ? null : UserProfile.fromJson(profile),
      household: household == null ? null : HouseholdProfile.fromJson(household),
      contacts: contacts,
    );
  }

  Future<void> saveProfile(String owner, UserProfile profile) =>
      _vault.write(_key('profile', owner), jsonEncode(profile.toJson()));

  Future<void> saveHousehold(String owner, HouseholdProfile household) =>
      _vault.write(_key('household', owner), jsonEncode(household.toJson()));

  Future<void> saveContacts(String owner, List<EmergencyContact> contacts) =>
      _vault.write(_key('contacts', owner), jsonEncode(contacts.map((c) => c.toJson()).toList()));

  Future<void> clear(String owner) async {
    for (final kind in ['profile', 'household', 'contacts']) {
      await _vault.delete(_key(kind, owner));
    }
  }
}

final householdRepositoryProvider =
    Provider<HouseholdRepository>((ref) => HouseholdRepository(ref.watch(secureVaultProvider)));

class HouseholdController extends AsyncNotifier<HouseholdData> {
  String? get _owner => ref.read(sessionProvider).owner;

  @override
  Future<HouseholdData> build() async {
    final owner = ref.watch(sessionProvider.select((s) => s.owner));
    if (owner == null) return const HouseholdData();
    return ref.read(householdRepositoryProvider).load(owner);
  }

  Future<void> saveAll(HouseholdData data) async {
    final owner = _owner;
    if (owner == null) return;
    final repo = ref.read(householdRepositoryProvider);
    if (data.profile != null) await repo.saveProfile(owner, data.profile!);
    if (data.household != null) await repo.saveHousehold(owner, data.household!);
    await repo.saveContacts(owner, data.contacts);
    state = AsyncData(data);
    if (data.profile != null) _record(SyncEntity.profile, owner);
    if (data.household != null) _record(SyncEntity.household, owner);
    for (final c in data.contacts) {
      _record(SyncEntity.contact, c.id);
    }
  }

  /// Queues the change for cloud sync (no-op for guests or when sync isn't configured).
  void _record(SyncEntity entity, String id, {bool deleted = false}) =>
      unawaited(ref.read(syncProvider.notifier).recordChange(entity, id, deleted: deleted));

  Future<void> updateProfile(UserProfile profile) async {
    final owner = _owner;
    if (owner == null) return;
    await ref.read(householdRepositoryProvider).saveProfile(owner, profile);
    state = AsyncData((state.value ?? const HouseholdData()).copyWith(profile: profile));
    _record(SyncEntity.profile, owner);
  }

  Future<void> updateHousehold(HouseholdProfile household) async {
    final owner = _owner;
    if (owner == null) return;
    await ref.read(householdRepositoryProvider).saveHousehold(owner, household);
    state = AsyncData((state.value ?? const HouseholdData()).copyWith(household: household));
    _record(SyncEntity.household, owner);
  }

  Future<void> saveContact(EmergencyContact contact) async {
    final current = state.value?.contacts ?? const [];
    final exists = current.any((c) => c.id == contact.id);
    await _writeContacts(
      exists ? [for (final c in current) c.id == contact.id ? contact : c] : [...current, contact],
    );
    _record(SyncEntity.contact, contact.id);
  }

  Future<void> removeContact(String id) async {
    await _writeContacts([for (final c in state.value?.contacts ?? const <EmergencyContact>[]) if (c.id != id) c]);
    _record(SyncEntity.contact, id, deleted: true);
  }

  Future<void> _writeContacts(List<EmergencyContact> contacts) async {
    final owner = _owner;
    if (owner == null) return;
    await ref.read(householdRepositoryProvider).saveContacts(owner, contacts);
    state = AsyncData((state.value ?? const HouseholdData()).copyWith(contacts: contacts));
  }
}

final householdProvider = AsyncNotifierProvider<HouseholdController, HouseholdData>(HouseholdController.new);
