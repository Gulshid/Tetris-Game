import 'package:flutter/material.dart';

import '../../../../core/theme/game_colors.dart';

/// Draws glossy blocks. Gradients and shapes are built once per cell size
/// and reused for every block, so painting stays cheap at 60/120 fps.
class BlockRenderer {
  double _cell = 0;
  List<Paint> _fills = const [];
  late RRect _body;
  late RRect _shine;
  final Paint _shinePaint = Paint()
    ..color = Colors.white.withValues(alpha: .12);

  /// Must be called before [draw]. Cheap when the size is unchanged.
  void prepare(double cell) {
    if (cell == _cell) return;
    _cell = cell;
    final rect = Rect.fromLTWH(0, 0, cell, cell);
    _body = RRect.fromRectAndRadius(
      rect.deflate(.6),
      Radius.circular(cell * .18),
    );
    _shine = RRect.fromRectAndRadius(
      rect.deflate(cell * .24),
      Radius.circular(cell * .1),
    );
    _fills = [
      for (final color in pieceColors)
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(color, Colors.white, .35)!,
              color,
              Color.lerp(color, Colors.black, .35)!,
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
      ..drawRRect(_shine, _shinePaint)
      ..restore();
  }
}
