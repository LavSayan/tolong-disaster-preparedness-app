import '../../household/domain/models.dart';

enum ChecklistCategory { waterFood, firstAidMeds, lightPower, clothing, hygiene, documents, communication, specialNeeds }

enum HouseholdNeed { children, seniors, pets, assistance }

/// A built-in go-bag item. Titles are localized by id; [need] marks household-specific suggestions.
class ChecklistTemplate {
  const ChecklistTemplate(this.id, this.category, {this.need});

  final String id;
  final ChecklistCategory category;
  final HouseholdNeed? need;
}

/// Ids are stable: saved progress is keyed by them, so never rename an id.
const goBagTemplates = [
  ChecklistTemplate('water', ChecklistCategory.waterFood),
  ChecklistTemplate('food', ChecklistCategory.waterFood),
  ChecklistTemplate('can_opener', ChecklistCategory.waterFood),
  ChecklistTemplate('first_aid_kit', ChecklistCategory.firstAidMeds),
  ChecklistTemplate('medicines', ChecklistCategory.firstAidMeds),
  ChecklistTemplate('masks', ChecklistCategory.firstAidMeds),
  ChecklistTemplate('flashlight', ChecklistCategory.lightPower),
  ChecklistTemplate('batteries', ChecklistCategory.lightPower),
  ChecklistTemplate('power_bank', ChecklistCategory.lightPower),
  ChecklistTemplate('clothes', ChecklistCategory.clothing),
  ChecklistTemplate('rain_gear', ChecklistCategory.clothing),
  ChecklistTemplate('blanket', ChecklistCategory.clothing),
  ChecklistTemplate('toiletries', ChecklistCategory.hygiene),
  ChecklistTemplate('sanitary', ChecklistCategory.hygiene),
  ChecklistTemplate('documents', ChecklistCategory.documents),
  ChecklistTemplate('cash', ChecklistCategory.documents),
  ChecklistTemplate('contact_list', ChecklistCategory.communication),
  ChecklistTemplate('whistle', ChecklistCategory.communication),
  ChecklistTemplate('radio', ChecklistCategory.communication),
  ChecklistTemplate('infant_supplies', ChecklistCategory.specialNeeds, need: HouseholdNeed.children),
  ChecklistTemplate('child_comfort', ChecklistCategory.specialNeeds, need: HouseholdNeed.children),
  ChecklistTemplate('senior_meds', ChecklistCategory.specialNeeds, need: HouseholdNeed.seniors),
  ChecklistTemplate('mobility_aids', ChecklistCategory.specialNeeds, need: HouseholdNeed.seniors),
  ChecklistTemplate('pet_supplies', ChecklistCategory.specialNeeds, need: HouseholdNeed.pets),
  ChecklistTemplate('pet_carrier', ChecklistCategory.specialNeeds, need: HouseholdNeed.pets),
  ChecklistTemplate('assistive_devices', ChecklistCategory.specialNeeds, need: HouseholdNeed.assistance),
];

class TemplateItemState {
  const TemplateItemState({this.done = false, this.editedTitle});

  final bool done;
  final String? editedTitle;

  Map<String, Object?> toJson() => {'done': done, 'editedTitle': editedTitle};

  factory TemplateItemState.fromJson(Map<String, Object?> j) =>
      TemplateItemState(done: j['done'] as bool? ?? false, editedTitle: j['editedTitle'] as String?);
}

class CustomChecklistItem {
  const CustomChecklistItem({required this.id, required this.title, required this.category, this.done = false});

  final String id;
  final String title;
  final ChecklistCategory category;
  final bool done;

  CustomChecklistItem copyWith({String? title, ChecklistCategory? category, bool? done}) => CustomChecklistItem(
        id: id,
        title: title ?? this.title,
        category: category ?? this.category,
        done: done ?? this.done,
      );

  Map<String, Object?> toJson() => {'id': id, 'title': title, 'category': category.name, 'done': done};

  factory CustomChecklistItem.fromJson(Map<String, Object?> j) => CustomChecklistItem(
        id: j['id'] as String,
        title: j['title'] as String? ?? '',
        category: ChecklistCategory.values.asNameMap()[j['category']] ?? ChecklistCategory.specialNeeds,
        done: j['done'] as bool? ?? false,
      );
}

/// What the user changed. Template items the user never touched have no entry, so new
/// templates appear automatically and template updates never overwrite user edits.
class ChecklistState {
  const ChecklistState({this.templates = const {}, this.custom = const [], this.updatedAt});

  final Map<String, TemplateItemState> templates;
  final List<CustomChecklistItem> custom;
  final DateTime? updatedAt;

  Map<String, Object?> toJson() => {
        'templates': templates.map((k, v) => MapEntry(k, v.toJson())),
        'custom': custom.map((c) => c.toJson()).toList(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  factory ChecklistState.fromJson(Map<String, Object?> j) => ChecklistState(
        templates: (j['templates'] as Map<String, Object?>? ?? const {})
            .map((k, v) => MapEntry(k, TemplateItemState.fromJson(v as Map<String, Object?>))),
        custom: (j['custom'] as List? ?? const [])
            .map((e) => CustomChecklistItem.fromJson(e as Map<String, Object?>))
            .toList(),
        updatedAt: j['updatedAt'] == null ? null : DateTime.tryParse(j['updatedAt'] as String),
      );
}

class ChecklistItemView {
  const ChecklistItemView({
    required this.id,
    required this.category,
    required this.done,
    this.templateId,
    this.customTitle,
    this.suggestedFor,
  });

  /// Template id or custom id.
  final String id;
  final String? templateId;

  /// Set for custom items and edited template items; otherwise use the localized template title.
  final String? customTitle;
  final ChecklistCategory category;
  final bool done;
  final HouseholdNeed? suggestedFor;

  bool get isCustom => templateId == null;
}

Set<HouseholdNeed> needsOf(HouseholdProfile? h) => {
      if (h != null && h.children > 0) HouseholdNeed.children,
      if (h != null && h.seniors > 0) HouseholdNeed.seniors,
      if (h?.hasPets == true) HouseholdNeed.pets,
      if (h?.assistanceNeeds?.trim().isNotEmpty == true) HouseholdNeed.assistance,
    };

/// Merges templates (filtered to this household's needs) with the user's saved state.
List<ChecklistItemView> buildChecklist(ChecklistState state, HouseholdProfile? household) {
  final needs = needsOf(household);
  final items = <ChecklistItemView>[
    for (final t in goBagTemplates)
      if (t.need == null || needs.contains(t.need) || state.templates[t.id]?.done == true)
        ChecklistItemView(
          id: t.id,
          templateId: t.id,
          category: t.category,
          done: state.templates[t.id]?.done ?? false,
          customTitle: state.templates[t.id]?.editedTitle,
          suggestedFor: t.need,
        ),
    for (final c in state.custom) ChecklistItemView(id: c.id, category: c.category, done: c.done, customTitle: c.title),
  ];
  items.sort((a, b) => a.category.index.compareTo(b.category.index));
  return items;
}
