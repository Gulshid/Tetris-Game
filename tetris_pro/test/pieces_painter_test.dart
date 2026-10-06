import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tetris_pro/engine/engine.dart';
import 'package:tetris_pro/features/game/presentation/painters/pieces_painter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('PiecesPainter draws NEXT and a dimmed HOLD without throwing', () {
    final engine = GameEngine(seed: 1)..start();
    engine.holdPiece(); // fills HOLD and disables further holds

    final next = PiecesPainter(engine: engine, pick: (e) => e.upcoming(5));
    final hold = PiecesPainter(
      engine: engine,
      pick: (e) => e.held == null ? const <Tetromino>[] : [e.held!],
      dimWhen: (e) => !e.canHold,
    );

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const w = 64.0;
    expect(
      () => next.paint(canvas, Size(w, PiecesPainter.heightFor(w, 5))),
      returnsNormally,
    );
    expect(
      () => hold.paint(canvas, Size(w, PiecesPainter.heightFor(w, 1))),
      returnsNormally,
    );
    recorder.endRecording();
    engine.dispose();
  });

  test('heightFor scales with slots', () {
    expect(PiecesPainter.heightFor(88, 2), 2 * PiecesPainter.heightFor(88, 1));
  });
}
