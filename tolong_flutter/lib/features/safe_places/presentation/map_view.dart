import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../data/hazard_layer_service.dart';
import '../data/map_style.dart';
import '../domain/evacuation_center.dart';
import '../domain/hazard.dart';

/// Camera commands the screen can send to whichever map implementation is mounted.
abstract interface class MapHandle {
  Future<void> focus(GeoPoint point, {double zoom});
  Future<void> showBounds(GeoBounds bounds);
  Future<void> zoomIn();
  Future<void> zoomOut();
}

typedef MapViewBuilder = Widget Function({
  required List<EvacuationCenter> centers,
  required String? selectedId,
  required GeoPoint? user,
  required List<GeoPoint>? route,
  required List<List<GeoPoint>>? outline,
  required ValueChanged<String> onCenterTap,
  required ValueChanged<MapHandle> onReady,
  HazardGroup? hazardGroup,
  ValueChanged<HazardDrawState>? onHazardDrawState,
});

/// Swappable so widget tests can use a fake (platform map views don't render in tests).
final mapViewBuilderProvider = Provider<MapViewBuilder>(
  (ref) => ({
    required centers,
    required selectedId,
    required user,
    required route,
    required outline,
    required onCenterTap,
    required onReady,
    hazardGroup,
    onHazardDrawState,
  }) =>
      MapLibreView(
        centers: centers,
        selectedId: selectedId,
        user: user,
        route: route,
        outline: outline,
        onCenterTap: onCenterTap,
        onReady: onReady,
        hazardGroup: hazardGroup,
        onHazardDrawState: onHazardDrawState,
      ),
);

LatLng _ll(GeoPoint p) => LatLng(p.lat, p.lng);

LatLngBounds _bounds(GeoBounds b) => LatLngBounds(southwest: _ll(b.southwest), northeast: _ll(b.northeast));

class MapLibreView extends StatefulWidget {
  const MapLibreView({
    super.key,
    required this.centers,
    required this.selectedId,
    required this.user,
    required this.route,
    required this.outline,
    required this.onCenterTap,
    required this.onReady,
    this.hazardGroup,
    this.onHazardDrawState,
  });

  final List<EvacuationCenter> centers;
  final String? selectedId;
  final GeoPoint? user;
  final List<GeoPoint>? route;

  /// Service-area outline (Quezon City boundary rings).
  final List<List<GeoPoint>>? outline;
  final ValueChanged<String> onCenterTap;
  final ValueChanged<MapHandle> onReady;

  /// Modelled hazard to overlay, or `null` for none.
  final HazardGroup? hazardGroup;

  /// Reports whether the active hazard overlay is actually drawing, [HazardDrawState] first
  /// resolving on the first `onMapIdle` after the layers are added. The screen surfaces
  /// [HazardDrawState.filterMatchedNothing] in the legend, because that state is the silent
  /// failure the overlay once had: data loaded, filter matched nothing, no error anywhere.
  final ValueChanged<HazardDrawState>? onHazardDrawState;

  @override
  State<MapLibreView> createState() => _MapLibreViewState();
}

class _MapLibreViewState extends State<MapLibreView> implements MapHandle {
  MapLibreMapController? _controller;
  bool _styleLoaded = false;
  Future<void> _pending = Future.value();

  /// Style layer ids this widget added for the hazard overlay, so they can be removed again.
  final Set<String> _hazardLayerIds = {};

  /// Whether the hazard source has been registered with the *current* style.
  ///
  /// Sources survive a group switch but not a style reload: re-adding one that exists is ignored
  /// on Android but throws in MapLibre GL JS, which would abort the whole sync and leave the new
  /// group undrawn. The flag is reset from [_onStyleLoaded], the one place a style replaces every
  /// runtime source.
  bool _hazardSourceAdded = false;

  /// The last [HazardDrawState] reported to `widget.onHazardDrawState`, so the callback fires on
  /// change rather than every idle frame. Reset when the group changes or the style reloads,
  /// because either event redraws the layers the counts are read from.
  HazardDrawState? _lastReported;

  @override
  void didUpdateWidget(MapLibreView old) {
    super.didUpdateWidget(old);
    if (old.centers != widget.centers || old.selectedId != widget.selectedId || old.user != widget.user) {
      _syncMarkers();
    }
    if (old.route != widget.route || old.outline != widget.outline) {
      _syncLines();
      final r = widget.route;
      if (old.route != widget.route && r != null && r.length > 1) showBounds(boundsOf(r));
    }
    if (old.hazardGroup != widget.hazardGroup) {
      _lastReported = null;
      _syncHazard();
    }
  }

