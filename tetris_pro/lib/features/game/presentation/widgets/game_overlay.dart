import 'dart:ui' show FontFeature, ImageFilter;

import 'package:flutter/material.dart';

import '../../../../core/theme/game_colors.dart';
import '../../../../engine/engine.dart';

/// Frosted-glass panel over the board for the READY, PAUSED and GAME OVER
/// states, with one big button. Shows nothing while the game is running.
///
/// Sizes come from the board width (not ScreenUtil), so it always fits the
/// board it covers.
class GameOverlay extends StatelessWidget {
  const GameOverlay({
    super.key,
    required this.engine,
    this.showKeyHint = false,
  });

  final GameEngine engine;

  /// Show "or press Enter" under the button (keyboard platforms).
  final bool showKeyHint;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: engine,
      builder: (context, _) {
        final phase = engine.phase;
        if (phase == GamePhase.playing || phase == GamePhase.clearing) {
          return const SizedBox.shrink();
        }

        final (String title, String label, IconData icon, VoidCallback action) =
            switch (phase) {
          GamePhase.ready => (
              'TETRIS',
              'START',
              Icons.play_arrow_rounded,
              engine.start,
            ),
          GamePhase.paused => (
              'PAUSED',
              'RESUME',
              Icons.play_arrow_rounded,
              engine.togglePause,
            ),
          _ => (
              'GAME OVER',
              'PLAY AGAIN',
              Icons.replay_rounded,
              engine.start,
            ),
        };

        return LayoutBuilder(
          builder: (context, box) {
            final u = box.maxWidth / 10; // one board cell
            return TweenAnimationBuilder<double>(
              // New key per phase: the panel animates in each time it appears.
              key: ValueKey(phase),
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              builder: (context, t, child) => Opacity(
                opacity: t,
                child: Transform.scale(scale: .94 + .06 * t, child: child),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(u * .35),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: Container(
                    color: GameColors.backgroundDeep.withValues(alpha: .72),
                    padding: EdgeInsets.all(u * .6),
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: SizedBox(
                          width: u * 8,
                          child: _OverlayContent(
                            engine: engine,
                            phase: phase,
                            u: u,
                            title: title,
                            label: label,
                            icon: icon,
                            action: action,
                            showKeyHint: showKeyHint,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _OverlayContent extends StatelessWidget {
  const _OverlayContent({
    required this.engine,
    required this.phase,
    required this.u,
    required this.title,
    required this.label,
    required this.icon,
    required this.action,
    required this.showKeyHint,
  });

  final GameEngine engine;
  final GamePhase phase;
  final double u;
  final String title;
  final String label;
  final IconData icon;
  final VoidCallback action;
  final bool showKeyHint;

  Gradient get _titleGradient => switch (phase) {
        GamePhase.over => GameColors.alert,
        GamePhase.paused => const LinearGradient(
            colors: [Colors.white, Color(0xFFB8C4FF)],
          ),
        _ => GameColors.brand,
      };

  String? get _subtitle => switch (phase) {
        GamePhase.ready => 'Stack. Clear. Repeat.',
        GamePhase.paused => 'Take a breather',
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final isOver = phase == GamePhase.over;
    final subtitle = _subtitle;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (isOver && engine.newBest) ...[
          _Badge(u: u),
          SizedBox(height: u * .4),
        ],
        SizedBox(
          width: double.infinity,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (rect) => _titleGradient.createShader(rect),
              child: Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: u * 1.3,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        ),
        if (subtitle != null) ...[
          SizedBox(height: u * .15),
          Text(
            subtitle,
            style: TextStyle(
              color: GameColors.textDim,
              fontSize: u * .5,
              letterSpacing: 1,
            ),
          ),
        ],
        if (isOver || phase == GamePhase.paused) ...[
          SizedBox(height: u * .5),
          _Metrics(engine: engine, u: u),
        ],
        if (phase == GamePhase.ready && engine.best > 0) ...[
          SizedBox(height: u * .35),
          Text(
            'BEST  ${engine.best}',
            style: TextStyle(
              color: GameColors.gold,
              fontSize: u * .55,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
        ],
        SizedBox(height: u * .7),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: GameColors.brand,
            borderRadius: BorderRadius.circular(u * .5),
            boxShadow: [
              BoxShadow(
                color: GameColors.accent.withValues(alpha: .35),
                blurRadius: u * .7,
              ),
            ],
          ),
          child: FilledButton(
            onPressed: action,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              foregroundColor: const Color(0xFF05070F),
              padding: EdgeInsets.symmetric(
                horizontal: u * 1.2,
                vertical: u * .55,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(u * .5),
              ),
              textStyle: TextStyle(
                fontSize: u * .7,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: u * .95),
                SizedBox(width: u * .25),
                Text(label),
              ],
            ),
          ),
        ),
        if (showKeyHint) ...[
          SizedBox(height: u * .4),
          Text(
            'or press Enter',
            style: TextStyle(
              color: GameColors.textFaint,
              fontSize: u * .42,
              letterSpacing: .5,
            ),
          ),
        ],
      ],
    );
  }
}

/// SCORE / LINES / LEVEL summary plus the best score.
class _Metrics extends StatelessWidget {
  const _Metrics({required this.engine, required this.u});

  final GameEngine engine;
  final double u;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: u * .4, horizontal: u * .3),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .05),
            borderRadius: BorderRadius.circular(u * .3),
            border: Border.all(color: GameColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _Metric(label: 'SCORE', value: '${engine.score}', u: u),
              _Metric(label: 'LINES', value: '${engine.lines}', u: u),
              _Metric(label: 'LEVEL', value: '${engine.level}', u: u),
            ],
          ),
        ),
        SizedBox(height: u * .3),
        Text(
          'Best ${engine.best}',
          style: TextStyle(
            color: engine.newBest ? GameColors.gold : GameColors.textDim,
            fontSize: u * .5,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, required this.u});

  final String label;
  final String value;
  final double u;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: GameColors.textFaint,
            fontSize: u * .38,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        SizedBox(height: u * .1),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: u * .75,
            fontWeight: FontWeight.w900,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

/// "NEW BEST!" pill.
class _Badge extends StatelessWidget {
  const _Badge({required this.u});

  final double u;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: u * .5, vertical: u * .18),
      decoration: BoxDecoration(
        color: GameColors.gold.withValues(alpha: .16),
        borderRadius: BorderRadius.circular(u),
        border: Border.all(color: GameColors.gold.withValues(alpha: .7)),
        boxShadow: [
          BoxShadow(
            color: GameColors.gold.withValues(alpha: .35),
            blurRadius: u * .6,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.emoji_events_rounded, size: u * .6, color: GameColors.gold),
          SizedBox(width: u * .2),
          Text(
            'NEW BEST!',
            style: TextStyle(
              color: GameColors.gold,
              fontSize: u * .5,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
