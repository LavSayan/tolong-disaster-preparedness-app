import '../../prepare/domain/checklist.dart';
import '../../supplies/domain/supplies.dart';
import 'readiness.dart';

/// Rule-based preparedness agent output. Each rule reads saved data only; nothing is guessed.
sealed class Recommendation {
  const Recommendation();
}

class RemoveExpired extends Recommendation {
  const RemoveExpired(this.item);
  final InventoryItem item;
}

class AddWater extends Recommendation {
  const AddWater(this.liters, this.targetDays);
  final double liters;
  final int targetDays;
}

class AddFood extends Recommendation {
  const AddFood(this.meals, this.targetDays);
  final double meals;
  final int targetDays;
}

class AddEmergencyContacts extends Recommendation {
  const AddEmergencyContacts(this.have);
  final int have;
}

class SetUpHousehold extends Recommendation {
  const SetUpHousehold();
}

class SetBarangay extends Recommendation {
  const SetBarangay();
}

class PackChecklistItem extends Recommendation {
  const PackChecklistItem(this.item);
  final ChecklistItemView item;
}

class AddSupplyCategory extends Recommendation {
  const AddSupplyCategory(this.category);
  final SupplyCategory category;
}

class CheckExpiringSoon extends Recommendation {
  const CheckExpiringSoon(this.item, this.days);
  final InventoryItem item;
  final int days;
}

/// Ordered by urgency: unusable supplies first, then life-sustaining shortfalls, then setup gaps.
List<Recommendation> recommend(ReadinessReport r, List<ChecklistItemView> checklist, DateTime today, {int max = 5}) {
  final s = r.supplies;
  final out = <Recommendation>[
    for (final i in s.expired) RemoveExpired(i),
    if (s.water.shortfall > 0) AddWater(s.water.shortfall, s.targets.targetDays),
    if (s.food.shortfall > 0) AddFood(s.food.shortfall, s.targets.targetDays),
    if (r.contactCount == 0) const AddEmergencyContacts(0),
    if (!r.householdSaved) const SetUpHousehold(),
    if (!r.barangaySet) const SetBarangay(),
    ...checklist.where((i) => !i.done).take(2).map(PackChecklistItem.new),
    for (final c in presenceCategories)
      if (!s.hasUsable(c)) AddSupplyCategory(c),
    for (final i in s.expiringSoon) CheckExpiringSoon(i, i.daysUntilExpiry(today)!),
    if (r.contactCount > 0 && r.contactCount < ReadinessReport.targetContacts) AddEmergencyContacts(r.contactCount),
  ];
  return out.take(max).toList();
}
