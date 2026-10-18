import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/clock.dart';
import '../../../core/theme.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets/animations.dart';
import '../../../shared/widgets/character.dart';
import '../../../shared/widgets/common.dart';
import '../../../shared/widgets/form_widgets.dart';
import '../../alerts/presentation/alert_card.dart';
import '../../household/data/household_repository.dart';
import '../../readiness/application/readiness_providers.dart';
import '../../readiness/domain/readiness.dart';
import '../../readiness/presentation/readiness_ring.dart';

String greetingFor(AppLocalizations l, DateTime now) => switch (now.hour) {
      < 12 => l.greetingMorning,
      < 18 => l.greetingAfternoon,
      _ => l.greetingEvening,
    };

final _alertDismissedProvider = NotifierProvider<_AlertDismissed, bool>(_AlertDismissed.new);

class _AlertDismissed extends Notifier<bool> {
  @override
  bool build() => false;

  void dismiss() => state = true;
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final firstName = ref.watch(householdProvider).value?.profile?.firstName ?? '';
    final greeting = greetingFor(l, ref.watch(clockProvider)());
    final title = firstName.isEmpty ? l.greetingNoName(greeting) : l.greetingWithName(greeting, firstName);
    final report = ref.watch(readinessProvider);
    final recCount = ref.watch(recommendationsProvider).length;
    final checklist = ref.watch(checklistItemsProvider);
    final household = ref.watch(householdProvider).value?.household;

    final toPack = checklist?.where((i) => !i.done).length;
    final water = report?.supplies.water;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 14),
          constraints: const BoxConstraints(minHeight: 212),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(color: AppColors.sageSoft, borderRadius: BorderRadius.circular(AppRadii.hero)),
          child: Stack(children: [
            const Positioned(right: -7, bottom: -10, child: Character(scene: Scene.home)),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 18, 48),
              child: FractionallySizedBox(
                widthFactor: 0.58,
                alignment: Alignment.topLeft,
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Eyebrow(l.sceneHomeEyebrow),
                  const SizedBox(height: 9),
                  Text(title, style: serif(29, height: 1.05, tracking: -0.05)),
                  const SizedBox(height: 8),
                  Text(l.sceneHomeSub, style: sans(13, height: 1.45, color: const Color(0xFF5E7166))),
                ]),
              ),
            ),
            Positioned(
              left: 20,
              right: 150,
              bottom: 18,
              child: Row(children: [
                const Icon(Icons.check_rounded, size: 14, color: Color(0xFF4F6B57)),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(l.homeNextStepsCount(recCount),
                      style: sans(11, weight: FontWeight.w600, color: const Color(0xFF4F6B57))),
                ),
              ]),
            ),
          ]),
        ),
        if (!ref.watch(_alertDismissedProvider))
          AlertCard(
            onDismiss: () => ref.read(_alertDismissedProvider.notifier).dismiss(),
            onMap: () => context.go('/safe-places'),
          ),
        if (report != null) FadeSlideIn(child: _StatusCard(report: report)),
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 7, 2, 12),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Eyebrow(l.nextStepsEyebrow),
                const SizedBox(height: 3),
                Text(l.nextStepsTitle, style: serif(22)),
              ]),
            ),
            IconButton(
              tooltip: l.nextStepsHelp,
              style: IconButton.styleFrom(backgroundColor: AppColors.cream, side: const BorderSide(color: AppColors.line)),
              onPressed: () => showSoon(context, l.nextStepsHelpText),
              icon: const Icon(Icons.help_outline_rounded, size: 19, color: Color(0xFF5C6B63)),
            ),
          ]),
        ),
        Row(children: [
          Expanded(
            child: _QuickAction(
              icon: Icons.backpack_outlined,
              label: l.quickGoBag,
              meta: toPack == null ? '' : l.quickGoBagMeta(toPack),
              background: AppColors.sageSoft,
              foreground: AppColors.sage,
              onTap: () => context.go('/prepare'),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: _QuickAction(
              icon: Icons.explore_outlined,
              label: l.quickSafePlaces,
              meta: l.quickSafePlacesMeta,
              background: AppColors.blueSoft,
              foreground: AppColors.blue,
              onTap: () => context.go('/safe-places'),
            ),
          ),
        ]),
        const SizedBox(height: 9),
        Row(children: [
          Expanded(
            child: _QuickAction(
              icon: Icons.inventory_outlined,
              label: l.quickSupplies,
              meta: water == null || water.available <= 0
                  ? l.quickSuppliesEmpty
                  : l.quickSuppliesWater(l.number(water.days)),
              background: AppColors.amberSoft,
              foreground: AppColors.amber,
              onTap: () => context.push('/supplies'),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: _QuickAction(
              icon: Icons.group_outlined,
              label: l.quickHousehold,
              meta: household == null
                  ? l.quickHouseholdSetUp
                  : household.hasPets == true
                      ? l.householdPeopleWithPets(household.size)
                      : l.householdPeople(household.size),
              background: AppColors.terracottaSoft,
              foreground: AppColors.terracotta,
              onTap: () => context.push('/profile'),
            ),
          ),
        ]),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.lock_outline_rounded, size: 14, color: Color(0xFF5C6B63)),
            const SizedBox(width: 5),
            Flexible(child: Text(l.homeFooter, style: sans(10, color: const Color(0xFF5C6B63)))),
          ]),
        ),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.report});

  final ReadinessReport report;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final water = report.supplies.water;
    return CardBox(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Eyebrow(l.householdStatus),
        const SizedBox(height: 13),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.readinessHeadline(report.score), style: serif(24)),
              const SizedBox(height: 5),
              Text(
                water.available > 0
                    ? l.waterCoverageSummary(report.supplies.householdSize, l.number(water.days))
                    : l.readinessNoWater,
                style: sans(12, height: 1.4, color: AppColors.muted),
              ),
            ]),
          ),
          const SizedBox(width: AppSpacing.md),
          ReadinessRing(score: report.score),
        ]),
        const SizedBox(height: 17),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: report.score / 100),
          duration: motion(context, const Duration(milliseconds: 900)),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) => ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 7,
              backgroundColor: const Color(0xFFE9EEE7),
              color: AppColors.sage,
            ),
          ),
        ),
        const SizedBox(height: 11),
        InkWell(
          onTap: () => context.push('/readiness'),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Flexible(
                child: Text(l.viewReadiness, style: sans(12, weight: FontWeight.w700, color: AppColors.sage)),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.sage),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.meta,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String meta;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.tile),
      side: const BorderSide(color: AppColors.line),
    );
    return Pressable(
      child: Material(
        color: AppColors.cream,
        shape: shape,
        child: InkWell(
          customBorder: shape,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 84),
            child: Stack(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(11, 13, 24, 13),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  IconTile(icon: icon, background: background, foreground: foreground, size: 29, radius: 10),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const SizedBox(height: 2),
                      Text(label, style: sans(11, weight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(meta, style: sans(10, color: const Color(0xFF5C6B63))),
                    ]),
                  ),
                ]),
              ),
              const Positioned(
                right: 8,
                bottom: 11,
                child: Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFFAAB4AD)),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
