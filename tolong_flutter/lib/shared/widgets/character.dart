import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme.dart';
import '../../l10n/l10n.dart';
import 'common.dart';
import 'scenes.dart';

export 'scenes.dart' show Scene;

String _characterSvg(Scene scene) {
  final isAlert = scene == Scene.alert;
  final b = StringBuffer('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 260 210">');
  void stroke(String d, String color, num width) => b.write(
      '<path d="$d" fill="none" stroke="$color" stroke-width="$width" stroke-linecap="round"/>');

  stroke('M43 187c23-24 49-36 82-36 45 0 81 14 99 36', '#c9d8c7', 4);
  b.write('<path d="M82 119c-6-28 7-68 48-70 39-2 57 27 53 64-2 26-14 42-49 43-32 1-47-13-52-37Z" fill="#a3c4a5"/>');
  b.write('<path d="M82 79c8-40 65-49 92-10-15-4-27-12-39-14-15 14-31 21-53 24Z" fill="#3f5d51"/>');
  b.write('<path d="M93 101c0-18 14-32 37-32 23 0 37 14 37 32v27c0 15-17 28-37 28-20 0-37-13-37-28v-27Z" fill="#f7e9cf"/>');
  stroke(isAlert ? 'M108 104l7 2' : 'M108 105c4 4 8 4 12 0', '#3f5d51', 3.5);
  stroke(isAlert ? 'M137 106l7-2' : 'M137 105c4 4 8 4 12 0', '#3f5d51', 3.5);
  b.write('<circle cx="116" cy="116" r="3.3" fill="#3f5d51"/><circle cx="147" cy="116" r="3.3" fill="#3f5d51"/>');
  stroke(isAlert ? 'M124 132c7-5 14-5 21 0' : 'M123 130c7 9 16 9 24 0', '#bd7357', 3.5);
  b.write('<path d="M94 151c14 9 33 13 50 9 10-3 20-7 28-15l16 43H78l16-37Z" fill="${isAlert ? '#c96c56' : '#719b7b'}"/>');
  stroke('M108 188l-6-31m49 31 4-36', '#3f5d51', 7);

  switch (scene) {
    case Scene.home:
      b.write('<path d="M83 161c-15 1-27-8-28-23-1-8 3-12 9-9l15 14 4-15c2-8 8-8 10-1l-1 23c-1 6-3 9-9 11Z" fill="#a3c4a5"/>');
    case Scene.alert:
      b.write('<path d="M169 156l19-28c3-5 10-3 9 3l-8 36-10 4Z" fill="#a3c4a5"/>');
      stroke('M179 132l12-11', '#3f5d51', 4);
      stroke('M185 114c6-4 13-4 18 0', '#d18b4b', 5);
    case Scene.guide:
      b.write('<rect x="161" y="142" width="35" height="28" rx="5" fill="#e4ae60" transform="rotate(-8 161 142)"/>');
      stroke('M169 151h20m-20 7h14', '#fff6df', 3);
      stroke('M170 140l12-10', '#3f5d51', 4);
    case Scene.map:
      b.write('<path d="M164 142l38-12 2 37-38 12-2-37Z" fill="#f6e4bc" stroke="#3f5d51" stroke-width="3"/>');
      b.write('<path d="m174 150 17 4 7-11m-18 27 12-13" fill="none" stroke="#719b7b" stroke-width="3"/>');
      b.write('<circle cx="192" cy="154" r="4" fill="#c96c56"/>');
      stroke('M176 138 182 129', '#3f5d51', 4);
  }
  b.write('</svg>');
  return b.toString();
}

class Character extends StatelessWidget {
  const Character({super.key, required this.scene, this.large = false});

  final Scene scene;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final mood = sceneInfo(context.l10n, scene).mood;
    return SizedBox(
      width: 184,
      height: 204,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: 19,
            top: 10,
            child: Container(
              width: 70,
              height: 70,
              decoration: const BoxDecoration(color: Color(0xFFF5E4B9), shape: BoxShape.circle),
            ),
          ),
          Positioned(
            right: 8,
            bottom: 5,
            child: Container(
              width: 136,
              height: 20,
              decoration: const BoxDecoration(
                color: Color(0xFFCBDCCA),
                borderRadius: BorderRadius.all(Radius.elliptical(68, 10)),
              ),
            ),
          ),
          Positioned(
            right: -27,
            bottom: 1,
            width: large ? 255 : 250,
            height: 202,
            child: SvgPicture.string(
              _characterSvg(scene),
              semanticsLabel: context.l10n.characterLabel(mood),
            ),
          ),
          Positioned(
            right: large ? 12 : 13,
            top: large ? 82 : 78,
            child: _MoodChip(mood),
          ),
        ],
      ),
    );
  }
}

class _MoodChip extends StatelessWidget {
  const _MoodChip(this.mood);

  final String mood;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF7),
        border: Border.all(color: const Color(0x245D7E65)),
        borderRadius: BorderRadius.circular(99),
        boxShadow: const [BoxShadow(color: Color(0x12415A47), blurRadius: 10, offset: Offset(0, 3))],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.auto_awesome_outlined, size: 13, color: Color(0xFF4F6B57)),
        const SizedBox(width: 5),
        Text(mood, style: sans(10, weight: FontWeight.w700, color: const Color(0xFF4F6B57))),
      ]),
    );
  }
}

class ContextHero extends StatelessWidget {
  const ContextHero({super.key, required this.scene, required this.background});

  final Scene scene;
  final Color background;

  @override
  Widget build(BuildContext context) {
    final info = sceneInfo(context.l10n, scene);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      constraints: const BoxConstraints(minHeight: 235),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(24)),
      child: Stack(children: [
        Positioned(right: 2, bottom: -3, child: Character(scene: scene, large: true)),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: FractionallySizedBox(
            widthFactor: 0.62,
            alignment: Alignment.topLeft,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Eyebrow(info.eyebrow),
                const SizedBox(height: 9),
                Text(info.title, style: serif(29, height: 1.05, tracking: -0.05)),
                const SizedBox(height: 8),
                Text(info.sub, style: sans(13, height: 1.45, color: const Color(0xFF5E7166))),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}
