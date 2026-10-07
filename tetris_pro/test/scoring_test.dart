import 'package:flutter_test/flutter_test.dart';
import 'package:tetris_pro/engine/engine.dart';

void main() {
  group('Scoring tables', () {
    test('line clear base points', () {
      expect([for (var n = 0; n <= 4; n++) Scoring.base(lines: n, tSpin: false)],
          [0, 100, 300, 500, 800]);
    });

    test('T-spin base points', () {
      expect([for (var n = 0; n <= 3; n++) Scoring.base(lines: n, tSpin: true)],
          [400, 800, 1200, 1600]);
    });

    test('only Tetris and T-spin line clears are difficult', () {
      expect(Scoring.isDifficult(lines: 4, tSpin: false), true);
      expect(Scoring.isDifficult(lines: 2, tSpin: true), true);
      expect(Scoring.isDifficult(lines: 3, tSpin: false), false);
      expect(Scoring.isDifficult(lines: 0, tSpin: true), false);
    });

    test('labels', () {
      expect(Scoring.label(lines: 1, tSpin: false), 'SINGLE');
      expect(Scoring.label(lines: 4, tSpin: false), 'TETRIS');
      expect(Scoring.label(lines: 2, tSpin: true), 'T-SPIN DOUBLE');
      expect(Scoring.label(lines: 0, tSpin: true), 'T-SPIN');
      expect(Scoring.label(lines: 0, tSpin: false), '');
    });
  });

  group('Board.parse', () {
    test('rows are aligned to the bottom of the field', () {
      final b = Board.parse(['#.........', '.3........']);
      expect(b.at(0, boardRows - 2), 1);
      expect(b.at(1, boardRows - 1), 3);
      expect(b.at(0, boardRows - 1), 0);
    });

    test('rejects rows of the wrong width', () {
      expect(() => Board.parse(['###']), throwsArgumentError);
    });
  });

  group('T-spin detection', () {
    // T pointing down into a notch; box top-left is (3, 19).
    const piece = Piece(Tetromino.t, rotation: 2, x: 3, y: 19);
    final threeCorners = Board.parse([
      '...#......', // row 19: overhang on the top-left corner
      '###...####',
      '####.#####', // row 21: both bottom corners filled
    ]);

    test('three blocked corners after a rotation is a T-spin', () {
      expect(
        Scoring.isTSpin(threeCorners, piece, lastActionWasRotation: true),
        true,
      );
    });

    test('same spot without a rotation is not a T-spin', () {
      expect(
        Scoring.isTSpin(threeCorners, piece, lastActionWasRotation: false),
        false,
      );
    });

    test('other pieces are never T-spins', () {
      const o = Piece(Tetromino.o, x: 3, y: 19);
      expect(Scoring.isTSpin(threeCorners, o, lastActionWasRotation: true),
          false);
    });

    test('two blocked corners are not enough', () {
      expect(
        Scoring.isTSpin(Board.empty(), piece, lastActionWasRotation: true),
        false,
      );
      // Floor makes both bottom corners blocked, still only two.
      const low = Piece(Tetromino.t, rotation: 0, x: 3, y: 20);
      expect(Scoring.isTSpin(Board.empty(), low, lastActionWasRotation: true),
          false);
    });

    test('walls count as blocked corners', () {
      const atWall = Piece(Tetromino.t, rotation: 1, x: -1, y: 10);
      expect(
        Scoring.isTSpin(Board.empty(), atWall, lastActionWasRotation: true),
        false, // two wall corners only
      );
      final withBlock = Board.empty().lock(const Piece(Tetromino.o, x: 1, y: 9));
      expect(
        Scoring.isTSpin(withBlock, atWall, lastActionWasRotation: true),
        true, // two walls + the O block on corner (1, 10)
      );
    });
  });
}
