import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/clock.dart';
import '../../../core/theme.dart';
import '../../../core/validation.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets/form_widgets.dart';
import '../../household/presentation/household_forms.dart';
import '../data/supplies_repository.dart';
import '../domain/supplies.dart';

const _defaultUnit = {
  SupplyCategory.water: SupplyUnit.liters,
  SupplyCategory.food: SupplyUnit.meals,
  SupplyCategory.medicine: SupplyUnit.tablets,
  SupplyCategory.firstAid: SupplyUnit.pieces,
  SupplyCategory.hygiene: SupplyUnit.pieces,
  SupplyCategory.lighting: SupplyUnit.pieces,
  SupplyCategory.other: SupplyUnit.pieces,
};

class SupplyEditorPage extends ConsumerStatefulWidget {
  const SupplyEditorPage({super.key, this.existing, this.initialCategory});

  final InventoryItem? existing;
  final SupplyCategory? initialCategory;

  @override
  ConsumerState<SupplyEditorPage> createState() => _SupplyEditorPageState();
}

class _SupplyEditorPageState extends ConsumerState<SupplyEditorPage> {
  final _form = GlobalKey<FormState>();
  late final InventoryItem? _e = widget.existing;
  late SupplyCategory _category = _e?.category ?? widget.initialCategory ?? SupplyCategory.water;
  late SupplyUnit _unit = _e?.unit ?? _defaultUnit[_category]!;
  late final _name = TextEditingController(text: _e?.name);
  late final _quantity = TextEditingController(text: _e == null ? '' : _fmt(_e.quantity));
  late final _perUnit = TextEditingController(text: _e?.perUnit == null ? '' : _fmt(_e!.perUnit!));
  late final _dailyUse = TextEditingController(text: _e?.dailyUse == null ? '' : _fmt(_e!.dailyUse!));
  late DateTime? _expiresOn = _e?.expiresOn;
  bool _saving = false;

  static String _fmt(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  bool get _needsPerUnit =>
      (_category == SupplyCategory.water && _unit.litersPerUnit == null) ||
      (_category == SupplyCategory.food && _unit != SupplyUnit.meals);

  bool get _usesDailyUse => _category != SupplyCategory.water && _category != SupplyCategory.food;

  @override
  void dispose() {
    for (final c in [_name, _quantity, _perUnit, _dailyUse]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final today = ref.read(clockProvider)();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiresOn ?? today.add(const Duration(days: 180)),
      firstDate: DateTime(today.year - 5),
      lastDate: DateTime(today.year + 15),
    );
    if (picked != null) setState(() => _expiresOn = picked);
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final item = InventoryItem(
      id: _e?.id ?? 's${ref.read(clockProvider)().microsecondsSinceEpoch}',
      name: _name.text.trim(),
      category: _category,
      quantity: Validators.parseNumber(_quantity.text)!,
      unit: _unit,
      perUnit: _needsPerUnit ? Validators.parseNumber(_perUnit.text) : null,
      dailyUse: _usesDailyUse ? Validators.parseNumber(_dailyUse.text) : null,
      expiresOn: _expiresOn,
    );
    await ref.read(suppliesProvider.notifier).upsert(item);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.supplySaved)));
    Navigator.pop(context);
  }

  Future<void> _delete() async {
    final l = context.l10n;
    final ok = await confirmDestructive(
      context,
      title: l.removeSupplyTitle,
      body: l.removeSupplyBody(_e!.name),
      confirmLabel: l.remove,
    );
    if (!ok) return;
    await ref.read(suppliesProvider.notifier).remove(_e.id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final v = Validators(l);
    final unitLabel = l.unit(_unit);

    return FormPage(
      title: _e == null ? l.supplyEditorAdd : l.supplyEditorEdit,
      children: [
        Form(
          key: _form,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            DropdownButtonFormField<SupplyCategory>(
              initialValue: _category,
              isExpanded: true,
              decoration: InputDecoration(labelText: l.supplyCategory),
              items: [
                for (final c in SupplyCategory.values) DropdownMenuItem(value: c, child: Text(l.supplyCategoryName(c), overflow: TextOverflow.ellipsis)),
              ],
              onChanged: (c) => setState(() {
                _category = c!;
                _unit = _defaultUnit[c]!;
              }),
            ),
            gap,
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.sentences,
              validator: (x) => v.required(x, l.supplyName),
              decoration: InputDecoration(labelText: l.supplyName),
            ),
            gap,
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: TextFormField(
                  controller: _quantity,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: v.positiveNumber,
                  decoration: InputDecoration(labelText: l.supplyQuantity),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: DropdownButtonFormField<SupplyUnit>(
                  key: ValueKey(_category),
                  initialValue: _unit,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: l.supplyUnit),
                  items: [
                    for (final u in SupplyUnit.values)
                      DropdownMenuItem(value: u, child: Text(l.unit(u), overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: (u) => setState(() => _unit = u!),
                ),
              ),
            ]),
            if (_needsPerUnit) ...[
              gap,
              TextFormField(
                controller: _perUnit,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: v.optionalPositiveNumber,
                decoration: InputDecoration(
                  labelText: _category == SupplyCategory.water
                      ? l.supplyPerUnitWater(unitLabel)
                      : l.supplyPerUnitFood(unitLabel),
                  helperText: l.supplyPerUnitHelp,
                ),
              ),
            ],
            if (_usesDailyUse) ...[
              gap,
              TextFormField(
                controller: _dailyUse,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: v.optionalPositiveNumber,
                decoration: InputDecoration(labelText: l.supplyDailyUse, helperText: l.supplyDailyUseHelp(unitLabel)),
              ),
            ],
            gap,
            InputDecorator(
              decoration: InputDecoration(labelText: l.supplyExpiry),
              child: Row(children: [
                Expanded(
                  child: Text(
                    _expiresOn == null ? l.supplyExpiryNone : l.date(_expiresOn!),
                    style: sans(13, color: _expiresOn == null ? AppColors.muted : AppColors.ink),
                  ),
                ),
                if (_expiresOn != null)
                  IconButton(
                    tooltip: l.supplyExpiryClear,
                    onPressed: () => setState(() => _expiresOn = null),
                    icon: const Icon(Icons.close_rounded, size: AppIconSizes.md),
                  ),
                IconButton(
                  tooltip: l.supplyExpiryPick,
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_month_outlined, color: AppColors.primary),
                ),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: AppSpacing.xxl),
        LoadingButton(label: l.save, loading: _saving, onPressed: _save),
        if (_e != null) ...[
          const SizedBox(height: AppSpacing.sm),
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: _delete,
            icon: const Icon(Icons.delete_outline_rounded, size: AppIconSizes.md),
            label: Text(l.remove),
          ),
        ],
      ],
    );
  }
}
