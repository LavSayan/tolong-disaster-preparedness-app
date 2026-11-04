import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme.dart';
import '../../../core/validation.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets/common.dart';
import '../../../shared/widgets/form_widgets.dart';
import '../application/submission_controllers.dart';
import '../data/location_service.dart';
import '../data/qc_area_repository.dart';
import '../domain/evacuation_center.dart';
import '../domain/qc_area.dart';
import '../domain/shelter_submission.dart';
import 'map_view.dart';

/// Community shelter submission: the user describes the site, the machine gate re-checks
/// every rule locally, and the server enforces them again — a government reviewer is the
/// human gate before the shelter ever appears in the ranked list.
///
/// Opening with [initial] turns the same form into an editor for that pending
/// submission (server-side, only the data columns are writable, never the status).
class SubmitShelterScreen extends ConsumerStatefulWidget {
  const SubmitShelterScreen({super.key, this.initial});

  final ShelterSubmission? initial;

  @override
  ConsumerState<SubmitShelterScreen> createState() => _SubmitShelterScreenState();
}

class _SubmitShelterScreenState extends ConsumerState<SubmitShelterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _accessibility = TextEditingController();
  final _capacity = TextEditingController();
  final _facilities = TextEditingController();
  final _lat = TextEditingController();
  final _lng = TextEditingController();
  Barangay? _barangay;
  FacilityType _facilityType = FacilityType.school;
  GeoPoint? _pin;
  bool _sending = false;
  bool _sent = false;
  SubmissionErrorCode? _error;

  /// Set when the form edits an existing pending submission instead of creating one.
  ShelterSubmission? _editing;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial == null) return;
    _editing = initial;
    final d = initial.draft;
    _name.text = d.name;
    _address.text = d.address ?? '';
    _accessibility.text = d.accessibility ?? '';
    _capacity.text = d.capacity?.toString() ?? '';
    _facilities.text = d.facilities.join(', ');
    _pin = d.location;
    _lat.text = d.location.lat.toStringAsFixed(6);
    _lng.text = d.location.lng.toStringAsFixed(6);
    _facilityType = d.facilityType;
  }

  @override
  void dispose() {
    for (final c in [_name, _address, _accessibility, _capacity, _facilities, _lat, _lng]) {
      c.dispose();
    }
    super.dispose();
  }

  GeoPoint? _coordinates() {
    final lat = double.tryParse(_lat.text.trim().replaceAll(',', '.'));
    final lng = double.tryParse(_lng.text.trim().replaceAll(',', '.'));
    return lat == null || lng == null ? null : GeoPoint(lat, lng);
  }

  /// The effective pin: the validated coordinates (kept in state so a pin survives a
  /// re-render), used by the preview map and the send action.
  GeoPoint? get _pinOrTyped => _pin ?? _coordinates();

  Future<void> _useMyLocation() async {
    final result = await ref.read(locationServiceProvider).current();
    if (result is! Located) return;
    setState(() {
      _pin = result.point;
      _lat.text = result.point.lat.toStringAsFixed(6);
      _lng.text = result.point.lng.toStringAsFixed(6);
    });
  }

  Future<void> _send() async {
    final l = context.l10n;
    FocusManager.instance.primaryFocus?.unfocus();
    if (_form.currentState != null && !_form.currentState!.validate()) return;

    final pin = _coordinates();
    if (_barangay == null) {
      setState(() => _error = SubmissionErrorCode.unknownBarangay);
      return;
    }
    if (pin == null) {
      setState(() => _error = SubmissionErrorCode.invalidFields);
      return;
    }
    setState(() {
      _error = null;
      _pin = pin;
      _lat.text = pin.lat.toStringAsFixed(6);
      _lng.text = pin.lng.toStringAsFixed(6);
    });

    final draft = ShelterSubmissionDraft(
      name: _name.text,
      location: pin,
      facilityType: _facilityType,
      barangay: _barangay!.name,
      address: _address.text.trim().isEmpty ? null : _address.text,
      accessibility: _accessibility.text.trim().isEmpty ? null : _accessibility.text,
      capacity: int.tryParse(_capacity.text.trim()),
      facilities: [
        for (final f in _facilities.text.split(','))
          if (f.trim().isNotEmpty) f.trim(),
      ],
    );

    setState(() {
      _error = null;
      _sending = true;
    });
    final editing = _editing;
    try {
      if (editing == null) {
        await ref.read(submitShelterServiceProvider).submit(draft);
      } else {
        await ref.read(submitShelterServiceProvider).edit(editing.id, draft);
      }
      ref.invalidate(mySubmissionsProvider);
      if (!mounted) return;
      setState(() {
        _sending = false;
        _sent = true;
      });
      showMessage(context, l.submitSent);
      await Future<void>.delayed(const Duration(seconds: 2));
      if (mounted) context.pop();
    } on SubmissionFailure catch (f) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = f.code;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final barangays = ref.watch(barangaysProvider).value ?? const <Barangay>[];
    final pin = _pinOrTyped;

    return FormPage(
      title: l.submitTitle,
      subtitle: l.submitSub,
      children: [
        Form(
          key: _form,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            TextFormField(
              controller: _name,
              decoration: InputDecoration(labelText: l.submitName, hintText: l.submitNameHint),
              validator: (v) => (v == null || v.trim().isEmpty || v.trim().length > 120) ? l.subErrInvalidFields : null,
            ),
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
              initialValue: _barangay,
              isExpanded: true,
              decoration: InputDecoration(labelText: l.submitBarangay),
              validator: (v) => v == null ? l.subErrUnknownBarangay : null,
              items: [
                for (final b in barangays)
                  DropdownMenuItem(value: b, child: Text(b.name, overflow: TextOverflow.ellipsis)),
              ],
              onChanged: (v) => setState(() => _barangay = v),
            ),
            gap,
            TextFormField(controller: _address, decoration: InputDecoration(labelText: l.submitAddress)),
            gap,
            TextFormField(
              controller: _accessibility,
              decoration: InputDecoration(labelText: l.submitAccessibility, hintText: l.submitAccessibilityHint),
            ),
            gap,
            TextFormField(
              controller: _capacity,
              decoration: InputDecoration(labelText: l.submitCapacity),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (raw) {
                if (raw == null || raw.trim().isEmpty) return null; // optional
                final v = Validators.parseNumber(raw);
                if (v == null || v != v.roundToDouble() || v < 1 || v > 100000) return l.subErrInvalidFields;
                return null;
              },
            ),
            gap,
            TextFormField(
              controller: _facilities,
              decoration: InputDecoration(labelText: l.submitFacilities),
            ),
            gap,
            Eyebrow(l.submitLocation.toUpperCase()),
            gap,
            _PinPreview(pin: pin, facilityLabel: l.facilityType(_facilityType)),
            gap,
            OutlinedButton.icon(
              onPressed: _useMyLocation,
              icon: const Icon(Icons.my_location_rounded, size: AppIconSizes.md),
              label: Text(l.submitLocate),
            ),
            gap,
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: _lat,
                  decoration: InputDecoration(labelText: l.submitLat),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  validator: (raw) {
                    if (double.tryParse((raw ?? '').trim().replaceAll(',', '.')) == null) {
                      return l.subErrInvalidFields;
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: TextFormField(
                  controller: _lng,
                  decoration: InputDecoration(labelText: l.submitLng),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  validator: (raw) {
                    if (double.tryParse((raw ?? '').trim().replaceAll(',', '.')) == null) {
                      return l.subErrInvalidFields;
                    }
                    return null;
                  },
                ),
              ),
            ]),
            gap,
            Text(l.submitMapHint, style: sans(11, height: 1.45, color: AppColors.muted)),
            gap,
            if (_error != null) InlineMessage(l.submissionError(_error!), tone: MessageTone.error),
            if (_sent) InlineMessage(l.submitSent, tone: MessageTone.success),
            if (!_sent)
              LoadingButton(
                label: _editing == null ? l.submitSend : l.edit,
                loading: _sending,
                onPressed: _send,
              ),
          ]),
        ),
      ],
    );
  }
}

