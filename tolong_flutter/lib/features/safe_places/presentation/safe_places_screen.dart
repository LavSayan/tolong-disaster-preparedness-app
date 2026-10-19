import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets/character.dart';
import '../../../shared/widgets/common.dart';
import '../../../shared/widgets/form_widgets.dart';
import '../application/safe_places_controller.dart';
import '../data/evacuation_center_repository.dart';
import '../data/hazard_layer_service.dart';
import '../data/location_service.dart';
import '../data/offline_map_service.dart';
import '../data/qc_area_repository.dart';
import '../data/route_service.dart';
import '../domain/evacuation_center.dart';
import '../domain/hazard.dart';
import 'barangay_widgets.dart';
import 'map_view.dart';
import 'navigation_screen.dart';
import 'offline_map_screen.dart';

class SafePlacesScreen extends ConsumerStatefulWidget {
  const SafePlacesScreen({super.key});

  @override
  ConsumerState<SafePlacesScreen> createState() => _SafePlacesScreenState();
}

class _SafePlacesScreenState extends ConsumerState<SafePlacesScreen> {
  MapHandle? _map;

  /// What the map last reported about the hazard overlay drawing, from the idle pin in
  /// `map_view.dart`. Only [HazardDrawState.filterMatchedNothing] is shown: the legend would
  /// otherwise lie about colours the map never painted. Paired with the group it was measured
  /// for, because picking a different group makes the report stale until the next idle frame.
  HazardGroup? _hazardDrawnGroup;
  HazardDrawState? _hazardDraw;

  void _select(EvacuationCenter c) {
    ref.read(safePlacesProvider.notifier).select(c.id);
    _map?.focus(c.location, zoom: 15);
  }

  Future<void> _locate(List<EvacuationCenter> centers) async {
    final controller = ref.read(safePlacesProvider.notifier);
    final result = await controller.locate();
    if (result is! Located) return;
    if (!ref.read(safePlacesProvider).outsideServiceArea && centers.isNotEmpty) {
      controller.select(byDistance(centers, result.point).first.$1.id);
    }
    await _map?.focus(result.point, zoom: 14);
  }

  Future<void> _searchBarangay() async {
    final b = await showBarangaySearch(context);
    if (b == null) return;
    ref.read(safePlacesProvider.notifier).setBarangay(b);
    await _map?.focus(b.center, zoom: 15);
  }

