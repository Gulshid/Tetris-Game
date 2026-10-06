import 'constants.dart';
import 'tetromino.dart';

/// Super Rotation System wall-kick offsets.
///
/// Each offset is a [Cell] where `x` is positive to the right and `y` is
/// positive UP, exactly as in the official tables. Our board's y grows
/// downward, so the engine subtracts `y` when it applies a kick.
///
/// Tables are keyed by `from * 4 + to` (rotation states 0, R, 2, L = 0..3).
/// Offsets are tried in order; the first collision-free one wins.
List<Cell> srsKicks(Tetromino type, int from, int to) {
  if (type == Tetromino.o) return _noKick; // the O piece never kicks
  final table = type == Tetromino.i ? _kickI : _kickJlstz;
  return table[(from & 3) * 4 + (to & 3)] ?? _noKick;
}

const List<Cell> _noKick = [(x: 0, y: 0)];

/// J, L, S, T, Z.
const Map<int, List<Cell>> _kickJlstz = {
  1: [(x: 0, y: 0), (x: -1, y: 0), (x: -1, y: 1), (x: 0, y: -2), (x: -1, y: -2)], // 0->R
  4: [(x: 0, y: 0), (x: 1, y: 0), (x: 1, y: -1), (x: 0, y: 2), (x: 1, y: 2)], // R->0
  6: [(x: 0, y: 0), (x: 1, y: 0), (x: 1, y: -1), (x: 0, y: 2), (x: 1, y: 2)], // R->2
  9: [(x: 0, y: 0), (x: -1, y: 0), (x: -1, y: 1), (x: 0, y: -2), (x: -1, y: -2)], // 2->R
  11: [(x: 0, y: 0), (x: 1, y: 0), (x: 1, y: 1), (x: 0, y: -2), (x: 1, y: -2)], // 2->L
  14: [(x: 0, y: 0), (x: -1, y: 0), (x: -1, y: -1), (x: 0, y: 2), (x: -1, y: 2)], // L->2
  12: [(x: 0, y: 0), (x: -1, y: 0), (x: -1, y: -1), (x: 0, y: 2), (x: -1, y: 2)], // L->0
  3: [(x: 0, y: 0), (x: 1, y: 0), (x: 1, y: 1), (x: 0, y: -2), (x: 1, y: -2)], // 0->L
};

/// I piece.
const Map<int, List<Cell>> _kickI = {
  1: [(x: 0, y: 0), (x: -2, y: 0), (x: 1, y: 0), (x: -2, y: -1), (x: 1, y: 2)], // 0->R
  4: [(x: 0, y: 0), (x: 2, y: 0), (x: -1, y: 0), (x: 2, y: 1), (x: -1, y: -2)], // R->0
  6: [(x: 0, y: 0), (x: -1, y: 0), (x: 2, y: 0), (x: -1, y: 2), (x: 2, y: -1)], // R->2
  9: [(x: 0, y: 0), (x: 1, y: 0), (x: -2, y: 0), (x: 1, y: -2), (x: -2, y: 1)], // 2->R
  11: [(x: 0, y: 0), (x: 2, y: 0), (x: -1, y: 0), (x: 2, y: 1), (x: -1, y: -2)], // 2->L
  14: [(x: 0, y: 0), (x: -2, y: 0), (x: 1, y: 0), (x: -2, y: -1), (x: 1, y: 2)], // L->2
  12: [(x: 0, y: 0), (x: 1, y: 0), (x: -2, y: 0), (x: 1, y: -2), (x: -2, y: 1)], // L->0
  3: [(x: 0, y: 0), (x: -1, y: 0), (x: 2, y: 0), (x: -1, y: 2), (x: 2, y: -1)], // 0->L
};
