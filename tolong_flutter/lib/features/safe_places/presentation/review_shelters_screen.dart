import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets/common.dart';
import '../../../shared/widgets/form_widgets.dart';
import '../application/submission_controllers.dart';
import '../data/hazard_bands_repository.dart';
import '../data/qc_area_repository.dart';
import '../domain/evacuation_center.dart';
import '../domain/qc_area.dart';
import '../domain/shelter_submission.dart';

/// The reviewers' queue (government officials and admins): pending submissions with
/// their exposure preview and the corrections/decisions. Every action runs through the
/// server RPC, which revalidates and gates on the role; this screen only guides the
/// user and never publishes on its own authority.
class ReviewSheltersScreen extends ConsumerWidget {
  const ReviewSheltersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final queue = ref.watch(pendingQueueProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        surfaceTintColor: Colors.transparent,
        title: Text(l.reviewTitle, style: serif(20)),
      ),
      body: queue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [InlineMessage(l.couldNotLoad, tone: MessageTone.error)],
        ),
        data: (pending) => pending.isEmpty
            ? ListView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                children: [InlineMessage(l.reviewEmpty)],
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.xxxl),
                children: [for (final s in pending) _ReviewCard(submission: s)],
              ),
      ),
    );
  }
}

enum _ReviewAction { none, editing, approving, rejecting }

/// A short, non-identifying tail of the submitter's account id for the reviewer UI.
String shortId(String id) => id.length <= 6 ? id : id.substring(id.length - 6);

class _ReviewCard extends ConsumerStatefulWidget {
  const _ReviewCard({required this.submission});

  final ShelterSubmission submission;

