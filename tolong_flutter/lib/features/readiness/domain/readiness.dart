import '../../household/domain/models.dart';
import '../../prepare/domain/checklist.dart';
import '../../supplies/domain/supplies.dart';

enum ReadinessArea { goBag, supplies, contacts, household }

class ReadinessComponent {
  const ReadinessComponent(this.area, this.weight, this.progress);

  final ReadinessArea area;
  final double weight;

  /// 0–1.
  final double progress;

  double get points => weight * progress * 100;
}

/// Transparent weighted score, 0–100:
/// go-bag checklist 40%, supply coverage 30%, emergency contacts 15% (2 or more = full),
/// household profile 15% (household composition saved + barangay set).
class ReadinessReport {
  const ReadinessReport({
    required this.components,
    required this.checklistDone,
    required this.checklistTotal,
    required this.supplies,
    required this.contactCount,
    required this.householdSaved,
    required this.barangaySet,
  });

  static const weights = {
    ReadinessArea.goBag: 0.40,
    ReadinessArea.supplies: 0.30,
    ReadinessArea.contacts: 0.15,
    ReadinessArea.household: 0.15,
  };

  static const targetContacts = 2;

  final List<ReadinessComponent> components;
  final int checklistDone;
  final int checklistTotal;
  final SupplyReport supplies;
  final int contactCount;
  final bool householdSaved;
  final bool barangaySet;

  int get score => components.fold<double>(0, (sum, c) => sum + c.points).round();

  ReadinessComponent component(ReadinessArea a) => components.firstWhere((c) => c.area == a);
}

ReadinessReport computeReadiness({
  required List<ChecklistItemView> checklist,
  required SupplyReport supplies,
  required List<EmergencyContact> contacts,
  required HouseholdProfile? household,
  required UserProfile? profile,
}) {
  final done = checklist.where((i) => i.done).length;
  final total = checklist.length;
  final barangaySet = profile?.barangay.trim().isNotEmpty == true;
  final householdSaved = household != null;

  final progress = {
    ReadinessArea.goBag: total == 0 ? 0.0 : done / total,
    ReadinessArea.supplies: supplies.score,
    ReadinessArea.contacts: (contacts.length / ReadinessReport.targetContacts).clamp(0.0, 1.0),
    ReadinessArea.household: (householdSaved ? 0.5 : 0.0) + (barangaySet ? 0.5 : 0.0),
  };

  return ReadinessReport(
    components: [
      for (final e in ReadinessReport.weights.entries) ReadinessComponent(e.key, e.value, progress[e.key]!),
    ],
    checklistDone: done,
    checklistTotal: total,
    supplies: supplies,
    contactCount: contacts.length,
    householdSaved: householdSaved,
    barangaySet: barangaySet,
  );
}
