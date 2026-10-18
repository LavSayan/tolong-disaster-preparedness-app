enum AppLanguage {
  english('en', 'English'),
  filipino('fil', 'Filipino');

  const AppLanguage(this.code, this.label);

  final String code;
  final String label;

  static AppLanguage fromCode(String? code) =>
      values.firstWhere((l) => l.code == code, orElse: () => AppLanguage.english);
}

class UserProfile {
  const UserProfile({
    required this.fullName,
    this.age,
    this.barangay = '',
    this.language = AppLanguage.english,
  });

  final String fullName;
  final int? age;
  final String barangay;
  final AppLanguage language;

  String get firstName => fullName.trim().split(RegExp(r'\s+')).first;

  UserProfile copyWith({String? fullName, int? age, String? barangay, AppLanguage? language}) => UserProfile(
        fullName: fullName ?? this.fullName,
        age: age ?? this.age,
        barangay: barangay ?? this.barangay,
        language: language ?? this.language,
      );

  Map<String, Object?> toJson() =>
      {'fullName': fullName, 'age': age, 'barangay': barangay, 'language': language.code};

  factory UserProfile.fromJson(Map<String, Object?> json) => UserProfile(
        fullName: json['fullName'] as String? ?? '',
        age: (json['age'] as num?)?.toInt(),
        barangay: json['barangay'] as String? ?? '',
        language: AppLanguage.fromCode(json['language'] as String?),
      );
}

/// Optional answers stay null when the user chooses not to say.
class HouseholdProfile {
  const HouseholdProfile({
    this.adults = 1,
    this.children = 0,
    this.seniors = 0,
    this.hasPets,
    this.assistanceNeeds,
  });

  final int adults;
  final int children;
  final int seniors;
  final bool? hasPets;
  final String? assistanceNeeds;

  int get size => adults + children + seniors;

  HouseholdProfile copyWith({
    int? adults,
    int? children,
    int? seniors,
    bool? Function()? hasPets,
    String? Function()? assistanceNeeds,
  }) =>
      HouseholdProfile(
        adults: adults ?? this.adults,
        children: children ?? this.children,
        seniors: seniors ?? this.seniors,
        hasPets: hasPets != null ? hasPets() : this.hasPets,
        assistanceNeeds: assistanceNeeds != null ? assistanceNeeds() : this.assistanceNeeds,
      );

  Map<String, Object?> toJson() => {
        'adults': adults,
        'children': children,
        'seniors': seniors,
        'hasPets': hasPets,
        'assistanceNeeds': assistanceNeeds,
      };

  factory HouseholdProfile.fromJson(Map<String, Object?> json) => HouseholdProfile(
        adults: (json['adults'] as num?)?.toInt() ?? 1,
        children: (json['children'] as num?)?.toInt() ?? 0,
        seniors: (json['seniors'] as num?)?.toInt() ?? 0,
        hasPets: json['hasPets'] as bool?,
        assistanceNeeds: json['assistanceNeeds'] as String?,
      );
}

class EmergencyContact {
  const EmergencyContact({
    required this.id,
    required this.name,
    required this.relationship,
    required this.phone,
  });

  final String id;
  final String name;
  final String relationship;
  final String phone;

  Map<String, Object?> toJson() => {'id': id, 'name': name, 'relationship': relationship, 'phone': phone};

  factory EmergencyContact.fromJson(Map<String, Object?> json) => EmergencyContact(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        relationship: json['relationship'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
      );
}

class HouseholdData {
  const HouseholdData({this.profile, this.household, this.contacts = const []});

  final UserProfile? profile;
  final HouseholdProfile? household;
  final List<EmergencyContact> contacts;

  HouseholdData copyWith({
    UserProfile? profile,
    HouseholdProfile? household,
    List<EmergencyContact>? contacts,
  }) =>
      HouseholdData(
        profile: profile ?? this.profile,
        household: household ?? this.household,
        contacts: contacts ?? this.contacts,
      );
}
