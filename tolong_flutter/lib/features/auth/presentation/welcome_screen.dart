import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets/animations.dart';
import '../../../shared/widgets/character.dart';
import '../../../shared/widgets/common.dart';
import '../../../shared/widgets/form_widgets.dart';
import '../../household/domain/models.dart';
import '../../settings/settings.dart';
import '../application/session.dart';
import '../data/auth_repository.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  Future<void> _confirmGuest(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      builder: (context) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xxl),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(l.guestSheetTitle, style: serif(22)),
          const SizedBox(height: AppSpacing.sm),
          Text(l.guestSheetBody, style: sans(13, height: 1.5, color: AppColors.muted)),
          const SizedBox(height: AppSpacing.xl),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l.guestContinue)),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
        ]),
      ),
    );
    if (ok == true) await ref.read(sessionProvider.notifier).enterGuestMode();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final configured = ref.watch(authRepositoryProvider).isConfigured;
    final language = ref.watch(settingsProvider.select((s) => s.language));
    return Scaffold(
      backgroundColor: AppColors.outer,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Material(
            color: AppColors.canvas,
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xxl),
                children: [
                  Row(children: [
                    const Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FittedBox(fit: BoxFit.scaleDown, child: Logo()),
                      ),
                    ),
                    SegmentedButton<AppLanguage>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(value: AppLanguage.english, label: Text('EN')),
                        ButtonSegment(value: AppLanguage.filipino, label: Text('FIL')),
                      ],
                      selected: {language},
                      onSelectionChanged: (s) =>
                          ref.read(settingsProvider.notifier).update((x) => x.copyWith(language: s.first)),
                    ),
                  ]),
                  const SizedBox(height: AppSpacing.xl),
                  FadeSlideIn(
                    child: Container(
                      height: 250,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: AppColors.sageSoft,
                        borderRadius: BorderRadius.circular(AppRadii.hero),
                      ),
                      child: Stack(children: [
                        const Positioned(right: 0, bottom: -10, child: Character(scene: Scene.home)),
                        Positioned(left: AppSpacing.xl, top: AppSpacing.xxl, child: Eyebrow(l.welcomeMeetTol)),
                      ]),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 120),
                    child: Text(l.welcomeTitle, style: serif(30, height: 1.05, tracking: -0.05)),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 200),
                    child: Text(l.welcomeBody, style: sans(13, height: 1.5, color: AppColors.muted)),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  if (!configured) ...[
                    InlineMessage(l.welcomeNotConfigured),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 280),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Pressable(
                        child: FilledButton(onPressed: () => context.push('/register'), child: Text(l.createAccount)),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Pressable(
                        child: OutlinedButton(onPressed: () => context.push('/login'), child: Text(l.logIn)),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextButton.icon(
                        onPressed: () => _confirmGuest(context, ref),
                        icon: const Icon(Icons.health_and_safety_outlined, size: AppIconSizes.md),
                        label: Text(l.emergencyAccess),
                      ),
                    ]),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
