import 'dart:typed_data';

import 'package:flutter/foundation.dart' show visibleForTesting;

import 'constants.dart';
import 'piece.dart';

/// Immutable playfield stored as a flat byte array (row-major).
/// 0 = empty, otherwise `Tetromino.cellValue` of the locked block.
class Board {
  Board.empty() : _cells = Uint8List(boardCols * boardRows);

  Board._(this._cells);

  /// Builds a board from text rows aligned to the BOTTOM of the field.
  /// `.` is empty, `#` is a block, `1`..`7` is a specific piece colour.
  /// Handy for tests: `Board.parse(['###.######'])` is a nearly full floor.
  @visibleForTesting
  factory Board.parse(List<String> rows) {
    if (rows.length > boardRows) {
      throw ArgumentError('at most $boardRows rows, got ${rows.length}');
    }
    final cells = Uint8List(boardCols * boardRows);
    final top = boardRows - rows.length;
    for (var r = 0; r < rows.length; r++) {
      final line = rows[r];
      if (line.length != boardCols) {
        throw ArgumentError('row $r needs $boardCols characters: "$line"');
      }
      for (var x = 0; x < boardCols; x++) {
        final ch = line[x];
        if (ch == '.') continue;
        final value = ch == '#' ? 1 : int.tryParse(ch);
        if (value == null || value < 1 || value > 7) {
          throw ArgumentError('bad cell "$ch" in row $r');
        }
        cells[(top + r) * boardCols + x] = value;
      }
    }
    return Board._(cells);
  }

  final Uint8List _cells;

  static bool inBounds(int x, int y) =>
      x >= 0 && x < boardCols && y >= 0 && y < boardRows;

  /// Cell value at (x, y). Throws if out of bounds.
  int at(int x, int y) {
    if (!inBounds(x, y)) throw RangeError('($x, $y) is outside the board');
    return _cells[y * boardCols + x];
  }

  /// True if the piece overlaps a wall, the floor or a locked block.
  /// Cells above the board (y < 0) are allowed.
  bool collides(Piece piece) {
    for (final c in piece.cells) {
      if (c.x < 0 || c.x >= boardCols || c.y >= boardRows) return true;
      if (c.y >= 0 && _cells[c.y * boardCols + c.x] != 0) return true;
    }
    return false;
  }

  /// Returns a new board with the piece written into it.
  Board lock(Piece piece) {
    final next = Uint8List.fromList(_cells);
    for (final c in piece.cells) {
      if (inBounds(c.x, c.y)) next[c.y * boardCols + c.x] = piece.type.cellValue;
    }
    return Board._(next);
  }

  bool isRowFull(int y) {
    final start = y * boardCols;
    for (var x = 0; x < boardCols; x++) {
      if (_cells[start + x] == 0) return false;
    }
    return true;
  }

  /// Indices of all full rows, top to bottom.
  List<int> get fullRows => [
        for (var y = 0; y < boardRows; y++)
          if (isRowFull(y)) y,
      ];

  /// Returns a new board with [rowsToRemove] deleted and empty rows added on top.
  Board removeRows(Iterable<int> rowsToRemove) {
    final remove = rowsToRemove.toSet();
    if (remove.isEmpty) return this;
    final next = Uint8List(boardCols * boardRows);
    var dst = boardRows - 1;
    for (var src = boardRows - 1; src >= 0; src--) {
      if (remove.contains(src)) continue;
      next.setRange(
        dst * boardCols,
        (dst + 1) * boardCols,
        _cells,
        src * boardCols,
      );
      dst--;
    }
    return Board._(next);
  }

  /// True if nothing is on the board.
  bool get isEmpty => _cells.every((v) => v == 0);
}