  @override
  ConsumerState<_ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends ConsumerState<_ReviewCard> {
  final _form = GlobalKey<FormState>();
  final _reason = TextEditingController();
  final _name = TextEditingController();
  final _lat = TextEditingController();
  final _lng = TextEditingController();
  final _address = TextEditingController();
  final _accessibility = TextEditingController();
  final _capacity = TextEditingController();
  final _facilities = TextEditingController();
  late String _barangay;
  late FacilityType _facilityType;
  _ReviewAction _acting = _ReviewAction.none;

  @override
  void initState() {
    super.initState();
    final d = widget.submission.draft;
    _name.text = d.name;
    _lat.text = d.location.lat.toStringAsFixed(6);
    _lng.text = d.location.lng.toStringAsFixed(6);
    _address.text = d.address ?? '';
    _accessibility.text = d.accessibility ?? '';
    _capacity.text = d.capacity?.toString() ?? '';
    _facilities.text = d.facilities.join(', ');
    _barangay = d.barangay;
    _facilityType = d.facilityType;
  }

  @override
  void dispose() {
    for (final c in [_reason, _name, _lat, _lng, _address, _accessibility, _capacity, _facilities]) {
      c.dispose();
    }
    super.dispose();
  }

  /// The corrected draft from the form, or null when the coordinate fields don't parse.
  ShelterSubmissionDraft? draft() {
    final lat = double.tryParse(_lat.text.trim().replaceAll(',', '.'));
    final lng = double.tryParse(_lng.text.trim().replaceAll(',', '.'));
    if (lat == null || lng == null || _name.text.trim().isEmpty) return null;
    return ShelterSubmissionDraft(
      name: _name.text,
      location: GeoPoint(lat, lng),
      facilityType: _facilityType,
      barangay: _barangay,
      address: _address.text,
      accessibility: _accessibility.text,
      capacity: int.tryParse(_capacity.text.trim()),
      facilities: [
        for (final f in _facilities.text.split(','))
          if (f.trim().isNotEmpty) f.trim(),
      ],
    );
  }

  Future<void> _saveEdits() async {
    final l = context.l10n;
    if (!_form.currentState!.validate()) return;
    final corrected = draft();
    if (corrected == null) {
      showMessage(context, l.subErrInvalidFields);
      return;
    }
    setState(() => _acting = _ReviewAction.editing);
    try {
      await ref.read(submitShelterServiceProvider).applyEdit(widget.submission.id, corrected);
      ref.invalidate(pendingQueueProvider);
      if (mounted) showMessage(context, l.reviewEditsSaved);
    } on SubmissionFailure catch (f) {
      if (mounted) showMessage(context, l.submissionError(f.code));
    } finally {
      if (mounted) setState(() => _acting = _ReviewAction.none);
    }
  }

  Future<void> _decide(bool approve) async {
    final l = context.l10n;
    if (!_form.currentState!.validate()) return;
    String? reason;
    if (!approve) {
      reason = await _askReason();
      if (reason == null || !mounted) return;
    }
    final corrected = draft();
    if (corrected == null) {
      showMessage(context, l.subErrInvalidFields);
      return;
    }
    setState(() => _acting = approve ? _ReviewAction.approving : _ReviewAction.rejecting);
    try {
      final service = ref.read(submitShelterServiceProvider);
      if (approve) {
        await service.approve(widget.submission.id, edits: corrected);
      } else {
        await service.reject(widget.submission.id, reason: reason!.trim());
      }
      ref.invalidate(pendingQueueProvider);
      ref.invalidate(mySubmissionsProvider);
      if (mounted) {
        showMessage(context, approve ? l.reviewApproved : l.reviewRejected);
      }
    } on SubmissionFailure catch (f) {
      if (mounted) showMessage(context, l.submissionError(f.code));
    } finally {
      if (mounted) setState(() => _acting = _ReviewAction.none);
    }
  }

  Future<String?> _askReason() async {
    final l = context.l10n;
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.reviewReasonLabel),
        content: TextFormField(
          controller: _reason,
          autofocus: true,
          maxLines: 3,
          maxLength: 300,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: (v) => (v == null || v.trim().isEmpty) ? l.reviewReasonRequired : null,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(l.cancel)),
          FilledButton(
            onPressed: () {
              final v = _reason.text.trim();
              if (v.isEmpty || v.length > 300) return;
              Navigator.pop(dialogContext, v);
            },
            child: Text(l.reviewReject),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final d = widget.submission.draft;
    final barangays = ref.watch(barangaysProvider).value ?? const <Barangay>[];
    final exposure = ref.watch(hazardBandsProvider).value?.exposureAt(d.location);
    final busy = _acting != _ReviewAction.none;

    return CardBox(
      child: Form(
        key: _form,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [Eyebrow(l.subStatusPending.toUpperCase())],
          ),
          const SizedBox(height: 4),
          Text(
            l.reviewSubmittedBy(shortId(widget.submission.submittedBy)),
            style: sans(11, color: AppColors.muted),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            exposure == null ? l.rankExposureUnknown : l.rankExposureValue(l.number(exposure.exposure)),
            style: sans(12, height: 1.45, color: exposure == null ? AppColors.terracotta : AppColors.muted),
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(controller: _name, decoration: InputDecoration(labelText: l.submitName)),
          gap,
          Row(children: [
            Expanded(child: TextFormField(controller: _lat, decoration: InputDecoration(labelText: l.submitLat))),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: TextFormField(controller: _lng, decoration: InputDecoration(labelText: l.submitLng))),
          ]),
          gap,
          DropdownButtonFormField<FacilityType>(
            initialValue: _facilityType,
            isExpanded: true,
            decoration: InputDecoration(labelText: l.submitFacility),
            items: [
              for (final t in FacilityType.values)
                DropdownMenuItem(value: t, child: Text(l.facilityType(t), overflow: TextOverflow.ellipsis)),
            ],
            onChanged: (v) => setState(() => _facilityType = v ?? _facilityType),
          ),
          gap,
          DropdownButtonFormField<Barangay>(
            // Initial value is the only barangay whose exact name matches; server FKs
            // make that guaranteed to exist in the asset.
            initialValue: barangays.where((b) => b.name == _barangay).firstOrNull,
            isExpanded: true,
            decoration: InputDecoration(labelText: l.submitBarangay),
            items: [
              for (final b in barangays) DropdownMenuItem(value: b, child: Text(b.name, overflow: TextOverflow.ellipsis)),
            ],
            onChanged: (v) => setState(() => _barangay = v?.name ?? _barangay),
          ),
          gap,
          TextFormField(controller: _address, decoration: InputDecoration(labelText: l.submitAddress)),
          gap,
          TextFormField(controller: _accessibility, decoration: InputDecoration(labelText: l.submitAccessibility)),
          gap,
          TextFormField(
            controller: _capacity,
            decoration: InputDecoration(labelText: l.submitCapacity),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          gap,
          TextFormField(controller: _facilities, decoration: InputDecoration(labelText: l.submitFacilities)),
          gap,
          TextButton(
            onPressed: busy ? null : _saveEdits,
            child: Text(l.reviewSaveEdits),
          ),
          Row(children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: busy ? null : () => _decide(true),
                icon: const Icon(Icons.check_circle_outline_rounded, size: AppIconSizes.md),
                label: Text(l.reviewApprove),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: busy ? null : () => _decide(false),
                icon: const Icon(Icons.close_rounded, size: AppIconSizes.md, color: AppColors.error),
                label: Text(l.reviewReject, overflow: TextOverflow.ellipsis),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}
