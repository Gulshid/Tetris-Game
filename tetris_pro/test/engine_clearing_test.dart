import 'package:flutter_test/flutter_test.dart';
import 'package:tetris_pro/engine/engine.dart';

import 'helpers/engine_helpers.dart';
import 'helpers/fixed_generator.dart';

GameEngine _engineWith(List<Tetromino> pieces) =>
    GameEngine(generator: FixedGenerator(pieces))..start();

/// Builds the stack for a single: I, I and an O waiting at the top.
/// Returns with the O grounded and about to lock.
GameEngine _readyToClearOneLine() {
  final e = _engineWith([Tetromino.i, Tetromino.i, Tetromino.o]);
  moveTo(e, 0);
  dropAndLock(e);
  moveTo(e, 4);
  dropAndLock(e);
  moveTo(e, 8);
  while (e.softStep()) {}
  return e;
}

/// Runs the engine for [seconds] in small frames. GameEngine.update clamps a
/// single call to 0.05 s, so long waits must be split up like a real ticker.
void _advance(GameEngine e, double seconds) {
  var left = seconds;
  while (left > 0) {
    final dt = left < 0.01 ? left : 0.01;
    e.update(dt);
    left -= dt;
  }
}

void main() {
  group('line-clear animation', () {
    test('rows stay on the board while they flash, then disappear', () {
      final e = _readyToClearOneLine();
      _advance(e, 0.52); // lock delay (0.5 s) passes: the O locks
      expect(e.phase, GamePhase.clearing);
      expect(e.clearingRows, [boardRows - 1]);
      expect(e.current, isNull);
      expect(e.board.isRowFull(boardRows - 1), true);
      expect(e.lines, 1); // counted immediately

      _advance(e, 0.1);
      expect(e.phase, GamePhase.clearing);
      expect(e.clearProgress, inInclusiveRange(0.2, 0.9));

      _advance(e, 0.3); // total flash time 0.32 s is over
      expect(e.phase, GamePhase.playing);
      expect(e.clearingRows, isEmpty);
      expect(e.clearProgress, 0);
      expect(e.board.isRowFull(boardRows - 1), false);
      expect(e.current, isNotNull); // next piece spawned
    });

    test('player input is ignored during the animation', () {
      final e = _readyToClearOneLine();
      _advance(e, 0.52);
      expect(e.phase, GamePhase.clearing);
      expect(e.move(1), false);
      expect(e.rotate(1), false);
      expect(e.hardDrop(), false);
      expect(e.holdPiece(), false);
    });

    test('pausing during the animation resumes it afterwards', () {
      final e = _readyToClearOneLine();
      _advance(e, 0.52);
      e.togglePause();
      expect(e.phase, GamePhase.paused);
      _advance(e, 5); // frozen
      expect(e.clearingRows, isNotEmpty);
      e.togglePause();
      expect(e.phase, GamePhase.clearing);
      _advance(e, 0.4);
      expect(e.phase, GamePhase.playing);
      expect(e.clearingRows, isEmpty);
    });
  });

  group('banner', () {
    test('shows after a clear, fades, then expires', () {
      final e = _readyToClearOneLine();
      _advance(e, 0.52);
      expect(e.banner, 'SINGLE');
      expect(e.bannerFade, 1.0);

      for (var i = 0; i < 20; i++) {
        e.update(0.05); // 1.0 s more: inside the fade-out window
      }
      expect(e.banner, 'SINGLE');
      expect(e.bannerFade, lessThan(1.0));

      for (var i = 0; i < 20; i++) {
        e.update(0.05);
      }
      expect(e.banner, '');
      expect(e.bannerFade, 0);
    });

    test('start() clears the banner and scoring state', () {
      final e = _readyToClearOneLine();
      _advance(e, 0.52);
      e.start();
      expect(e.banner, '');
      expect(e.combo, -1);
      expect(e.backToBack, false);
      expect(e.clearingRows, isEmpty);
      expect(e.score, 0);
    });
  });

  group('pause', () {
    test('pause is ignored before the game starts and after game over', () {
      final e = GameEngine(generator: FixedGenerator([Tetromino.o]));
      e.togglePause();
      expect(e.phase, GamePhase.ready);

      e.start();
      while (e.phase == GamePhase.playing) {
        e.hardDrop();
      }
      e.togglePause();
      expect(e.phase, GamePhase.over);
    });
  });

  group('best score and events', () {
    test('game over records the best score and flags a new best', () {
      final e = _engineWith([Tetromino.o]);
      while (e.phase == GamePhase.playing) {
        e.hardDrop();
      }
      expect(e.phase, GamePhase.over);
      expect(e.score, greaterThan(0));
      expect(e.best, e.score);
      expect(e.newBest, true);
    });

    test('a lower score keeps the old best', () {
      final e = _engineWith([Tetromino.o]);
      e.best = 1000000;
      while (e.phase == GamePhase.playing) {
        e.hardDrop();
      }
      expect(e.best, 1000000);
      expect(e.newBest, false);
    });

    test('events fire for rotate, drop, clear and over', () {
      final e = _engineWith([Tetromino.o]);
      final events = <GameEvent>[];
      e.onEvent = events.add;

      e.rotate(1); // the O piece rotates in place and still succeeds
      e.hardDrop();
      expect(events, containsAllInOrder([GameEvent.rotate, GameEvent.drop]));

      while (e.phase == GamePhase.playing) {
        e.hardDrop();
      }
      expect(events.last, GameEvent.over);
    });

    test('a line clear fires the clear event once', () {
      final e = _readyToClearOneLine();
      final events = <GameEvent>[];
      e.onEvent = events.add;
      _advance(e, 1.0);
      expect(events.where((x) => x == GameEvent.clear).length, 1);
    });
  });
}
