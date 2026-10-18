import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets/animations.dart';
import '../../../shared/widgets/common.dart';
import '../../../shared/widgets/form_widgets.dart';
import '../data/guidebook_repository.dart';
import '../domain/guidebook.dart';

IconData guideIcon(String key) => switch (key) {
      'flood' => Icons.flood_outlined,
      'earthquake' => Icons.vibration_rounded,
      'fire' => Icons.local_fire_department_outlined,
      'typhoon' => Icons.cyclone_outlined,
      'first_aid' => Icons.medical_services_outlined,
      _ => Icons.menu_book_outlined,
    };

(Color, Color) guideColors(String accent) => switch (accent) {
      'blue' => (AppColors.blueSoft, AppColors.blue),
      'amber' => (AppColors.amberSoft, AppColors.amber),
      'terracotta' || 'rose' => (AppColors.terracottaSoft, AppColors.terracotta),
      _ => (AppColors.sageSoft, AppColors.sage),
    };

/// Compact entry point shown on the Prepare screen.
class GuidebookCard extends ConsumerWidget {
  const GuidebookCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final categories = ref.watch(guidebookProvider).value ?? const <GuideCategory>[];
    return CardBox(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Eyebrow(l.guidebookEyebrow),
              const SizedBox(height: AppSpacing.xs),
              Text(l.guidebookTitle, style: serif(20)),
            ]),
          ),
          TextButton(onPressed: () => context.push('/guidebook'), child: Text(l.guidebookSeeAll)),
        ]),
        const SizedBox(height: AppSpacing.md),
        Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [
          for (final c in categories)
            ActionChip(
              avatar: Icon(guideIcon(c.icon), size: AppIconSizes.md, color: guideColors(c.accent).$2),
              label: Text(c.title.of(l.localeName)),
              backgroundColor: guideColors(c.accent).$1,
              side: BorderSide.none,
              onPressed: () => context.push('/guidebook/${c.id}'),
            ),
        ]),
      ]),
    );
  }
}

class GuidebookScreen extends ConsumerWidget {
  const GuidebookScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final async = ref.watch(guidebookProvider);
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        surfaceTintColor: Colors.transparent,
        title: Text(l.guidebookTitle, style: serif(20)),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: InlineMessage(l.couldNotLoad, tone: MessageTone.error)),
        data: (categories) => ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.xxxl),
          children: [
            Text(l.guidebookIntro, style: sans(13, height: 1.45, color: AppColors.muted)),
            const SizedBox(height: AppSpacing.lg),
            for (final (i, c) in categories.indexed)
              FadeSlideIn(
                delay: Duration(milliseconds: 50 * i),
                child: _CategoryTile(category: c),
              ),
          ],
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category});

  final GuideCategory category;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final (soft, strong) = guideColors(category.accent);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.card),
      side: const BorderSide(color: AppColors.line),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Pressable(
        child: Material(
          color: AppColors.cream,
          shape: shape,
          child: InkWell(
            customBorder: shape,
            onTap: () => context.push('/guidebook/${category.id}'),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(children: [
                IconTile(icon: guideIcon(category.icon), background: soft, foreground: strong, size: 48, iconSize: 24, radius: 16),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(category.title.of(l.localeName), style: serif(19)),
                    const SizedBox(height: 2),
                    Text(category.summary.of(l.localeName), style: sans(12, color: AppColors.muted)),
                    const SizedBox(height: AppSpacing.xs),
                    Text(l.guideSectionCount(category.sections.length),
                        style: sans(11, weight: FontWeight.w700, color: category.hasContent ? strong : AppColors.warning)),
                  ]),
                ),
                const Icon(Icons.chevron_right_rounded, color: Color(0xFFAAB4AD)),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class GuideCategoryScreen extends ConsumerWidget {
  const GuideCategoryScreen({super.key, required this.categoryId});

  final String categoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final categories = ref.watch(guidebookProvider).value;
    final category = categories?.where((c) => c.id == categoryId).firstOrNull;
    final lang = l.localeName;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        surfaceTintColor: Colors.transparent,
        title: Text(category?.title.of(lang) ?? l.guidebookTitle, style: serif(20)),
      ),
      body: categories == null
          ? const Center(child: CircularProgressIndicator())
          : category == null
              ? Center(child: InlineMessage(l.couldNotLoad, tone: MessageTone.error))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.xxxl),
                  children: [
                    _Header(category: category),
                    if (!category.hasContent)
                      _EmptyGuide(category: category)
                    else
                      for (final phase in GuidePhase.values)
                        for (final s in category.sections.where((x) => x.phase == phase)) _SectionCard(section: s),
                  ],
                ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.category});

  final GuideCategory category;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final (soft, strong) = guideColors(category.accent);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(color: soft, borderRadius: BorderRadius.circular(AppRadii.hero)),
      child: Row(children: [
        Icon(guideIcon(category.icon), size: 44, color: strong),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(category.title.of(l.localeName), style: serif(26)),
            const SizedBox(height: AppSpacing.xs),
            Text(category.summary.of(l.localeName), style: sans(13, color: AppColors.ink)),
            const SizedBox(height: AppSpacing.sm),
            Row(children: [
              const Icon(Icons.offline_pin_outlined, size: AppIconSizes.sm, color: AppColors.success),
              const SizedBox(width: AppSpacing.xs),
              Flexible(child: Text(l.guideOffline, style: sans(11, weight: FontWeight.w600, color: AppColors.success))),
            ]),
          ]),
        ),
      ]),
    );
  }
}

