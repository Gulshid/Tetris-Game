import 'package:flutter_test/flutter_test.dart';
import 'package:tetris_pro/engine/engine.dart';

import 'helpers/engine_helpers.dart';
import 'helpers/fixed_generator.dart';

GameEngine _engineWith(List<Tetromino> pieces) =>
    GameEngine(generator: FixedGenerator(pieces))..start();

/// Lets the current piece land and lock, and returns the points that the
/// LOCK itself earned (soft drop points before it are not counted).
int _lockAndMeasure(GameEngine e) {
  while (e.softStep()) {}
  final before = e.score;
  for (var i = 0; i < 22; i++) {
    e.update(0.05); // 1.1 s: lock delay + clear animation
  }
  return e.score - before;
}

/// Places a vertical I piece in board column [col] and locks it.
int _placeVerticalI(GameEngine e, int col) {
  e.rotate(1); // vertical I occupies box column 2
  moveTo(e, col - 2);
  return _lockAndMeasure(e);
}

/// Fills columns 0..8 with vertical I pieces (rows 18-21), then drops the
/// last one in column 9: a Tetris. Returns the points of that last lock.
int _tetris(GameEngine e) {
  for (var col = 0; col < 9; col++) {
    expect(_placeVerticalI(e, col), 0, reason: 'column $col clears nothing');
  }
  return _placeVerticalI(e, 9);
}

void main() {
  group('line clear scoring', () {
    test('single = 100 at level 1', () {
      final e = _engineWith([Tetromino.i, Tetromino.i, Tetromino.o]);
      moveTo(e, 0);
      dropAndLock(e);
      moveTo(e, 4);
      dropAndLock(e);
      moveTo(e, 8);
      expect(_lockAndMeasure(e), 100);
      expect(e.lines, 1);
      expect(e.banner, 'SINGLE');
    });

    test('double = 300', () {
      final e = _engineWith([Tetromino.o]);
      for (final x in [0, 2, 4, 6]) {
        moveTo(e, x);
        dropAndLock(e);
      }
      moveTo(e, 8);
      expect(_lockAndMeasure(e), 300);
      expect(e.lines, 2);
      expect(e.banner, 'DOUBLE');
    });

    test('tetris = 800', () {
      final e = _engineWith([Tetromino.i]);
      expect(_tetris(e), 800);
      expect(e.lines, 4);
      expect(e.board.isEmpty, true);
      expect(e.banner, 'TETRIS');
    });
  });

  group('back-to-back', () {
    test('second Tetris in a row is worth 1.5x', () {
      final e = _engineWith([Tetromino.i]);
      expect(_tetris(e), 800);
      expect(e.backToBack, true);
      expect(_tetris(e), 1200); // 800 * 1.5, combo is 0 after non-clearing locks
      expect(e.banner, contains('BACK-TO-BACK'));
    });

    test('a plain clear in between breaks the chain', () {
      // Ten I pieces make a Tetris, then five O pieces make a Double.
      final e = _engineWith([
        for (var i = 0; i < 10; i++) Tetromino.i,
        for (var i = 0; i < 5; i++) Tetromino.o,
      ]);
      _tetris(e);
      expect(e.backToBack, true);

      for (final x in [0, 2, 4, 6]) {
        moveTo(e, x);
        dropAndLock(e);
      }
      moveTo(e, 8);
      expect(_lockAndMeasure(e), 300); // plain double, no bonus
      expect(e.backToBack, false);
    });
  });

  group('combo', () {
    test('consecutive clears add 50 x combo x level', () {
      final e = _engineWith([
        for (var i = 0; i < 8; i++) Tetromino.i,
        Tetromino.o,
        Tetromino.o,
      ]);
      for (var col = 0; col < 8; col++) {
        _placeVerticalI(e, col);
      }
      moveTo(e, 8);
      expect(_lockAndMeasure(e), 300); // first clear: combo 0
      expect(e.combo, 0);

      moveTo(e, 8);
      expect(_lockAndMeasure(e), 350); // 300 + 50 * 1 * level 1
      expect(e.combo, 1);
      expect(e.banner, contains('COMBO x1'));
    });

    test('a lock without a clear resets the combo', () {
      final e = _engineWith([
        for (var i = 0; i < 8; i++) Tetromino.i,
        Tetromino.o,
        Tetromino.o,
        Tetromino.i,
      ]);
      for (var col = 0; col < 8; col++) {
        _placeVerticalI(e, col);
      }
      moveTo(e, 8);
      _lockAndMeasure(e);
      moveTo(e, 8);
      _lockAndMeasure(e);
      expect(e.combo, 1);
      dropAndLock(e); // a flat I clears nothing
      expect(e.combo, -1);
    });
  });

  group('T-spin scoring', () {
    // T pointing down into a notch; box top-left is (3, 19).
    const piece = Piece(Tetromino.t, rotation: 2, x: 3, y: 19);

    GameEngine spin(List<String> rows, {required bool rotated}) {
      final e = _engineWith([Tetromino.o]);
      e.debugSetState(
        board: Board.parse(rows),
        current: piece,
        lastActionWasRotation: rotated,
      );
      return e;
    }

    int lockPoints(GameEngine e) {
      final before = e.score;
      for (var i = 0; i < 22; i++) {
        e.update(0.05);
      }
      return e.score - before;
    }

    const doubleRows = [
      '...#......',
      '###...####',
      '####.#####',
    ];

    test('T-spin double = 1200', () {
      final e = spin(doubleRows, rotated: true);
      expect(lockPoints(e), 1200);
      expect(e.lines, 2);
    });

    test('the same lock without a rotation is a plain double = 300', () {
      final e = spin(doubleRows, rotated: false);
      expect(lockPoints(e), 300);
    });

    test('T-spin with no lines = 400 and shows a banner', () {
      final e = spin(const [
        '...#......',
        '##....####',
        '#..#.#####',
      ], rotated: true);
      for (var i = 0; i < 12; i++) {
        e.update(0.05); // 0.6 s: the lock happens at 0.5 s
      }
      expect(e.score, 400);
      expect(e.lines, 0);
      expect(e.banner, 'T-SPIN');
    });
  });

  group('levels', () {
    test('level rises every 10 lines and speeds up gravity', () {
      final e = _engineWith([Tetromino.i]);
      _tetris(e);
      _tetris(e);
      expect(e.lines, 8);
      expect(e.level, 1);
      _tetris(e);
      expect(e.lines, 12);
      expect(e.level, 2);
      expect(e.gravityInterval, lessThan(1.0));
      expect(e.banner, contains('LEVEL 2'));
    });
  });
}
