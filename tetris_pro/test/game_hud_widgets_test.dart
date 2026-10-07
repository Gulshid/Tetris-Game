import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tetris_pro/engine/engine.dart';
import 'package:tetris_pro/features/game/presentation/widgets/banner_text.dart';
import 'package:tetris_pro/features/game/presentation/widgets/game_overlay.dart';

import 'helpers/fixed_generator.dart';

Future<void> _pump(WidgetTester tester, Widget child) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(width: 300, height: 600, child: child),
          ),
        ),
      ),
    );

GameEngine _newEngine() =>
    GameEngine(generator: FixedGenerator([Tetromino.o]));

void main() {
  group('GameOverlay', () {
    testWidgets('READY shows START and the button starts the game', (t) async {
      final e = _newEngine();
      await _pump(t, GameOverlay(engine: e));
      expect(find.text('TETRIS'), findsOneWidget);
      expect(find.text('START'), findsOneWidget);

      await t.tap(find.text('START'));
      await t.pump();
      expect(e.phase, GamePhase.playing);
      expect(find.text('START'), findsNothing);
    });

    testWidgets('PAUSED shows RESUME and the button resumes', (t) async {
      final e = _newEngine()..start();
      e.togglePause();
      await _pump(t, GameOverlay(engine: e));
      expect(find.text('PAUSED'), findsOneWidget);

      await t.tap(find.text('RESUME'));
      await t.pump();
      expect(e.phase, GamePhase.playing);
    });

    testWidgets('GAME OVER shows the score and PLAY AGAIN restarts', (t) async {
      final e = _newEngine()..start();
      while (e.phase == GamePhase.playing) {
        e.hardDrop();
      }
      await _pump(t, GameOverlay(engine: e));
      expect(find.text('GAME OVER'), findsOneWidget);
      expect(find.text('Score ${e.score}'), findsOneWidget);
      expect(find.text('NEW BEST!'), findsOneWidget);

      await t.tap(find.text('PLAY AGAIN'));
      await t.pump();
      expect(e.phase, GamePhase.playing);
      expect(e.score, 0);
    });

    testWidgets('shows nothing while playing', (t) async {
      final e = _newEngine()..start();
      await _pump(t, GameOverlay(engine: e));
      expect(find.byType(FilledButton), findsNothing);
    });
  });

  group('BannerText', () {
    testWidgets('shows the engine banner text', (t) async {
      final e = _newEngine()..start();
      e.debugSetState(
        board: Board.parse(const [
          '...#......',
          '##....####',
          '#..#.#####',
        ]),
        current: const Piece(Tetromino.t, rotation: 2, x: 3, y: 19),
        lastActionWasRotation: true,
      );
      await _pump(t, BannerText(engine: e));
      expect(find.text('T-SPIN'), findsNothing);

      for (var i = 0; i < 12; i++) {
        e.update(0.05); // the T locks at 0.5 s: a T-spin with no lines
      }
      await t.pump();
      expect(find.text('T-SPIN'), findsOneWidget);
    });
  });
}
