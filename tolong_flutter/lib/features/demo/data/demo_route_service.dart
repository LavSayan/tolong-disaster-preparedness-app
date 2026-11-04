import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../safe_places/data/route_service.dart';
import '../../safe_places/domain/evacuation_center.dart';
import '../../safe_places/domain/ranking.dart';
import '../application/demo_session.dart';

/// English on purpose: route attributions and map-data credit lines stay technical English
/// throughout the app (OSM/ORS strings are English), and this is the same kind of line.
/// The card still proves provenance: nothing pretends the line came from a road router.
const demoRouteAttribution = 'Simulated direct line — demo tools, not a road route';

/// Wraps the real route service only in demo builds. While the fake-route switch is on, any
/// route request returns a straight-line plan whose duration is the app's own walking
/// estimate — so "By route" travel and the wheelchair-verified state can be demonstrated
/// with zero network calls and no ORS key.
class DemoRouteService implements RouteService {
  DemoRouteService(this._ref, this._base);

  final Ref _ref;
  final RouteService _base;

  @override
  Future<RouteResult> route(GeoPoint from, GeoPoint to, RouteProfile profile) async {
    final fakeRoute = _ref.read(demoSessionProvider.select((s) => s.fakeRoute));
    if (!fakeRoute) return _base.route(from, to, profile);
    final meters = from.distanceKm(to) * 1000;
    return RouteFound(RoutePlan(
      profile: profile,
      distanceMeters: meters,
      durationSeconds: estimateTravelSeconds(meters),
      points: [from, to],
      attribution: demoRouteAttribution,
    ));
  }
}
