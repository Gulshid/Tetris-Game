import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tetris_pro/engine/engine.dart';
import 'package:tetris_pro/features/game/presentation/painters/board_painter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('BoardPainter paints a started game without throwing', () {
    final engine = GameEngine(seed: 1)..start();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    expect(
      () => BoardPainter(engine).paint(canvas, const Size(300, 600)),
      returnsNormally,
    );
    recorder.endRecording();
    engine.dispose();
  });

  test('BoardPainter paints before the game starts', () {
    final engine = GameEngine(seed: 1);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    expect(
      () => BoardPainter(engine).paint(canvas, const Size(150, 300)),
      returnsNormally,
    );
    recorder.endRecording();
    engine.dispose();
  });
}
