import 'package:flutter_test/flutter_test.dart';
import 'package:tetris_pro/engine/engine.dart';

import 'helpers/engine_helpers.dart';
import 'helpers/fixed_generator.dart';

GameEngine _engine() => GameEngine(
      generator: FixedGenerator(
        [Tetromino.t, Tetromino.i, Tetromino.o, Tetromino.s],
      ),
    )..start();

void main() {
  group('hold', () {
    test('first hold stores the piece and spawns the next one', () {
      final e = _engine();
      expect(e.current!.type, Tetromino.t);
      expect(e.holdPiece(), true);
      expect(e.held, Tetromino.t);
      expect(e.current!.type, Tetromino.i);
      expect(e.canHold, false);
    });

    test('only one hold per piece', () {
      final e = _engine()..holdPiece();
      expect(e.holdPiece(), false);
      expect(e.held, Tetromino.t);
      expect(e.current!.type, Tetromino.i);
    });

    test('hold is available again after a piece locks and swaps back', () {
      final e = _engine()..holdPiece(); // held T, current I
      dropAndLock(e); // I locks, O spawns
      expect(e.canHold, true);
      expect(e.current!.type, Tetromino.o);
      expect(e.holdPiece(), true);
      expect(e.held, Tetromino.o);
      expect(e.current!.type, Tetromino.t); // swapped in from hold
    });

    test('a swapped-in piece restarts at the spawn position', () {
      final e = _engine()..holdPiece();
      dropAndLock(e);
      e.move(2);
      e.holdPiece();
      expect(e.current!.y, 0);
      expect(e.current!.x, Tetromino.t.spawnX);
      expect(e.current!.rotation, 0);
    });

    test('start() clears the hold slot', () {
      final e = _engine()..holdPiece();
      e.start();
      expect(e.held, isNull);
      expect(e.canHold, true);
    });

    test('hold is ignored before the game starts', () {
      final e = GameEngine(generator: FixedGenerator([Tetromino.t]));
      expect(e.holdPiece(), false);
    });
  });

  group('next queue', () {
    test('upcoming returns the next pieces without consuming them', () {
      final e = _engine();
      expect(e.upcoming(3), [Tetromino.i, Tetromino.o, Tetromino.s]);
      expect(e.upcoming(3), [Tetromino.i, Tetromino.o, Tetromino.s]);
    });

    test('the queue advances when a piece locks', () {
      final e = _engine();
      dropAndLock(e);
      expect(e.current!.type, Tetromino.i);
      expect(e.upcoming(1), [Tetromino.o]);
    });

    test('with the real 7-bag, upcoming(5) is stable and has 5 pieces', () {
      final e = GameEngine(seed: 3)..start();
      final a = e.upcoming(5);
      expect(a.length, 5);
      expect(e.upcoming(5), a);
    });
  });
}
