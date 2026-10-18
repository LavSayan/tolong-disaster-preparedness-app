import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../features/auth/data/auth_repository.dart';
import '../features/prepare/domain/checklist.dart';
import '../features/readiness/domain/readiness.dart';
import '../features/readiness/domain/recommendations.dart';
import '../features/safe_places/data/route_service.dart';
import '../features/safe_places/domain/evacuation_center.dart';
import '../features/supplies/domain/supplies.dart';
import 'generated/app_localizations.dart';

export 'generated/app_localizations.dart';

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

extension AppLocalizationsX on AppLocalizations {
  /// "2.5", "12", "1,250" — at most one decimal, in the current language's format.
  String number(double value) => NumberFormat('#,##0.#', localeName).format(value);

  String date(DateTime d) => DateFormat.yMMMd(localeName).format(d);

  String supplyCategoryName(SupplyCategory c) => switch (c) {
        SupplyCategory.water => supWater,
        SupplyCategory.food => supFood,
        SupplyCategory.medicine => supMedicine,
        SupplyCategory.firstAid => supFirstAid,
        SupplyCategory.hygiene => supHygiene,
        SupplyCategory.lighting => supLighting,
        SupplyCategory.other => supOther,
      };

  String unit(SupplyUnit u) => switch (u) {
        SupplyUnit.liters => unitLiters,
        SupplyUnit.milliliters => unitMilliliters,
        SupplyUnit.gallons => unitGallons,
        SupplyUnit.bottles => unitBottles,
        SupplyUnit.meals => unitMeals,
        SupplyUnit.packs => unitPacks,
        SupplyUnit.cans => unitCans,
        SupplyUnit.pieces => unitPieces,
        SupplyUnit.tablets => unitTablets,
        SupplyUnit.boxes => unitBoxes,
        SupplyUnit.kilograms => unitKilograms,
      };

  String routeError(RouteErrorCode c) => switch (c) {
        RouteErrorCode.notConfigured => routeErrNotConfigured,
        RouteErrorCode.network => routeErrNetwork,
        RouteErrorCode.noRoute => routeErrNoRoute,
        RouteErrorCode.outsideArea => routeErrOutside,
        RouteErrorCode.quota => routeErrQuota,
        RouteErrorCode.unknown => routeErrUnknown,
      };

  String facilityType(FacilityType t) => switch (t) {
        FacilityType.school => typeSchool,
        FacilityType.coveredCourt => typeCoveredCourt,
        FacilityType.barangayHall => typeBarangayHall,
        FacilityType.other => typeOther,
      };

  String checklistCategory(ChecklistCategory c) => switch (c) {
        ChecklistCategory.waterFood => catWaterFood,
        ChecklistCategory.firstAidMeds => catFirstAidMeds,
        ChecklistCategory.lightPower => catLightPower,
        ChecklistCategory.clothing => catClothing,
        ChecklistCategory.hygiene => catHygiene,
        ChecklistCategory.documents => catDocuments,
        ChecklistCategory.communication => catCommunication,
        ChecklistCategory.specialNeeds => catSpecialNeeds,
      };

  String householdNeed(HouseholdNeed n) => switch (n) {
        HouseholdNeed.children => suggestedChildren,
        HouseholdNeed.seniors => suggestedSeniors,
        HouseholdNeed.pets => suggestedPets,
        HouseholdNeed.assistance => suggestedAssistance,
      };

  String templateTitle(String id) => switch (id) {
        'water' => tplWater,
        'food' => tplFood,
        'can_opener' => tplCanOpener,
        'first_aid_kit' => tplFirstAidKit,
        'medicines' => tplMedicines,
        'masks' => tplMasks,
        'flashlight' => tplFlashlight,
        'batteries' => tplBatteries,
        'power_bank' => tplPowerBank,
        'clothes' => tplClothes,
        'rain_gear' => tplRainGear,
        'blanket' => tplBlanket,
        'toiletries' => tplToiletries,
        'sanitary' => tplSanitary,
        'documents' => tplDocuments,
        'cash' => tplCash,
        'contact_list' => tplContactList,
        'whistle' => tplWhistle,
        'radio' => tplRadio,
        'infant_supplies' => tplInfantSupplies,
        'child_comfort' => tplChildComfort,
        'senior_meds' => tplSeniorMeds,
        'mobility_aids' => tplMobilityAids,
        'pet_supplies' => tplPetSupplies,
        'pet_carrier' => tplPetCarrier,
        'assistive_devices' => tplAssistiveDevices,
        _ => id,
      };

  String checklistTitle(ChecklistItemView item) => item.customTitle ?? templateTitle(item.templateId ?? item.id);

  String readinessArea(ReadinessArea a) => switch (a) {
        ReadinessArea.goBag => areaGoBag,
        ReadinessArea.supplies => areaSupplies,
        ReadinessArea.contacts => areaContacts,
        ReadinessArea.household => areaHousehold,
      };

  String readinessHeadline(int score) => score >= 80
      ? readinessWell
      : score >= 50
          ? readinessGetting
          : readinessStart;

  String recommendation(Recommendation r) => switch (r) {
        RemoveExpired(:final item) => recRemoveExpired(item.name),
        AddWater(:final liters, :final targetDays) => recAddWater(targetDays, number(liters)),
        AddFood(:final meals, :final targetDays) => recAddFood(targetDays, number(meals)),
        AddEmergencyContacts(:final have) => have == 0 ? recAddFirstContact : recAddBackupContact,
        SetUpHousehold() => recSetUpHousehold,
        SetBarangay() => recSetBarangay,
        PackChecklistItem(:final item) => recPack(checklistTitle(item)),
        AddSupplyCategory(:final category) => recAddCategory(supplyCategoryName(category)),
        CheckExpiringSoon(:final item, :final days) => recExpiringSoon(days, item.name),
      };

  String authError(AuthFailure f) => switch (f.code) {
        AuthErrorCode.notConfigured => errNotConfigured,
        AuthErrorCode.network => errNetwork,
        AuthErrorCode.invalidCredentials => errInvalidCredentials,
        AuthErrorCode.emailNotConfirmed => errEmailNotConfirmed,
        AuthErrorCode.alreadyRegistered => errAlreadyRegistered,
        AuthErrorCode.rateLimited => errRateLimited,
        AuthErrorCode.weakPassword => errWeakPassword,
        AuthErrorCode.unknown => errUnknown,
      };
}
