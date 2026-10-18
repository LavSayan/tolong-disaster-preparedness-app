import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env.dart';
import '../domain/evacuation_center.dart';

enum RouteProfile {
  walking('foot-walking'),
  wheelchair('wheelchair');

  const RouteProfile(this.apiName);

  final String apiName;
}

class RoutePlan {
  const RoutePlan({
    required this.profile,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.points,
    required this.attribution,
  });

  final RouteProfile profile;
  final double distanceMeters;
  final double durationSeconds;
  final List<GeoPoint> points;
  final String attribution;
}

enum RouteErrorCode { notConfigured, network, noRoute, outsideArea, quota, unknown }

sealed class RouteResult {
  const RouteResult();
}

class RouteFound extends RouteResult {
  const RouteFound(this.plan);
  final RoutePlan plan;
}

class RouteFailed extends RouteResult {
  const RouteFailed(this.code);
  final RouteErrorCode code;
}

abstract interface class RouteService {
  /// Road-based route from [from] to [to]. Never throws; failures come back as [RouteFailed].
  Future<RouteResult> route(GeoPoint from, GeoPoint to, RouteProfile profile);
}

/// Calls the `tol-route` Supabase Edge Function, which holds the OpenRouteService key.
class EdgeFunctionRouteService implements RouteService {
  @override
  Future<RouteResult> route(GeoPoint from, GeoPoint to, RouteProfile profile) async {
    try {
      final res = await Supabase.instance.client.functions.invoke('tol-route', body: {
        'from': {'lat': from.lat, 'lng': from.lng},
        'to': {'lat': to.lat, 'lng': to.lng},
        'profile': profile.apiName,
      });
      return parseRouteResponse(res.data, profile);
    } on FunctionException catch (e) {
      return RouteFailed(errorFromCode(_errorCode(e.details), e.status));
    } catch (e) {
      debugPrint('Route request failed: ${e.runtimeType}');
      return const RouteFailed(RouteErrorCode.network);
    }
  }

  static String? _errorCode(Object? details) => details is Map ? details['error'] as String? : null;
}

@visibleForTesting
RouteErrorCode errorFromCode(String? code, int status) => switch (code) {
      'not_configured' => RouteErrorCode.notConfigured,
      'no_route' => RouteErrorCode.noRoute,
      'outside_area' => RouteErrorCode.outsideArea,
      'quota_exceeded' || 'rate_limited' => RouteErrorCode.quota,
      'upstream_unreachable' => RouteErrorCode.network,
      _ => status == 404 ? RouteErrorCode.notConfigured : RouteErrorCode.unknown,
    };

@visibleForTesting
RouteResult parseRouteResponse(Object? data, RouteProfile profile) {
  if (data is! Map) return const RouteFailed(RouteErrorCode.unknown);
  final raw = data['points'];
  if (raw is! List || raw.length < 2) return const RouteFailed(RouteErrorCode.noRoute);
  return RouteFound(RoutePlan(
    profile: profile,
    distanceMeters: (data['distance_m'] as num?)?.toDouble() ?? 0,
    durationSeconds: (data['duration_s'] as num?)?.toDouble() ?? 0,
    points: [for (final p in raw.cast<List>()) GeoPoint((p[0] as num).toDouble(), (p[1] as num).toDouble())],
    attribution: data['attribution'] as String? ?? '',
  ));
}

/// Used when the build has no Supabase configuration, so routing fails honestly.
class UnavailableRouteService implements RouteService {
  @override
  Future<RouteResult> route(GeoPoint from, GeoPoint to, RouteProfile profile) async =>
      const RouteFailed(RouteErrorCode.notConfigured);
}

final routeServiceProvider = Provider<RouteService>(
  (ref) => Env.supabaseConfigured ? EdgeFunctionRouteService() : UnavailableRouteService(),
);
