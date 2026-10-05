import 'package:flutter/foundation.dart';

import 'constants.dart';
import 'tetromino.dart';

/// An immutable falling piece. Use [copyWith] / [shifted] to "move" it.
@immutable
class Piece {
  const Piece(this.type, {this.rotation = 0, this.x = 0, this.y = 0});

  /// A piece at its spawn position in the hidden rows.
  factory Piece.spawn(Tetromino type) => Piece(type, x: type.spawnX);

  final Tetromino type;

  /// 0..3 (clockwise quarter turns from the spawn orientation).
  final int rotation;

  /// Top-left of the piece box on the board.
  final int x, y;

  Piece copyWith({int? rotation, int? x, int? y}) => Piece(
        type,
        rotation: (rotation ?? this.rotation) & 3,
        x: x ?? this.x,
        y: y ?? this.y,
      );

  Piece shifted(int dx, int dy) => copyWith(x: x + dx, y: y + dy);

  /// Absolute board coordinates of the four blocks.
  Iterable<Cell> get cells => type
      .shape(rotation)
      .map<Cell>((c) => (x: c.x + x, y: c.y + y));

  @override
  bool operator ==(Object other) =>
      other is Piece &&
      other.type == type &&
      other.rotation == rotation &&
      other.x == x &&
      other.y == y;

  @override
  int get hashCode => Object.hash(type, rotation, x, y);

  @override
  String toString() => 'Piece(${type.name}, rot: $rotation, x: $x, y: $y)';
}
