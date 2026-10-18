import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/clock.dart';
import '../../../core/theme.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets/character.dart';
import '../../../shared/widgets/common.dart';
import '../../../shared/widgets/form_widgets.dart';
import '../../guidebook/presentation/guidebook_screens.dart';
import '../../household/presentation/household_forms.dart';
import '../../readiness/application/readiness_providers.dart';
import '../../readiness/presentation/recommendation_list.dart';
import '../data/checklist_repository.dart';
import '../domain/checklist.dart';

class PrepareScreen extends ConsumerWidget {
  const PrepareScreen({super.key});

  Future<void> _reset(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final ok = await confirmDestructive(
      context,
      title: l.prepareResetTitle,
      body: l.prepareResetBody,
      confirmLabel: l.prepareResetConfirm,
    );
    if (!ok) return;
    await ref.read(checklistStateProvider.notifier).resetProgress();
    if (context.mounted) showSoon(context, l.prepareResetDone);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final items = ref.watch(checklistItemsProvider);
    final updatedAt = ref.watch(checklistStateProvider).value?.updatedAt;

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const ContextHero(scene: Scene.guide, background: AppColors.amberSoft),
      CardBox(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: items == null
            ? const Padding(padding: EdgeInsets.all(AppSpacing.xl), child: Center(child: CircularProgressIndicator()))
            : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Row(children: [
                  const IconTile(
                    icon: Icons.backpack_outlined,
                    background: AppColors.amberSoft,
                    foreground: AppColors.amber,
                    size: 41,
                    iconSize: 21,
                    radius: 14,
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Eyebrow(l.prepareMiniGuideEyebrow),
                      const SizedBox(height: 4),
                      Text(l.prepareMiniGuideTitle, style: serif(20)),
                    ]),
                  ),
                ]),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Text(l.prepareIntro, style: sans(12, height: 1.5, color: AppColors.muted)),
                ),
                _Progress(items: items, updatedAt: updatedAt),
                const SizedBox(height: AppSpacing.md),
                for (final category in ChecklistCategory.values)
                  if (items.any((i) => i.category == category)) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.xs),
                      child: Text(l.checklistCategory(category).toUpperCase(),
                          style: sans(10, weight: FontWeight.w700, color: AppColors.muted, letterSpacing: 1)),
                    ),
                    for (final item in items.where((i) => i.category == category)) _CheckRow(item: item),
                  ],
                const SizedBox(height: AppSpacing.lg),
                FilledButton.icon(
                  onPressed: () => showChecklistItemEditor(context, ref),
                  icon: const Icon(Icons.add_rounded, size: AppIconSizes.md),
                  label: Text(l.prepareAddItem),
                ),
                const SizedBox(height: AppSpacing.xs),
                TextButton(onPressed: () => _reset(context, ref), child: Text(l.prepareReset)),
              ]),
      ),
      CardBox(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Eyebrow(l.recommendationsEyebrow),
          const SizedBox(height: AppSpacing.xs),
          Text(l.recommendationsTitle, style: serif(20)),
          const SizedBox(height: AppSpacing.sm),
          const RecommendationList(hideChecklistItems: true),
        ]),
      ),
      const GuidebookCard(),
    ]);
  }
}

class _Progress extends ConsumerWidget {
  const _Progress({required this.items, required this.updatedAt});

  final List<ChecklistItemView> items;
  final DateTime? updatedAt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final done = items.where((i) => i.done).length;
    final now = ref.watch(clockProvider)();
    String? saved;
    if (updatedAt != null) {
      final sameDay = updatedAt!.year == now.year && updatedAt!.month == now.month && updatedAt!.day == now.day;
      saved = sameDay ? DateFormat.jm(l.localeName).format(updatedAt!) : l.date(updatedAt!);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text(l.preparePacked(done, items.length), style: sans(13, weight: FontWeight.w700))),
        Text('${items.isEmpty ? 0 : (done * 100 / items.length).round()}%',
            style: sans(13, weight: FontWeight.w700, color: AppColors.primary)),
      ]),
      const SizedBox(height: AppSpacing.sm),
      TweenAnimationBuilder<double>(
        tween: Tween(end: items.isEmpty ? 0 : done / items.length),
        duration: motion(context, AppDurations.slow),
        curve: Curves.easeOutCubic,
        builder: (context, value, _) => ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.pill),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 7,
            backgroundColor: const Color(0xFFE9EEE7),
            color: AppColors.primary,
          ),
        ),
      ),
      if (saved != null) ...[
        const SizedBox(height: AppSpacing.xs),
        Text(l.prepareSavedAt(saved), style: sans(10, color: AppColors.muted)),
      ],
    ]);
  }
}

class _CheckRow extends ConsumerWidget {
  const _CheckRow({required this.item});

