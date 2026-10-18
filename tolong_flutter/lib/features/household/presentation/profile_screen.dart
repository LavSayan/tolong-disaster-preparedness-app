import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets/common.dart';
import '../../../shared/widgets/form_widgets.dart';
import '../../auth/application/session.dart';
import '../../auth/data/auth_repository.dart';
import '../../safe_places/data/qc_area_repository.dart';
import '../../safe_places/presentation/barangay_widgets.dart';
import '../../settings/settings.dart';
import '../data/household_repository.dart';
import '../domain/models.dart';
import 'household_forms.dart';

Future<void> confirmSignOut(BuildContext context, WidgetRef ref) async {
  final l = context.l10n;
  final guest = ref.read(sessionProvider).guest;
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(guest ? l.leaveGuestTitle : l.signOutTitle),
      content: Text(guest ? l.leaveGuestBody : l.signOutBody),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(96, 44)),
          onPressed: () => Navigator.pop(context, true),
          child: Text(guest ? l.leave : l.logOut),
        ),
      ],
    ),
  );
  if (ok == true) await ref.read(sessionProvider.notifier).signOut();
}

/// Saves the profile locally, mirrors its language to the app setting, and syncs it to the account.
Future<void> saveProfile(WidgetRef ref, UserProfile profile) async {
  await ref.read(householdProvider.notifier).updateProfile(profile);
  await ref.read(settingsProvider.notifier).update((s) => s.copyWith(language: profile.language));
  await ref.read(authRepositoryProvider).syncProfile(profile);
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final session = ref.watch(sessionProvider);
    final data = ref.watch(householdProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        surfaceTintColor: Colors.transparent,
        title: Text(l.profileTitle, style: serif(20)),
      ),
      body: data.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: InlineMessage(l.couldNotLoad, tone: MessageTone.error)),
        data: (d) {
          final h = d.household;
          return ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.xxxl),
            children: [
              if (session.guest) ...[
                InlineMessage(l.profileGuestNote),
                const SizedBox(height: AppSpacing.lg),
              ],
              CardBox(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _SectionHeader(
                    eyebrow: l.sectionYou,
                    onEdit: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const _EditProfilePage())),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(d.profile?.fullName.isNotEmpty == true ? d.profile!.fullName : l.notSet, style: serif(22)),
                  const SizedBox(height: AppSpacing.xs),
                  if (session.user?.email != null) Text(session.user!.email!, style: sans(12, color: AppColors.muted)),
                  const SizedBox(height: AppSpacing.md),
                  _Fact(l.age, d.profile?.age?.toString() ?? '—'),
                  _Fact(l.barangay, d.profile?.barangay.isNotEmpty == true ? d.profile!.barangay : '—'),
                  _Fact(l.language, d.profile?.language.label ?? '—'),
                ]),
              ),
              CardBox(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _SectionHeader(
                    eyebrow: l.sectionHousehold,
                    onEdit: () =>
                        Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const _EditHouseholdPage())),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (h == null)
                    Text(l.notSetUpYet, style: sans(13, color: AppColors.muted))
                  else ...[
                    Text(l.householdPeople(h.size), style: serif(22)),
                    const SizedBox(height: AppSpacing.md),
                    _Fact(l.adults, '${h.adults}'),
                    _Fact(l.children, '${h.children}'),
                    _Fact(l.seniors, '${h.seniors}'),
                    _Fact(l.pets, switch (h.hasPets) { true => l.yes, false => l.no, null => l.notShared }),
                    _Fact(l.assistanceNeeds, h.assistanceNeeds ?? l.notShared),
                  ],
                ]),
              ),
              const _ContactsCard(),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: () => confirmSignOut(context, ref),
                icon: const Icon(Icons.logout_rounded, size: AppIconSizes.md),
                label: Text(session.guest ? l.leaveGuest : l.logOut),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ContactsCard extends ConsumerWidget {
  const _ContactsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final contacts = ref.watch(householdProvider).value?.contacts ?? const <EmergencyContact>[];
    final controller = ref.read(householdProvider.notifier);
    return CardBox(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Eyebrow(l.sectionContacts),
        const SizedBox(height: AppSpacing.sm),
        if (contacts.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Text(l.noContactsYet, style: sans(13, color: AppColors.muted)),
          ),
        for (final c in contacts)
          ContactTile(
            contact: c,
            onEdit: () async {
              final updated = await showContactEditor(context, existing: c);
              if (updated != null) await controller.saveContact(updated);
            },
            onDelete: () async {
              if (await confirmRemoveContact(context, c)) await controller.removeContact(c.id);
            },
          ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: () async {
            final added = await showContactEditor(context);
            if (added != null) await controller.saveContact(added);
          },
          icon: const Icon(Icons.person_add_alt_1_outlined, size: AppIconSizes.md),
          label: Text(l.addContact),
        ),
      ]),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.eyebrow, required this.onEdit});

  final String eyebrow;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: Eyebrow(eyebrow)),
      TextButton.icon(onPressed: onEdit, icon: const Icon(Icons.edit_outlined, size: 16), label: Text(context.l10n.edit)),
    ]);
  }
}