  /// Adds the bundled NOAH hazard archive and one fill layer per severity band.
  ///
  /// Runs from `_onStyleLoaded`, never `_onMapCreated`: MapLibre discards every source and layer
  /// added at runtime when the style is replaced, and that callback is already the place markers
  /// and lines are (re)drawn.
  ///
  /// Added layer ids are tracked in [_hazardLayerIds] rather than read back from the style, which
  /// would mean parsing the whole style JSON on every change.
  ///
  /// Any failure here is logged and swallowed. The overlay is supplementary — if the archive is
  /// missing or the protocol unregistered the map must still work, because an evacuation centre
  /// marker matters more than a flood band.
  void _syncHazard() {
    _pending = _pending.then((_) async {
      final c = _controller;
      if (c == null || !_styleLoaded || !mounted) return;
      const sourceId = HazardLayerSpec.sourceId;
      final group = widget.hazardGroup;
      try {
        // Clear previous bands first so switching groups never leaves stale fills behind.
        for (final id in _hazardLayerIds) {
          try {
            await c.removeLayer(id);
          } catch (_) {
            // Already gone (e.g. the style reloaded under us); nothing to undo.
          }
        }
        _hazardLayerIds.clear();
        if (group == null) return;

        if (!_hazardSourceAdded) {
          await c.addSource(sourceId, VectorSourceProperties(url: hazardArchiveUrl));
          _hazardSourceAdded = true;
        }
        for (final spec in hazardLayerSpecs(group)) {
          await c.addFillLayer(
            sourceId,
            spec.id,
            FillLayerProperties(
              fillColor: spec.band.color,
              fillOpacity: spec.opacity,
            ),
            sourceLayer: spec.sourceLayer,
            filter: hazardFilterExpression(spec),
          );
          _hazardLayerIds.add(spec.id);
        }
      } catch (e) {
        debugPrint('Hazard overlay unavailable: ${e.runtimeType}');
        _hazardLayerIds.clear();
      }
    });
  }

  /// Counts what the hazard overlay actually drew once the map settles.
  ///
  /// The overlay can fail **silently**: a severity filter that matches nothing paints no fills
  /// and throws no error, which once showed a legend over a colourless map for days. So after
  /// each idle frame with an active group, the source is queried unfiltered (features loaded for
  /// this view) and again under `hazardGroupFilterExpression` (what the filters select).
  /// `classifyDraw` turns the two counts into the state the screen reports — a non-empty source
  /// with zero matches is [HazardDrawState.filterMatchedNothing], the only state the legend
  /// warns about, because an empty view and a drawn view are both normal.
  Future<void> _onMapIdle() async {
    final group = widget.hazardGroup;
    if (group == null || _hazardLayerIds.isEmpty) return;
    _pending = _pending.then((_) async {
      final c = _controller;
      if (c == null || !_styleLoaded || !mounted) return;
      try {
        var sourceCount = 0;
        var matchedCount = 0;
        const sourceId = HazardLayerSpec.sourceId;
        for (final layer in group.sourceLayers) {
          final unfiltered = c.querySourceFeatures(sourceId, layer, null);
          final filtered =
              c.querySourceFeatures(sourceId, layer, hazardGroupFilterExpression(group));
          sourceCount += (await unfiltered).length;
          matchedCount += (await filtered).length;
        }
        final state = classifyDraw(sourceCount: sourceCount, matchedCount: matchedCount);
        if (kDebugMode) {
          debugPrint('Hazard overlay draws $matchedCount of $sourceCount loaded ($state)');
        }
        if (state != _lastReported) {
          _lastReported = state;
          widget.onHazardDrawState?.call(state);
        }
      } catch (e) {
        // A style reload can beat the layers; the next idle pin re-checks.
        debugPrint('Hazard draw check skipped: ${e.runtimeType}');
      }
    });
  }

  /// Draws the city outline (thin) and the route (thick) on the line layer.
  void _syncLines() {
    _pending = _pending.then((_) async {
      final c = _controller;
      if (c == null || !_styleLoaded || !mounted) return;
      await c.clearLines();
      for (final ring in widget.outline ?? const <List<GeoPoint>>[]) {
        await c.addLine(LineOptions(
          geometry: [for (final p in ring) _ll(p)],
          lineColor: '#3F5D51',
          lineWidth: 1.6,
          lineOpacity: 0.55,
        ));
      }
      final r = widget.route;
      if (r == null || r.length < 2) return;
      await c.addLine(LineOptions(
        geometry: [for (final p in r) _ll(p)],
        lineColor: '#63896D',
        lineWidth: 5,
        lineOpacity: 0.9,
        lineJoin: 'round',
      ));
    }).catchError((Object e) => debugPrint('Line draw failed: ${e.runtimeType}'));
  }

