import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets/form_widgets.dart';
import '../../household/presentation/household_forms.dart';
import '../../settings/settings.dart';
import '../application/tol_controller.dart';
import '../domain/tol_models.dart';

/// Round Tol face used on the floating button and in the chat header.
class TolAvatar extends StatelessWidget {
  const TolAvatar({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(color: AppColors.sageSoft, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Icon(Icons.chat_bubble_rounded, size: size * 0.48, color: AppColors.sage),
    );
  }
}

/// Floating entry point. Gently bobs unless reduced motion is on.
class TolFab extends StatefulWidget {
  const TolFab({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  State<TolFab> createState() => _TolFabState();
}

class _TolFabState extends State<TolFab> with SingleTickerProviderStateMixin {
  late final AnimationController _float =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2600));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _float.stop();
    } else if (!_float.isAnimating) {
      _float.repeat();
    }
  }

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AnimatedBuilder(
      animation: _float,
      builder: (context, child) =>
          Transform.translate(offset: Offset(0, -3 * sin(2 * pi * _float.value)), child: child),
      child: Tooltip(
        message: l.tolOpen,
        child: Material(
          color: AppColors.sage,
          elevation: 4,
          shadowColor: const Color(0x33415A47),
          shape: const StadiumBorder(),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: widget.onTap,
            child: Container(
              // 48 dp keeps the button at Android's minimum tap-target height.
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.fromLTRB(12, 8, 18, 8),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Text(l.tolTitle, style: sans(14, weight: FontWeight.w700, color: Colors.white)),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class TolChatScreen extends ConsumerStatefulWidget {
  const TolChatScreen({super.key});

  @override
  ConsumerState<TolChatScreen> createState() => _TolChatScreenState();
}

class _TolChatScreenState extends ConsumerState<TolChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToEnd() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
      });

  Future<void> _send([String? text]) async {
    final value = (text ?? _input.text).trim();
    if (value.isEmpty) return;
    _input.clear();
    await ref.read(tolProvider.notifier).send(value, context.l10n);
  }

  Future<void> _clear() async {
    final l = context.l10n;
    final ok =
        await confirmDestructive(context, title: l.tolClearTitle, body: l.tolClearBody, confirmLabel: l.tolClear);
    if (ok) await ref.read(tolProvider.notifier).clear();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final state = ref.watch(tolProvider);
    final online = ref.watch(tolOnlineAvailableProvider);
    final consent = ref.watch(settingsProvider.select((s) => s.tolContextConsent));
    ref.listen(tolProvider.select((s) => s.messages.length), (_, __) => _scrollToEnd());

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        title: Row(children: [
          const TolAvatar(size: 36),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.tolTitle, style: serif(18)),
              _ModeChip(online: online),
            ]),
          ),
        ]),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'clear') _clear();
              if (v == 'consent') {
                ref.read(settingsProvider.notifier).update((s) => s.copyWith(tolContextConsent: !s.tolContextConsent));
              }
            },
            itemBuilder: (_) => [
              CheckedPopupMenuItem(value: 'consent', checked: consent, child: Text(l.tolShareContext)),
              PopupMenuItem(value: 'clear', enabled: state.messages.isNotEmpty, child: Text(l.tolClear)),
            ],
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(children: [
          Expanded(
            child: ListView(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
              children: [
                _Bubble(text: l.tolWelcome, mine: false),
                if (!online)
                  Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md), child: InlineMessage(l.tolOfflineReason)),
                for (final m in state.messages) _MessageView(message: m, isLast: m == state.messages.lastOrNull),
                if (state.sending) _Bubble(text: l.tolTyping, mine: false, muted: true),
                if (state.messages.isEmpty && !state.sending) ...[
                  const SizedBox(height: AppSpacing.md),
                  Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [
                    for (final q in [l.tolSuggestGoBag, l.tolSuggestWater, l.tolSuggestStart, l.tolSuggestFlood])
                      ActionChip(
                        label: Text(q),
                        backgroundColor: AppColors.cream,
                        side: const BorderSide(color: AppColors.line),
                        onPressed: () => _send(q),
                      ),
                  ]),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.sm, AppSpacing.sm),
            decoration: const BoxDecoration(
              color: AppColors.cream,
              border: Border(top: BorderSide(color: AppColors.line)),
            ),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _input,
                  minLines: 1,
                  maxLines: 4,
                  maxLength: 1000,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  decoration: InputDecoration(hintText: l.tolInputHint, counterText: ''),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              IconButton.filled(
                tooltip: l.tolSend,
                onPressed: state.sending ? null : _send,
                style: IconButton.styleFrom(backgroundColor: AppColors.sage),
                icon: const Icon(Icons.send_rounded, color: Colors.white),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({required this.online});

  final bool online;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final color = online ? AppColors.success : AppColors.warning;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 5),
      Flexible(
        child: Text(
          online ? l.tolModeOnline : l.tolModeOffline,
          overflow: TextOverflow.ellipsis,
          style: sans(11, weight: FontWeight.w600, color: color),
        ),
      ),
    ]);
  }
}

class _MessageView extends ConsumerWidget {
  const _MessageView({required this.message, required this.isLast});

  final TolMessage message;
  final bool isLast;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    if (message.role == TolRole.user) return _Bubble(text: message.text, mine: true);
    final online = message.mode == TolMode.online;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (message.onlineFailed)
        Padding(
          padding: const EdgeInsets.only(left: AppSpacing.xs, bottom: 4),
          child: Text(l.tolOnlineFailed, style: sans(10, color: AppColors.warning)),
        ),
      _Bubble(text: message.text, mine: false),
      Padding(
        padding: const EdgeInsets.only(left: AppSpacing.xs, bottom: AppSpacing.md),
        child: Row(children: [
          Icon(online ? Icons.auto_awesome_outlined : Icons.offline_bolt_outlined,
              size: 12, color: online ? AppColors.muted : AppColors.warning),
          const SizedBox(width: 4),
          Flexible(child: Text(online ? l.tolAiLabel : l.tolOfflineLabel, style: sans(10, color: AppColors.muted))),
          if (message.onlineFailed && isLast)
            TextButton(
              onPressed: () => ref.read(tolProvider.notifier).retryOnline(l),
              child: Text(l.tolRetryOnline),
            ),
        ]),
      ),
    ]);
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.text, required this.mine, this.muted = false});

  final String text;
  final bool mine;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.8),
        child: Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: mine ? AppColors.sage : AppColors.cream,
            border: mine ? null : Border.all(color: AppColors.line),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(mine ? 18 : 4),
              bottomRight: Radius.circular(mine ? 4 : 18),
            ),
          ),
          child: SelectableText(
            text,
            style: sans(13, height: 1.45, color: mine ? Colors.white : (muted ? AppColors.muted : AppColors.ink)),
          ),
        ),
      ),
    );
  }
}
