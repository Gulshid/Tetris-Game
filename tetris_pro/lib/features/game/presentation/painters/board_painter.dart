import 'package:flutter/material.dart';

import '../../../../core/theme/game_colors.dart';
import '../../../../engine/engine.dart';
import 'block_renderer.dart';

/// Paints the playfield: background, grid, locked blocks and the active piece.
/// It listens to the engine directly, so only the canvas repaints, never
/// the widget tree.
class BoardPainter extends CustomPainter {
  BoardPainter(this.engine) : super(repaint: engine);

  final GameEngine engine;
  final BlockRenderer _blocks = BlockRenderer();

  static final Paint _background = Paint()..color = GameColors.boardFill;
  static final Paint _gridPaint = Paint()
    ..color = GameColors.grid
    ..strokeWidth = 1;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / boardCols;
    _blocks.prepare(cell);

    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(cell * .35)),
      _background,
    );

    for (var c = 1; c < boardCols; c++) {
      canvas.drawLine(Offset(c * cell, 0), Offset(c * cell, size.height), _gridPaint);
    }
    for (var r = 1; r < visibleRows; r++) {
      canvas.drawLine(Offset(0, r * cell), Offset(size.width, r * cell), _gridPaint);
    }

    final board = engine.board;
    for (var y = hiddenRows; y < boardRows; y++) {
      for (var x = 0; x < boardCols; x++) {
        final value = board.at(x, y);
        if (value != 0) {
          _blocks.draw(canvas, x * cell, (y - hiddenRows) * cell, value - 1);
        }
      }
    }

    final piece = engine.current;
    if (piece != null) {
      for (final c in piece.cells) {
        if (c.y >= hiddenRows) {
          _blocks.draw(
            canvas,
            c.x * cell,
            (c.y - hiddenRows) * cell,
            piece.type.index,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant BoardPainter oldDelegate) =>
      oldDelegate.engine != engine;
}
