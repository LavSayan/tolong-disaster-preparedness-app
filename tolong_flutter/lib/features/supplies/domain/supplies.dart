import 'dart:math';

enum SupplyCategory { water, food, medicine, firstAid, hygiene, lighting, other }

/// Categories that count toward the supply score besides water and food.
const presenceCategories = [
  SupplyCategory.medicine,
  SupplyCategory.firstAid,
  SupplyCategory.hygiene,
  SupplyCategory.lighting,
];

enum SupplyUnit {
  liters(litersPerUnit: 1),
  milliliters(litersPerUnit: 0.001),
  gallons(litersPerUnit: 3.785),
  bottles,
  meals,
  packs,
  cans,
  pieces,
  tablets,
  boxes,
  kilograms;

  const SupplyUnit({this.litersPerUnit});

  /// Set for volume units, so water in these units converts to liters without extra input.
  final double? litersPerUnit;
}

class PreparednessTargets {
  const PreparednessTargets({
    this.waterLitersPerPersonPerDay = 3.8,
    this.mealsPerPersonPerDay = 3,
    this.targetDays = 3,
  });

  /// Default follows the widely used "one gallon (≈3.8 L) per person per day" guideline
  /// for drinking and basic hygiene. Users can change it in Settings.
  final double waterLitersPerPersonPerDay;
  final int mealsPerPersonPerDay;
  final int targetDays;

  PreparednessTargets copyWith({double? waterLitersPerPersonPerDay, int? mealsPerPersonPerDay, int? targetDays}) =>
      PreparednessTargets(
        waterLitersPerPersonPerDay: waterLitersPerPersonPerDay ?? this.waterLitersPerPersonPerDay,
        mealsPerPersonPerDay: mealsPerPersonPerDay ?? this.mealsPerPersonPerDay,
        targetDays: targetDays ?? this.targetDays,
      );
}

class InventoryItem {
  const InventoryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.unit,
    this.perUnit,
    this.dailyUse,
    this.expiresOn,
  });

  final String id;
  final String name;
  final SupplyCategory category;
  final double quantity;
  final SupplyUnit unit;

  /// Water: liters in one unit (e.g. one bottle = 0.5 L). Food: meals in one unit (e.g. one pack = 2 meals).
  /// Not needed when the unit already says it (liters, gallons, meals).
  final double? perUnit;

  /// Household use per day, in this item's unit (e.g. 2 tablets/day). Optional.
  final double? dailyUse;
  final DateTime? expiresOn;

  bool isExpired(DateTime today) => expiresOn != null && _day(expiresOn!).isBefore(_day(today));

  int? daysUntilExpiry(DateTime today) => expiresOn == null ? null : _day(expiresOn!).difference(_day(today)).inDays;

  /// Water in liters, or null when the volume of one unit is unknown.
  double? get liters {
    if (category != SupplyCategory.water) return null;
    final factor = unit.litersPerUnit ?? perUnit;
    return factor == null ? null : quantity * factor;
  }

  /// Food in meals, or null when servings per unit are unknown.
  double? get meals {
    if (category != SupplyCategory.food) return null;
    if (unit == SupplyUnit.meals) return quantity;
    return perUnit == null ? null : quantity * perUnit!;
  }

  double? get daysOfUse => (dailyUse == null || dailyUse! <= 0) ? null : quantity / dailyUse!;

  InventoryItem copyWith({double? quantity}) => InventoryItem(
        id: id,
        name: name,
        category: category,
        quantity: quantity ?? this.quantity,
        unit: unit,
        perUnit: perUnit,
        dailyUse: dailyUse,
        expiresOn: expiresOn,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'category': category.name,
        'quantity': quantity,
        'unit': unit.name,
        'perUnit': perUnit,
        'dailyUse': dailyUse,
        'expiresOn': expiresOn?.toIso8601String(),
      };

  factory InventoryItem.fromJson(Map<String, Object?> j) => InventoryItem(
        id: j['id'] as String,
        name: j['name'] as String? ?? '',
        category: SupplyCategory.values.asNameMap()[j['category']] ?? SupplyCategory.other,
        quantity: (j['quantity'] as num?)?.toDouble() ?? 0,
        unit: SupplyUnit.values.asNameMap()[j['unit']] ?? SupplyUnit.pieces,
        perUnit: (j['perUnit'] as num?)?.toDouble(),
        dailyUse: (j['dailyUse'] as num?)?.toDouble(),
        expiresOn: j['expiresOn'] == null ? null : DateTime.tryParse(j['expiresOn'] as String),
      );
}

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