class _EmptyGuide extends StatelessWidget {
  const _EmptyGuide({required this.category});

  final GuideCategory category;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final (soft, strong) = guideColors(category.accent);
    return CardBox(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(color: soft, shape: BoxShape.circle),
          child: Icon(Icons.auto_stories_outlined, size: 34, color: strong),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(l.guideComingSoon(category.title.of(l.localeName)), textAlign: TextAlign.center, style: serif(19)),
        const SizedBox(height: AppSpacing.sm),
        Text(l.guideVisualSoon, textAlign: TextAlign.center, style: sans(12, height: 1.45, color: AppColors.muted)),
        const SizedBox(height: AppSpacing.lg),
        Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, alignment: WrapAlignment.center, children: [
          for (final p in [GuidePhase.before, GuidePhase.during, GuidePhase.after])
            Chip(
              label: Text(_phaseLabel(l, p)),
              backgroundColor: AppColors.canvas,
              side: const BorderSide(color: AppColors.line),
            ),
        ]),
      ]),
    );
  }
}

String _phaseLabel(AppLocalizations l, GuidePhase p) => switch (p) {
      GuidePhase.before => l.guideBefore,
      GuidePhase.during => l.guideDuring,
      GuidePhase.after => l.guideAfter,
      GuidePhase.general => l.guideGeneral,
    };

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.section});

  final GuideSection section;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final lang = l.localeName;
    return CardBox(
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        childrenPadding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
        title: Text(section.title.of(lang), style: sans(14, weight: FontWeight.w700)),
        subtitle: Text(_phaseLabel(l, section.phase), style: sans(11, color: AppColors.muted)),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (i, s) in section.steps.indexed) ...[
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              CircleAvatar(
                radius: 11,
                backgroundColor: AppColors.sageSoft,
                child: Text('${i + 1}', style: sans(11, weight: FontWeight.w700, color: AppColors.sage)),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(s.text.of(lang), style: sans(13, height: 1.45))),
            ]),
            if (s.image != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm, left: 30),
                child: ClipRRect(borderRadius: BorderRadius.circular(AppRadii.md), child: Image.asset(s.image!)),
              ),
            const SizedBox(height: AppSpacing.md),
          ],
          Text(l.guideSource(section.source.name), style: sans(10, color: AppColors.muted)),
        ],
      ),
    );
  }
}
