import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../l10n/l10n.dart';
import '../../shared/widgets/character.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/form_widgets.dart';
import '../auth/application/session.dart';
import '../auth/data/auth_repository.dart';
import '../household/data/household_repository.dart';
import '../household/domain/models.dart';
import '../household/presentation/household_forms.dart';
import '../safe_places/data/qc_area_repository.dart';
import '../safe_places/presentation/barangay_widgets.dart';
import '../settings/settings.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const _steps = 5;

  final _page = PageController();
  final _profileForm = GlobalKey<FormState>();
  late final AuthUserInfo? _user = ref.read(sessionProvider).user;
  late final _name = TextEditingController(text: _user?.fullName);
  late final _age = TextEditingController(text: _user?.age?.toString());
  late final _barangay = TextEditingController(text: _user?.barangay);
  final _assistance = TextEditingController();

  int _step = 0;
  bool _saving = false;
  HouseholdProfile _household = const HouseholdProfile();
  final List<EmergencyContact> _contacts = [];
  late bool _notifications = ref.read(settingsProvider).notificationsOptIn;
  late bool _location = ref.read(settingsProvider).locationOptIn;
  late bool _offline = ref.read(settingsProvider).offlineDownloadsOptIn;

  @override
  void dispose() {
    for (final c in [_name, _age, _barangay, _assistance]) {
      c.dispose();
    }
    _page.dispose();
    super.dispose();
  }

  void _goTo(int step) {
    FocusScope.of(context).unfocus();
    setState(() => _step = step);
    final duration = motion(context, AppDurations.normal);
    // Scroll animations reject a zero duration, so jump when reduced motion is on.
    if (duration == Duration.zero) {
      _page.jumpToPage(step);
    } else {
      _page.animateToPage(step, duration: duration, curve: Curves.easeOutCubic);
    }
  }

  void _next() {
    if (_step == 0 && !_profileForm.currentState!.validate()) return;
    if (_step < _steps - 1) _goTo(_step + 1);
  }

  void _setLanguage(AppLanguage language) =>
      ref.read(settingsProvider.notifier).update((s) => s.copyWith(language: language));

  void _skipHouseholdOptional() {
    _assistance.clear();
    setState(() => _household = _household.copyWith(hasPets: () => null, assistanceNeeds: () => null));
    _goTo(2);
  }

  Future<void> _finish() async {
    setState(() => _saving = true);
    final assistance = _assistance.text.trim();
    final language = ref.read(settingsProvider).language;
    final profile = UserProfile(
      fullName: _name.text.trim(),
      age: int.tryParse(_age.text.trim()),
      barangay: canonicalBarangay(ref.read(barangaysProvider).value, _barangay.text),
      language: language,
    );
    await ref.read(householdProvider.notifier).saveAll(HouseholdData(
          profile: profile,
          household: _household.copyWith(assistanceNeeds: () => assistance.isEmpty ? null : assistance),
          contacts: List.of(_contacts),
        ));
    await ref.read(settingsProvider.notifier).update((s) => s.copyWith(
          notificationsOptIn: _notifications,
          locationOptIn: _location,
          offlineDownloadsOptIn: _offline,
        ));
    await ref.read(authRepositoryProvider).syncProfile(profile);
    await ref.read(sessionProvider.notifier).completeOnboarding();
  }

  Future<void> _addContact() async {
    final c = await showContactEditor(context);
    if (c != null) setState(() => _contacts.add(c));
  }

  Future<void> _editContact(EmergencyContact contact) async {
    final c = await showContactEditor(context, existing: contact);
    if (c != null) setState(() => _contacts[_contacts.indexWhere((x) => x.id == c.id)] = c);
  }

  Future<void> _removeContact(EmergencyContact contact) async {
    if (await confirmRemoveContact(context, contact)) setState(() => _contacts.remove(contact));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final language = ref.watch(settingsProvider.select((s) => s.language));
    final firstName = _name.text.trim().split(' ').first;

    final steps = <Widget>[
      _StepBody(
        eyebrow: l.onbStep(1, _steps),
        title: l.onbAboutTitle,
        subtitle: l.onbAboutSub,
        child: Form(
          key: _profileForm,
          child: ProfileFields(
            name: _name,
            age: _age,
            barangay: _barangay,
            language: language,
            onLanguageChanged: _setLanguage,
          ),
        ),
      ),
      _StepBody(
        eyebrow: l.onbStep(2, _steps),
        title: l.onbHouseholdTitle,
        subtitle: l.onbHouseholdSub,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          HouseholdFields(
            household: _household,
            assistance: _assistance,
            onChanged: (h) => setState(() => _household = h),
          ),
          TextButton(onPressed: _skipHouseholdOptional, child: Text(l.onbSkipOptional)),
        ]),
      ),
      _StepBody(
        eyebrow: l.onbStep(3, _steps),
        title: l.onbContactsTitle,
        subtitle: l.onbContactsSub,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (_contacts.isEmpty)
            InlineMessage(l.onbNoContacts)
          else
            for (final c in _contacts)
              ContactTile(contact: c, onEdit: () => _editContact(c), onDelete: () => _removeContact(c)),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: _addContact,
            icon: const Icon(Icons.person_add_alt_1_outlined, size: AppIconSizes.md),
            label: Text(l.addContact),
          ),
        ]),
      ),
      _StepBody(
        eyebrow: l.onbStep(4, _steps),
        title: l.onbPrefsTitle,
        subtitle: l.onbPrefsSub,
        child: Column(children: [
          _PreferenceSwitch(
            icon: Icons.notifications_none_rounded,
            title: l.prefReminders,
            subtitle: l.prefRemindersSub,
            value: _notifications,
            onChanged: (x) => setState(() => _notifications = x),
          ),
          _PreferenceSwitch(
            icon: Icons.my_location_rounded,
            title: l.prefLocation,
            subtitle: l.prefLocationSub,
            value: _location,
            onChanged: (x) => setState(() => _location = x),
          ),
          _PreferenceSwitch(
            icon: Icons.download_for_offline_outlined,
            title: l.prefOffline,
            subtitle: l.prefOfflineSub,
            value: _offline,
            onChanged: (x) => setState(() => _offline = x),
          ),
        ]),
      ),
      ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xxl, AppSpacing.xl, AppSpacing.xl),
        children: [
          Container(
            height: 240,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(color: AppColors.sageSoft, borderRadius: BorderRadius.circular(AppRadii.hero)),
            child: const Stack(children: [Positioned(right: 0, bottom: -10, child: Character(scene: Scene.home))]),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            firstName.isEmpty ? l.onbWelcomeTitle : l.onbWelcomeTitleName(firstName),
            style: serif(28, height: 1.08, tracking: -0.05),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(l.onbWelcomeBody, style: sans(13, height: 1.5, color: AppColors.muted)),
        ],
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.outer,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Material(
            color: AppColors.canvas,
            child: SafeArea(
              child: Column(children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, 0),
                  child: Row(children: [
                    const Logo(),
                    const Spacer(),
                    Text('${_step + 1}/$_steps', style: sans(12, weight: FontWeight.w700, color: AppColors.muted)),
                  ]),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, 0),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: (_step + 1) / _steps),
                    duration: motion(context, AppDurations.normal),
                    builder: (context, value, _) => ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                      child: LinearProgressIndicator(
                        value: value,
                        minHeight: 6,
                        backgroundColor: const Color(0xFFE9EEE7),
                        color: AppColors.primary,
                        semanticsLabel: l.setupProgress,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: PageView(controller: _page, physics: const NeverScrollableScrollPhysics(), children: steps),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.lg),
                  child: Row(children: [
                    if (_step > 0 && _step < _steps - 1) ...[
                      Expanded(child: OutlinedButton(onPressed: () => _goTo(_step - 1), child: Text(l.back))),
                      const SizedBox(width: AppSpacing.md),
                    ],
                    Expanded(
                      flex: 2,
                      child: _step == _steps - 1
                          ? LoadingButton(label: l.continueToDashboard, loading: _saving, onPressed: _finish)
                          : FilledButton(
                              onPressed: _next,
                              child: Text(_step == 2 && _contacts.isEmpty ? l.skipForNow : l.next),
                            ),
                    ),
                  ]),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _StepBody extends StatelessWidget {
  const _StepBody({required this.eyebrow, required this.title, required this.subtitle, required this.child});

  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xxl, AppSpacing.xl, AppSpacing.xl),
      children: [
        Eyebrow(eyebrow),
        const SizedBox(height: AppSpacing.sm),
        Text(title, style: serif(28, height: 1.08, tracking: -0.05)),
        const SizedBox(height: AppSpacing.sm),
        Text(subtitle, style: sans(13, height: 1.45, color: AppColors.muted)),
        const SizedBox(height: AppSpacing.xxl),
        child,
      ],
    );
  }
}

class _PreferenceSwitch extends StatelessWidget {
  const _PreferenceSwitch({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      secondary: IconTile(icon: icon, background: AppColors.sageSoft, foreground: AppColors.primary),
      title: Text(title, style: sans(13, weight: FontWeight.w600)),
      subtitle: Text(subtitle, style: sans(11, color: AppColors.muted)),
      value: value,
      onChanged: onChanged,
    );
  }
}
