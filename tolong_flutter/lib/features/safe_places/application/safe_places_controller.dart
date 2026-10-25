import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/location_service.dart';
import '../data/qc_area_repository.dart';
import '../data/route_service.dart';
import '../domain/evacuation_center.dart';
import '../domain/qc_area.dart';

class SafePlacesState {
  const SafePlacesState({
    this.selectedId,
    this.location,
    this.locating = false,
    this.profile = RouteProfile.walking,
    this.routing = false,
    this.route,
    this.routeError,
    this.userInsideQc,
    this.barangay,
  });

  final String? selectedId;

  /// Checked against the OSM city boundary when the location arrives.
  final bool? userInsideQc;

  /// Barangay the user searched for, used to frame the map and sort centers.
  final Barangay? barangay;

  /// Last location request result; null until the user asks for their location.
  final LocationResult? location;
  final bool locating;

  final RouteProfile profile;
  final bool routing;

  /// Route to the selected center. Cleared whenever the destination or profile changes.
  final RoutePlan? route;
  final RouteErrorCode? routeError;

  GeoPoint? get userPoint => switch (location) {
        Located(:final point) => point,
        _ => null,
      };

  bool get outsideServiceArea => userPoint != null && userInsideQc == false;

  /// Point that distances are measured from: the user if known, else the searched barangay.
  GeoPoint? get reference => userPoint ?? barangay?.center;

  SafePlacesState copyWith({
    String? Function()? selectedId,
    LocationResult? location,
    bool? locating,
    RouteProfile? profile,
    bool? routing,
    RoutePlan? Function()? route,
    RouteErrorCode? Function()? routeError,
    bool? userInsideQc,
    Barangay? Function()? barangay,
  }) =>
      SafePlacesState(
        userInsideQc: userInsideQc ?? this.userInsideQc,
        barangay: barangay != null ? barangay() : this.barangay,
        selectedId: selectedId != null ? selectedId() : this.selectedId,
        location: location ?? this.location,
        locating: locating ?? this.locating,
        profile: profile ?? this.profile,
        routing: routing ?? this.routing,
        route: route != null ? route() : this.route,
        routeError: routeError != null ? routeError() : this.routeError,
      );
}

class SafePlacesController extends Notifier<SafePlacesState> {
  @override
  SafePlacesState build() => const SafePlacesState();

  void select(String? id) {
    if (id == state.selectedId) return;
    state = state.copyWith(selectedId: () => id, route: () => null, routeError: () => null);
  }

  void setProfile(RouteProfile profile) =>
      state = state.copyWith(profile: profile, route: () => null, routeError: () => null);

  /// Only runs when the user taps "Show my location" or asks for a route; never on its own.
  Future<LocationResult> locate() async {
    state = state.copyWith(locating: true);
    final result = await ref.read(locationServiceProvider).current();
    bool? inside;
    if (result is Located) inside = await isInsideQc(result.point);
    state = state.copyWith(location: result, locating: false, userInsideQc: inside);
    return result;
  }

  /// Uses the bundled OSM boundary; falls back to the rough rectangle if it can't be read.
  Future<bool> isInsideQc(GeoPoint p) async {
    try {
      return (await ref.read(qcBoundaryProvider.future)).contains(p);
    } catch (_) {
      return qcApproxBounds.contains(p);
    }
  }

  void setBarangay(Barangay? b) => state = state.copyWith(barangay: () => b);

  /// Forgets the located point (demo tools clear their override with this). Keeps the
  /// barangay/search reference, selection and profile; drops the route because it started
  /// from the old point.
  void clearLocation() => state = SafePlacesState(
        selectedId: state.selectedId,
        barangay: state.barangay,
        profile: state.profile,
      );

  /// Plans a road-based route from the user to [center]. Locates the user first if needed.
  Future<void> requestRoute(EvacuationCenter center) async {
    select(center.id);
    var from = state.userPoint;
    if (from == null) {
      await locate();
      from = state.userPoint;
      if (from == null) return;
    }
    if (state.outsideServiceArea) {
      state = state.copyWith(routeError: () => RouteErrorCode.outsideArea);
      return;
    }
    state = state.copyWith(routing: true, route: () => null, routeError: () => null);
    final profile = state.profile;
    final result = await ref.read(routeServiceProvider).route(from, center.location, profile);
    // Ignore a late answer if the user picked another center or profile meanwhile.
    if (state.selectedId != center.id || state.profile != profile) {
      state = state.copyWith(routing: false);
      return;
    }
    state = switch (result) {
      RouteFound(:final plan) => state.copyWith(routing: false, route: () => plan),
      RouteFailed(:final code) => state.copyWith(routing: false, routeError: () => code),
    };
  }
}

final safePlacesProvider = NotifierProvider<SafePlacesController, SafePlacesState>(SafePlacesController.new);
