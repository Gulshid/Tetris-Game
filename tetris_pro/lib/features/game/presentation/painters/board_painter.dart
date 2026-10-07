import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/game_colors.dart';
import '../../../../engine/engine.dart';
import 'block_renderer.dart';

/// Paints the playfield: background, grid dots, locked blocks, the line-clear
/// flash, the ghost piece and the active piece (with a soft glow). It listens
/// to the engine directly, so only the canvas repaints, never the widget tree.
class BoardPainter extends CustomPainter {
  BoardPainter(this.engine) : super(repaint: engine);

  final GameEngine engine;
  final BlockRenderer _blocks = BlockRenderer();

  final Paint _backgroundPaint = Paint();
  final Paint _dotPaint = Paint()..color = GameColors.gridDot;
  final Paint _ghostStroke = Paint()..style = PaintingStyle.stroke;
  final Paint _ghostFill = Paint();
  final Paint _glowPaint = Paint();
  final Paint _flashPaint = Paint();

  Size _preparedSize = Size.zero;
  double _dotRadius = 1;

  void _prepare(Size size) {
    if (size == _preparedSize) return;
    _preparedSize = size;
    final cell = size.width / boardCols;
    _backgroundPaint.shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [GameColors.boardFillTop, GameColors.boardFill],
    ).createShader(Offset.zero & size);
    _glowPaint.maskFilter = MaskFilter.blur(BlurStyle.normal, cell * .32);
    _dotRadius = math.max(.8, cell * .035);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / boardCols;
    _blocks.prepare(cell);
    _prepare(size);

    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(cell * .35)),
      _backgroundPaint,
    );

    // Grid: a dot at every inner corner is calmer than full lines.
    for (var c = 1; c < boardCols; c++) {
      for (var r = 1; r < visibleRows; r++) {
        canvas.drawCircle(Offset(c * cell, r * cell), _dotRadius, _dotPaint);
      }
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

    // Line-clear flash: full rows pulse white-hot in the middle.
    final clearing = engine.clearingRows;
    if (clearing.isNotEmpty) {
      final pulse =
          math.sin(engine.clearProgress * math.pi).clamp(0.0, 1.0).toDouble();
      for (final y in clearing) {
        if (y < hiddenRows) continue;
        final rect = Rect.fromLTWH(0, (y - hiddenRows) * cell, size.width, cell);
        _flashPaint.shader = LinearGradient(
          colors: [
            Colors.white.withValues(alpha: pulse * .45),
            Colors.white.withValues(alpha: pulse * .95),
            Colors.white.withValues(alpha: pulse * .45),
          ],
        ).createShader(rect);
        canvas.drawRect(rect, _flashPaint);
      }
    }

    final piece = engine.current;
    if (piece == null) return;

    // Ghost first, so the active piece is drawn on top of it.
    final ghost = engine.ghost;
    if (ghost != null && ghost.y != piece.y) {
      final color = piece.type.color;
      _ghostStroke
        ..strokeWidth = math.max(1.5, cell * .07)
        ..color = color.withValues(alpha: .55);
      _ghostFill.color = color.withValues(alpha: .10);
      final radius = Radius.circular(cell * .16);
      for (final c in ghost.cells) {
        if (c.y < hiddenRows) continue;
        final rect = Rect.fromLTWH(
          c.x * cell,
          (c.y - hiddenRows) * cell,
          cell,
          cell,
        ).deflate(cell * .1);
        final rrect = RRect.fromRectAndRadius(rect, radius);
        canvas
          ..drawRRect(rrect, _ghostFill)
          ..drawRRect(rrect, _ghostStroke);
      }
    }

    // Soft halo under the active piece.
    _glowPaint.color = piece.type.color.withValues(alpha: .5);
    for (final c in piece.cells) {
      if (c.y < hiddenRows) continue;
      final rect = Rect.fromLTWH(
        c.x * cell,
        (c.y - hiddenRows) * cell,
        cell,
        cell,
      ).inflate(cell * .06);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(cell * .22)),
        _glowPaint,
      );
    }

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

  @override
  bool shouldRepaint(covariant BoardPainter oldDelegate) =>
      oldDelegate.engine != engine;
}
