import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../core/clock.dart';
import '../core/theme.dart';
import '../features/auth/application/session.dart';
import '../features/household/data/household_repository.dart';
import '../features/tol/presentation/tol_chat_screen.dart';
import '../l10n/l10n.dart';
import '../shared/widgets/animations.dart';
import '../shared/widgets/common.dart';
import '../shared/widgets/form_widgets.dart';

List<String> _tabTitles(AppLocalizations l) => [l.tabHome, l.tabPrepare, l.tabSafePlaces, l.tabMore];

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guest = ref.watch(sessionProvider.select((s) => s.guest));
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Material(
            color: AppColors.canvas,
            child: Column(children: [
              const SafeArea(bottom: false, child: _Header()),
              if (guest) const _GuestBanner(),
              Expanded(
                child: Stack(children: [
                  Positioned.fill(child: shell),
                  // Hidden on Safe places so it never covers the map controls.
                  if (shell.currentIndex != 2)
                    Positioned(
                        right: AppSpacing.lg, bottom: AppSpacing.lg, child: TolFab(onTap: () => context.push('/tol'))),
                ]),
              ),
              _BottomNav(
                index: shell.currentIndex,
                onSelect: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Scrollable page frame for one bottom-navigation tab: section label, date, then content.
class TabPage extends ConsumerWidget {
  const TabPage({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final now = ref.watch(clockProvider)();
    return ListView(
      // Extra bottom space so the floating Tol button never hides the last item.
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 1, AppSpacing.xl, 88),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 0, 2, 18),
          child: Row(children: [
            Flexible(
              child: Text(_tabTitles(l)[index].toUpperCase(),
                  overflow: TextOverflow.ellipsis,
                  style: sans(12, weight: FontWeight.w700, color: AppColors.sage, letterSpacing: 1.2)),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(DateFormat('EEEE · MMM d', l.localeName).format(now),
                style: sans(11, weight: FontWeight.w500, color: const Color(0xFF5C6B63))),
          ]),
        ),
        FadeSlideIn(child: child),
      ],
    );
  }
}

class _GuestBanner extends StatelessWidget {
  const _GuestBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.md),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(color: AppColors.amberSoft, borderRadius: BorderRadius.circular(AppRadii.sm)),
      child: Row(children: [
        const Icon(Icons.health_and_safety_outlined, size: AppIconSizes.sm, color: Color(0xFF7A521A)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child:
              Text(context.l10n.guestBanner, style: sans(10, weight: FontWeight.w600, color: const Color(0xFF7A521A))),
        ),
      ]),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final name = ref.watch(householdProvider).value?.profile?.fullName ?? '';
    return SizedBox(
      height: 72,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 0, 12, 0),
        child: Row(children: [
          const Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(fit: BoxFit.scaleDown, child: Logo()),
            ),
          ),
          _HeaderIcon(Icons.sensors_rounded,
              tooltip: l.headerOfflineStatus, onTap: () => context.push('/offline-readiness')),
          _HeaderIcon(Icons.notifications_none_rounded,
              tooltip: l.headerAlerts, onTap: () => showSoon(context, l.soonAlerts)),
          Semantics(
            button: true,
            label: l.openProfile,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => context.push('/profile'),
              // The visible avatar stays 33 dp; the tap area around it is 48 dp.
              child: SizedBox.square(
                dimension: 48,
                child: Center(
                  child: Container(
                    width: 33,
                    height: 33,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(color: Color(0xFFE2B998), shape: BoxShape.circle),
                    child: name.isEmpty
                        ? const Icon(Icons.person_outline_rounded, size: 18, color: Color(0xFF6D4736))
                        : Text(name[0].toUpperCase(),
                            style: sans(13, weight: FontWeight.w700, color: const Color(0xFF6D4736))),
                  ),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon(this.icon, {required this.tooltip, required this.onTap});

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: const Color(0xFF5C6B63)),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.index, required this.onSelect});

  final int index;
  final ValueChanged<int> onSelect;

  static const _icons = [
    Icons.home_outlined,
    Icons.backpack_outlined,
    Icons.explore_outlined,
    Icons.more_horiz_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final titles = _tabTitles(context.l10n);
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xF0FBFAF6),
        border: Border(top: BorderSide(color: Color(0xCCDDDED4))),
      ),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 70),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              for (var i = 0; i < titles.length; i++)
                Expanded(
                  child: Semantics(
                    selected: i == index,
                    button: true,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      onTap: () => onSelect(i),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          AnimatedContainer(
                            duration: motion(context, AppDurations.normal),
                            curve: Curves.easeOutCubic,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
                            decoration: BoxDecoration(
                              color: i == index ? AppColors.sageSoft : Colors.transparent,
                              borderRadius: BorderRadius.circular(AppRadii.pill),
                            ),
                            child: Icon(_icons[i],
                                size: AppIconSizes.lg, color: i == index ? AppColors.sage : const Color(0xFF5C6B63)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            titles[i],
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: sans(10,
                                height: 1.15,
                                weight: i == index ? FontWeight.w700 : FontWeight.w500,
                                color: i == index ? AppColors.sage : const Color(0xFF5C6B63)),
                          ),
                        ]),
                      ),
                    ),
                  ),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}
