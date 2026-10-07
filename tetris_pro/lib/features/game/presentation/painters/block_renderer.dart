import 'package:flutter/material.dart';

import '../../../../core/theme/game_colors.dart';

/// Draws beveled, glossy blocks. Gradients and shapes are built once per cell
/// size and reused for every block, so painting stays cheap at 60/120 fps.
class BlockRenderer {
  double _cell = 0;
  List<Paint> _fills = const [];
  late RRect _body;
  late RRect _inner;
  late RRect _gloss;

  final Paint _glossPaint = Paint();
  final Paint _innerPaint = Paint()..style = PaintingStyle.stroke;
  final Paint _edgePaint = Paint()..style = PaintingStyle.stroke;

  /// Must be called before [draw]. Cheap when the size is unchanged.
  void prepare(double cell) {
    if (cell == _cell) return;
    _cell = cell;
    final rect = Rect.fromLTWH(0, 0, cell, cell);

    _body = RRect.fromRectAndRadius(
      rect.deflate(.6),
      Radius.circular(cell * .18),
    );
    _inner = _body.deflate(cell * .1);
    final glossRect = Rect.fromLTWH(
      cell * .14,
      cell * .12,
      cell * .72,
      cell * .38,
    );
    _gloss = RRect.fromRectAndRadius(glossRect, Radius.circular(cell * .12));

    _glossPaint.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.white.withValues(alpha: .42),
        Colors.white.withValues(alpha: 0),
      ],
    ).createShader(glossRect);

    _innerPaint
      ..strokeWidth = (cell * .05).clamp(1.0, 4.0).toDouble()
      ..color = Colors.white.withValues(alpha: .20);
    _edgePaint
      ..strokeWidth = (cell * .04).clamp(.8, 3.0).toDouble()
      ..color = Colors.black.withValues(alpha: .35);

    _fills = [
      for (final color in pieceColors)
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(color, Colors.white, .35)!,
              color,
              Color.lerp(color, Colors.black, .38)!,
            ],
          ).createShader(rect),
    ];
  }

  /// Draws one block whose top-left corner is at ([x], [y]) in canvas pixels.
  /// [pieceIndex] is the Tetromino index (0..6).
  void draw(Canvas canvas, double x, double y, int pieceIndex) {
    canvas
      ..save()
      ..translate(x, y)
      ..drawRRect(_body, _fills[pieceIndex])
      ..drawRRect(_inner, _innerPaint)
      ..drawRRect(_gloss, _glossPaint)
      ..drawRRect(_body, _edgePaint)
      ..restore();
  }
}