  final ChecklistItemView item;

  Future<void> _remove(BuildContext context, WidgetRef ref, String title) async {
    final l = context.l10n;
    final ok = await confirmDestructive(
      context,
      title: l.removeItemTitle,
      body: l.removeItemBody(title),
      confirmLabel: l.remove,
    );
    if (ok) await ref.read(checklistStateProvider.notifier).removeCustom(item.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final title = l.checklistTitle(item);
    final duration = motion(context, AppDurations.normal);
    return Semantics(
      checked: item.done,
      child: InkWell(
        onTap: () => ref.read(checklistStateProvider.notifier).toggle(item, !item.done),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
          child: Row(children: [
            AnimatedContainer(
              duration: duration,
              curve: Curves.easeOutBack,
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: item.done ? AppColors.sage : Colors.transparent,
                border: Border.all(color: item.done ? AppColors.sage : const Color(0xFFCCD5CC), width: 1.5),
                borderRadius: BorderRadius.circular(7),
              ),
              child: AnimatedScale(
                scale: item.done ? 1 : 0,
                duration: duration,
                curve: Curves.easeOutBack,
                child: const Icon(Icons.check_rounded, size: 14, color: Colors.white),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                AnimatedDefaultTextStyle(
                  duration: duration,
                  style: sans(12, color: item.done ? AppColors.muted : AppColors.ink),
                  child: Text(title),
                ),
                if (item.suggestedFor != null || item.isCustom)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: SampleTag(item.isCustom ? l.customTag : l.householdNeed(item.suggestedFor!)),
                  ),
              ]),
            ),
            PopupMenuButton<String>(
              tooltip: l.itemActions(title),
              icon: const Icon(Icons.more_vert_rounded, size: 18, color: AppColors.muted),
              onSelected: (action) => action == 'edit'
                  ? showChecklistItemEditor(context, ref, existing: item, currentTitle: title)
                  : _remove(context, ref, title),
              itemBuilder: (_) => [
                PopupMenuItem(value: 'edit', child: Text(l.edit)),
                if (item.isCustom) PopupMenuItem(value: 'remove', child: Text(l.remove)),
              ],
            ),
          ]),
        ),
      ),
    );
  }
}

Future<void> showChecklistItemEditor(
  BuildContext context,
  WidgetRef ref, {
  ChecklistItemView? existing,
  String? currentTitle,
}) async {
  final result = await showModalBottomSheet<(String, ChecklistCategory)>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _ItemEditor(
      initialTitle: currentTitle ?? '',
      initialCategory: existing?.category ?? ChecklistCategory.waterFood,
      editing: existing != null,
      categoryLocked: existing != null && !existing.isCustom,
    ),
  );
  if (result == null) return;
  final controller = ref.read(checklistStateProvider.notifier);
  if (existing == null) {
    await controller.addCustom(result.$1, result.$2);
  } else {
    await controller.rename(existing, result.$1, result.$2);
  }
}

class _ItemEditor extends StatefulWidget {
  const _ItemEditor({
    required this.initialTitle,
    required this.initialCategory,
    required this.editing,
    required this.categoryLocked,
  });

  final String initialTitle;
  final ChecklistCategory initialCategory;
  final bool editing;
  final bool categoryLocked;

  @override
  State<_ItemEditor> createState() => _ItemEditorState();
}

class _ItemEditorState extends State<_ItemEditor> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.initialTitle);
  late ChecklistCategory _category = widget.initialCategory;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    // Scrollable so the sheet still fits on small phones with large text or the keyboard open.
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        AppSpacing.xxl + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Form(
        key: _form,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(widget.editing ? l.itemEditorEdit : l.itemEditorAdd, style: serif(20)),
          const SizedBox(height: AppSpacing.lg),
          TextFormField(
            controller: _title,
            autofocus: !widget.editing,
            textCapitalization: TextCapitalization.sentences,
            validator: (x) => (x == null || x.trim().isEmpty) ? l.itemNameRequired : null,
            decoration: InputDecoration(labelText: l.itemEditorName),
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<ChecklistCategory>(
            initialValue: _category,
            isExpanded: true,
            decoration: InputDecoration(labelText: l.itemEditorCategory),
            items: [
              for (final c in ChecklistCategory.values)
                DropdownMenuItem(value: c, child: Text(l.checklistCategory(c), overflow: TextOverflow.ellipsis)),
            ],
            onChanged: widget.categoryLocked ? null : (c) => setState(() => _category = c!),
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton(
            onPressed: () {
              if (_form.currentState!.validate()) Navigator.pop(context, (_title.text.trim(), _category));
            },
            child: Text(l.save),
          ),
        ]),
      ),
    );
  }
}