  /// Picks which modelled hazard the map overlays. Chosen from a sheet rather than a row of map
  /// buttons so four groups fit without crowding the map controls.
Future<void> _pickHazard(HazardOverlayController controller, HazardGroup? current) async {
    final l = context.l10n;
    // Report rather than hide: if the archive cannot be read, say so plainly instead of showing a
    // control that does nothing.
    final available = ref.read(hazardLayerStatusProvider);
    final unavailable = available is HazardProtocolMissing;
    final picked = await showModalBottomSheet<HazardGroup?>(
      context: context,
      // Scrollable: four groups plus headings and the "off" row exceed a 360 dp sheet, and the
      // accessibility checklist requires bottom sheets to scroll at large text sizes.
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.sm),
              child: Text(l.hazardLegendTitle, style: serif(19)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.md),
              child: Text(unavailable ? l.hazardUnavailableGeneric : l.hazardLegendNote,
                  style: sans(12, height: 1.45, color: unavailable ? AppColors.terracotta : AppColors.muted)),
            ),
          for (final g in HazardGroup.values)
            ListTile(
              // 48 dp so the tap target meets the accessibility test.
              minTileHeight: 48,
              // Disabled rather than removed: the user can see what the app supports and is told
              // why it cannot show it right now.
              enabled: !unavailable,
              leading: Icon(Icons.layers_outlined,
                  size: 20, color: unavailable ? AppColors.muted : AppColors.blue),
              title: Text(l.hazardGroupName(g),
                  style: sans(13,
                      weight: FontWeight.w600, color: unavailable ? AppColors.muted : AppColors.ink)),
              trailing: current == g
                  ? const Icon(Icons.check_rounded, size: 18, color: AppColors.sage)
                  : null,
              onTap: () => Navigator.of(sheetContext).pop(g),
            ),
          ListTile(
            minTileHeight: 48,
            leading: const Icon(Icons.visibility_off_outlined, size: 20, color: AppColors.muted),
            title: Text(l.hazardButton, style: sans(13, color: AppColors.muted)),
            onTap: () => Navigator.of(sheetContext).pop(),
          ),
          const SizedBox(height: AppSpacing.sm),
          ]),
        ),
      ),
    );
    controller.select(picked);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final centersAsync = ref.watch(evacuationCentersProvider);
    final centers = centersAsync.value ?? const <EvacuationCenter>[];
    final state = ref.watch(safePlacesProvider);
    final buildMap = ref.watch(mapViewBuilderProvider);
    final user = state.userPoint;
    final anyUnverified = centers.any((c) => !c.verified);
    final boundary = ref.watch(qcBoundaryProvider).value;
    final hazardGroup = ref.watch(hazardOverlayProvider);
    final hazardController = ref.read(hazardOverlayProvider.notifier);
    final hazardDraw = _hazardDrawnGroup == hazardGroup ? _hazardDraw : null;

    final selected = centers.where((c) => c.id == state.selectedId).firstOrNull;
    final nearestId =
        user == null || centers.isEmpty || state.outsideServiceArea ? null : byDistance(centers, user).first.$1.id;

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const ContextHero(scene: Scene.map, background: AppColors.blueSoft),
      _BarangayBar(onSearch: _searchBarangay),
      CardBox(
        padding: EdgeInsets.zero,
        child: SizedBox(
          height: 340,
          child: Stack(children: [
            Positioned.fill(
              child: Semantics(
                label: l.mapLabel,
                child: buildMap(
                  centers: centers,
                  selectedId: state.selectedId,
                  user: user,
                  route: state.route?.points,
                  outline: boundary?.rings,
                  onCenterTap: (id) {
                    final c = centers.where((x) => x.id == id).firstOrNull;
                    if (c != null) _select(c);
                  },
                  hazardGroup: hazardGroup,
                  onHazardDrawState: (s) =>
                      setState(() { _hazardDrawnGroup = hazardGroup; _hazardDraw = s; }),
                  onReady: (handle) => _map = handle,
                ),
              ),
            ),
            if (anyUnverified) Positioned(left: 10, top: 10, child: SampleTag(l.mapDemoBanner)),
            Positioned(
              right: 10,
              top: 10,
              child: Column(children: [
                _MapButton(icon: Icons.add_rounded, tooltip: l.mapZoomIn, onTap: () => _map?.zoomIn()),
                const SizedBox(height: 6),
                _MapButton(icon: Icons.remove_rounded, tooltip: l.mapZoomOut, onTap: () => _map?.zoomOut()),
                const SizedBox(height: 14),
                _MapButton(
                  icon: Icons.my_location_rounded,
                  tooltip: l.mapMyLocation,
                  busy: state.locating,
                  onTap: () => _locate(centers),
                ),
                const SizedBox(height: 6),
                _MapButton(
                  icon: Icons.zoom_out_map_rounded,
                  tooltip: l.mapResetView,
                  onTap: () => _map?.showBounds(boundary?.bounds ?? qcApproxBounds),
                ),
                // Always shown. An earlier version hid this on web with `if (!kIsWeb)`, which meant the overlay
                // was unreachable in exactly the platform it had been wired for. Availability is
                // now reported by [hazardLayerStatusProvider] instead, so a build that cannot read
                // the archive says so rather than silently losing the control.
                const SizedBox(height: 6),
                _MapButton(
                  icon: Icons.water_damage_outlined,
                  tooltip: l.hazardButton,
                  active: hazardGroup != null,
                  onTap: () => _pickHazard(hazardController, hazardGroup),
                ),
              ]),
            ),
          ]),
        ),
      ),
      if (hazardGroup != null)
        _HazardLegendCard(group: hazardGroup, drawn: hazardDraw),
      _LocationMessage(state: state),
      if (centersAsync.isLoading)
        const Padding(padding: EdgeInsets.all(AppSpacing.xl), child: Center(child: CircularProgressIndicator()))
      else if (centersAsync.hasError)
        InlineMessage(l.couldNotLoad, tone: MessageTone.error)
      else ...[
        if (selected != null)
          _CenterCard(
            center: selected,
            heading: selected.id == nearestId ? l.centerNearest : l.centerSelected,
            distanceKm: user?.distanceKm(selected.location),
          )
        else
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: InlineMessage(l.centerTapHint),
          ),
        _CenterList(
          centers: centers,
          reference: state.reference,
          fromBarangay: user == null ? state.barangay?.name : null,
          selectedId: state.selectedId,
          onSelect: _select,
        ),
        const _OfflineMapCard(),
      ],
    ]);
  }
}

