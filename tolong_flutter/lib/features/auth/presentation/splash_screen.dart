import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets/character.dart';
import '../../../shared/widgets/common.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else if (_controller.value == 0) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final character = CurvedAnimation(parent: _controller, curve: const Interval(0, 0.7, curve: Curves.easeOutBack));
    final text = CurvedAnimation(parent: _controller, curve: const Interval(0.4, 1, curve: Curves.easeOut));
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ScaleTransition(
            scale: Tween(begin: 0.85, end: 1.0).animate(character),
            child: FadeTransition(
              opacity: character,
              child: const SizedBox(width: 200, height: 210, child: Character(scene: Scene.home)),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          FadeTransition(
            opacity: text,
            child: Column(children: [
              const Logo(),
              const SizedBox(height: AppSpacing.sm),
              Text(context.l10n.tagline, style: sans(13, color: AppColors.muted)),
            ]),
          ),
        ]),
      ),
    );
  }
}
