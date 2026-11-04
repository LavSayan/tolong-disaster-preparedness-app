import '../../../l10n/l10n.dart';
import '../../alerts/presentation/alert_card.dart';
import '../domain/demo_models.dart';

/// The four localized strings the shared [AlertCard] renders, derived from one
/// [DemoAdvisory]. Home (card) and the header bell (sheet) compose the same texts from the
/// same advisory so the two surfaces can never drift apart.
class AdvisoryTexts {
  const AdvisoryTexts({required this.category, required this.title, required this.body, required this.tag});

  final String category;
  final String title;
  final String body;
  final String tag;
}

AdvisoryTexts advisoryTexts(AppLocalizations l, DemoAdvisory a) {
  final severity = switch (a.severity) {
    DemoSeverity.advisory => l.alertSeverityAdvisory,
    DemoSeverity.warning => l.alertSeverityWarning,
    DemoSeverity.severe => l.alertSeveritySevere,
  };
  return AdvisoryTexts(
    category: switch (a.type) {
      DemoDisasterType.flood => l.alertTypeFlood,
      DemoDisasterType.earthquake => l.alertTypeEarthquake,
      DemoDisasterType.fire => l.alertTypeFire,
    },
    title: '$severity · ${a.area.trim()}',
    body: a.message?.trim().isEmpty ?? true ? l.alertSimulatedNote : a.message!.trim(),
    tag: l.alertSimulatedTag,
  );
}
