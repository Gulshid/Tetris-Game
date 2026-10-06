import 'package:flutter_test/flutter_test.dart';
import 'package:tetris_pro/engine/engine.dart';

import 'helpers/fixed_generator.dart';

GameEngine _engineWith(Tetromino type) =>
    GameEngine(generator: FixedGenerator([type]))..start();

void main() {
  group('move', () {
    test('shifts the piece and reports success', () {
      final e = _engineWith(Tetromino.t);
      final x0 = e.current!.x;
      expect(e.move(1), true);
      expect(e.current!.x, x0 + 1);
      expect(e.move(-1), true);
      expect(e.current!.x, x0);
    });

    test('cannot pass the left or right wall', () {
      final e = _engineWith(Tetromino.t);
      for (var i = 0; i < 20; i++) {
        e.move(-1);
      }
      expect(e.current!.cells.every((c) => c.x >= 0), true);
      expect(e.move(-1), false);

      for (var i = 0; i < 20; i++) {
        e.move(1);
      }
      expect(e.current!.cells.every((c) => c.x < boardCols), true);
      expect(e.move(1), false);
    });

    test('is ignored when the game is not playing', () {
      final e = GameEngine(generator: FixedGenerator([Tetromino.t]));
      expect(e.move(1), false);
      expect(e.rotate(1), false);
    });

    test('notifies listeners only when the piece actually moved', () {
      final e = _engineWith(Tetromino.t);
      var notifications = 0;
      e.addListener(() => notifications++);
      e.move(1);
      expect(notifications, 1);
      for (var i = 0; i < 20; i++) {
        e.move(1);
      }
      final afterWall = notifications;
      e.move(1); // blocked by the wall
      expect(notifications, afterWall);
    });
  });

  group('rotate', () {
    test('clockwise four times returns to the start', () {
      final e = _engineWith(Tetromino.t);
      for (var i = 1; i <= 4; i++) {
        expect(e.rotate(1), true);
        expect(e.current!.rotation, i & 3);
      }
    });

    test('counter-clockwise from 0 wraps to 3', () {
      final e = _engineWith(Tetromino.t);
      expect(e.rotate(-1), true);
      expect(e.current!.rotation, 3);
    });

    test('is rejected when the rotated shape would leave the board', () {
      final e = _engineWith(Tetromino.i);
      expect(e.rotate(1), true); // vertical I
      for (var i = 0; i < 10; i++) {
        e.move(-1); // push against the left wall
      }
      expect(e.current!.rotation, 1);
      expect(e.rotate(1), false); // flat I would stick out of the wall
      expect(e.rotate(-1), false);
      expect(e.current!.rotation, 1);
    });
  });
}
