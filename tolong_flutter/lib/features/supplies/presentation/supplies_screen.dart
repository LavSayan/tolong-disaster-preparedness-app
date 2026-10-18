import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/clock.dart';
import '../../../core/theme.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets/animations.dart';
import '../../../shared/widgets/common.dart';
import '../../../shared/widgets/form_widgets.dart';
import '../../readiness/application/readiness_providers.dart';
import '../data/supplies_repository.dart';
import '../domain/supplies.dart';
import 'supply_editor.dart';

IconData supplyIcon(SupplyCategory c) => switch (c) {
      SupplyCategory.water => Icons.water_drop_outlined,
      SupplyCategory.food => Icons.rice_bowl_outlined,
      SupplyCategory.medicine => Icons.medication_outlined,
      SupplyCategory.firstAid => Icons.medical_services_outlined,
      SupplyCategory.hygiene => Icons.soap_outlined,
      SupplyCategory.lighting => Icons.flashlight_on_outlined,
      SupplyCategory.other => Icons.inventory_2_outlined,
    };

Future<void> showInfoSheet(BuildContext context, String title, String body) => showModalBottomSheet<void>(
      context: context,
      builder: (context) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xxl),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: serif(20)),
          const SizedBox(height: AppSpacing.md),
          Text(body, style: sans(13, height: 1.5, color: AppColors.muted)),
        ]),
      ),
    );

class SuppliesScreen extends ConsumerWidget {
  const SuppliesScreen({super.key});

  void _open(BuildContext context, {InventoryItem? item, SupplyCategory? category}) => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => SupplyEditorPage(existing: item, initialCategory: category)),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final report = ref.watch(supplyReportProvider);
    final items = ref.watch(suppliesProvider).value ?? const <InventoryItem>[];
    final today = ref.watch(clockProvider)();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        surfaceTintColor: Colors.transparent,
        title: Text(l.suppliesTitle, style: serif(20)),
        actions: [
          IconButton(
            tooltip: l.suppliesHowTitle,
            onPressed: () => showInfoSheet(context, l.suppliesHowTitle, l.suppliesHowBody),
            icon: const Icon(Icons.info_outline_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _open(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(l.suppliesAdd),
      ),
      body: report == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, 96),
              children: [
                Text(l.suppliesEstimateNote(report.householdSize), style: sans(12, height: 1.45, color: AppColors.muted)),
                if (!report.householdSizeKnown) ...[
                  const SizedBox(height: AppSpacing.sm),
                  InlineMessage(l.suppliesHouseholdUnknown),
                ],
                const SizedBox(height: AppSpacing.lg),
                FadeSlideIn(
                  child: _CoverageCard(
                    title: l.suppliesWater,
                    icon: Icons.water_drop_outlined,
                    color: AppColors.blue,
                    soft: AppColors.blueSoft,
                    coverage: report.water,
                    stored: l.coverageWaterStored(l.number(report.water.available), l.number(report.water.needPerDay)),
                    shortText: l.coverageShortWater(l.number(report.water.shortfall)),
                  ),
                ),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 80),
                  child: _CoverageCard(
                    title: l.suppliesFood,
                    icon: Icons.rice_bowl_outlined,
                    color: AppColors.amber,
                    soft: AppColors.amberSoft,
                    coverage: report.food,
                    stored: l.coverageFoodStored(l.number(report.food.available), l.number(report.food.needPerDay)),
                    shortText: l.coverageShortFood(l.number(report.food.shortfall)),
                  ),
                ),
                Eyebrow(l.suppliesEssentials.toUpperCase()),
                const SizedBox(height: AppSpacing.sm),
                // Two columns whose tiles grow with their text (a fixed-ratio grid clips at large text sizes).
                LayoutBuilder(
                  builder: (context, constraints) => Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final c in presenceCategories)
                        SizedBox(
                          width: (constraints.maxWidth - AppSpacing.sm) / 2,
                          child: _EssentialTile(
                            category: c,
                            count: report.usableCounts[c] ?? 0,
                            onTap: () => _open(context, category: c),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Eyebrow(l.suppliesInventory.toUpperCase()),
                const SizedBox(height: AppSpacing.sm),
                if (items.isEmpty)
                  InlineMessage(l.suppliesEmpty)
                else
                  CardBox(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
                    child: Column(children: [
                      for (final i in [...items]..sort((a, b) => a.category.index.compareTo(b.category.index)))
                        _InventoryTile(item: i, today: today, onTap: () => _open(context, item: i)),
                    ]),
                  ),
              ],
            ),
    );
  }
}

