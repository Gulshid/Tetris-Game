import 'package:flutter_test/flutter_test.dart';
import 'package:tetris_pro/engine/engine.dart';

import 'helpers/fixed_generator.dart';

GameEngine _engineWith(Tetromino type) =>
    GameEngine(generator: FixedGenerator([type]))..start();

/// Runs the engine for [seconds] in small frames (like a real ticker).
void _advance(GameEngine e, double seconds) {
  var left = seconds;
  while (left > 0) {
    final dt = left < 0.01 ? left : 0.01;
    e.update(dt);
    left -= dt;
  }
}

void main() {
  group('DAS / ARR', () {
    test('key down moves one column immediately', () {
      final e = _engineWith(Tetromino.t);
      final x0 = e.current!.x;
      e.setDir(1);
      expect(e.current!.x, x0 + 1);
    });

    test('no repeat before the DAS delay', () {
      final e = _engineWith(Tetromino.t);
      final x0 = e.current!.x;
      e.setDir(1);
      _advance(e, 0.10); // DAS is 0.16 s
      expect(e.current!.x, x0 + 1);
    });

    test('repeats after DAS and slides to the wall', () {
      final e = _engineWith(Tetromino.t);
      final x0 = e.current!.x;
      e.setDir(1);
      _advance(e, 0.20);
      expect(e.current!.x, greaterThan(x0 + 1));
      _advance(e, 0.40);
      expect(e.current!.cells.map((c) => c.x).reduce((a, b) => a > b ? a : b),
          boardCols - 1);
    });

    test('releasing before DAS stops all further movement', () {
      final e = _engineWith(Tetromino.t);
      e.setDir(-1);
      final x = e.current!.x;
      e.releaseDir(-1);
      _advance(e, 0.5);
      expect(e.current!.x, x);
    });

    test('ARR of 0 slides to the wall in one frame after DAS', () {
      final e = _engineWith(Tetromino.t)..arr = 0;
      e.setDir(-1);
      _advance(e, 0.20);
      expect(e.current!.cells.map((c) => c.x).reduce((a, b) => a < b ? a : b),
          0);
    });

    test('opposite key takes over, and releasing it resumes the first', () {
      final e = _engineWith(Tetromino.t);
      final x0 = e.current!.x;
      e.setDir(-1); // x0 - 1
      e.setDir(1); // x0
      expect(e.current!.x, x0);
      e.releaseDir(1); // left is still held: it resumes sliding
      _advance(e, 0.15);
      expect(e.current!.x, lessThan(x0));
    });

    test('releaseInputs stops a held direction and soft drop', () {
      final e = _engineWith(Tetromino.t);
      e.setDir(1);
      e.softDrop = true;
      e.releaseInputs();
      final x = e.current!.x;
      _advance(e, 0.5);
      expect(e.current!.x, x);
      expect(e.softDrop, false);
    });
  });

  group('levels and gravity curve', () {
    test('level 1 is exactly one second per row', () {
      expect(GameEngine.gravityForLevel(1), 1.0);
      expect(_engineWith(Tetromino.t).level, 1);
    });

    test('gravity gets faster with every level', () {
      var prev = GameEngine.gravityForLevel(1);
      for (var l = 2; l <= 20; l++) {
        final g = GameEngine.gravityForLevel(l);
        expect(g, lessThan(prev), reason: 'level $l');
        prev = g;
      }
    });

    test('gravity never drops below the minimum interval', () {
      expect(GameEngine.gravityForLevel(60), GameEngine.minGravityInterval);
      expect(GameEngine.gravityForLevel(500), GameEngine.minGravityInterval);
    });
  });

  group('pause', () {
    test('togglePause freezes and resumes the game', () {
      final e = _engineWith(Tetromino.t);
      e.togglePause();
      expect(e.phase, GamePhase.paused);
      final y = e.current!.y;
      _advance(e, 3);
      expect(e.current!.y, y);
      e.togglePause();
      expect(e.phase, GamePhase.playing);
    });
  });
}
