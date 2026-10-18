import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../l10n/l10n.dart';

/// Circular score that sweeps to its value (instantly under reduced motion).
class ReadinessRing extends StatelessWidget {
  const ReadinessRing({super.key, required this.score, this.size = 57, this.stroke = 5});

  final int score;
  final double size;
  final double stroke;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.l10n.readinessScoreSemantics(score),
      excludeSemantics: true,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: score / 100),
        duration: motion(context, const Duration(milliseconds: 900)),
        curve: Curves.easeOutCubic,
        builder: (context, value, _) => SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _RingPainter(value, stroke),
            child: Center(
              child: Text.rich(
                TextSpan(children: [
                  TextSpan(text: '${(value * 100).round()}'),
                  TextSpan(text: '%', style: sans(size * 0.16, weight: FontWeight.w700, color: AppColors.sage)),
                ]),
                style: sans(size * 0.28, weight: FontWeight.w700, color: AppColors.sage),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.progress, this.stroke);

  final double progress;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final arc = rect.deflate(stroke / 2);
    canvas.drawArc(
      arc,
      0,
      2 * pi,
      false,
      Paint()
        ..color = const Color(0xFFD8E6D8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
    canvas.drawArc(
      arc,
      -pi / 2,
      2 * pi * progress,
      false,
      Paint()
        ..color = AppColors.sage
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = stroke,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress || old.stroke != stroke;
}
