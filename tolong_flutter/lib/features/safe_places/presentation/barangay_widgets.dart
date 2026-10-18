import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../../../l10n/l10n.dart';
import '../data/qc_area_repository.dart';
import '../domain/qc_area.dart';

/// Searchable list of Quezon City's 142 barangays. Returns the chosen one, or null.
Future<Barangay?> showBarangaySearch(BuildContext context) => showModalBottomSheet<Barangay>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _BarangaySearchSheet(),
    );

class _BarangaySearchSheet extends ConsumerStatefulWidget {
  const _BarangaySearchSheet();

  @override
  ConsumerState<_BarangaySearchSheet> createState() => _BarangaySearchSheetState();
}

class _BarangaySearchSheetState extends ConsumerState<_BarangaySearchSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final all = ref.watch(barangaysProvider).value ?? const <Barangay>[];
    final hits = searchBarangays(all, _query);
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.8,
      child: Padding(
        padding: EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, MediaQuery.viewInsetsOf(context).bottom),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(l.brgySearch, style: serif(20)),
          const SizedBox(height: AppSpacing.md),
          TextField(
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: l.brgySearchHint,
              prefixIcon: const Icon(Icons.search_rounded),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: hits.isEmpty
                ? Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xl),
                    child: Text(l.brgyNoMatch, textAlign: TextAlign.center, style: sans(13, color: AppColors.muted)),
                  )
                : ListView.builder(
                    itemCount: hits.length,
                    itemBuilder: (_, i) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.location_city_outlined, color: AppColors.primary),
                      title: Text(hits[i].name, style: sans(13, weight: FontWeight.w600)),
                      onTap: () => Navigator.pop(context, hits[i]),
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Text(l.brgySource, style: sans(10, color: AppColors.muted)),
          ),
        ]),
      ),
    );
  }
}

/// Barangay form field restricted to Quezon City's official list, with type-ahead suggestions.
class BarangayField extends ConsumerStatefulWidget {
  const BarangayField({super.key, required this.controller, this.textInputAction = TextInputAction.next});

  final TextEditingController controller;
  final TextInputAction textInputAction;

  @override
  ConsumerState<BarangayField> createState() => _BarangayFieldState();
}

class _BarangayFieldState extends ConsumerState<BarangayField> {
  final _focus = FocusNode();

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final all = ref.watch(barangaysProvider).value;
    final controller = widget.controller;
    final textInputAction = widget.textInputAction;

    return Autocomplete<Barangay>(
      textEditingController: controller,
      focusNode: _focus,
      displayStringForOption: (b) => b.name,
      optionsBuilder: (value) => value.text.trim().isEmpty ? const [] : searchBarangays(all ?? const [], value.text).take(8),
      onSelected: (b) => controller.text = b.name,
      fieldViewBuilder: (context, textController, focusNode, onSubmit) => TextFormField(
        controller: textController,
        focusNode: focusNode,
        textCapitalization: TextCapitalization.words,
        textInputAction: textInputAction,
        onFieldSubmitted: (_) => onSubmit(),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return l.valRequired(l.barangay);
          // While the list is still loading, don't block the form.
          if (all != null && findBarangay(all, v) == null) return l.brgyInvalid;
          return null;
        },
        decoration: InputDecoration(labelText: l.barangay, helperText: l.barangayHelper),
      ),
      optionsViewBuilder: (context, onSelected, options) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          color: AppColors.surface,
          elevation: 4,
          borderRadius: BorderRadius.circular(AppRadii.md),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 260, maxWidth: 320),
            child: ListView(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              children: [
                for (final b in options)
                  ListTile(dense: true, title: Text(b.name, style: sans(13)), onTap: () => onSelected(b)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Canonical spelling of a typed barangay ("sto nino" → "Santo Niño"), or the input unchanged.
String canonicalBarangay(List<Barangay>? all, String input) =>
    (all == null ? null : findBarangay(all, input))?.name ?? input.trim();