class _BarangayBar extends ConsumerWidget {
  const _BarangayBar({required this.onSearch});

  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final barangay = ref.watch(safePlacesProvider.select((s) => s.barangay));
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.pill),
      side: const BorderSide(color: AppColors.line),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Material(
        color: AppColors.cream,
        shape: shape,
        child: InkWell(
          customBorder: shape,
          onTap: onSearch,
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
            child: Row(children: [
              const Icon(Icons.search_rounded, color: AppColors.muted, size: AppIconSizes.lg),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    barangay == null ? l.brgySearch : l.brgyShowing(barangay.name),
                    overflow: TextOverflow.ellipsis,
                    style: sans(13,
                        weight: barangay == null ? FontWeight.w400 : FontWeight.w600,
                        color: barangay == null ? AppColors.muted : AppColors.ink),
                  ),
                ),
              ),
              if (barangay != null)
                IconButton(
                  tooltip: l.brgyClear,
                  visualDensity: VisualDensity.compact,
                  onPressed: () => ref.read(safePlacesProvider.notifier).setBarangay(null),
                  icon: const Icon(Icons.close_rounded, size: AppIconSizes.md),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _OfflineMapCard extends ConsumerWidget {
  const _OfflineMapCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final status = ref.watch(offlineMapProvider);
    return CardBox(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        onTap: () => context.push('/offline-map'),
        leading: const IconTile(
          icon: Icons.download_for_offline_outlined,
          background: AppColors.blueSoft,
          foreground: AppColors.blue,
          size: 34,
          radius: 11,
        ),
        title: Text(l.offTitle, style: sans(13, weight: FontWeight.w600)),
        subtitle: Text(offlineStatusText(l, status), style: sans(11, color: AppColors.muted)),
        trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFFAAB4AD)),
      ),
    );
  }
}

class _MapButton extends StatelessWidget {
  const _MapButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.busy = false,
    this.active = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool busy;

  /// Tints the button so an enabled map layer is obvious without reading the legend.
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AppColors.sageSoft : AppColors.cream,
      shape: const CircleBorder(side: BorderSide(color: AppColors.line)),
      elevation: 1,
      child: IconButton(
        tooltip: tooltip,
        onPressed: busy ? null : onTap,
        icon: busy
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
            : Icon(icon, size: 20, color: active ? AppColors.sage : AppColors.ink),
      ),
    );
  }
}

/// On-screen legend for the active hazard group.
///
/// Deliberately a legend rather than tap-a-polygon-to-inspect: every band has to be explainable
/// without hunting on the map, and the wording has to be readable by someone who is stressed.
///
/// [drawn] is what the map reported about actually painting the group. Only
/// `filterMatchedNothing` is rendered, as a data note: the legend sitting there while the map
/// draws nothing is exactly the silent failure this once shipped as, and the honest UI says so
/// instead of leaving a colourless map to be read as "no hazard here".
class _HazardLegendCard extends StatelessWidget {
  const _HazardLegendCard({required this.group, this.drawn});

  final HazardGroup group;
  final HazardDrawState? drawn;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final bands = group.severityBands;
    return CardBox(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Expanded(child: Eyebrow('MODELLED HAZARD')),
          Text(l.hazardTitle, style: sans(10, weight: FontWeight.w700, color: AppColors.blue)),
        ]),
        const SizedBox(height: AppSpacing.sm),
        Text(l.hazardLegendNote, style: sans(12, height: 1.45, color: AppColors.muted)),
        const SizedBox(height: AppSpacing.md),
        if (drawn == HazardDrawState.filterMatchedNothing)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Text(l.hazardNothingDrawn,
                style: sans(12, height: 1.45, color: AppColors.terracotta)),
          ),
        // Storm surge is a coastal hazard and Quezon City is inland, so the archive has no data
        // for it here. Say so rather than showing an empty key.
        if (group == HazardGroup.stormSurge)
          Text(l.hazardNoData, style: sans(12, height: 1.45, color: AppColors.terracotta))
        else
          for (final band in bands)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(children: [
                Container(
                  width: 22,
                  height: 14,
                  decoration: BoxDecoration(
                    // `band.color` is '#RRGGBB'; Flutter wants AARRGGBB.
                    color: Color(int.parse('FF${band.color.substring(1)}', radix: 16)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                    child: Text(l.hazardSeverity(band.level), style: sans(12, weight: FontWeight.w600))),
              ]),
            ),
        const SizedBox(height: AppSpacing.sm),
        Text(l.hazardLowerExposure, style: sans(11, height: 1.45, color: AppColors.muted)),
        Text(l.hazardCoverageGap, style: sans(11, height: 1.45, color: AppColors.muted)),
        const SizedBox(height: AppSpacing.sm),
        Text(l.hazardSource, style: sans(10, height: 1.4, color: AppColors.muted)),
      ]),
    );
  }
}

