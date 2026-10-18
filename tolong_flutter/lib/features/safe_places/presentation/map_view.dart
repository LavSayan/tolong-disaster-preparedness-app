import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../data/map_style.dart';
import '../domain/evacuation_center.dart';

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
  }) =>
      MapLibreView(
        centers: centers,
        selectedId: selectedId,
        user: user,
        route: route,
        outline: outline,
        onCenterTap: onCenterTap,
        onReady: onReady,
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
  });

  final List<EvacuationCenter> centers;
  final String? selectedId;
  final GeoPoint? user;
  final List<GeoPoint>? route;

  /// Service-area outline (Quezon City boundary rings).
  final List<List<GeoPoint>>? outline;
  final ValueChanged<String> onCenterTap;
  final ValueChanged<MapHandle> onReady;

  @override
  State<MapLibreView> createState() => _MapLibreViewState();
}

class _MapLibreViewState extends State<MapLibreView> implements MapHandle {
  MapLibreMapController? _controller;
  bool _styleLoaded = false;
  Future<void> _pending = Future.value();

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
    _syncMarkers();
    _syncLines();
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
      styleString: openFreeMapStyle,
      initialCameraPosition: CameraPosition(target: _ll(qcApproxBounds.center), zoom: 11.2),
      cameraTargetBounds: CameraTargetBounds(_bounds(metroPanBounds)),
      minMaxZoomPreference: const MinMaxZoomPreference(10, 18),
      onMapCreated: _onMapCreated,
      onStyleLoadedCallback: _onStyleLoaded,
      onMapClick: _onMapClick,
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
