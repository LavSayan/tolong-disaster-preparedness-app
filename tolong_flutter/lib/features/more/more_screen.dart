import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/demo.dart';
import '../../core/theme.dart';
import '../../l10n/l10n.dart';
import '../../shared/widgets/common.dart';
import '../auth/application/session.dart';
import '../household/presentation/profile_screen.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final guest = ref.watch(sessionProvider.select((s) => s.guest));

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      CardBox(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.lg),
        child: Column(children: [
          _MoreTile(
            icon: Icons.insights_outlined,
            title: l.moreReadiness,
            background: AppColors.sageSoft,
            foreground: AppColors.primary,
            onTap: () => context.push('/readiness'),
          ),
          _MoreTile(
            icon: Icons.inventory_outlined,
            title: l.moreSupplies,
            background: AppColors.amberSoft,
            foreground: AppColors.amber,
            onTap: () => context.push('/supplies'),
          ),
          _MoreTile(
            icon: Icons.group_outlined,
            title: l.moreProfile,
            background: AppColors.terracottaSoft,
            foreground: AppColors.terracotta,
            onTap: () => context.push('/profile'),
          ),
          _MoreTile(
            icon: Icons.contact_phone_outlined,
            title: l.moreContacts,
            background: AppColors.blueSoft,
            foreground: AppColors.blue,
            onTap: () => context.push('/profile'),
          ),
          _MoreTile(
            icon: Icons.settings_outlined,
            title: l.moreSettings,
            background: AppColors.sageSoft,
            foreground: AppColors.primary,
            onTap: () => context.push('/settings'),
          ),
          // The disaster guidebook has no cited content yet, so the whole feature is absent
          // (no tile, no route): an empty "coming soon" surface would be a placeholder.
          _MoreTile(
            icon: Icons.download_for_offline_outlined,
            title: l.moreOffline,
            background: AppColors.blueSoft,
            foreground: AppColors.blue,
            onTap: () => context.push('/offline-readiness'),
          ),
          // Visible only in demo builds (compile-time DEMO_TOOLS define); English on purpose —
          // same as the panel itself, an internal tool with no shipped strings.
          if (ref.watch(demoToolsEnabledProvider))
            _MoreTile(
              icon: Icons.bug_report_outlined,
              title: 'Demo tools',
              background: AppColors.amberSoft,
              foreground: AppColors.amber,
              onTap: () => context.push('/demo'),
            ),
        ]),
      ),
      OutlinedButton.icon(
        onPressed: () => confirmSignOut(context, ref),
        icon: const Icon(Icons.logout_rounded, size: AppIconSizes.md),
        label: Text(guest ? l.leaveGuest : l.logOut),
      ),
      const SizedBox(height: AppSpacing.lg),
      Text(l.disclaimer, textAlign: TextAlign.center, style: sans(10, height: 1.5, color: const Color(0xFF5C6B63))),
    ]);
  }
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({
    required this.icon,
    required this.title,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: IconTile(icon: icon, background: background, foreground: foreground, size: 34, radius: 11),
      title: Text(title, style: sans(13, weight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFFAAB4AD)),
    );
  }
}