class _CoverageCard extends StatelessWidget {
  const _CoverageCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.soft,
    required this.coverage,
    required this.stored,
    required this.shortText,
  });

  final String title;
  final IconData icon;
  final Color color;
  final Color soft;
  final DayCoverage coverage;
  final String stored;
  final String shortText;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final met = coverage.shortfall <= 0;
    return CardBox(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          IconTile(icon: icon, background: soft, foreground: color, size: 34, radius: 11),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(title, style: sans(14, weight: FontWeight.w700))),
          Text(l.coverageDays(l.number(coverage.days)), style: serif(22, color: color)),
        ]),
        const SizedBox(height: AppSpacing.md),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: coverage.progress),
          duration: motion(context, const Duration(milliseconds: 700)),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) => ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            child: LinearProgressIndicator(value: value, minHeight: 7, backgroundColor: soft, color: color),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(spacing: AppSpacing.md, runSpacing: AppSpacing.xs, children: [
          Text(l.coverageTarget(coverage.targetDays), style: sans(11, color: AppColors.muted)),
          Text(met ? l.coverageMet : shortText,
              style: sans(11, weight: FontWeight.w700, color: met ? AppColors.success : AppColors.error)),
        ]),
        const SizedBox(height: AppSpacing.xs),
        Text(stored, style: sans(11, color: AppColors.muted)),
        if (coverage.unknownItems > 0) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(l.coverageUnknownItems(coverage.unknownItems), style: sans(11, color: AppColors.warning)),
        ],
      ]),
    );
  }
}

class _EssentialTile extends StatelessWidget {
  const _EssentialTile({required this.category, required this.count, required this.onTap});

  final SupplyCategory category;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final has = count > 0;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.tile),
      side: const BorderSide(color: AppColors.line),
    );
    return Material(
      color: AppColors.cream,
      shape: shape,
      child: InkWell(
        customBorder: shape,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Row(children: [
            Icon(has ? Icons.check_circle_rounded : supplyIcon(category),
                size: AppIconSizes.md, color: has ? AppColors.success : AppColors.muted),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l.supplyCategoryName(category), style: sans(11, weight: FontWeight.w700)),
                Text(has ? l.essentialCount(count) : l.essentialNone,
                    style: sans(10, color: has ? AppColors.muted : AppColors.error)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _InventoryTile extends StatelessWidget {
  const _InventoryTile({required this.item, required this.today, required this.onTap});

  final InventoryItem item;
  final DateTime today;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final expired = item.isExpired(today);
    final days = item.daysUntilExpiry(today);
    final soon = !expired && days != null && days <= expiringSoonDays;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: Icon(supplyIcon(item.category), color: expired ? AppColors.error : AppColors.primary),
      title: Text(item.name, style: sans(13, weight: FontWeight.w600)),
      subtitle: Wrap(spacing: AppSpacing.sm, runSpacing: 2, crossAxisAlignment: WrapCrossAlignment.center, children: [
        Text('${l.number(item.quantity)} ${l.unit(item.unit)}', style: sans(11, color: AppColors.muted)),
        if (item.daysOfUse != null) Text(l.lastsAbout(l.number(item.daysOfUse!)), style: sans(11, color: AppColors.muted)),
        if (item.expiresOn != null && !expired && !soon)
          Text(l.expiresOn(l.date(item.expiresOn!)), style: sans(11, color: AppColors.muted)),
        if (expired) _Flag(l.expiredTag, AppColors.error),
        if (soon) _Flag('${l.expiresSoonTag} · ${l.date(item.expiresOn!)}', AppColors.warning),
      ]),
      trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFFAAB4AD)),
    );
  }
}

class _Flag extends StatelessWidget {
  const _Flag(this.text, this.color);

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(color: color.withAlpha(30), borderRadius: BorderRadius.circular(AppRadii.pill)),
      child: Text(text, style: sans(10, weight: FontWeight.w700, color: color)),
    );
  }
}
