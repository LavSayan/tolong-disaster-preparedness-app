import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tolong_flutter/app/router.dart';
import 'package:tolong_flutter/core/storage/secure_vault.dart';
import 'package:tolong_flutter/core/validation.dart';
import 'package:tolong_flutter/features/auth/application/session.dart';
import 'package:tolong_flutter/features/auth/data/auth_repository.dart';
import 'package:tolong_flutter/features/home/presentation/home_screen.dart';
import 'package:tolong_flutter/features/household/data/household_repository.dart';
import 'package:tolong_flutter/features/household/domain/models.dart';
import 'package:tolong_flutter/features/prepare/domain/checklist.dart';
import 'package:tolong_flutter/features/readiness/domain/readiness.dart';
import 'package:tolong_flutter/features/readiness/domain/recommendations.dart';
import 'package:tolong_flutter/features/supplies/domain/supplies.dart';
import 'package:tolong_flutter/l10n/l10n.dart';

final today = DateTime(2026, 10, 18);

InventoryItem item(
  String name,
  SupplyCategory category,
  double quantity,
  SupplyUnit unit, {
  double? perUnit,
  DateTime? expiresOn,
}) =>
    InventoryItem(
      id: name,
      name: name,
      category: category,
      quantity: quantity,
      unit: unit,
      perUnit: perUnit,
      expiresOn: expiresOn,
    );

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final fil = lookupAppLocalizations(const Locale('fil'));

  group('redirectFor', () {
    const user = AuthUserInfo(id: 'u1', email: 'a@b.co');

    test('holds on splash until the session is ready', () {
      expect(redirectFor(const SessionState(), '/home'), '/splash');
      expect(redirectFor(const SessionState(), '/splash'), isNull);
    });

    test('signed-out users only reach public screens', () {
      const s = SessionState(ready: true);
      expect(redirectFor(s, '/home'), '/welcome');
      expect(redirectFor(s, '/settings'), '/welcome');
      expect(redirectFor(s, '/login'), isNull);
    });

    test('new accounts must finish onboarding first', () {
      const s = SessionState(ready: true, user: user);
      expect(redirectFor(s, '/home'), '/onboarding');
      expect(redirectFor(s, '/onboarding'), isNull);
    });

    test('onboarded accounts skip auth screens and onboarding', () {
      const s = SessionState(ready: true, user: user, onboardingComplete: true);
      expect(redirectFor(s, '/welcome'), '/home');
      expect(redirectFor(s, '/supplies'), isNull);
    });

    test('guests go straight to the app', () {
      expect(redirectFor(const SessionState(ready: true, guest: true), '/welcome'), '/home');
    });

    test('password recovery pins the reset screen', () {
      const s = SessionState(ready: true, user: user, onboardingComplete: true, recoveringPassword: true);
      expect(redirectFor(s, '/home'), '/reset-password');
    });

    test('role-gated routes fail closed', () {
      const onboarded = SessionState(ready: true, user: user, onboardingComplete: true);
      expect(redirectFor(onboarded, '/review-shelters'), '/home');
      expect(redirectFor(onboarded, '/admin'), '/home');
      // Unverified role is treated as no privilege even when signed in.
      const unverified = SessionState(ready: true, user: user, onboardingComplete: true, role: AppUserRole.user);
      expect(redirectFor(unverified, '/review-shelters'), '/home');
      expect(redirectFor(unverified, '/admin'), '/home');
    });

    test('submission routes require a signed-in account', () {
      const guest = SessionState(ready: true, guest: true);
      expect(redirectFor(guest, '/submit-shelter'), '/welcome');
      expect(redirectFor(guest, '/my-submissions'), '/welcome');
      const onboarded = SessionState(ready: true, user: user, onboardingComplete: true);
      expect(redirectFor(onboarded, '/submit-shelter'), isNull);
      expect(redirectFor(onboarded, '/my-submissions'), isNull);
    });

    test('reviewers and admins reach their screens', () {
      const reviewer = SessionState(ready: true, user: user, onboardingComplete: true, role: AppUserRole.government);
      expect(redirectFor(reviewer, '/review-shelters'), isNull);
      expect(redirectFor(reviewer, '/admin'), '/home'); // official is not an admin
      const admin = SessionState(ready: true, user: user, onboardingComplete: true, role: AppUserRole.admin);
      expect(redirectFor(admin, '/review-shelters'), isNull); // admin also reviews
      expect(redirectFor(admin, '/admin'), isNull);
    });
  });

  group('Validators', () {
    final v = Validators(en);

    test('email, password, age and phone', () {
      expect(v.email('mia@example.com'), isNull);
      expect(v.email('mia@'), isNotNull);
      expect(v.password('short1'), isNotNull);
      expect(v.password('safer2026'), isNull);
      expect(v.age('0'), isNotNull);
      expect(v.age('34'), isNull);
      expect(v.phone('0917 123 4567'), isNull);
      expect(v.phone('(02) 8123-4567'), isNull);
      expect(v.phone('12345'), isNotNull);
    });

    test('messages are localized', () {
      expect(Validators(fil).email(''), 'Pakilagay ang iyong email.');
    });
  });

  group('Supply coverage', () {
    const targets = PreparednessTargets(waterLitersPerPersonPerDay: 2, mealsPerPersonPerDay: 3, targetDays: 3);

    test('matches the worked example: 4 people, 24 L at 8 L/day = 3 days', () {
      final r = computeSupplyReport(
        items: [item('Water', SupplyCategory.water, 24, SupplyUnit.liters)],
        householdSize: 4,
        targets: targets,
        today: today,
      );
      expect(r.water.needPerDay, 8);
      expect(r.water.days, 3);
      expect(r.water.shortfall, 0);
    });

    test('converts gallons and mL, and uses liters-per-bottle when given', () {
      final r = computeSupplyReport(
        items: [
          item('Jug', SupplyCategory.water, 1, SupplyUnit.gallons),
          item('Small', SupplyCategory.water, 500, SupplyUnit.milliliters),
          item('Bottles', SupplyCategory.water, 4, SupplyUnit.bottles, perUnit: 0.5),
          item('Unknown bottles', SupplyCategory.water, 6, SupplyUnit.bottles),
        ],
        householdSize: 1,
        targets: targets,
        today: today,
      );
      expect(r.water.available, closeTo(3.785 + 0.5 + 2, 1e-9));
      expect(r.water.unknownItems, 1);
    });

    test('food is counted in meals, never added to liters', () {
      final r = computeSupplyReport(
        items: [
          item('Rice meals', SupplyCategory.food, 12, SupplyUnit.meals),
          item('Canned', SupplyCategory.food, 6, SupplyUnit.cans, perUnit: 2),
          item('Biscuits', SupplyCategory.food, 10, SupplyUnit.packs),
          item('Water', SupplyCategory.water, 10, SupplyUnit.liters),
        ],
        householdSize: 2,
        targets: targets,
        today: today,
      );
      expect(r.food.available, 24);
      expect(r.food.days, 4);
      expect(r.food.unknownItems, 1);
      expect(r.water.available, 10);
    });

    test('expired items do not count and are reported', () {
      final r = computeSupplyReport(
        items: [
          item('Old water', SupplyCategory.water, 20, SupplyUnit.liters, expiresOn: DateTime(2026, 10, 1)),
          item('Paracetamol', SupplyCategory.medicine, 10, SupplyUnit.tablets, expiresOn: DateTime(2026, 11, 2)),
        ],
        householdSize: 1,
        targets: targets,
        today: today,
      );
      expect(r.water.available, 0);
      expect(r.expired.single.name, 'Old water');
      expect(r.expiringSoon.single.name, 'Paracetamol');
      expect(r.hasUsable(SupplyCategory.medicine), isTrue);
    });

    test('unknown household size assumes 1 person and says so', () {
      final r = computeSupplyReport(items: const [], householdSize: null, targets: targets, today: today);
      expect(r.householdSize, 1);
      expect(r.householdSizeKnown, isFalse);
    });

    test('score: water 30%, food 30%, four essentials 10% each', () {
      final full = computeSupplyReport(
        items: [
          item('W', SupplyCategory.water, 6, SupplyUnit.liters),
          item('F', SupplyCategory.food, 9, SupplyUnit.meals),
          item('M', SupplyCategory.medicine, 1, SupplyUnit.boxes),
          item('A', SupplyCategory.firstAid, 1, SupplyUnit.pieces),
          item('H', SupplyCategory.hygiene, 1, SupplyUnit.pieces),
          item('L', SupplyCategory.lighting, 1, SupplyUnit.pieces),
        ],
        householdSize: 1,
        targets: targets,
        today: today,
      );
      expect(full.score, closeTo(1.0, 1e-9));

      final halfWater = computeSupplyReport(
        items: [item('W', SupplyCategory.water, 3, SupplyUnit.liters)],
        householdSize: 1,
        targets: targets,
        today: today,
      );
      expect(halfWater.score, closeTo(0.15, 1e-9));
    });
  });

  group('Checklist', () {
    test('household needs add suggested items; others stay hidden', () {
      final base = buildChecklist(const ChecklistState(), const HouseholdProfile());
      final withKids = buildChecklist(const ChecklistState(), const HouseholdProfile(children: 1, hasPets: true));
      expect(base.any((i) => i.id == 'infant_supplies'), isFalse);
      expect(withKids.any((i) => i.id == 'infant_supplies'), isTrue);
      expect(withKids.any((i) => i.id == 'pet_supplies'), isTrue);
      expect(withKids.any((i) => i.id == 'senior_meds'), isFalse);
    });

    test('user edits survive template merges and new templates appear unchecked', () {
      const state = ChecklistState(
        templates: {'water': TemplateItemState(done: true, editedTitle: 'Two 5-gallon jugs')},
        custom: [CustomChecklistItem(id: 'c1', title: 'Spare glasses', category: ChecklistCategory.specialNeeds)],
      );
      final items = buildChecklist(state, null);
      final water = items.firstWhere((i) => i.id == 'water');
      expect(water.done, isTrue);
      expect(en.checklistTitle(water), 'Two 5-gallon jugs');
      expect(items.firstWhere((i) => i.id == 'flashlight').done, isFalse);
      expect(items.firstWhere((i) => i.id == 'c1').isCustom, isTrue);
      expect(en.checklistTitle(items.firstWhere((i) => i.id == 'flashlight')), 'Flashlight');
    });

    test('state round-trips through JSON', () {
      const state = ChecklistState(templates: {'cash': TemplateItemState(done: true)});
      final back = ChecklistState.fromJson(state.toJson());
      expect(back.templates['cash']!.done, isTrue);
    });
  });

  group('Readiness', () {
    final emptySupplies = computeSupplyReport(
      items: const [],
      householdSize: 2,
      targets: const PreparednessTargets(),
      today: today,
    );

    test('weights add up to 100 and an empty household scores 0', () {
      expect(ReadinessReport.weights.values.fold<double>(0, (a, b) => a + b), closeTo(1, 1e-9));
      final r = computeReadiness(
        checklist: buildChecklist(const ChecklistState(), null),
        supplies: emptySupplies,
        contacts: const [],
        household: null,
        profile: null,
      );
      expect(r.score, 0);
    });

    test('contacts and household profile contribute their documented share', () {
      final r = computeReadiness(
        checklist: buildChecklist(const ChecklistState(), null),
        supplies: emptySupplies,
        contacts: const [
          EmergencyContact(id: '1', name: 'A', relationship: 'Sister', phone: '09171234567'),
          EmergencyContact(id: '2', name: 'B', relationship: 'Friend', phone: '09181234567'),
        ],
        household: const HouseholdProfile(adults: 2),
        profile: const UserProfile(fullName: 'Maria', barangay: 'Batasan Hills'),
      );
      expect(r.score, 30);
      expect(r.component(ReadinessArea.contacts).points, closeTo(15, 1e-9));
    });

    test('recommendations put expired supplies and shortfalls first', () {
      final supplies = computeSupplyReport(
        items: [item('Old rice', SupplyCategory.food, 5, SupplyUnit.meals, expiresOn: DateTime(2026, 1, 1))],
        householdSize: 2,
        targets: const PreparednessTargets(),
        today: today,
      );
      final checklist = buildChecklist(const ChecklistState(), null);
      final report = computeReadiness(
        checklist: checklist,
        supplies: supplies,
        contacts: const [],
        household: null,
        profile: null,
      );
      final recs = recommend(report, checklist, today);
      expect(recs.first, isA<RemoveExpired>());
      expect(recs[1], isA<AddWater>());
      expect(recs[2], isA<AddFood>());
      expect(recs.length, 5);
      expect(en.recommendation(recs[1]), 'Add about 22.8 L of water to cover 3 days.');
      expect(fil.recommendation(recs.first), 'Expired na ang Old rice. Palitan ito.');
    });
  });

  test('HouseholdRepository round-trips and clears data per owner', () async {
    final repo = HouseholdRepository(MemoryVault());
    await repo.saveProfile('u1', const UserProfile(fullName: 'Maria Santos', age: 34, barangay: 'Bagong Pag-asa'));
    await repo.saveHousehold('u1', const HouseholdProfile(adults: 2, children: 2, hasPets: true));
    final d = await repo.load('u1');
    expect(d.profile!.firstName, 'Maria');
    expect(d.household!.size, 4);
    expect((await repo.load(guestOwner)).profile, isNull);
    await repo.clear('u1');
    expect((await repo.load('u1')).profile, isNull);
  });

  test('greeting follows the time of day, in both languages', () {
    expect(greetingFor(en, DateTime(2026, 10, 18, 7)), 'Good morning');
    expect(greetingFor(en, DateTime(2026, 10, 18, 13)), 'Good afternoon');
    expect(greetingFor(fil, DateTime(2026, 10, 18, 20)), 'Magandang gabi');
  });

  test('every checklist template has a title in both languages', () {
    for (final t in goBagTemplates) {
      expect(en.templateTitle(t.id), isNot(t.id), reason: t.id);
      expect(fil.templateTitle(t.id), isNot(t.id), reason: t.id);
    }
  });
}
