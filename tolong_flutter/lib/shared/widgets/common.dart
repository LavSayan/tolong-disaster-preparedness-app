import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/theme.dart';

class Logo extends StatelessWidget {
  const Logo({super.key});

  Widget _petal(Color color) => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(9),
            topRight: Radius.circular(2),
            bottomRight: Radius.circular(9),
            bottomLeft: Radius.circular(2),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Transform.rotate(
          angle: pi / 4,
          child: SizedBox(
            width: 27,
            height: 27,
            child: Stack(children: [
              Positioned(top: 0, left: 9, child: _petal(AppColors.sage)),
              Positioned(top: 9, left: 0, child: _petal(AppColors.blue)),
              Positioned(top: 9, right: 0, child: _petal(AppColors.amber)),
              Positioned(bottom: 0, left: 9, child: _petal(AppColors.terracotta)),
            ]),
          ),
        ),
        const SizedBox(width: 10),
        Text.rich(
          TextSpan(children: [
            const TextSpan(text: 'Tolong'),
            TextSpan(text: '.', style: sans(21, weight: FontWeight.w700, color: AppColors.terracotta)),
          ]),
          style: sans(21, weight: FontWeight.w700, letterSpacing: -1.05),
          // A brand mark, not body text: it keeps its size so headers fit at large text settings.
          textScaler: TextScaler.noScaling,
          semanticsLabel: 'TolongApp',
        ),
      ],
    );
  }
}

class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.color = const Color(0xFF4F6B57)});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: sans(10, weight: FontWeight.w700, color: color, letterSpacing: 1.3));
}

class CardBox extends StatelessWidget {
  const CardBox({super.key, required this.child, this.padding = const EdgeInsets.all(18)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    // Material (not a decorated box) so ink ripples from list tiles inside stay visible.
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Material(
        color: AppColors.cream,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppColors.line),
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({super.key, required this.label, required this.icon, this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.sage,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap ?? () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label, style: sans(12, weight: FontWeight.w600, color: Colors.white)),
              const SizedBox(width: 7),
              Icon(icon, size: 17, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

/// Marks placeholder content so it is never mistaken for real data.
class SampleTag extends StatelessWidget {
  const SampleTag(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: AppColors.amberSoft, borderRadius: BorderRadius.circular(AppRadii.pill)),
      child: Text(label, style: sans(9, weight: FontWeight.w700, color: const Color(0xFF9A7036), letterSpacing: 0.6)),
    );
  }
}

class IconTile extends StatelessWidget {
  const IconTile({
    super.key,
    required this.icon,
    required this.background,
    required this.foreground,
    this.size = 38,
    this.iconSize = 19,
    this.radius = 12,
  });

  final IconData icon;
  final Color background;
  final Color foreground;
  final double size;
  final double iconSize;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(radius)),
      child: Icon(icon, size: iconSize, color: foreground),
    );
  }
}
