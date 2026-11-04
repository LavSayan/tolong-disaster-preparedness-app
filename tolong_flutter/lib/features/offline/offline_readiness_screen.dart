import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../l10n/l10n.dart';
import '../../shared/widgets/animations.dart';
import '../../shared/widgets/common.dart';
import '../auth/application/session.dart';
import '../safe_places/data/evacuation_center_repository.dart';
import '../safe_places/data/offline_map_service.dart';
import '../safe_places/presentation/offline_map_screen.dart';
import '../sync/application/sync_engine.dart';

enum Readiness { ready, partial, missing }

class OfflineReadinessScreen extends ConsumerWidget {
  const OfflineReadinessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final map = ref.watch(offlineMapProvider);
    final centers = ref.watch(evacuationCentersProvider).value ?? const [];
    final session = ref.watch(sessionProvider);
    final sync = ref.watch(syncProvider);

    String time(DateTime t) => DateFormat.yMMMd(l.localeName).add_jm().format(t.toLocal());

    final (syncState, syncBody) = switch (sync) {
      _ when session.guest => (Readiness.missing, l.orcSyncGuest),
      SyncStatus(enabled: false) => (Readiness.missing, l.orcSyncOff),
      SyncStatus(syncing: true) => (Readiness.partial, l.orcSyncing),
      SyncStatus(:final error?) when error.isNotEmpty => (Readiness.partial, l.orcSyncError),
      SyncStatus(:final lastSuccessAt, :final pending) => (
          pending == 0 && lastSuccessAt != null ? Readiness.ready : Readiness.partial,
          '${lastSuccessAt == null ? l.orcSyncNever : l.orcSyncLast(time(lastSuccessAt))} ${l.orcSyncPending(pending)}',
        ),
    };

    final items = <_Item>[
      _Item(
        icon: Icons.map_outlined,
        title: l.orcMap,
        body: offlineStatusText(l, map),
        state: switch (map) {
          OfflineDownloaded() => Readiness.ready,
          OfflineDownloading() => Readiness.partial,
          _ => Readiness.missing,
        },
        onTap: () => context.push('/offline-map'),
      ),
      _Item(
        icon: Icons.location_city_outlined,
        title: l.orcAreaData,
        body: l.orcAreaDataBody,
        state: Readiness.ready,
      ),
      _Item(
        icon: Icons.night_shelter_outlined,
        title: l.orcCenters,
        body: l.orcCentersBody(centers.length),
        state: centers.isEmpty ? Readiness.missing : (centers.every((c) => c.verified) ? Readiness.ready : Readiness.partial),
        onTap: () => context.go('/safe-places'),
      ),
      _Item(
        icon: Icons.lock_outline_rounded,
        title: l.orcHousehold,
        body: l.orcHouseholdBody,
        state: Readiness.ready,
        onTap: () => context.push('/profile'),
      ),
      _Item(icon: Icons.cloud_sync_outlined, title: l.orcSync, body: syncBody, state: syncState),
    ];
    final ready = items.where((i) => i.state == Readiness.ready).length;
    final mapBytes = map is OfflineDownloaded ? map.bytes : null;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        surfaceTintColor: Colors.transparent,
        title: Text(l.orcTitle, style: serif(20)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.xxxl),
        children: [
          CardBox(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.orcIntro, style: sans(13, height: 1.45, color: AppColors.muted)),
              const SizedBox(height: AppSpacing.md),
              Text(l.orcReadyCount(ready, items.length), style: serif(22)),
              const SizedBox(height: AppSpacing.sm),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: ready / items.length),
                duration: motion(context, const Duration(milliseconds: 700)),
                curve: Curves.easeOutCubic,
                builder: (context, v, _) => ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  child: LinearProgressIndicator(
                    value: v,
                    minHeight: 7,
                    backgroundColor: const Color(0xFFE9EEE7),
                    color: AppColors.sage,
                  ),
                ),
              ),
              if (mapBytes != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(l.orcStorage(l.number(mapBytes / (1024 * 1024))), style: sans(11, color: AppColors.muted)),
              ],
            ]),
          ),
          for (final (i, item) in items.indexed)
            FadeSlideIn(delay: Duration(milliseconds: 40 * i), child: _ItemTile(item: item)),
          if (sync.enabled) ...[
            const SizedBox(height: AppSpacing.sm),
            FilledButton.icon(
              onPressed: sync.syncing ? null : () => ref.read(syncProvider.notifier).syncNow(),
              icon: const Icon(Icons.cloud_upload_outlined, size: AppIconSizes.md),
              label: Text(sync.syncing ? l.orcSyncing : l.orcSyncNow),
            ),
          ],
        ],
      ),
    );
  }
}

class _Item {
  const _Item({required this.icon, required this.title, required this.body, required this.state, this.onTap});

  final IconData icon;
  final String title;
  final String body;
  final Readiness state;
  final VoidCallback? onTap;
}

class _ItemTile extends StatelessWidget {
  const _ItemTile({required this.item});

  final _Item item;

  @override
  Widget build(BuildContext context) {
    final (badge, color) = switch (item.state) {
      Readiness.ready => (Icons.check_circle_rounded, AppColors.success),
      Readiness.partial => (Icons.error_outline_rounded, AppColors.warning),
      Readiness.missing => (Icons.cancel_outlined, AppColors.muted),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: AppColors.cream,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.tile),
          side: const BorderSide(color: AppColors.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: item.onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              IconTile(icon: item.icon, background: AppColors.sageSoft, foreground: AppColors.primary, size: 34, radius: 11),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(item.title, style: sans(13, weight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(item.body, style: sans(11, height: 1.4, color: AppColors.muted)),
                ]),
              ),
              const SizedBox(width: AppSpacing.sm),
              Semantics(label: item.state.name, child: Icon(badge, color: color, size: AppIconSizes.lg)),
            ]),
          ),
        ),
      ),
    );
  }
}
