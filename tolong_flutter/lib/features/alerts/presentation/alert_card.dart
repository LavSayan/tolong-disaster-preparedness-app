import 'dart:math';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets/common.dart';
import 'warning_sound.dart';

class AlertCard extends StatefulWidget {
  const AlertCard({super.key, required this.onDismiss, required this.onMap});

  final VoidCallback onDismiss;
  final VoidCallback onMap;

  @override
  State<AlertCard> createState() => _AlertCardState();
}

class _AlertCardState extends State<AlertCard> with SingleTickerProviderStateMixin {
  late final AnimationController _breathe =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));

  void _onSoundChanged(bool playing) {
    if (playing) {
      _breathe.repeat();
    } else {
      _breathe
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _breathe.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AnimatedBuilder(
      animation: _breathe,
      builder: (context, child) {
        final t = sin(pi * _breathe.value);
        return Container(
          margin: const EdgeInsets.only(bottom: 18),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.terracottaSoft,
            border: Border.all(color: const Color(0xFFEDCDBD)),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Color.fromRGBO(189, 115, 87, 0.09 * t), spreadRadius: 5 * t)],
          ),
          child: child,
        );
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: const Color(0xFFDFAA90), borderRadius: BorderRadius.circular(13)),
            child: const Icon(Icons.waves_rounded, size: 22, color: Color(0xFF8C543F)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(l.alertFloodAdvisory,
                        style: sans(9, weight: FontWeight.w700, color: const Color(0xFFA55E48), letterSpacing: 1.08)),
                    SampleTag(l.alertDemoTag),
                  ],
                ),
                const SizedBox(height: 6),
                Text(l.alertDemoTitle, style: serif(18, height: 1.13, tracking: -0.03, color: const Color(0xFF60483E))),
                const SizedBox(height: 6),
                Text(l.alertDemoBody, style: sans(11, height: 1.45, color: const Color(0xFF835F50))),
                FloodAlertSound(onChanged: _onSoundChanged),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: widget.onMap,
                      child: Row(children: [
                        Flexible(
                          child: Text(l.alertOpenSafePlaces,
                              style: sans(11, weight: FontWeight.w700, color: const Color(0xFF925642))),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF925642)),
                      ]),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Semantics(
                    label: l.alertDismiss,
                    button: true,
                    child: Material(
                      color: const Color(0x59FFFFFF),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: widget.onDismiss,
                        child: const SizedBox(
                          width: 25,
                          height: 25,
                          child: Icon(Icons.close_rounded, size: 16, color: Color(0xFF9A6C5A)),
                        ),
                      ),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FloodAlertSound extends StatefulWidget {
  const FloodAlertSound({super.key, required this.onChanged});

  final ValueChanged<bool> onChanged;

  @override
  State<FloodAlertSound> createState() => _FloodAlertSoundState();
}

class _FloodAlertSoundState extends State<FloodAlertSound> with SingleTickerProviderStateMixin {
  static final Uint8List _wav = buildWarningWav();

  // Created on first play so the audio plugin is not started for users who never tap it.
  AudioPlayer? _player;
  late final AnimationController _bars = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
  bool _playing = false;

  Future<void> _start() async {
    final player = _player ??= AudioPlayer();
    await player.setReleaseMode(ReleaseMode.loop);
    await player.play(BytesSource(_wav, mimeType: 'audio/wav'));
    if (!mounted) return;
    setState(() => _playing = true);
    _bars.repeat();
    widget.onChanged(true);
  }

  Future<void> _stop() async {
    await _player?.stop();
    if (!mounted) return;
    setState(() => _playing = false);
    _bars.stop();
    widget.onChanged(false);
  }

  @override
  void dispose() {
    _player?.dispose();
    _bars.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const fg = Color(0xFF8E5947);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Semantics(
        button: true,
        toggled: _playing,
        child: Material(
          color: _playing ? const Color(0xFFFFF8EF) : const Color(0x5CFFFFFF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: Color(0x38A35B43)),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: _playing ? _stop : _start,
            child: Container(
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 9),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(color: const Color(0xFFEDCBBB), borderRadius: BorderRadius.circular(7)),
                  child: Icon(_playing ? Icons.volume_up_rounded : Icons.volume_off_rounded, size: 15, color: fg),
                ),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(_playing ? context.l10n.soundPlaying : context.l10n.soundPlay,
                      style: sans(10, weight: FontWeight.w700, color: _playing ? const Color(0xFF9A523B) : fg)),
                ),
                if (_playing) ...[
                  const SizedBox(width: 9),
                  AnimatedBuilder(
                    animation: _bars,
                    builder: (context, _) => Row(children: [
                      for (final (height, offset) in const [(6.0, 0.25), (13.0, 0.0), (9.0, 0.56)])
                        Padding(
                          padding: const EdgeInsets.only(right: 2),
                          child: Transform.scale(
                            scaleY: 0.85 + 0.3 * sin(2 * pi * (_bars.value + offset)),
                            child: Container(
                              width: 2,
                              height: height,
                              decoration: BoxDecoration(
                                color: AppColors.terracotta,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                    ]),
                  ),
                ],
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