  @override
  void dispose() {
    _controller?.onCircleTapped.remove(_onCircleTapped);
    super.dispose();
  }

  void _onMapCreated(MapLibreMapController controller) {
    _controller = controller;
    controller.onCircleTapped.add(_onCircleTapped);
    widget.onReady(this);
  }

  void _onStyleLoaded() {
    _styleLoaded = true;
    _hazardSourceAdded = false;
    _hazardLayerIds.clear();
    _lastReported = null;
    _syncMarkers();
    _syncLines();
    _syncHazard();
    final r = widget.route;
    final o = widget.outline;
    showBounds(r != null && r.length > 1
        ? boundsOf(r)
        : (o != null && o.isNotEmpty ? boundsOf([for (final ring in o) ...ring]) : qcApproxBounds));
  }

  void _onCircleTapped(Circle circle) {
    final id = circle.data?['id'];
    if (id is String) widget.onCenterTap(id);
  }

  /// Fallback for platforms where annotation taps don't arrive (seen on web): treat a map tap
  /// within ~28 screen pixels of a center as a tap on that center.
  void _onMapClick(Point<double> _, LatLng tapped) {
    final zoom = _controller?.cameraPosition?.zoom;
    if (zoom == null || widget.centers.isEmpty) return;
    final hit = nearestWithinPixels(widget.centers, GeoPoint(tapped.latitude, tapped.longitude), zoom, 28);
    if (hit != null) widget.onCenterTap(hit.id);
  }

  /// Redraws all markers. Calls are chained so overlapping updates can't interleave.
  void _syncMarkers() {
    _pending = _pending.then((_) async {
      final c = _controller;
      if (c == null || !_styleLoaded || !mounted) return;
      await c.clearCircles();
      for (final center in widget.centers) {
        final selected = center.id == widget.selectedId;
        await c.addCircle(
          CircleOptions(
            geometry: _ll(center.location),
            circleRadius: selected ? 11 : 8,
            circleColor: selected ? '#BD7357' : '#6D91A2',
            circleBlur: 0,
            circleOpacity: 1,
            circleStrokeWidth: 3,
            circleStrokeColor: '#FFFFFF',
            circleStrokeOpacity: 1,
          ),
          {'id': center.id},
        );
      }
      final user = widget.user;
      if (user != null) {
        await c.addCircle(CircleOptions(
          geometry: _ll(user),
          circleRadius: 7,
          circleColor: '#2F6FED',
          circleBlur: 0,
          circleOpacity: 1,
          circleStrokeWidth: 3,
          circleStrokeColor: '#FFFFFF',
          circleStrokeOpacity: 1,
        ));
      }
    }).catchError((Object e) => debugPrint('Marker sync failed: ${e.runtimeType}'));
  }

  Future<void> _camera(CameraUpdate update) async {
    final c = _controller;
    if (c == null) return;
    if (mounted && MediaQuery.disableAnimationsOf(context)) {
      await c.moveCamera(update);
    } else {
      await c.animateCamera(update, duration: const Duration(milliseconds: 650));
    }
  }

  @override
  Future<void> focus(GeoPoint point, {double zoom = 15}) => _camera(CameraUpdate.newLatLngZoom(_ll(point), zoom));

  @override
  Future<void> showBounds(GeoBounds bounds) =>
      _camera(CameraUpdate.newLatLngBounds(_bounds(bounds), left: 24, top: 24, right: 24, bottom: 24));

  @override
  Future<void> zoomIn() => _camera(CameraUpdate.zoomIn());

  @override
  Future<void> zoomOut() => _camera(CameraUpdate.zoomOut());

  @override
  Widget build(BuildContext context) {
    return MapLibreMap(
      styleString: BasemapStyle.current.styleUrl,
      initialCameraPosition: CameraPosition(target: _ll(qcApproxBounds.center), zoom: 11.2),
      cameraTargetBounds: CameraTargetBounds(_bounds(metroPanBounds)),
      minMaxZoomPreference: const MinMaxZoomPreference(10, 18),
      onMapCreated: _onMapCreated,
      onStyleLoadedCallback: _onStyleLoaded,
      onMapClick: _onMapClick,
      onMapIdle: _onMapIdle,
      trackCameraPosition: true,
      compassEnabled: false,
      rotateGesturesEnabled: false,
      tiltGesturesEnabled: false,
      attributionButtonPosition: AttributionButtonPosition.bottomRight,
      // Lets the map own drag gestures while it sits inside the scrolling page.
      gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{
        Factory<OneSequenceGestureRecognizer>(EagerGestureRecognizer.new),
      },
    );
  }
}
