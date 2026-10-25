import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/theme.dart';
import '../../core/config/demo.dart';
import '../../core/validation.dart';
import '../../l10n/l10n.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/form_widgets.dart';
import '../auth/application/session.dart';
import '../auth/data/auth_repository.dart';
import '../auth/presentation/privacy_notice.dart';
import '../household/data/household_repository.dart';
import '../household/domain/models.dart';
import '../household/presentation/household_forms.dart';
import '../household/presentation/profile_screen.dart';
import '../supplies/presentation/supplies_screen.dart';
import 'local_data.dart';
import 'settings.dart';

final appVersionProvider = FutureProvider<String>((ref) async {
  try {
    final info = await PackageInfo.fromPlatform();
    return '${info.version} (${info.buildNumber})';
  } catch (_) {
    return '—';
  }
});

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final s = ref.watch(settingsProvider);
    final session = ref.watch(sessionProvider);
    final controller = ref.read(settingsProvider.notifier);
    void set(AppSettings Function(AppSettings) change) => controller.update(change);
    final barangay = ref.watch(householdProvider).value?.profile?.barangay ?? '';

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        surfaceTintColor: Colors.transparent,
        title: Text(l.settingsTitle, style: serif(20)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.xxxl),
        children: [
          _Section(l.setAccount, [
            if (session.guest) InlineMessage(l.setGuestAccountNote),
            _Tile(icon: Icons.person_outline_rounded, title: l.setProfile, onTap: () => context.push('/profile')),
            if (session.signedIn) ...[
              _Tile(
                icon: Icons.lock_reset_rounded,
                title: l.setChangePassword,
                subtitle: l.setChangePasswordSub,
                onTap: () => _changePassword(context, ref),
              ),
              _Tile(
                icon: Icons.delete_forever_outlined,
                title: l.setDeleteAccount,
                danger: true,
                onTap: () => _deleteAccount(context, ref),
              ),
            ],
            _Tile(
              icon: Icons.logout_rounded,
              title: session.guest ? l.leaveGuest : l.logOut,
              onTap: () => confirmSignOut(context, ref),
            ),
          ]),
          _Section(l.setPreferences, [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l.language, style: sans(13, weight: FontWeight.w600)),
                const SizedBox(height: AppSpacing.sm),
                LanguagePicker(value: s.language, onChanged: (x) => _setLanguage(ref, x)),
              ]),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.setReduceMotion, style: sans(13, weight: FontWeight.w600)),
              subtitle: Text(l.setReduceMotionSub, style: sans(11, color: AppColors.muted)),
              value: s.reducedMotion,
              onChanged: (x) => set((s) => s.copyWith(reducedMotion: x)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l.setTextSize, style: sans(13, weight: FontWeight.w600)),
                const SizedBox(height: AppSpacing.sm),
                SegmentedButton<TextSize>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(value: TextSize.normal, label: Text(l.textNormal)),
                    ButtonSegment(value: TextSize.large, label: Text(l.textLarge)),
                    ButtonSegment(value: TextSize.larger, label: Text(l.textLarger)),
                  ],
                  selected: {s.textSize},
                  onSelectionChanged: (x) => set((s) => s.copyWith(textSize: x.first)),
                ),
              ]),
            ),
          ]),
          _Section(l.setTargets, [
            Text(l.setTargetsSub, style: sans(11, color: AppColors.muted)),
            _Tile(
              icon: Icons.water_drop_outlined,
              title: l.setWaterTarget,
              subtitle: l.setWaterTargetSub,
              trailing: l.number(s.targets.waterLitersPerPersonPerDay),
              onTap: () async {
                final v = await _askNumber(context, l.setWaterTarget, s.targets.waterLitersPerPersonPerDay, 0.5, 20);
                if (v != null) set((s) => s.copyWith(targets: s.targets.copyWith(waterLitersPerPersonPerDay: v)));
              },
            ),
            _Tile(
              icon: Icons.rice_bowl_outlined,
              title: l.setMealsTarget,
              trailing: '${s.targets.mealsPerPersonPerDay}',
              onTap: () async {
                final v = await _askNumber(context, l.setMealsTarget, s.targets.mealsPerPersonPerDay.toDouble(), 1, 6,
                    integer: true);
                if (v != null) set((s) => s.copyWith(targets: s.targets.copyWith(mealsPerPersonPerDay: v.round())));
              },
            ),
            _Tile(
              icon: Icons.calendar_month_outlined,
              title: l.setDaysTarget,
              subtitle: l.setDaysTargetSub,
              trailing: '${s.targets.targetDays}',
              onTap: () async {
                final v =
                    await _askNumber(context, l.setDaysTarget, s.targets.targetDays.toDouble(), 1, 30, integer: true);
                if (v != null) set((s) => s.copyWith(targets: s.targets.copyWith(targetDays: v.round())));
              },
            ),
          ]),
          _Section(l.setLocation, [
            _Switch(l.prefLocation, s.locationOptIn, (x) => set((s) => s.copyWith(locationOptIn: x)),
                subtitle: l.setLocationNote),
            _Tile(
              icon: Icons.location_city_outlined,
              title: l.setDefaultBarangay,
              trailing: barangay.isEmpty ? l.notSet : barangay,
              onTap: () => context.push('/profile'),
            ),
            _Tile(
              icon: Icons.download_for_offline_outlined,
              title: l.setOfflineMaps,
              onTap: () => context.push('/offline-map'),
            ),
          ]),
          _Section(l.setPrivacy, [
            _Tile(icon: Icons.privacy_tip_outlined, title: l.setPrivacyNotice, onTap: () => showPrivacyNotice(context)),
            _Switch(l.tolShareContext, s.tolContextConsent, (x) => set((s) => s.copyWith(tolContextConsent: x)),
                subtitle: l.tolShareContextSub),
            _Tile(
              icon: Icons.storage_outlined,
              title: l.setStorage,
              onTap: () => showInfoSheet(context, l.setStorage, session.guest ? l.setStorageGuest : l.setStorageAccount),
            ),
            _Tile(
              icon: Icons.cleaning_services_outlined,
              title: l.setClearLocal,
              subtitle: l.setClearLocalSub,
              danger: true,
              onTap: () => _clearLocal(context, ref),
            ),
          ]),
          _Section(l.setInfo, [
            _Tile(
              icon: Icons.info_outline_rounded,
              title: l.setAbout,
              onTap: () => showInfoSheet(context, l.setAbout, l.setAboutBody),
            ),
            _Tile(
              icon: Icons.tag_rounded,
              title: l.setVersion,
              trailing: ref.watch(appVersionProvider).value ?? '…',
              // Demo builds only: the hidden admin entry (see core/config/demo.dart). A
              // long-press keeps it invisible in day-to-day use, including every release build.
              onLongPress:
                  ref.watch(demoToolsEnabledProvider) ? () => context.push('/demo') : null,
            ),
            _Tile(
              icon: Icons.source_outlined,
              title: l.setDataSources,
              onTap: () => showInfoSheet(context, l.setDataSources, l.setDataSourcesBody),
            ),
            _Tile(
              icon: Icons.map_outlined,
              title: l.setMapAttribution,
              onTap: () => showInfoSheet(context, l.setMapAttribution, l.setMapAttributionBody),
            ),
            _Tile(
              icon: Icons.health_and_safety_outlined,
              title: l.setDisclaimer,
              onTap: () => showInfoSheet(context, l.setDisclaimer, l.disclaimer),
            ),
            _Tile(
              icon: Icons.description_outlined,
              title: l.setLicenses,
              onTap: () => showLicensePage(
                context: context,
                applicationName: l.appTitle,
                applicationVersion: ref.read(appVersionProvider).value,
              ),
            ),
          ]),
        ],
      ),
    );
  }

  /// The app language and the profile's preferred language are kept in step.
  Future<void> _setLanguage(WidgetRef ref, AppLanguage language) async {
    await ref.read(settingsProvider.notifier).update((s) => s.copyWith(language: language));
    final profile = ref.read(householdProvider).value?.profile;
    if (profile != null && profile.language != language) {
      final updated = profile.copyWith(language: language);
      await ref.read(householdProvider.notifier).updateProfile(updated);
      await ref.read(authRepositoryProvider).syncProfile(updated);
    }
  }

  Future<void> _changePassword(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final email = ref.read(sessionProvider).user?.email;
    if (email == null) return;
    try {
      await ref.read(authRepositoryProvider).sendPasswordReset(email);
      if (context.mounted) showMessage(context, l.setChangePasswordSent(email));
    } on AuthFailure catch (e) {
      if (context.mounted) showMessage(context, l.authError(e));
    }
  }

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final ok = await confirmDestructive(
      context,
      title: l.setDeleteTitle,
      body: l.setDeleteBody,
      confirmLabel: l.setDeleteAccount,
    );
    if (!ok) return;
    try {
      await ref.read(sessionProvider.notifier).deleteAccount();
      if (context.mounted) showMessage(context, l.setDeleteDone);
    } on AuthFailure catch (e) {
      if (context.mounted) showMessage(context, l.authError(e));
    }
  }

  Future<void> _clearLocal(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final owner = ref.read(sessionProvider).owner;
    if (owner == null) return;
    final ok = await confirmDestructive(
      context,
      title: l.setClearTitle,
      body: l.setClearBody,
      confirmLabel: l.setClearConfirm,
    );
    if (!ok) return;
    await ref.read(localDataProvider).clear(owner);
    if (context.mounted) showMessage(context, l.setCleared);
  }
}

