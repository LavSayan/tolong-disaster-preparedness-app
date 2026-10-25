import '../../safe_places/domain/evacuation_center.dart';

/// What kind of simulated advisory the demo tools can put on Home. Only advisory *text*
/// changes; the card always carries the simulated tag, and nothing in the app changes its
/// behaviour or data because of it.
enum DemoDisasterType { flood, earthquake, fire }

enum DemoSeverity { advisory, warning, severe }

/// One simulated advisory, exactly as the admin typed it. No persistence: it lives only in
/// the session state, so every launch of the demo build starts clean.
class DemoAdvisory {
  const DemoAdvisory({
    required this.type,
    required this.severity,
    required this.area,
    this.message,
  });

  final DemoDisasterType type;
  final DemoSeverity severity;

  /// Affected places as free text (or a barangay name picked from the search sheet).
  final String area;

  /// Optional custom sentence; when empty the card shows the built-in simulation note.
  final String? message;
}

enum DemoWeightsMode { trained, baseline }

class DemoState {
  const DemoState({
    this.locationOverride,
    this.advisory,
    this.advisoryRevision = 0,
    this.weightsMode = DemoWeightsMode.trained,
    this.fakeRoute = false,
  });

  final GeoPoint? locationOverride;
  final DemoAdvisory? advisory;

  /// Bumped on every advisory change so Home can dismiss a card while the next one still
  /// shows. Dismissal is compared against this revision, never against the object itself.
  final int advisoryRevision;
  final DemoWeightsMode weightsMode;
  final bool fakeRoute;

  /// True while at least one simulated input differs from the launch defaults; drives the
  /// app-wide "demo overrides active" banner.
  bool get hasOverrides =>
      locationOverride != null || advisory != null || weightsMode != DemoWeightsMode.trained || fakeRoute;

  DemoState copyWith({
    GeoPoint? locationOverride,
    bool clearLocationOverride = false,
    DemoAdvisory? advisory,
    bool clearAdvisory = false,
    int? advisoryRevision,
    DemoWeightsMode? weightsMode,
    bool? fakeRoute,
  }) =>
      DemoState(
        locationOverride: clearLocationOverride ? null : (locationOverride ?? this.locationOverride),
        advisory: clearAdvisory ? null : (advisory ?? this.advisory),
        advisoryRevision: advisoryRevision ?? this.advisoryRevision,
        weightsMode: weightsMode ?? this.weightsMode,
        fakeRoute: fakeRoute ?? this.fakeRoute,
      );
}

class DemoLocationPreset {
  const DemoLocationPreset(this.label, this.point);

  final String label;
  final GeoPoint point;
}

/// City demo presets. The first four are inside Quezon City; the last sits outside the
/// boundary so the outside-service-area flow can be shown without leaving the desk chair.
const demoLocationPresets = [
  DemoLocationPreset('Batasan Hills', GeoPoint(14.7010, 121.0987)),
  DemoLocationPreset('Cubao — Araneta area', GeoPoint(14.6208, 121.0910)),
  DemoLocationPreset('Fairview', GeoPoint(14.7430, 121.0640)),
  DemoLocationPreset('UP Diliman', GeoPoint(14.6539, 121.0561)),
  DemoLocationPreset('Outside QC — Manila City Hall', GeoPoint(14.5889, 120.9804)),
];

/// A scripted flood scenario the panel can fill in with one tap.
const demoFloodSample = DemoAdvisory(
  type: DemoDisasterType.flood,
  severity: DemoSeverity.warning,
  area: 'Batasan Hills, Commonwealth',
  message:
      'Rising water along a creek in the marked barangays. Shelters are open; avoid flooded underpasses.',
);