/// Coverage for a consumable measured against a daily household need.
class DayCoverage {
  const DayCoverage({required this.available, required this.needPerDay, required this.targetDays, this.unknownItems = 0});

  final double available;
  final double needPerDay;
  final int targetDays;

  /// Items that couldn't be counted because their per-unit amount is missing.
  final int unknownItems;

  double get days => needPerDay <= 0 ? 0 : available / needPerDay;
  double get shortfall => max(0, needPerDay * targetDays - available);
  double get progress => targetDays <= 0 ? 1 : min(1, days / targetDays);
}

class SupplyReport {
  const SupplyReport({
    required this.householdSize,
    required this.householdSizeKnown,
    required this.water,
    required this.food,
    required this.usableCounts,
    required this.expired,
    required this.expiringSoon,
    required this.targets,
  });

  final int householdSize;
  final bool householdSizeKnown;
  final DayCoverage water;
  final DayCoverage food;
  final Map<SupplyCategory, int> usableCounts;
  final List<InventoryItem> expired;
  final List<InventoryItem> expiringSoon;
  final PreparednessTargets targets;

  static const waterWeight = 0.3;
  static const foodWeight = 0.3;
  static const presenceWeight = 0.1;

  bool hasUsable(SupplyCategory c) => (usableCounts[c] ?? 0) > 0;

  List<SupplyCategory> get missingEssentials => [
        if (!hasUsable(SupplyCategory.water)) SupplyCategory.water,
        if (!hasUsable(SupplyCategory.food)) SupplyCategory.food,
        for (final c in presenceCategories)
          if (!hasUsable(c)) c,
      ];

  /// 0–1. Water 30% and food 30% scaled by days covered vs target; medicine, first aid,
  /// hygiene and lighting 10% each for having at least one unexpired item.
  double get score =>
      water.progress * waterWeight +
      food.progress * foodWeight +
      presenceCategories.where(hasUsable).length * presenceWeight;
}

const expiringSoonDays = 30;

SupplyReport computeSupplyReport({
  required List<InventoryItem> items,
  required int? householdSize,
  required PreparednessTargets targets,
  required DateTime today,
}) {
  final size = (householdSize == null || householdSize < 1) ? 1 : householdSize;
  final usable = items.where((i) => !i.isExpired(today) && i.quantity > 0).toList();

  var liters = 0.0, meals = 0.0;
  var unknownWater = 0, unknownFood = 0;
  for (final i in usable) {
    if (i.category == SupplyCategory.water) {
      final l = i.liters;
      l == null ? unknownWater++ : liters += l;
    } else if (i.category == SupplyCategory.food) {
      final m = i.meals;
      m == null ? unknownFood++ : meals += m;
    }
  }

  final counts = <SupplyCategory, int>{};
  for (final i in usable) {
    counts[i.category] = (counts[i.category] ?? 0) + 1;
  }

  return SupplyReport(
    householdSize: size,
    householdSizeKnown: householdSize != null && householdSize >= 1,
    water: DayCoverage(
      available: liters,
      needPerDay: size * targets.waterLitersPerPersonPerDay,
      targetDays: targets.targetDays,
      unknownItems: unknownWater,
    ),
    food: DayCoverage(
      available: meals,
      needPerDay: (size * targets.mealsPerPersonPerDay).toDouble(),
      targetDays: targets.targetDays,
      unknownItems: unknownFood,
    ),
    usableCounts: counts,
    expired: items.where((i) => i.isExpired(today)).toList(),
    expiringSoon: usable.where((i) {
      final d = i.daysUntilExpiry(today);
      return d != null && d <= expiringSoonDays;
    }).toList()
      ..sort((a, b) => a.expiresOn!.compareTo(b.expiresOn!)),
    targets: targets,
  );
}