Future<double?> _askNumber(
  BuildContext context,
  String title,
  double current,
  double min,
  double max, {
  bool integer = false,
}) {
  final l = context.l10n;
  final controller = TextEditingController(text: l.number(current));
  final form = GlobalKey<FormState>();
  return showDialog<double>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Form(
        key: form,
        child: TextFormField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.numberWithOptions(decimal: !integer),
          validator: (x) {
            final n = Validators.parseNumber(x);
            if (n == null || n < min || n > max || (integer && n != n.roundToDouble())) {
              return '${l.numberInvalid} (${l.number(min)}–${l.number(max)})';
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(88, 44)),
          onPressed: () {
            if (form.currentState!.validate()) Navigator.pop(context, Validators.parseNumber(controller.text));
          },
          child: Text(l.save),
        ),
      ],
    ),
  ).whenComplete(controller.dispose);
}

class _Section extends StatelessWidget {
  const _Section(this.title, this.children);

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
        padding: const EdgeInsets.only(left: 2, bottom: AppSpacing.sm),
        child: Eyebrow(title.toUpperCase()),
      ),
      CardBox(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
      ),
    ]);
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.error : AppColors.ink;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      onLongPress: onLongPress,
      leading: Icon(icon, color: danger ? AppColors.error : AppColors.primary, size: AppIconSizes.lg),
      title: Text(title, style: sans(13, weight: FontWeight.w600, color: color)),
      subtitle: subtitle == null ? null : Text(subtitle!, style: sans(11, color: AppColors.muted)),
      trailing: trailing != null
          ? ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 120),
              child: Text(trailing!,
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                  style: sans(12, weight: FontWeight.w700, color: AppColors.muted)),
            )
          : (onTap == null ? null : const Icon(Icons.chevron_right_rounded, color: Color(0xFFAAB4AD))),
    );
  }
}

class _Switch extends StatelessWidget {
  const _Switch(this.title, this.value, this.onChanged, {this.subtitle});

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: sans(13, weight: FontWeight.w600)),
      subtitle: subtitle == null ? null : Text(subtitle!, style: sans(11, color: AppColors.muted)),
      value: value,
      onChanged: onChanged,
    );
  }
}
