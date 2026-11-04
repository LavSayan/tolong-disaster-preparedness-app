import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets/common.dart';
import '../../../shared/widgets/form_widgets.dart';
import '../application/submission_controllers.dart';
import '../domain/shelter_submission.dart';

/// The signed-in user's own submissions and their review status. Pending rows can be
/// edited (same form as submission) or withdrawn; approved/rejected rows are history —
/// an approved one now lives in the ranked list, a rejected one shows the note.
class MySubmissionsScreen extends ConsumerWidget {
  const MySubmissionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final queue = ref.watch(mySubmissionsProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        surfaceTintColor: Colors.transparent,
        title: Text(l.mySubmissionsTitle, style: serif(20)),
      ),
      body: queue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => e is SubmissionFailure
            ? ListView(padding: const EdgeInsets.all(AppSpacing.xl), children: [
                InlineMessage(l.submissionError(e.code), tone: MessageTone.error),
              ])
            : ListView(padding: const EdgeInsets.all(AppSpacing.xl), children: [
                InlineMessage(l.couldNotLoad, tone: MessageTone.error),
              ]),
        data: (submissions) => submissions.isEmpty
            ? ListView(padding: const EdgeInsets.all(AppSpacing.xl), children: [
                InlineMessage(l.mySubmissionsEmpty),
              ])
            : ListView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.xxxl),
                children: [
                  for (final s in submissions)
                    _SubmissionCard(submission: s),
                ],
              ),
      ),
    );
  }
}

class _SubmissionCard extends ConsumerWidget {
  const _SubmissionCard({required this.submission});

  final ShelterSubmission submission;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final d = submission.draft;
    final (statusColor, statusIcon) = switch (submission.status) {
      SubmissionStatus.pending => (AppColors.amberSoft, Icons.pending_outlined),
      SubmissionStatus.approved => (AppColors.sageSoft, Icons.check_circle_outline_rounded),
      SubmissionStatus.rejected => (AppColors.errorSoft, Icons.close_rounded),
    };

    Future<void> withdraw() async {
      try {
        await ref.read(submitShelterServiceProvider).withdraw(submission.id);
        ref.invalidate(mySubmissionsProvider);
        if (context.mounted) showMessage(context, l.mySubmissionsWithdrawn);
      } on SubmissionFailure catch (f) {
        if (context.mounted) showMessage(context, l.submissionError(f.code));
      }
    }

    return CardBox(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          IconTile(
            icon: statusIcon,
            background: statusColor,
            foreground: statusIcon == Icons.close_rounded ? AppColors.error : statusColor == AppColors.amberSoft
                ? const Color(0xFF9A7036)
                : const Color(0xFF3F654A),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [Eyebrow(l.submissionStatus(submission.status).toUpperCase())],
              ),
              const SizedBox(height: 4),
              Text(d.name, style: serif(18)),
              const SizedBox(height: 4),
              Text(
                '${l.facilityType(d.facilityType)} · ${d.barangay}',
                style: sans(11, color: AppColors.muted),
              ),
              const SizedBox(height: 4),
              Text(l.date(submission.submittedAt), style: sans(11, color: AppColors.muted)),
            ]),
          ),
        ]),
        if (submission.rejectionReason != null && submission.rejectionReason!.trim().isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          InlineMessage(l.subRejection(submission.rejectionReason!.trim()), tone: MessageTone.error),
        ],
        if (submission.status == SubmissionStatus.pending) ...[
          const SizedBox(height: AppSpacing.md),
          Row(children: [
            TextButton.icon(
              onPressed: () => context.push('/submit-shelter', extra: submission),
              icon: const Icon(Icons.edit_outlined, size: AppIconSizes.md, color: AppColors.primary),
              label: Text(l.edit, style: sans(12, color: AppColors.primary)),
            ),
            const SizedBox(width: AppSpacing.lg),
            TextButton.icon(
              onPressed: withdraw,
              icon: const Icon(Icons.delete_outline_rounded, size: AppIconSizes.md, color: AppColors.error),
              label: Text(l.mySubmissionsWithdraw, style: sans(12, color: AppColors.error)),
            ),
          ]),
        ],
      ]),
    );
  }
}
