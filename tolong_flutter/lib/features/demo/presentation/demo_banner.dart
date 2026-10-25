import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme.dart';
import '../../../l10n/l10n.dart';
import '../../alerts/presentation/alert_card.dart';
import '../application/demo_session.dart';
import 'advisory_texts.dart';

/// Thin strip under the app header: shown on every tab while at least one simulated input is
/// active, so no screenshot can be mistaken for a live app. Runs only in demo builds
/// ([demoBannerActiveProvider] is false everywhere else, including every test scope).
class DemoBanner extends StatelessWidget {
  const DemoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.md),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.amberSoft,
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Row(children: [
        const Icon(Icons.bug_report_outlined, size: AppIconSizes.sm, color: Color(0xFF7A521A)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            context.l10n.demoBannerActive,
            style: sans(10, weight: FontWeight.w600, color: const Color(0xFF7A521A)),
          ),
        ),
      ]),
    );
  }
}

/// What the header bell opens while a simulated advisory is live: the same advisory text the
/// Home card renders, plus buttons. Hidden bell in every non-demo build.
void showSimulatedAdvisorySheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.lg),
          child: _AdvisorySheet(),
        ),
      ),
    ),
  );
}

class _AdvisorySheet extends ConsumerWidget {
  const _AdvisorySheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final advisory = ref.watch(demoAdvisoryProvider);
    if (advisory == null) return Text(l.headerAlerts, style: serif(19));
    final t = advisoryTexts(l, advisory);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l.headerAlerts, style: serif(19)),
        const SizedBox(height: AppSpacing.md),
        AlertCard(
          category: t.category,
          title: t.title,
          body: t.body,
          tag: t.tag,
          onDismiss: () => Navigator.of(context).pop(),
          onMap: () {
            Navigator.of(context).pop();
            context.push('/safe-places');
          },
        ),
        const SizedBox(height: AppSpacing.xs),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            context.push('/demo');
          },
          child: Text(l.demoOpenTools),
        ),
      ],
    );
  }
}
