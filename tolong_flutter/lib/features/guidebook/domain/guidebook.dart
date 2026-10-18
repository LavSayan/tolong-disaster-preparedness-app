/// Text in both app languages. Falls back to English when a translation is missing.
class LocalizedText {
  const LocalizedText({required this.en, this.fil});

  final String en;
  final String? fil;

  String of(String languageCode) => languageCode == 'fil' && (fil?.isNotEmpty ?? false) ? fil! : en;

  factory LocalizedText.fromJson(Object? j) {
    if (j is String) return LocalizedText(en: j);
    final m = (j as Map?) ?? const {};
    return LocalizedText(en: m['en'] as String? ?? '', fil: m['fil'] as String?);
  }
}

enum GuidePhase { before, during, after, general }

class GuideSource {
  const GuideSource({required this.name, this.url, this.retrieved});

  final String name;
  final String? url;
  final String? retrieved;

  factory GuideSource.fromJson(Map<String, Object?> j) =>
      GuideSource(name: j['name'] as String? ?? '', url: j['url'] as String?, retrieved: j['retrieved'] as String?);
}

class GuideStep {
  const GuideStep({required this.text, this.image});

  final LocalizedText text;

  /// Optional bundled image under assets/guidebook/images/, so it works offline.
  final String? image;

  factory GuideStep.fromJson(Map<String, Object?> j) =>
      GuideStep(text: LocalizedText.fromJson(j['text']), image: j['image'] as String?);
}

class GuideSection {
  const GuideSection({
    required this.id,
    required this.phase,
    required this.title,
    required this.steps,
    required this.source,
    this.checklistTemplateIds = const [],
  });

  final String id;
  final GuidePhase phase;
  final LocalizedText title;
  final List<GuideStep> steps;

  /// Every section must say where its guidance comes from.
  final GuideSource source;

  /// Go-bag items this section relates to (links into the Prepare checklist).
  final List<String> checklistTemplateIds;

  factory GuideSection.fromJson(Map<String, Object?> j) => GuideSection(
        id: j['id'] as String,
        phase: GuidePhase.values.asNameMap()[j['phase']] ?? GuidePhase.general,
        title: LocalizedText.fromJson(j['title']),
        steps: [for (final s in j['steps'] as List? ?? const []) GuideStep.fromJson(s as Map<String, Object?>)],
        source: GuideSource.fromJson(j['source'] as Map<String, Object?>),
        checklistTemplateIds: (j['checklistTemplateIds'] as List?)?.cast<String>() ?? const [],
      );
}

class GuideCategory {
  const GuideCategory({
    required this.id,
    required this.icon,
    required this.accent,
    required this.title,
    required this.summary,
    required this.sections,
  });

  final String id;
  final String icon;
  final String accent;
  final LocalizedText title;
  final LocalizedText summary;
  final List<GuideSection> sections;

  bool get hasContent => sections.isNotEmpty;

  factory GuideCategory.fromJson(Map<String, Object?> j) => GuideCategory(
        id: j['id'] as String,
        icon: j['icon'] as String? ?? '',
        accent: j['accent'] as String? ?? 'sage',
        title: LocalizedText.fromJson(j['title']),
        summary: LocalizedText.fromJson(j['summary']),
        // Sections without a source are dropped: unsourced safety guidance is never shown.
        sections: [
          for (final s in j['sections'] as List? ?? const [])
            if ((s as Map)['source'] is Map && ((s['source'] as Map)['name'] as String? ?? '').isNotEmpty)
              GuideSection.fromJson(s.cast<String, Object?>()),
        ],
      );
}
