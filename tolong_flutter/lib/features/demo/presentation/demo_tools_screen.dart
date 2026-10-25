import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../../../shared/widgets/common.dart';
import '../../../shared/widgets/form_widgets.dart';
import '../../auth/application/session.dart';
import '../../household/presentation/household_forms.dart' show confirmDestructive;
import '../../household/presentation/profile_screen.dart' show confirmSignOut;
import '../../safe_places/application/ranking_controller.dart';
import '../../safe_places/application/safe_places_controller.dart';
import '../../safe_places/data/evacuation_center_repository.dart';
import '../../safe_places/data/hazard_layer_service.dart';
import '../../safe_places/data/location_service.dart' show Located;
import '../../safe_places/data/route_service.dart' show RouteErrorCode;
import '../../safe_places/domain/evacuation_center.dart';
import '../../safe_places/domain/hazard.dart';
import '../../safe_places/domain/ranking.dart' show RankingFeatures, RankingWeights;
import '../../safe_places/presentation/barangay_widgets.dart';
import '../../settings/local_data.dart';
import '../application/demo_session.dart';
import '../domain/demo_models.dart';

/// The demo/admin panel. Reachable only in builds compiled with `--dart-define=DEMO_TOOLS=true`
/// (Settings -> long-press the version row, or the More tile). English-only on purpose: it is
/// an internal tool, never shipped to users, and its strings never appear outside this screen.
/// Everything it changes is in-memory and labelled — the app-wide banner and the simulated tag
/// on the advisory card are the honesty markers.
class DemoToolsScreen extends ConsumerStatefulWidget {
  const DemoToolsScreen({super.key});

  @override
  ConsumerState<DemoToolsScreen> createState() => _DemoToolsScreenState();
}

class _DemoToolsScreenState extends ConsumerState<DemoToolsScreen> {
  final _lat = TextEditingController();
  final _lng = TextEditingController();
  final _area = TextEditingController(text: demoFloodSample.area);
  final _message = TextEditingController(text: demoFloodSample.message ?? '');
  DemoDisasterType _type = demoFloodSample.type;
  DemoSeverity _severity = demoFloodSample.severity;