class _Fact extends StatelessWidget {
  const _Fact(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 130, child: Text(label, style: sans(12, color: AppColors.muted))),
        Expanded(child: Text(value, style: sans(12, weight: FontWeight.w600))),
      ]),
    );
  }
}

class _EditProfilePage extends ConsumerStatefulWidget {
  const _EditProfilePage();

  @override
  ConsumerState<_EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<_EditProfilePage> {
  final _form = GlobalKey<FormState>();
  late final UserProfile? _initial = ref.read(householdProvider).value?.profile;
  late final _name = TextEditingController(text: _initial?.fullName);
  late final _age = TextEditingController(text: _initial?.age?.toString());
  late final _barangay = TextEditingController(text: _initial?.barangay);
  late AppLanguage _language = _initial?.language ?? ref.read(settingsProvider).language;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _barangay.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    await saveProfile(
      ref,
      UserProfile(
        fullName: _name.text.trim(),
        age: int.tryParse(_age.text.trim()),
        barangay: canonicalBarangay(ref.read(barangaysProvider).value, _barangay.text),
        language: _language,
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.profileSaved)));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return FormPage(
      title: l.editDetailsTitle,
      children: [
        Form(
          key: _form,
          child: ProfileFields(
            name: _name,
            age: _age,
            barangay: _barangay,
            language: _language,
            onLanguageChanged: (x) => setState(() => _language = x),
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        LoadingButton(label: l.save, loading: _saving, onPressed: _save),
      ],
    );
  }
}

class _EditHouseholdPage extends ConsumerStatefulWidget {
  const _EditHouseholdPage();

  @override
  ConsumerState<_EditHouseholdPage> createState() => _EditHouseholdPageState();
}

class _EditHouseholdPageState extends ConsumerState<_EditHouseholdPage> {
  late HouseholdProfile _household = ref.read(householdProvider).value?.household ?? const HouseholdProfile();
  late final _assistance = TextEditingController(text: _household.assistanceNeeds);
  bool _saving = false;

  @override
  void dispose() {
    _assistance.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final text = _assistance.text.trim();
    await ref
        .read(householdProvider.notifier)
        .updateHousehold(_household.copyWith(assistanceNeeds: () => text.isEmpty ? null : text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.householdSaved)));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return FormPage(
      title: l.editHouseholdTitle,
      children: [
        HouseholdFields(household: _household, assistance: _assistance, onChanged: (h) => setState(() => _household = h)),
        const SizedBox(height: AppSpacing.xxl),
        LoadingButton(label: l.save, loading: _saving, onPressed: _save),
      ],
    );
  }
}
