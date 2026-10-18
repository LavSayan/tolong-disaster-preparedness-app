import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../core/validation.dart';
import '../../../l10n/l10n.dart';
import '../../safe_places/presentation/barangay_widgets.dart';
import '../domain/models.dart';

/// Name / age / barangay / language fields shared by onboarding and profile editing.
class ProfileFields extends StatelessWidget {
  const ProfileFields({
    super.key,
    required this.name,
    required this.age,
    required this.barangay,
    required this.language,
    required this.onLanguageChanged,
  });

  final TextEditingController name;
  final TextEditingController age;
  final TextEditingController barangay;
  final AppLanguage language;
  final ValueChanged<AppLanguage> onLanguageChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final v = Validators(l);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      TextFormField(
        controller: name,
        textCapitalization: TextCapitalization.words,
        validator: v.fullName,
        decoration: InputDecoration(labelText: l.name),
      ),
      const SizedBox(height: AppSpacing.md),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: 96,
          child: TextFormField(
            controller: age,
            keyboardType: TextInputType.number,
            validator: v.age,
            decoration: InputDecoration(labelText: l.age),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: BarangayField(controller: barangay)),
      ]),
      const SizedBox(height: AppSpacing.lg),
      Text(l.preferredLanguage, style: sans(12, weight: FontWeight.w600, color: AppColors.muted)),
      const SizedBox(height: AppSpacing.sm),
      LanguagePicker(value: language, onChanged: onLanguageChanged),
    ]);
  }
}

class LanguagePicker extends StatelessWidget {
  const LanguagePicker({super.key, required this.value, required this.onChanged});

  final AppLanguage value;
  final ValueChanged<AppLanguage> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<AppLanguage>(
      segments: [for (final l in AppLanguage.values) ButtonSegment(value: l, label: Text(l.label))],
      selected: {value},
      onSelectionChanged: (s) => onChanged(s.first),
      showSelectedIcon: false,
    );
  }
}

class CounterRow extends StatelessWidget {
  const CounterRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 30,
    this.caption,
  });

  final String label;
  final String? caption;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: sans(13, weight: FontWeight.w600)),
            if (caption != null) Text(caption!, style: sans(11, color: AppColors.muted)),
          ]),
        ),
        IconButton.outlined(
          tooltip: l.fewerOf(label),
          onPressed: value > min ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove_rounded, size: AppIconSizes.md),
        ),
        SizedBox(
          width: 40,
          child: Text('$value', textAlign: TextAlign.center, style: sans(16, weight: FontWeight.w700)),
        ),
        IconButton.outlined(
          tooltip: l.moreOf(label),
          onPressed: value < max ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add_rounded, size: AppIconSizes.md),
        ),
      ]),
    );
  }
}

/// Household composition editor. Optional answers (pets, assistance) can be left unanswered.
class HouseholdFields extends StatelessWidget {
  const HouseholdFields({super.key, required this.household, required this.assistance, required this.onChanged});

  final HouseholdProfile household;
  final TextEditingController assistance;
  final ValueChanged<HouseholdProfile> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final h = household;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      CounterRow(
        label: l.adults,
        caption: l.adultsCaption,
        value: h.adults,
        min: 1,
        onChanged: (x) => onChanged(h.copyWith(adults: x)),
      ),
      CounterRow(
        label: l.children,
        caption: l.childrenCaption,
        value: h.children,
        onChanged: (x) => onChanged(h.copyWith(children: x)),
      ),
      CounterRow(
        label: l.seniors,
        caption: l.seniorsCaption,
        value: h.seniors,
        onChanged: (x) => onChanged(h.copyWith(seniors: x)),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Text(l.householdSizeLabel(h.size), style: sans(12, weight: FontWeight.w700, color: AppColors.primary)),
      ),
      const Divider(color: AppColors.line),
      const SizedBox(height: AppSpacing.sm),
      Text(l.petsQuestion, style: sans(12, weight: FontWeight.w600, color: AppColors.muted)),
      const SizedBox(height: AppSpacing.sm),
      Wrap(spacing: AppSpacing.sm, children: [
        for (final (label, value) in [(l.yes, true), (l.no, false), (l.preferNotToSay, null)])
          ChoiceChip(
            label: Text(label),
            selected: h.hasPets == value,
            onSelected: (_) => onChanged(h.copyWith(hasPets: () => value)),
          ),
      ]),
      const SizedBox(height: AppSpacing.lg),
      TextFormField(
        controller: assistance,
        maxLines: 2,
        maxLength: 200,
        decoration: InputDecoration(labelText: l.assistanceLabel, helperText: l.assistanceHelper, helperMaxLines: 2),
      ),
    ]);
  }
}

/// Bottom sheet for adding or editing one emergency contact. Returns null when cancelled.
Future<EmergencyContact?> showContactEditor(BuildContext context, {EmergencyContact? existing}) {
  return showModalBottomSheet<EmergencyContact>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _ContactEditor(existing: existing),
  );
}

class _ContactEditor extends StatefulWidget {
  const _ContactEditor({this.existing});

  final EmergencyContact? existing;

  @override
  State<_ContactEditor> createState() => _ContactEditorState();
}

class _ContactEditorState extends State<_ContactEditor> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.existing?.name);
  late final _relationship = TextEditingController(text: widget.existing?.relationship);
  late final _phone = TextEditingController(text: widget.existing?.phone);

  @override
  void dispose() {
    _name.dispose();
    _relationship.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    Navigator.pop(
      context,
      EmergencyContact(
        id: widget.existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        name: _name.text.trim(),
        relationship: _relationship.text.trim(),
        phone: Validators.normalizePhone(_phone.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final v = Validators(l);
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
          Text(widget.existing == null ? l.contactAddTitle : l.contactEditTitle, style: serif(20)),
          const SizedBox(height: AppSpacing.lg),
          TextFormField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            validator: (x) => v.required(x, l.name),
            decoration: InputDecoration(labelText: l.name),
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _relationship,
            textCapitalization: TextCapitalization.sentences,
            validator: (x) => v.required(x, l.relationship),
            decoration: InputDecoration(labelText: l.relationship, hintText: l.relationshipHint),
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            validator: v.phone,
            decoration: InputDecoration(labelText: l.phone, hintText: l.phoneHint),
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton(onPressed: _save, child: Text(l.saveContact)),
        ]),
      ),
    );
  }
}

class ContactTile extends StatelessWidget {
  const ContactTile({super.key, required this.contact, required this.onEdit, required this.onDelete});

  final EmergencyContact contact;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: AppColors.terracottaSoft,
        foregroundColor: AppColors.terracotta,
        child: Text(contact.name.isEmpty ? '?' : contact.name[0].toUpperCase()),
      ),
      title: Text(contact.name, style: sans(13, weight: FontWeight.w600)),
      subtitle: Text('${contact.relationship} · ${contact.phone}', style: sans(11, color: AppColors.muted)),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        IconButton(tooltip: l.editNamed(contact.name), onPressed: onEdit, icon: const Icon(Icons.edit_outlined, size: 20)),
        IconButton(
          tooltip: l.removeNamed(contact.name),
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.error),
        ),
      ]),
    );
  }
}

/// Generic destructive-action confirmation used across the app.
Future<bool> confirmDestructive(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.l10n.cancel)),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.error, minimumSize: const Size(96, 44)),
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return ok ?? false;
}

Future<bool> confirmRemoveContact(BuildContext context, EmergencyContact contact) {
  final l = context.l10n;
  return confirmDestructive(
    context,
    title: l.removeContactTitle,
    body: l.removeContactBody(contact.name),
    confirmLabel: l.remove,
  );
}
