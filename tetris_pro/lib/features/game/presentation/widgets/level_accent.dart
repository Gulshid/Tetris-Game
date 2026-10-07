import 'package:flutter/material.dart';

import '../../../../core/theme/game_colors.dart';
import '../../../../engine/engine.dart';

/// Rebuilds [builder] with the accent colour of the current level, fading
/// smoothly from one level colour to the next.
class LevelAccent extends StatelessWidget {
  const LevelAccent({
    super.key,
    required this.engine,
    required this.builder,
    this.child,
  });

  final GameEngine engine;
  final Widget Function(BuildContext context, Color accent, Widget? child)
      builder;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: engine,
      builder: (context, _) {
        final target = GameColors.accentForLevel(engine.level);
        return TweenAnimationBuilder<Color?>(
          tween: ColorTween(end: target),
          duration: const Duration(milliseconds: 700),
          builder: (context, value, _) =>
              builder(context, value ?? target, child),
        );
      },
    );
  }
}
