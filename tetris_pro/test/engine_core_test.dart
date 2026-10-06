import 'package:flutter_test/flutter_test.dart';
import 'package:tetris_pro/engine/engine.dart';

void main() {
  group('Tetromino shapes', () {
    test('every rotation of every piece has 4 distinct cells', () {
      for (final t in Tetromino.values) {
        expect(t.rotations.length, 4);
        for (final r in t.rotations) {
          expect(r.length, 4);
          expect(r.toSet().length, 4);
        }
      }
    });

    test('all cells stay inside the piece box', () {
      for (final t in Tetromino.values) {
        for (final r in t.rotations) {
          for (final c in r) {
            expect(c.x, inInclusiveRange(0, t.boxSize - 1));
            expect(c.y, inInclusiveRange(0, t.boxSize - 1));
          }
        }
      }
    });

    test('T rotated once is a vertical T', () {
      final cells = Tetromino.t.shape(1).toSet();
      expect(cells, {
        (x: 1, y: 0),
        (x: 1, y: 1),
        (x: 2, y: 1),
        (x: 1, y: 2),
      });
    });

    test('four rotations return to the start (except flat symmetry)', () {
      for (final t in Tetromino.values) {
        expect(t.shape(4).toSet(), t.shape(0).toSet());
      }
    });

    test('cellValue round-trips', () {
      for (final t in Tetromino.values) {
        expect(Tetromino.fromCellValue(t.cellValue), t);
      }
    });
  });

  group('Board', () {
    test('walls and floor collide', () {
      final board = Board.empty();
      expect(board.collides(const Piece(Tetromino.o, x: -1)), true);
      expect(board.collides(const Piece(Tetromino.o, x: boardCols - 1)), true);
      expect(board.collides(const Piece(Tetromino.o, y: boardRows - 1)), true);
      expect(board.collides(Piece.spawn(Tetromino.t)), false);
    });

    test('lock writes cells and blocks overlapping pieces', () {
      final piece = Piece.spawn(Tetromino.i).shifted(0, 10);
      final board = Board.empty().lock(piece);
      expect(board.collides(piece), true);
      for (final c in piece.cells) {
        expect(board.at(c.x, c.y), Tetromino.i.cellValue);
      }
    });

    test('lock does not mutate the original board', () {
      final original = Board.empty();
      original.lock(Piece.spawn(Tetromino.o));
      expect(original.isEmpty, true);
    });

    test('full rows are detected and removed', () {
      // Two I pieces plus an O fill row 21 (10 wide): 4 + 4 + 2.
      var board = Board.empty()
          .lock(const Piece(Tetromino.i, x: 0, y: 20)) // row 21
          .lock(const Piece(Tetromino.i, x: 4, y: 20))
          .lock(const Piece(Tetromino.o, x: 8, y: 20)); // rows 20-21
      expect(board.fullRows, [21]);
      board = board.removeRows(board.fullRows);
      expect(board.fullRows, isEmpty);
      // The O's top half drops down into row 21.
      expect(board.at(8, 21), Tetromino.o.cellValue);
      expect(board.at(0, 21), 0);
    });
  });

  group('7-bag', () {
    test('every 7 pieces contain each tetromino once', () {
      final gen = SevenBagGenerator(seed: 1);
      for (var bag = 0; bag < 5; bag++) {
        final seven = [for (var i = 0; i < 7; i++) gen.next()];
        expect(seven.toSet().length, 7);
      }
    });

    test('same seed gives the same sequence; peek does not consume', () {
      final a = SevenBagGenerator(seed: 42);
      final b = SevenBagGenerator(seed: 42);
      expect(a.peek(10), b.peek(10));
      expect(a.next(), b.peek(1).first);
    });
  });

  group('GameEngine', () {
    test('start spawns a piece at the top and enters playing', () {
      final e = GameEngine(seed: 7)..start();
      expect(e.phase, GamePhase.playing);
      expect(e.current, isNotNull);
      expect(e.current!.y, 0);
    });

    test('gravity moves the piece down about one row per second', () {
      final e = GameEngine(seed: 7)..start();
      for (var i = 0; i < 22; i++) {
        e.update(0.05); // 1.1 s total
      }
      expect(e.current!.y, 1);
    });

    test('a piece that reaches the floor locks into the board', () {
      final e = GameEngine(seed: 7)..start();
      for (var i = 0; i < 600; i++) {
        e.update(0.05); // 30 s: first piece lands at ~21 s and locks
      }
      expect(e.board.isEmpty, false);
      expect(e.phase, GamePhase.playing);
      expect(e.board.collides(e.current!), false);
    });

    test('engine starts in the ready phase', () {
      expect(GameEngine(seed: 7).phase, GamePhase.ready);
    });

    test('update is ignored while not playing', () {
      final e = GameEngine(seed: 7);
      e.update(5);
      expect(e.current, isNull);
    });
  });
}
