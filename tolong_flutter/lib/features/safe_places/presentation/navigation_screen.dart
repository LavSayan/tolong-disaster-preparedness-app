import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets/form_widgets.dart';
import '../application/safe_places_controller.dart';
import '../data/location_service.dart';
import '../data/route_service.dart';
import '../domain/evacuation_center.dart';
import 'map_view.dart';

const offRouteMeters = 60.0;
const arrivedMeters = 40.0;

String routeSummaryText(AppLocalizations l, RoutePlan plan) =>
    l.routeSummary(l.number(plan.distanceMeters / 1000), (plan.durationSeconds / 60).ceil().clamp(1, 9999));

/// Route preview that follows the user's live location. Deliberately not turn-by-turn.
class NavigationScreen extends ConsumerStatefulWidget {
  const NavigationScreen({super.key, required this.center, required this.plan});

  final EvacuationCenter center;
  final RoutePlan plan;

  @override
  ConsumerState<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends ConsumerState<NavigationScreen> {
  StreamSubscription<GeoPoint>? _sub;
  late GeoPoint? _user = ref.read(safePlacesProvider).userPoint;
  bool _lost = false;
  MapHandle? _map;

  @override
  void initState() {
    super.initState();
    _sub = ref.read(locationServiceProvider).watch().listen(
      (p) {
        setState(() {
          _user = p;
          _lost = false;
        });
        _map?.focus(p, zoom: 16);
      },
      onError: (Object _) => setState(() => _lost = true),
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final buildMap = ref.watch(mapViewBuilderProvider);
    final user = _user;
    final toGoal = user == null ? null : user.distanceKm(widget.center.location) * 1000;
    final offRoute = user != null && distanceToPolylineMeters(user, widget.plan.points) > offRouteMeters;
    final arrived = toGoal != null && toGoal <= arrivedMeters;

    final (String status, MessageTone tone) = switch (null) {
      _ when _lost => (l.navLocationLost, MessageTone.error),
      _ when user == null => (l.navWaiting, MessageTone.info),
      _ when arrived => (l.navArrived(widget.center.name), MessageTone.success),
      _ when offRoute => (l.navOffRoute, MessageTone.error),
      _ => (l.navRemaining(l.number(toGoal! / 1000), widget.center.name), MessageTone.info),
    };

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        surfaceTintColor: Colors.transparent,
        title: Text(l.navTitle, style: serif(20)),
      ),
      body: SafeArea(
        top: false,
        child: Column(children: [
          Expanded(
            child: buildMap(
              centers: [widget.center],
              selectedId: widget.center.id,
              user: user,
              route: widget.plan.points,
              outline: null,
              onCenterTap: (_) {},
              onReady: (h) => _map = h,
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.lg),
            decoration: const BoxDecoration(
              color: AppColors.cream,
              border: Border(top: BorderSide(color: AppColors.line)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(widget.center.name, style: serif(20)),
              const SizedBox(height: AppSpacing.xs),
              Text(routeSummaryText(l, widget.plan), style: sans(12, weight: FontWeight.w700, color: AppColors.primary)),
              const SizedBox(height: AppSpacing.md),
              InlineMessage(status, tone: tone),
              const SizedBox(height: AppSpacing.sm),
              Text(l.navPreviewNote, style: sans(11, color: AppColors.muted)),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, size: AppIconSizes.md),
                label: Text(l.navEnd),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(widget.plan.attribution, textAlign: TextAlign.center, style: sans(9, color: AppColors.muted)),
            ]),
          ),
        ]),
      ),
    );
  }
}
