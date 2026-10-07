import 'dart:math' as math;

import 'board.dart';
import 'constants.dart';
import 'piece.dart';
import 'tetromino.dart';

/// Guideline scoring rules as pure functions (no engine state).
///
/// Base points are multiplied by the level at the moment of the clear:
///
/// | Clear            | Points |
/// |------------------|--------|
/// | Single           | 100    |
/// | Double           | 300    |
/// | Triple           | 500    |
/// | Tetris           | 800    |
/// | T-Spin (no line) | 400    |
/// | T-Spin Single    | 800    |
/// | T-Spin Double    | 1200   |
/// | T-Spin Triple    | 1600   |
abstract final class Scoring {
  static const List<int> _lineBase = [0, 100, 300, 500, 800];
  static const List<int> _tSpinBase = [400, 800, 1200, 1600];
  static const List<String> _names = ['', 'SINGLE', 'DOUBLE', 'TRIPLE', 'TETRIS'];

  /// Each consecutive clearing lock adds `comboStep * combo * level`.
  static const int comboStep = 50;

  /// A "difficult" clear straight after another one is worth 1.5x.
  static const double backToBackMultiplier = 1.5;

  /// Base points (before the level multiplier) for clearing [lines] rows.
  static int base({required int lines, required bool tSpin}) {
    RangeError.checkValueInInterval(lines, 0, 4, 'lines');
    return tSpin ? _tSpinBase[math.min(lines, 3)] : _lineBase[lines];
  }

  /// Tetrises and T-spin line clears are "difficult" (they chain back-to-back).
  static bool isDifficult({required int lines, required bool tSpin}) =>
      lines > 0 && (lines == 4 || tSpin);

  /// Banner text such as `T-SPIN DOUBLE`, or '' for nothing worth showing.
  static String label({required int lines, required bool tSpin}) {
    if (lines == 0) return tSpin ? 'T-SPIN' : '';
    return '${tSpin ? 'T-SPIN ' : ''}${_names[lines]}';
  }

  /// T-spin rule: a T piece whose last action was a rotation and with at
  /// least 3 of the 4 corners of its 3x3 box blocked (walls and floor count).
  ///
  /// Call this BEFORE the piece is written into [board].
  static bool isTSpin(
    Board board,
    Piece piece, {
    required bool lastActionWasRotation,
  }) {
    if (piece.type != Tetromino.t || !lastActionWasRotation) return false;
    var blocked = 0;
    for (final (dx, dy) in const [(0, 0), (2, 0), (0, 2), (2, 2)]) {
      final x = piece.x + dx;
      final y = piece.y + dy;
      final outside = x < 0 || x >= boardCols || y >= boardRows;
      if (outside || (y >= 0 && board.at(x, y) != 0)) blocked++;
    }
    return blocked >= 3;
  }
}
