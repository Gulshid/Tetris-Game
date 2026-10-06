import 'package:flutter/material.dart';

import '../../../../engine/engine.dart';
import 'block_renderer.dart';

/// Draws a vertical stack of mini pieces. Used for both HOLD (1 slot) and
/// NEXT (5 slots). Every piece is centred inside its own slot.
class PiecesPainter extends CustomPainter {
  PiecesPainter({
    required this.engine,
    required this.pick,
    this.dimWhen,
  }) : super(repaint: engine);

  final GameEngine engine;

  /// Which pieces to draw, top to bottom.
  final List<Tetromino> Function(GameEngine engine) pick;

  /// When this returns true the whole stack is drawn faded (HOLD locked).
  final bool Function(GameEngine engine)? dimWhen;

  final BlockRenderer _blocks = BlockRenderer();

  static const double _widthInCells = 4.4;
  static const double _slotInCells = 3.0;

  /// Height needed for [slots] pieces when the painter is [width] wide.
  static double heightFor(double width, int slots) =>
      slots * _slotInCells * (width / _widthInCells);

  @override
  void paint(Canvas canvas, Size size) {
    final cs = size.width / _widthInCells;
    final slotHeight = cs * _slotInCells;
    _blocks.prepare(cs);

    final dim = dimWhen?.call(engine) ?? false;
    if (dim) {
      canvas.saveLayer(
        Offset.zero & size,
        Paint()..color = const Color(0x59FFFFFF), // ~35% opacity
      );
    }

    final list = pick(engine);
    for (var i = 0; i < list.length; i++) {
      final cells = list[i].shape(0);
      var minX = 99, maxX = -1, minY = 99, maxY = -1;
      for (final c in cells) {
        if (c.x < minX) minX = c.x;
        if (c.x > maxX) maxX = c.x;
        if (c.y < minY) minY = c.y;
        if (c.y > maxY) maxY = c.y;
      }
      final ox = (size.width - (maxX - minX + 1) * cs) / 2 - minX * cs;
      final oy = i * slotHeight + (slotHeight - (maxY - minY + 1) * cs) / 2 - minY * cs;
      for (final c in cells) {
        _blocks.draw(canvas, ox + c.x * cs, oy + c.y * cs, list[i].index);
      }
    }

    if (dim) canvas.restore();
  }

  @override
  bool shouldRepaint(covariant PiecesPainter oldDelegate) =>
      oldDelegate.engine != engine;
}
