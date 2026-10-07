import 'package:flutter/material.dart';

import '../../../../core/theme/game_colors.dart';
import '../../../../engine/engine.dart';

/// Dark panel over the board for the READY, PAUSED and GAME OVER states,
/// with one big button. Shows nothing while the game is running.
///
/// Sizes come from the board width (not ScreenUtil), so it always fits the
/// board it covers.
class GameOverlay extends StatelessWidget {
  const GameOverlay({super.key, required this.engine});

  final GameEngine engine;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: engine,
      builder: (context, _) {
        final phase = engine.phase;
        if (phase == GamePhase.playing || phase == GamePhase.clearing) {
          return const SizedBox.shrink();
        }

        final (String title, String label, VoidCallback action) = switch (phase) {
          GamePhase.ready => ('TETRIS', 'START', engine.start),
          GamePhase.paused => ('PAUSED', 'RESUME', engine.togglePause),
          _ => ('GAME OVER', 'PLAY AGAIN', engine.start),
        };

        return LayoutBuilder(
          builder: (context, box) {
            final u = box.maxWidth / 10; // one board cell
            return Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: .72),
                borderRadius: BorderRadius.circular(u * .35),
              ),
              padding: EdgeInsets.all(u * .6),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: u * 1.3,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      if (phase == GamePhase.over) ...[
                        SizedBox(height: u * .4),
                        Text(
                          'Score ${engine.score}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: u * .8,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          engine.newBest ? 'NEW BEST!' : 'Best ${engine.best}',
                          style: TextStyle(
                            color: engine.newBest
                                ? const Color(0xFFFFD600)
                                : GameColors.textDim,
                            fontSize: u * .7,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                      SizedBox(height: u * .8),
                      FilledButton(
                        onPressed: action,
                        child: Text(label),
                      ),
                    ],
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
