import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/storage/secure_vault.dart';
import '../household/domain/models.dart';
import '../supplies/domain/supplies.dart';

enum TextSize {
  normal(1.0),
  large(1.15),
  larger(1.3);

  const TextSize(this.factor);

  final double factor;
}

/// Non-sensitive preferences. Opt-ins record what the user wants; Android permissions are
/// requested later, when a feature first needs them.
class AppSettings {
  const AppSettings({
    this.language = AppLanguage.english,
    this.reducedMotion = false,
    this.textSize = TextSize.normal,
    this.locationOptIn = true,
    this.offlineDownloadsOptIn = true,
    this.targets = const PreparednessTargets(),
    this.tolContextConsent = false,
  });

  /// Whether Tol may send a household summary (no names or numbers) with online questions.
  final bool tolContextConsent;

  final AppLanguage language;
  final bool reducedMotion;
  final TextSize textSize;
  final bool locationOptIn;
  final bool offlineDownloadsOptIn;
  final PreparednessTargets targets;

  AppSettings copyWith({
    AppLanguage? language,
    bool? reducedMotion,
    TextSize? textSize,
    bool? locationOptIn,
    bool? offlineDownloadsOptIn,
    PreparednessTargets? targets,
    bool? tolContextConsent,
  }) =>
      AppSettings(
        tolContextConsent: tolContextConsent ?? this.tolContextConsent,
        language: language ?? this.language,
        reducedMotion: reducedMotion ?? this.reducedMotion,
        textSize: textSize ?? this.textSize,
        locationOptIn: locationOptIn ?? this.locationOptIn,
        offlineDownloadsOptIn: offlineDownloadsOptIn ?? this.offlineDownloadsOptIn,
        targets: targets ?? this.targets,
      );
}

AppLanguage _deviceLanguage() {
  final code = PlatformDispatcher.instance.locale.languageCode;
  return code == 'fil' || code == 'tl' ? AppLanguage.filipino : AppLanguage.english;
}

class SettingsController extends Notifier<AppSettings> {
  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  AppSettings build() {
    final p = ref.watch(sharedPreferencesProvider);
    const d = PreparednessTargets();
    final savedLanguage = p.getString('language');
    return AppSettings(
      language: savedLanguage == null ? _deviceLanguage() : AppLanguage.fromCode(savedLanguage),
      reducedMotion: p.getBool('reduced_motion') ?? false,
      textSize: TextSize.values.asNameMap()[p.getString('text_size')] ?? TextSize.normal,
      locationOptIn: p.getBool('opt_in_location') ?? true,
      offlineDownloadsOptIn: p.getBool('opt_in_offline_downloads') ?? true,
      targets: PreparednessTargets(
        waterLitersPerPersonPerDay: p.getDouble('target_water_l') ?? d.waterLitersPerPersonPerDay,
        mealsPerPersonPerDay: p.getInt('target_meals') ?? d.mealsPerPersonPerDay,
        targetDays: p.getInt('target_days') ?? d.targetDays,
      ),
      tolContextConsent: p.getBool('tol_context_consent') ?? false,
    );
  }

  Future<void> save(AppSettings s) async {
    state = s;
    await _prefs.setString('language', s.language.code);
    await _prefs.setBool('reduced_motion', s.reducedMotion);
    await _prefs.setString('text_size', s.textSize.name);
    await _prefs.setBool('opt_in_location', s.locationOptIn);
    await _prefs.setBool('opt_in_offline_downloads', s.offlineDownloadsOptIn);
    await _prefs.setDouble('target_water_l', s.targets.waterLitersPerPersonPerDay);
    await _prefs.setInt('target_meals', s.targets.mealsPerPersonPerDay);
    await _prefs.setInt('target_days', s.targets.targetDays);
    await _prefs.setBool('tol_context_consent', s.tolContextConsent);
  }

  Future<void> update(AppSettings Function(AppSettings) change) => save(change(state));
}

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(SettingsController.new);