class _LocationMessage extends ConsumerWidget {
  const _LocationMessage({required this.state});

  final SafePlacesState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final service = ref.read(locationServiceProvider);
    Widget wrap(Widget child) => Padding(padding: const EdgeInsets.only(bottom: AppSpacing.lg), child: child);

    if (state.locating) return wrap(InlineMessage(l.locLocating));
    if (state.outsideServiceArea) return wrap(InlineMessage('${l.locOutside} ${l.locApproxArea}'));
    return switch (state.location) {
      LocationDenied() => wrap(InlineMessage(l.locDenied)),
      LocationDeniedForever() => wrap(Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          InlineMessage(l.locDeniedForever, tone: MessageTone.error),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(onPressed: service.openAppSettings, child: Text(l.locOpenSettings)),
          ),
        ])),
      LocationServiceOff() => wrap(Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          InlineMessage(l.locServiceOff, tone: MessageTone.error),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(onPressed: service.openLocationSettings, child: Text(l.locTurnOn)),
          ),
        ])),
      LocationFailed() => wrap(InlineMessage(l.locFailed, tone: MessageTone.error)),
      _ => const SizedBox.shrink(),
    };
  }
}

class _CenterCard extends StatelessWidget {
  const _CenterCard({required this.center, required this.heading, required this.distanceKm});

  final EvacuationCenter center;
  final String heading;
  final double? distanceKm;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    String orUnverified(String? v) => (v == null || v.trim().isEmpty) ? l.notVerified : v;

    return CardBox(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const IconTile(
            icon: Icons.location_on_outlined,
            background: AppColors.terracottaSoft,
            foreground: AppColors.terracotta,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [Eyebrow(heading), if (!center.verified) SampleTag(l.tagNotRealData)],
              ),
              const SizedBox(height: 4),
              Text(center.name, style: serif(20)),
              const SizedBox(height: 4),
              Text(l.facilityType(center.facilityType), style: sans(11, color: AppColors.muted)),
              if (distanceKm != null) ...[
                const SizedBox(height: 4),
                Text(l.centerDistance(l.number(distanceKm!)),
                    style: sans(11, weight: FontWeight.w600, color: AppColors.blue)),
              ],
            ]),
          ),
        ]),
        const SizedBox(height: AppSpacing.md),
        _Fact(l.centerBarangay, orUnverified(center.barangay)),
        _Fact(l.centerAddress, orUnverified(center.address)),
        _Fact(l.centerAccessibility, orUnverified(center.accessibility)),
        _Fact(l.centerCapacity, center.capacity?.toString() ?? l.notVerified),
        _Fact(l.centerFacilities, center.facilities.isEmpty ? l.notVerified : center.facilities.join(', ')),
        _Fact(l.centerStatus, orUnverified(center.status)),
        _Fact(l.centerSource, center.source),
        _Fact(l.centerLastVerified, center.lastVerified == null ? l.notVerified : l.date(center.lastVerified!)),
        const SizedBox(height: AppSpacing.md),
        _RouteSection(center: center),
      ]),
    );
  }
}

class _RouteSection extends ConsumerWidget {
  const _RouteSection({required this.center});

