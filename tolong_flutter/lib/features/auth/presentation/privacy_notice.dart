import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../l10n/l10n.dart';

/// Draft notice for the academic prototype. Have it reviewed before any public release.
Future<void> showPrivacyNotice(BuildContext context) {
  final l = context.l10n;
  Widget section(String title, String body) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: sans(13, weight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.xs),
          Text(body, style: sans(12, height: 1.5, color: AppColors.muted)),
        ]),
      );

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xxl),
        children: [
          Text(l.privacyTitle, style: serif(22)),
          const SizedBox(height: AppSpacing.xs),
          Text(l.privacyDraft, style: sans(11, color: AppColors.muted)),
          const SizedBox(height: AppSpacing.lg),
          section(l.privacyCollectTitle, l.privacyCollectBody),
          section(l.privacyWhyTitle, l.privacyWhyBody),
          section(l.privacyWhereTitle, l.privacyWhereBody),
          section(l.privacyNotTitle, l.privacyNotBody),
          section(l.privacyChoicesTitle, l.privacyChoicesBody),
        ],
      ),
    ),
  );
}
