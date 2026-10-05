import 'constants.dart';

/// The seven tetrominoes. Order matters everywhere: I, O, T, S, Z, J, L.
enum Tetromino {
  i,
  o,
  t,
  s,
  z,
  j,
  l;

  /// Side length of the square box the piece rotates inside.
  int get boxSize => this == i ? 4 : (this == o ? 2 : 3);

  /// Column where the piece spawns (box left edge).
  int get spawnX => this == o ? 4 : 3;

  /// Value stored in a board cell for a locked block (0 means empty).
  int get cellValue => index + 1;

  /// All four rotation states (0, R, 2, L), each as 4 cells.
  List<List<Cell>> get rotations => _rotationTable[index];

  /// Cells of one rotation state.
  List<Cell> shape(int rotation) => rotations[rotation & 3];

  /// Inverse of [cellValue]. Throws on 0 or out-of-range values.
  static Tetromino fromCellValue(int value) {
    RangeError.checkValueInInterval(value, 1, values.length, 'value');
    return values[value - 1];
  }
}

// Base (rotation 0) cells as [x, y] inside each piece's box.
const List<List<List<int>>> _base = [
  [[0, 1], [1, 1], [2, 1], [3, 1]], // I
  [[0, 0], [1, 0], [0, 1], [1, 1]], // O
  [[1, 0], [0, 1], [1, 1], [2, 1]], // T
  [[1, 0], [2, 0], [0, 1], [1, 1]], // S
  [[0, 0], [1, 0], [1, 1], [2, 1]], // Z
  [[0, 0], [0, 1], [1, 1], [2, 1]], // J
  [[2, 0], [0, 1], [1, 1], [2, 1]], // L
];

/// Built once, on first use. Rotating clockwise maps (x, y) -> (n-1-y, x).
final List<List<List<Cell>>> _rotationTable = List.unmodifiable(
  List.generate(Tetromino.values.length, (t) {
    final n = Tetromino.values[t].boxSize;
    var current = [for (final c in _base[t]) (x: c[0], y: c[1])];
    return List<List<Cell>>.unmodifiable(
      List.generate(4, (_) {
        final out = List<Cell>.unmodifiable(current);
        current = [for (final c in current) (x: n - 1 - c.y, y: c.x)];
        return out;
      }),
    );
  }),
);
