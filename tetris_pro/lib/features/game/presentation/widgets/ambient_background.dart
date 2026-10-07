import 'package:flutter/material.dart';

import '../../../../core/theme/game_colors.dart';
import '../../../../engine/engine.dart';
import 'level_accent.dart';

/// Full-screen backdrop: a deep vertical gradient with a soft glow that
/// takes the colour of the current level.
class AmbientBackground extends StatelessWidget {
  const AmbientBackground({
    super.key,
    required this.engine,
    required this.child,
  });

  final GameEngine engine;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LevelAccent(
      engine: engine,
      child: child,
      builder: (context, accent, child) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(GameColors.background, accent, .07)!,
              GameColors.backgroundDeep,
            ],
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -.25),
              radius: 1.05,
              colors: [
                accent.withValues(alpha: .13),
                accent.withValues(alpha: 0),
              ],
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
