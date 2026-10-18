import '../../household/domain/models.dart';
import '../../readiness/domain/readiness.dart';

enum TolRole { user, tol }

/// Where a Tol reply came from. Shown on every message so users can tell AI from saved guidance.
enum TolMode { online, offline }

class TolMessage {
  const TolMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.createdAt,
    this.mode,
    this.onlineFailed = false,
  });

  final String id;
  final TolRole role;
  final String text;
  final DateTime createdAt;

  /// Set for Tol replies.
  final TolMode? mode;

  /// True when Tol tried to answer online, couldn't, and fell back to offline guidance.
  final bool onlineFailed;

  Map<String, Object?> toJson() => {
        'id': id,
        'role': role.name,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
        'mode': mode?.name,
        'onlineFailed': onlineFailed,
      };

  factory TolMessage.fromJson(Map<String, Object?> j) => TolMessage(
        id: j['id'] as String,
        role: TolRole.values.asNameMap()[j['role']] ?? TolRole.user,
        text: j['text'] as String? ?? '',
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
        mode: TolMode.values.asNameMap()[j['mode']],
        onlineFailed: j['onlineFailed'] == true,
      );
}

/// What the app really knows, sent so the model can't present demo data as fact.
class TolFacts {
  const TolFacts({required this.alertsConnected, required this.centersVerified, required this.guidebookHasContent});

  final bool alertsConnected;
  final bool centersVerified;
  final bool guidebookHasContent;

  Map<String, Object?> toJson() => {
        'alertsConnected': alertsConnected,
        'centersVerified': centersVerified,
        'guidebookHasContent': guidebookHasContent,
      };
}

/// Household summary shared only with consent. Deliberately excludes names, ages of
/// individuals, phone numbers, contacts and medicine names.
Map<String, Object?> householdSummary({
  required HouseholdProfile? household,
  required UserProfile? profile,
  required ReadinessReport? readiness,
}) {
  final s = readiness?.supplies;
  return {
    if (household != null) ...{
      'householdSize': household.size,
      'hasChildren': household.children > 0,
      'hasSeniors': household.seniors > 0,
      if (household.hasPets != null) 'hasPets': household.hasPets,
      'hasAssistanceNeeds': household.assistanceNeeds?.trim().isNotEmpty == true,
    },
    if (profile?.barangay.isNotEmpty == true) 'barangay': profile!.barangay,
    if (readiness != null) ...{
      'readinessScore': readiness.score,
      'checklistDone': readiness.checklistDone,
      'checklistTotal': readiness.checklistTotal,
    },
    if (s != null) ...{
      'waterDays': double.parse(s.water.days.toStringAsFixed(1)),
      'missingSupplies': [for (final c in s.missingEssentials) c.name],
    },
  };
}

/// Last [max] messages in the shape the Edge Function expects.
List<Map<String, String>> conversationForApi(List<TolMessage> messages, {int max = 12}) => [
      for (final m in messages.length > max ? messages.sublist(messages.length - max) : messages)
        {'role': m.role == TolRole.user ? 'user' : 'assistant', 'content': m.text},
    ];
