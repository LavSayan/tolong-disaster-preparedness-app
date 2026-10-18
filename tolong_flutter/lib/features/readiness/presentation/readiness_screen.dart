import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets/animations.dart';
import '../../../shared/widgets/common.dart';
import '../../supplies/presentation/supplies_screen.dart';
import '../application/readiness_providers.dart';
import '../domain/readiness.dart';
import 'readiness_ring.dart';
import 'recommendation_list.dart';

class ReadinessScreen extends ConsumerWidget {
  const ReadinessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final report = ref.watch(readinessProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        surfaceTintColor: Colors.transparent,
        title: Text(l.readinessTitle, style: serif(20)),
        actions: [
          IconButton(
            tooltip: l.readinessHowTitle,
            onPressed: () => showInfoSheet(context, l.readinessHowTitle, l.readinessHowBody),
            icon: const Icon(Icons.info_outline_rounded),
          ),
        ],
      ),
      body: report == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.xxxl),
              children: [
                FadeSlideIn(
                  child: CardBox(
                    child: Row(children: [
                      ReadinessRing(score: report.score, size: 96, stroke: 8),
                      const SizedBox(width: AppSpacing.xl),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(l.readinessHeadline(report.score), style: serif(24)),
                          const SizedBox(height: AppSpacing.xs),
                          TextButton(
                            style: TextButton.styleFrom(padding: EdgeInsets.zero),
                            onPressed: () => showInfoSheet(context, l.readinessHowTitle, l.readinessHowBody),
                            child: Text(l.readinessHowTitle),
                          ),
                        ]),
                      ),
                    ]),
                  ),
                ),
                for (final (i, c) in report.components.indexed)
                  FadeSlideIn(
                    delay: Duration(milliseconds: 60 * (i + 1)),
                    child: _AreaCard(component: c, report: report),
                  ),
                CardBox(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Eyebrow(l.recommendationsEyebrow),
                    const SizedBox(height: AppSpacing.xs),
                    Text(l.readinessNextActions, style: serif(20)),
                    const SizedBox(height: AppSpacing.sm),
                    const RecommendationList(),
                  ]),
                ),
              ],
            ),
    );
  }
}

class _AreaCard extends StatelessWidget {
  const _AreaCard({required this.component, required this.report});

  final ReadinessComponent component;
  final ReadinessReport report;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = report.supplies;
    final (icon, details, action, route) = switch (component.area) {
      ReadinessArea.goBag => (
          Icons.backpack_outlined,
          [l.areaGoBagDetail(report.checklistDone, report.checklistTotal)],
          l.openChecklist,
          '/prepare',
        ),
      ReadinessArea.supplies => (
          Icons.inventory_outlined,
          [l.areaSuppliesDetail(l.number(s.food.days), l.number(s.water.days))],
          l.openSupplies,
          '/supplies',
        ),
      ReadinessArea.contacts => (
          Icons.contact_phone_outlined,
          [l.areaContactsDetail(report.contactCount)],
          l.openHousehold,
          '/profile',
        ),
      ReadinessArea.household => (
          Icons.group_outlined,
          [
            report.householdSaved ? l.householdDetailsSaved : l.householdDetailsMissing,
            report.barangaySet ? l.barangaySet : l.barangayMissing,
          ],
          l.openHousehold,
          '/profile',
        ),
    };
    final complete = component.progress >= 1;

    return CardBox(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          IconTile(
            icon: complete ? Icons.check_rounded : icon,
            background: complete ? AppColors.sageSoft : AppColors.amberSoft,
            foreground: complete ? AppColors.success : AppColors.amber,
            size: 34,
            radius: 11,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(flex: 3, child: Text(l.readinessArea(component.area), style: sans(14, weight: FontWeight.w700))),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            flex: 2,
            child: Text(
              l.areaPoints((component.weight * 100).round(), component.points.round()),
              textAlign: TextAlign.end,
              style: sans(11, weight: FontWeight.w700, color: AppColors.muted),
            ),
          ),
        ]),
        const SizedBox(height: AppSpacing.md),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: component.progress),
          duration: motion(context, const Duration(milliseconds: 700)),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) => ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 6,
              backgroundColor: const Color(0xFFE9EEE7),
              color: AppColors.sage,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final d in details) Text(d, style: sans(12, color: AppColors.muted)),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => route == '/prepare' ? context.go(route) : context.push(route),
            child: Text(action),
          ),
        ),
      ]),
    );
  }
}
