import 'package:flutter_test/flutter_test.dart';
import 'package:tetris_pro/engine/engine.dart';

import 'helpers/engine_helpers.dart';
import 'helpers/fixed_generator.dart';

GameEngine _engineWith(List<Tetromino> pieces) =>
    GameEngine(generator: FixedGenerator(pieces))..start();

void main() {
  group('locking', () {
    test('a landed piece locks into the board and a new one spawns', () {
      final e = _engineWith([Tetromino.o]);
      dropAndLock(e);
      expect(filledCells(e.board), 4);
      expect(e.current!.y, 0);
      expect(e.phase, GamePhase.playing);
    });

    test('softStep stops at the floor', () {
      final e = _engineWith([Tetromino.o]);
      var steps = 0;
      while (e.softStep()) {
        steps++;
      }
      expect(steps, 20); // spawn y=0, O is 2 tall, floor at row 21
      expect(e.softStep(), false);
    });
  });

  group('line clears', () {
    test('clears one line and drops the rest of the stack', () {
      final e = _engineWith([Tetromino.i, Tetromino.i, Tetromino.o]);
      for (final x in [0, 4, 8]) {
        moveTo(e, x);
        dropAndLock(e);
      }
      expect(e.lines, 1);
      // The O's top half falls into the bottom row; nothing else is left.
      expect(e.board.at(8, 21), Tetromino.o.cellValue);
      expect(e.board.at(9, 21), Tetromino.o.cellValue);
      expect(e.board.at(0, 21), 0);
      expect(filledCells(e.board), 2);
    });

    test('clears two lines at once', () {
      final e = _engineWith([Tetromino.o]);
      for (final x in [0, 2, 4, 6, 8]) {
        moveTo(e, x);
        dropAndLock(e);
      }
      expect(e.lines, 2);
      expect(e.board.isEmpty, true);
      expect(e.phase, GamePhase.playing);
    });

    test('start() resets the line counter and the board', () {
      final e = _engineWith([Tetromino.o]);
      for (final x in [0, 2, 4, 6, 8]) {
        moveTo(e, x);
        dropAndLock(e);
      }
      e.start();
      expect(e.lines, 0);
      expect(e.board.isEmpty, true);
    });
  });

  group('game over', () {
    test('stacking to the top ends the game and stops the simulation', () {
      final e = _engineWith([Tetromino.o]);
      for (var i = 0; i < 11 && e.phase == GamePhase.playing; i++) {
        dropAndLock(e);
      }
      expect(e.phase, GamePhase.over);
      expect(e.move(1), false);
      expect(e.holdPiece(), false);
    });

    test('start() recovers from game over', () {
      final e = _engineWith([Tetromino.o]);
      for (var i = 0; i < 11; i++) {
        dropAndLock(e);
      }
      expect(e.phase, GamePhase.over);
      e.start();
      expect(e.phase, GamePhase.playing);
      expect(e.board.isEmpty, true);
    });
  });
}