/// Small map preview with the pin standing in as an ordinary (unverified) center, so a
/// submitter sees exactly where the coordinate pair lands. Editable coordinates stay
/// authoritative — this preview never invents a position by itself.
class _PinPreview extends ConsumerStatefulWidget {
  const _PinPreview({required this.pin, required this.facilityLabel});

  final GeoPoint? pin;
  final String facilityLabel;

  @override
  ConsumerState<_PinPreview> createState() => _PinPreviewState();
}

class _PinPreviewState extends ConsumerState<_PinPreview> {
  MapHandle? _map;

  /// A one-shot token so the next `focus` only fires once per pin change or map mount,
  /// never on every build frame.
  GeoPoint? _focusedPin;

  void _focusIf(GeoPoint? pin) {
    if (pin != null && _map != null && pin != _focusedPin) {
      _focusedPin = pin;
      unawaited(_map!.focus(pin));
    }
  }

  @override
  void didUpdateWidget(_PinPreview old) {
    super.didUpdateWidget(old);
    _focusIf(widget.pin);
  }

  @override
  Widget build(BuildContext context) {
    final pin = widget.pin;
    if (pin == null) {
      _map = null;
      _focusedPin = null;
      return InlineMessage(context.l10n.submitMapHint);
    }
    _focusIf(pin);
    final synthetic = EvacuationCenter(
      id: 'submit-pin',
      name: widget.facilityLabel,
      location: pin,
      facilityType: FacilityType.other,
      source: '',
      verified: false,
    );
    final buildMap = ref.watch(mapViewBuilderProvider);
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: SizedBox(
        height: 170,
        child: buildMap(
          centers: [synthetic],
          selectedId: 'submit-pin',
          user: null,
          route: null,
          outline: null,
          onCenterTap: (_) {},
          onReady: (handle) {
            _map = handle;
            _focusedPin = null;
            _focusIf(pin);
          },
        ),
      ),
    );
  }
}