  final EvacuationCenter center;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final state = ref.watch(safePlacesProvider);
    final controller = ref.read(safePlacesProvider.notifier);
    final plan = state.route;
    final needsLocation = switch (state.location) {
      LocationDenied() || LocationDeniedForever() || LocationServiceOff() || LocationFailed() => true,
      _ => false,
    };

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Divider(color: AppColors.line),
      const SizedBox(height: AppSpacing.sm),
      SegmentedButton<RouteProfile>(
        showSelectedIcon: false,
        segments: [
          ButtonSegment(
            value: RouteProfile.walking,
            icon: const Icon(Icons.directions_walk_rounded, size: AppIconSizes.md),
            label: Text(l.routeProfileWalking),
          ),
          ButtonSegment(
            value: RouteProfile.wheelchair,
            icon: const Icon(Icons.accessible_rounded, size: AppIconSizes.md),
            label: Text(l.routeProfileWheelchair, overflow: TextOverflow.ellipsis),
          ),
        ],
        selected: {state.profile},
        onSelectionChanged: (s) => controller.setProfile(s.first),
      ),
      if (state.profile == RouteProfile.wheelchair) ...[
        const SizedBox(height: AppSpacing.xs),
        Text(l.routeWheelchairNote, style: sans(10, height: 1.4, color: AppColors.muted)),
      ],
      const SizedBox(height: AppSpacing.md),
      if (state.routing || state.locating)
        InlineMessage(state.locating ? l.locLocating : l.routeLoading)
      else if (state.routeError != null)
        InlineMessage(l.routeError(state.routeError!), tone: MessageTone.error)
      else if (needsLocation && plan == null)
        InlineMessage(l.routeNeedsLocation),
      if (plan != null) ...[
        Row(children: [
          const Icon(Icons.route_rounded, color: AppColors.primary, size: AppIconSizes.lg),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(routeSummaryText(l, plan), style: sans(14, weight: FontWeight.w700, color: AppColors.primary)),
          ),
        ]),
        const SizedBox(height: AppSpacing.xs),
        Text(l.routeDisclaimer, style: sans(10, height: 1.4, color: AppColors.muted)),
        const SizedBox(height: 2),
        Text(plan.attribution, style: sans(9, color: AppColors.muted)),
      ],
      const SizedBox(height: AppSpacing.md),
      if (plan == null)
        LoadingButton(
          label: l.routeShow,
          loading: state.routing || state.locating,
          onPressed: () => controller.requestRoute(center),
        )
      else
        PrimaryButton(
          label: l.mapStartNavigation,
          icon: Icons.navigation_rounded,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => NavigationScreen(center: center, plan: plan)),
          ),
        ),
    ]);
  }
}

class _Fact extends StatelessWidget {
  const _Fact(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final unverified = value == context.l10n.notVerified;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 120, child: Text(label, style: sans(11, color: AppColors.muted))),
        Expanded(
          child: Text(value,
              style: sans(11,
                  weight: unverified ? FontWeight.w400 : FontWeight.w600,
                  color: unverified ? AppColors.muted : AppColors.ink)),
        ),
      ]),
    );
  }
}

class _CenterList extends StatelessWidget {
  const _CenterList({
    required this.centers,
    required this.reference,
    required this.fromBarangay,
    required this.selectedId,
    required this.onSelect,
  });

  final List<EvacuationCenter> centers;

  /// Where distances are measured from (the user, or a searched barangay).
  final GeoPoint? reference;

  /// Set when [reference] is a barangay center rather than the user.
  final String? fromBarangay;
  final String? selectedId;
  final ValueChanged<EvacuationCenter> onSelect;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final rows = reference == null ? [for (final c in centers) (c, null as double?)] : byDistance(centers, reference!);
    return CardBox(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Eyebrow(l.centersTitle.toUpperCase()),
        if (centers.any((c) => !c.verified)) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(l.centersDemoNote, style: sans(11, height: 1.45, color: AppColors.muted)),
        ],
        if (fromBarangay != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(l.centersFromBarangay(fromBarangay!), style: sans(11, height: 1.45, color: AppColors.blue)),
        ],
        const SizedBox(height: AppSpacing.sm),
        for (final (c, km) in rows)
          ListTile(
            contentPadding: EdgeInsets.zero,
            selected: c.id == selectedId,
            selectedColor: AppColors.terracotta,
            onTap: () => onSelect(c),
            leading: Icon(Icons.location_on_rounded, color: c.id == selectedId ? AppColors.terracotta : AppColors.blue),
            title: Text(c.name, style: sans(13, weight: FontWeight.w600)),
            subtitle: Text(
              km == null ? l.facilityType(c.facilityType) : '${l.facilityType(c.facilityType)} · ≈ ${l.number(km)} km',
              style: sans(11, color: AppColors.muted),
            ),
            trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFFAAB4AD)),
          ),
      ]),
    );
  }
}
