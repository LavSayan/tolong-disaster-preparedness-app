import '../../household/data/household_repository.dart';
import '../../household/domain/models.dart';
import '../../prepare/data/checklist_repository.dart';
import '../../prepare/domain/checklist.dart';
import '../../supplies/data/supplies_repository.dart';
import '../../supplies/domain/supplies.dart';
import '../domain/sync_types.dart';

/// Reads and writes synced records in the encrypted on-device repositories.
/// Single-document entities (profile, household, checklist) use the owner id as record id.
class LocalRecordSource {
  LocalRecordSource({required this.household, required this.supplies, required this.checklist});

  final HouseholdRepository household;
  final SuppliesRepository supplies;
  final ChecklistRepository checklist;

  /// Current local contents, or null if the record no longer exists.
  Future<Map<String, Object?>?> read(String owner, SyncEntity entity, String recordId) async {
    switch (entity) {
      case SyncEntity.profile:
        return (await household.load(owner)).profile?.toJson();
      case SyncEntity.household:
        return (await household.load(owner)).household?.toJson();
      case SyncEntity.contact:
        return (await household.load(owner)).contacts.where((c) => c.id == recordId).firstOrNull?.toJson();
      case SyncEntity.supply:
        return (await supplies.load(owner)).where((s) => s.id == recordId).firstOrNull?.toJson();
      case SyncEntity.checklist:
        return (await checklist.load(owner)).toJson();
    }
  }

  /// Writes a record that came from the server.
  Future<void> apply(String owner, RemoteRecord r) async {
    final data = r.data;
    switch (r.entity) {
      case SyncEntity.profile:
        if (!r.deleted && data != null) await household.saveProfile(owner, UserProfile.fromJson(data));
      case SyncEntity.household:
        if (!r.deleted && data != null) await household.saveHousehold(owner, HouseholdProfile.fromJson(data));
      case SyncEntity.contact:
        final current = (await household.load(owner)).contacts.where((c) => c.id != r.recordId).toList();
        if (!r.deleted && data != null) current.add(EmergencyContact.fromJson(data));
        await household.saveContacts(owner, current);
      case SyncEntity.supply:
        final current = (await supplies.load(owner)).where((s) => s.id != r.recordId).toList();
        if (!r.deleted && data != null) current.add(InventoryItem.fromJson(data));
        await supplies.save(owner, current);
      case SyncEntity.checklist:
        if (!r.deleted && data != null) await checklist.save(owner, ChecklistState.fromJson(data));
    }
  }
}
