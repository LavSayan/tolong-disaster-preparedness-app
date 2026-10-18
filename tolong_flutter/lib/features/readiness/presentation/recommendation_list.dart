import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme.dart';
import '../../../l10n/l10n.dart';
import '../application/readiness_providers.dart';
import '../domain/recommendations.dart';

(IconData, Color, String) _style(Recommendation r) => switch (r) {
      RemoveExpired() => (Icons.event_busy_outlined, AppColors.error, '/supplies'),
      AddWater() => (Icons.water_drop_outlined, AppColors.blue, '/supplies'),
      AddFood() => (Icons.rice_bowl_outlined, AppColors.amber, '/supplies'),
      AddSupplyCategory() => (Icons.add_box_outlined, AppColors.amber, '/supplies'),
      CheckExpiringSoon() => (Icons.schedule_outlined, AppColors.warning, '/supplies'),
      AddEmergencyContacts() => (Icons.contact_phone_outlined, AppColors.terracotta, '/profile'),
      SetUpHousehold() || SetBarangay() => (Icons.group_outlined, AppColors.terracotta, '/profile'),
      PackChecklistItem() => (Icons.backpack_outlined, AppColors.primary, '/prepare'),
    };

/// Output of the rule-based preparedness agent, each item linked to the screen that fixes it.
class RecommendationList extends ConsumerWidget {
  const RecommendationList({super.key, this.hideChecklistItems = false});

  /// On the Prepare screen the checklist is already visible, so its items would be noise.
  final bool hideChecklistItems;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final recs = ref
        .watch(recommendationsProvider)
        .where((r) => !(hideChecklistItems && r is PackChecklistItem))
        .toList();
    if (recs.isEmpty) {
      return Text(l.recommendationsEmpty, style: sans(12, height: 1.45, color: AppColors.muted));
    }
    return Column(children: [
      for (final r in recs)
        Builder(builder: (context) {
          final (icon, color, route) = _style(r);
          return ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: Icon(icon, color: color, size: AppIconSizes.lg),
            title: Text(l.recommendation(r), style: sans(12, height: 1.35)),
            trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFFAAB4AD)),
            onTap: () => route == '/prepare' ? context.go(route) : context.push(route),
          );
        }),
    ]);
  }
}
