import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets/common.dart';
import '../../../shared/widgets/form_widgets.dart';
import '../../household/presentation/household_forms.dart';
import '../data/offline_map_service.dart';
import '../data/qc_area_repository.dart';
import '../domain/qc_area.dart';

String offlineStatusText(AppLocalizations l, OfflineMapStatus s) => switch (s) {
      OfflineUnsupported() => l.offUnsupported,
      OfflineChecking() => '…',
      OfflineNotDownloaded() => l.offStatusNone,
      OfflineDownloading(:final fraction) => l.offStatusDownloading((fraction * 100).round()),
      OfflineDownloaded(:final at, :final bytes) =>
        l.offStatusDone(at == null ? '—' : l.date(at), l.number((bytes ?? 0) / (1024 * 1024))),
      OfflineFailed() => l.offStatusFailed,
    };

class OfflineMapScreen extends ConsumerWidget {
  const OfflineMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final status = ref.watch(offlineMapProvider);
    final boundary = ref.watch(qcBoundaryProvider).value;
    final controller = ref.read(offlineMapProvider.notifier);
    final tiles = boundary == null ? null : estimateTileCount(boundary.bounds, offlineMinZoom, offlineMaxZoom);

    Future<void> delete() async {
      final ok = await confirmDestructive(
        context,
        title: l.offDeleteTitle,
        body: l.offDeleteBody,
        confirmLabel: l.remove,
      );
      if (!ok) return;
      await controller.delete();
      if (context.mounted) showSoon(context, l.offDeleted);
    }

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        surfaceTintColor: Colors.transparent,
        title: Text(l.offTitle, style: serif(20)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.xxxl),
        children: [
          CardBox(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                const IconTile(
                  icon: Icons.download_for_offline_outlined,
                  background: AppColors.blueSoft,
                  foreground: AppColors.blue,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: Text(l.offIntro, style: sans(13, height: 1.45))),
              ]),
              const SizedBox(height: AppSpacing.lg),
              Text(l.offIncludes, style: sans(12, height: 1.45, color: AppColors.muted)),
              const SizedBox(height: AppSpacing.sm),
              Text(l.offNotIncluded, style: sans(12, height: 1.45, color: AppColors.muted)),
              if (tiles != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text('${l.offEstimate(tiles)} ${l.offWifi}', style: sans(11, color: AppColors.muted)),
              ],
            ]),
          ),
          CardBox(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              InlineMessage(
                offlineStatusText(l, status),
                tone: switch (status) {
                  OfflineDownloaded() => MessageTone.success,
                  OfflineFailed() => MessageTone.error,
                  _ => MessageTone.info,
                },
              ),
              if (status is OfflineDownloading) ...[
                const SizedBox(height: AppSpacing.md),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  child: LinearProgressIndicator(
                    value: status.fraction,
                    minHeight: 7,
                    backgroundColor: AppColors.blueSoft,
                    color: AppColors.blue,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              if (status is OfflineNotDownloaded || status is OfflineFailed)
                FilledButton.icon(
                  onPressed: boundary == null ? null : () => controller.download(boundary),
                  icon: const Icon(Icons.download_rounded, size: AppIconSizes.md),
                  label: Text(status is OfflineFailed ? l.offRetry : l.offDownload),
                ),
              if (status is OfflineDownloaded)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                  onPressed: delete,
                  icon: const Icon(Icons.delete_outline_rounded, size: AppIconSizes.md),
                  label: Text(l.offDelete),
                ),
            ]),
          ),
          Text(l.setMapAttributionBody, style: sans(10, height: 1.45, color: AppColors.muted)),
        ],
      ),
    );
  }
}