  @override
  void dispose() {
    for (final c in [_lat, _lng, _area, _message]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Sets the override and immediately re-locates, so the ranked list, distances and the
  /// nearest-centre selection react the way a real fix would.
  Future<void> _applyLocation(GeoPoint point) async {
    ref.read(demoSessionProvider.notifier).setLocationOverride(point);
    final controller = ref.read(safePlacesProvider.notifier);
    final result = await controller.locate();
    final centers = ref.read(evacuationCentersProvider).value ?? const [];
    if (result is Located && centers.isNotEmpty && !ref.read(safePlacesProvider).outsideServiceArea) {
      controller.select(byDistance(centers, result.point).first.$1.id);
    }
  }

  void _clearLocation() {
    ref.read(demoSessionProvider.notifier).setLocationOverride(null);
    ref.read(safePlacesProvider.notifier).clearLocation();
  }

  void _applyManualLocation() {
    final lat = double.tryParse(_lat.text.trim());
    final lng = double.tryParse(_lng.text.trim());
    if (lat == null || lng == null || lat < -90 || lat > 90 || lng < -180 || lng > 180) {
      showMessage(context, 'Enter a latitude in [-90, 90] and a longitude in [-180, 180].');
      return;
    }
    _applyLocation(GeoPoint(lat, lng));
  }

  void _applyAdvisory() {
    final area = _area.text.trim();
    if (area.isEmpty) {
      showMessage(context, 'Name at least one affected barangay or area.');
      return;
    }
    ref.read(demoSessionProvider.notifier).setAdvisory(DemoAdvisory(
          type: _type,
          severity: _severity,
          area: area,
          message: _message.text.trim().isEmpty ? null : _message.text.trim(),
        ));
    showMessage(context, 'Advisory is live on Home with the SIMULATED tag.');
  }

  Future<void> _planRoute() async {
    final place = ref.read(safePlacesProvider);
    final centers = ref.read(evacuationCentersProvider).value ?? const [];
    final reference = place.reference;
    final selectedId = place.selectedId ??
        (reference != null && centers.isNotEmpty ? byDistance(centers, reference).first.$1.id : null);
    final center = centers.where((c) => c.id == selectedId).firstOrNull;
    if (center == null) {
      showMessage(context, 'Set a location first, then plan a route.');
      return;
    }
    await ref.read(safePlacesProvider.notifier).requestRoute(center);
    if (!mounted) return;
    final after = ref.read(safePlacesProvider);
    showMessage(context, switch (after.routeError) {
      RouteErrorCode.outsideArea => 'Route failed: outside the service area.',
      RouteErrorCode.notConfigured => 'Route failed: routing not configured in this build.',
      _ => after.route == null ? 'Route failed.' : 'Route set — see the Safe places screen.',
    });
  }

  Future<void> _resetOverrides() async {
    final ok = await confirmDestructive(
      context,
      title: 'Reset demo overrides?',
      body: 'Location, advisory, weights and the fake-route switch return to launch defaults. '
          'Household data is not touched.',
      confirmLabel: 'Reset',
    );
    if (!ok) return;
    ref.read(demoSessionProvider.notifier).reset();
    ref.read(safePlacesProvider.notifier).clearLocation();
    ref.read(hazardOverlayProvider.notifier).select(null);
    if (mounted) showMessage(context, 'Demo overrides reset.');
  }

  Future<void> _clearLocalData() async {
    final ok = await confirmDestructive(
      context,
      title: 'Clear local data?',
      body: 'Household details, contacts, supplies and checklist progress are removed from this '
          'phone — the same action as Settings, Clear local data.',
      confirmLabel: 'Clear',
    );
    if (!ok) return;
    final owner = ref.read(sessionProvider).owner;
    if (owner == null) return;
    await ref.read(localDataProvider).clear(owner);
    if (mounted) showMessage(context, 'Local data cleared.');
  }

  @override
  Widget build(BuildContext context) {
    final demo = ref.watch(demoSessionProvider);
    final place = ref.watch(safePlacesProvider);
    final ranking = ref.watch(rankedCentersProvider);
    final hazardGroup = ref.watch(hazardOverlayProvider);
    final hazardAvailable = ref.watch(hazardLayerStatusProvider) is HazardBundled;
    final reference = place.reference;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        surfaceTintColor: Colors.transparent,
        title: Text('Demo tools', style: serif(20)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.xxxl),
        children: [
          CardBox(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                const SampleTag('DEMO BUILD'),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Simulated inputs only. Every change is labelled in the app and resets on '
                    'restart. Never distribute this build.',
                    style: sans(11, height: 1.45, color: AppColors.muted),
                  ),
                ),
              ]),
            ]),
          ),
          _Section('MY LOCATION', [
            Text(
              'Reference: ${reference == null ? 'none' : '${reference.lat.toStringAsFixed(4)}, ${reference.lng.toStringAsFixed(4)}'}'
              '${demo.locationOverride == null ? '' : '  (override)'}',
              style: sans(12, color: AppColors.muted),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final preset in demoLocationPresets)
                  OutlinedButton(
                    onPressed: () => _applyLocation(preset.point),
                    child: Text(preset.label),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton(
              onPressed: () async {
                final b = await showBarangaySearch(context);
                if (b != null && mounted) await _applyLocation(b.center);
              },
              child: const Text('Use a barangay centre…'),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _lat,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  decoration: const InputDecoration(labelText: 'Latitude'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextField(
                  controller: _lng,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  decoration: const InputDecoration(labelText: 'Longitude'),
                ),
              ),
            ]),
            const SizedBox(height: AppSpacing.sm),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: _applyManualLocation, child: const Text('Apply coordinates'))),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton(
                  onPressed: demo.locationOverride == null ? null : _clearLocation,
                  child: const Text('Clear override'),
                ),
              ),
            ]),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton(
              onPressed: demo.locationOverride == null ? null : () => _applyLocation(demo.locationOverride!),
              child: const Text('Re-apply location'),
            ),
          ]),
          _Section('SIMULATED DISASTER ADVISORY', [
            SegmentedButton<DemoDisasterType>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: DemoDisasterType.flood, label: Text('Flood')),
                ButtonSegment(value: DemoDisasterType.earthquake, label: Text('Earthquake')),
                ButtonSegment(value: DemoDisasterType.fire, label: Text('Fire')),
              ],
              selected: {_type},
              onSelectionChanged: (x) => setState(() => _type = x.first),
            ),
            const SizedBox(height: AppSpacing.sm),
            SegmentedButton<DemoSeverity>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: DemoSeverity.advisory, label: Text('Advisory')),
                ButtonSegment(value: DemoSeverity.warning, label: Text('Warning')),
                ButtonSegment(value: DemoSeverity.severe, label: Text('Severe')),
              ],
              selected: {_severity},
              onSelectionChanged: (x) => setState(() => _severity = x.first),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(controller: _area, decoration: const InputDecoration(labelText: 'Affected areas')),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _message,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Message (optional — empty shows the built-in simulation note)',
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                OutlinedButton(
                  onPressed: () => setState(() {
                    _type = demoFloodSample.type;
                    _severity = demoFloodSample.severity;
                    _area.text = demoFloodSample.area;
                    _message.text = demoFloodSample.message ?? '';
                  }),
                  child: const Text('Fill flood sample'),
                ),
                FilledButton(onPressed: _applyAdvisory, child: const Text('Show on Home')),
                OutlinedButton(
                  onPressed: demo.advisory == null
                      ? null
                      : () => ref.read(demoSessionProvider.notifier).setAdvisory(null),
                  child: const Text('Remove from Home'),
                ),
              ],
            ),
          ]),
          _Section('ROUTES', [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Fake routes (straight line, no network)', style: sans(13, weight: FontWeight.w600)),
              subtitle: Text(
                'Plan a route without an ORS key: the line is a direct segment, travel uses the '
                "app's walking estimate, and wheelchair mode reads verified. The attribution on "
                'the route says it is simulated.',
                style: sans(11, height: 1.45, color: AppColors.muted),
              ),
              value: demo.fakeRoute,
              onChanged: (x) => ref.read(demoSessionProvider.notifier).setFakeRoute(x),
            ),
            OutlinedButton(onPressed: _planRoute, child: const Text('Plan route to selected centre')),
          ]),
          _Section('RANKING WEIGHTS', [
            SegmentedButton<DemoWeightsMode>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: DemoWeightsMode.trained, label: Text('Trained v1')),
                ButtonSegment(value: DemoWeightsMode.baseline, label: Text('Baseline 45/35/20')),
              ],
              selected: {demo.weightsMode},
              onSelectionChanged: (x) => ref.read(demoSessionProvider.notifier).setWeightsMode(x.first),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              ranking.weightsTrained
                  ? 'Weights provenance shown on cards: Trained weights v1'
                  : 'Weights provenance shown on cards: Default weights'
                      '${ranking.weightsFallbackReason == null ? '' : ' — ${ranking.weightsFallbackReason}'}',
              style: sans(11, color: AppColors.muted),
            ),
            const SizedBox(height: AppSpacing.md),
            if (!ranking.available)
              const InlineMessage('No ranked list yet — set a location above, then come back.')
            else ...[
              for (final r in ranking.ranked)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _ScoreRow(rank: r.rank, name: r.center.name, features: r.features, weights: ranking.weights),
                ),
            ],
          ]),
          _Section('MAP', [
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                OutlinedButton(
                  onPressed: hazardGroup == null ? null : () => ref.read(hazardOverlayProvider.notifier).select(null),
                  child: const Text('Hazard overlay: off'),
                ),
                for (final g in HazardGroup.values)
                  OutlinedButton(
                    onPressed: () => ref.read(hazardOverlayProvider.notifier).select(g),
                    child: Text('Hazard overlay: ${g.name}'),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              hazardAvailable
                  ? 'Hazard overlay is available in this build.'
                  : 'Hazard overlay cannot draw here (the pmtiles protocol did not register).',
              style: sans(11, color: AppColors.muted),
            ),
          ]),
          _Section('UTILITIES', [
            OutlinedButton(onPressed: _resetOverrides, child: const Text('Reset all demo overrides')),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton(onPressed: _clearLocalData, child: const Text('Clear local data…')),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton(
              onPressed: () => confirmSignOut(context, ref),
              child: const Text('Sign out…'),
            ),
          ]),
        ],
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({
    required this.rank,
    required this.name,
    required this.features,
    required this.weights,
  });

  final int rank;
  final String name;
  final RankingFeatures features;
  final RankingWeights weights;

  String _pct(double x) => (x * 100).toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final c = weights.contributions(features);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(
            child: Text('$rank. $name', overflow: TextOverflow.ellipsis, style: sans(12, weight: FontWeight.w700)),
          ),
          Text(weights.score(features).toStringAsFixed(2),
              style: sans(12, weight: FontWeight.w700, color: AppColors.sage)),
        ]),
        Text(
          'xE ${_pct(features.xExposure)} · xT ${_pct(features.xTravel)} · xA ${_pct(features.xAccessibility)}'
          '${features.travelEstimated ? ' · estimated travel' : ' · by route'}'
          ' · exposure ${features.exposure.toStringAsFixed(3)}',
          style: sans(11, color: AppColors.muted),
        ),
        Text(
          'contributions E ${c['exposure']!.toStringAsFixed(1)} · T ${c['travel']!.toStringAsFixed(1)}'
          ' · A ${c['accessibility']!.toStringAsFixed(1)}',
          style: sans(11, color: AppColors.muted),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title, this.children);

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: AppSpacing.sm),
          child: Eyebrow(title, color: AppColors.terracotta),
        ),
        CardBox(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
        ),
      ],
    );
  }
}
