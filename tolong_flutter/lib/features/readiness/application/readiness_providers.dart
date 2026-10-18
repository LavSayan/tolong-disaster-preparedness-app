import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/clock.dart';
import '../../household/data/household_repository.dart';
import '../../prepare/data/checklist_repository.dart';
import '../../prepare/domain/checklist.dart';
import '../../settings/settings.dart';
import '../../supplies/data/supplies_repository.dart';
import '../../supplies/domain/supplies.dart';
import '../domain/readiness.dart';
import '../domain/recommendations.dart';

final checklistItemsProvider = Provider<List<ChecklistItemView>?>((ref) {
  final state = ref.watch(checklistStateProvider).value;
  final household = ref.watch(householdProvider);
  if (state == null || !household.hasValue) return null;
  return buildChecklist(state, household.value!.household);
});

final supplyReportProvider = Provider<SupplyReport?>((ref) {
  final items = ref.watch(suppliesProvider).value;
  final household = ref.watch(householdProvider);
  if (items == null || !household.hasValue) return null;
  return computeSupplyReport(
    items: items,
    householdSize: household.value!.household?.size,
    targets: ref.watch(settingsProvider.select((s) => s.targets)),
    today: ref.watch(clockProvider)(),
  );
});

/// Null while any source is still loading.
final readinessProvider = Provider<ReadinessReport?>((ref) {
  final checklist = ref.watch(checklistItemsProvider);
  final supplies = ref.watch(supplyReportProvider);
  final data = ref.watch(householdProvider).value;
  if (checklist == null || supplies == null || data == null) return null;
  return computeReadiness(
    checklist: checklist,
    supplies: supplies,
    contacts: data.contacts,
    household: data.household,
    profile: data.profile,
  );
});

final recommendationsProvider = Provider<List<Recommendation>>((ref) {
  final report = ref.watch(readinessProvider);
  final checklist = ref.watch(checklistItemsProvider);
  if (report == null || checklist == null) return const [];
  return recommend(report, checklist, ref.watch(clockProvider)());
});
