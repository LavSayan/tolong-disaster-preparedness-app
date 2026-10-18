import '../../../l10n/l10n.dart';
import '../../guidebook/domain/guidebook.dart';
import '../../prepare/domain/checklist.dart';
import '../../readiness/domain/readiness.dart';
import '../../readiness/domain/recommendations.dart';

/// Rule-based offline Tol. It is not a language model: it matches keywords and answers
/// only from data saved on this phone, plus fixed pointers to official sources.
enum TolIntent { emergency, alerts, goBag, water, food, expiry, readiness, evacuation, contacts, guide, greeting, unknown }

class TolIntentMatch {
  const TolIntentMatch(this.intent, {this.guideId});

  final TolIntent intent;
  final String? guideId;
}

String _normalize(String s) {
  const accents = {'ñ': 'n', 'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u'};
  final lower = s.toLowerCase();
  return [for (final ch in lower.split('')) accents[ch] ?? ch].join();
}

bool _word(String text, String w) => RegExp('(^|[^a-z])${RegExp.escape(w)}([^a-z]|\$)').hasMatch(text);

bool _any(String text, List<String> keys) => keys.any((k) => k.length <= 3 ? _word(text, k) : text.contains(k));

const _guideKeys = {
  'flood': ['flood', 'baha', 'binaha'],
  'earthquake': ['earthquake', 'lindol'],
  'fire': ['fire', 'sunog'],
  'typhoon': ['typhoon', 'bagyo', 'storm'],
  'first_aid': ['first aid', 'firstaid', 'paunang lunas'],
};

/// Ordered by safety: danger first, then "is something happening now", then app topics.
TolIntentMatch detectIntent(String question) {
  final t = _normalize(question);
  if (_any(t, ['emergency', 'help me', 'saklolo', 'trapped', 'naiipit', 'nasusunog', 'lumulubog', 'injured', 'sugatan', 'drowning', 'nalulunod', '911'])) {
    return const TolIntentMatch(TolIntent.emergency);
  }
  if (_any(t, ['alert', 'advisory', 'abiso', 'weather', 'panahon', 'forecast', 'signal no', 'ngayon', 'right now', 'today', 'current'])) {
    return const TolIntentMatch(TolIntent.alerts);
  }
  if (_any(t, ['go-bag', 'gobag', 'go bag', 'checklist', 'kit', 'dalhin', 'ilalagay', 'bag', 'pack'])) {
    return const TolIntentMatch(TolIntent.goBag);
  }
  if (_any(t, ['water', 'tubig'])) return const TolIntentMatch(TolIntent.water);
  if (_any(t, ['food', 'pagkain', 'meal', 'ulam', 'bigas', 'rice'])) return const TolIntentMatch(TolIntent.food);
  if (_any(t, ['expire', 'expiry', 'expired', 'luma na', 'sira'])) return const TolIntentMatch(TolIntent.expiry);
  // A named hazard ("maghanda sa lindol") is more specific than generic "get ready" words.
  for (final e in _guideKeys.entries) {
    if (_any(t, e.value)) return TolIntentMatch(TolIntent.guide, guideId: e.key);
  }
  if (_any(t, ['ready', 'readiness', 'score', 'handa', 'kahandaan', 'una kong', 'start', 'simula'])) {
    return const TolIntentMatch(TolIntent.readiness);
  }
  if (_any(t, ['evacuat', 'center', 'shelter', 'lilikas', 'lumikas', 'ligtas na lugar', 'safe place', 'route', 'ruta'])) {
    return const TolIntentMatch(TolIntent.evacuation);
  }
  if (_any(t, ['contact', 'kontak', 'tatawagan'])) return const TolIntentMatch(TolIntent.contacts);
  if (_any(t, ['hi', 'hello', 'kumusta', 'hey', 'musta', 'good morning', 'magandang'])) {
    return const TolIntentMatch(TolIntent.greeting);
  }
  return const TolIntentMatch(TolIntent.unknown);
}

/// Everything the offline guide may read. Any part can be missing while data loads.
class OfflineSnapshot {
  const OfflineSnapshot({
    this.checklist,
    this.readiness,
    this.recommendations = const [],
    this.contactCount = 0,
    this.guides = const [],
  });

  final List<ChecklistItemView>? checklist;
  final ReadinessReport? readiness;
  final List<Recommendation> recommendations;
  final int contactCount;
  final List<GuideCategory> guides;
}

String offlineAnswer(AppLocalizations l, String question, OfflineSnapshot s) {
  final match = detectIntent(question);
  final supplies = s.readiness?.supplies;
  switch (match.intent) {
    case TolIntent.emergency:
      return l.tolOffEmergency;
    case TolIntent.alerts:
      return l.tolOffAlerts;
    case TolIntent.goBag:
      final items = s.checklist;
      if (items == null || items.isEmpty) return l.tolOffFallback;
      final todo = items.where((i) => !i.done).toList();
      if (todo.isEmpty) return l.tolOffGoBagDone;
      return l.tolOffGoBag(items.length - todo.length, todo.take(3).map(l.checklistTitle).join(', '), items.length);
    case TolIntent.water:
      if (supplies == null || supplies.water.available <= 0) return l.tolOffWaterNone;
      return l.tolOffWater(supplies.householdSize, l.number(supplies.water.days), supplies.targets.targetDays);
    case TolIntent.food:
      if (supplies == null || supplies.food.available <= 0) return l.tolOffFoodNone;
      return l.tolOffFood(supplies.householdSize, l.number(supplies.food.days), supplies.targets.targetDays);
    case TolIntent.expiry:
      if (supplies == null || (supplies.expired.isEmpty && supplies.expiringSoon.isEmpty)) return l.tolOffExpiryNone;
      final none = l.essentialNone;
      return l.tolOffExpiry(
        supplies.expired.isEmpty ? none : supplies.expired.map((i) => i.name).join(', '),
        supplies.expiringSoon.isEmpty ? none : supplies.expiringSoon.map((i) => i.name).join(', '),
      );
    case TolIntent.readiness:
      final r = s.readiness;
      if (r == null) return l.tolOffFallback;
      if (s.recommendations.isEmpty) return l.tolOffReadinessNoTip(r.score);
      return l.tolOffReadiness(r.score, l.recommendation(s.recommendations.first));
    case TolIntent.evacuation:
      return l.tolOffEvacuation;
    case TolIntent.contacts:
      return l.tolOffContacts(s.contactCount);
    case TolIntent.guide:
      final g = s.guides.where((c) => c.id == match.guideId).firstOrNull;
      final name = g?.title.of(l.localeName) ?? match.guideId!;
      return g != null && g.hasContent ? l.tolOffGuideReady(name) : l.tolOffGuideSoon(name);
    case TolIntent.greeting:
      return l.tolOffGreeting;
    case TolIntent.unknown:
      return l.tolOffFallback;
  }
}
