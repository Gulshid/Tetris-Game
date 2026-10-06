import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tetris_pro/engine/engine.dart';
import 'package:tetris_pro/features/game/presentation/input/keyboard_handler.dart';

import 'helpers/fixed_generator.dart';

KeyDownEvent _down(LogicalKeyboardKey k, PhysicalKeyboardKey p) =>
    KeyDownEvent(physicalKey: p, logicalKey: k, timeStamp: Duration.zero);
KeyUpEvent _up(LogicalKeyboardKey k, PhysicalKeyboardKey p) =>
    KeyUpEvent(physicalKey: p, logicalKey: k, timeStamp: Duration.zero);
KeyRepeatEvent _repeat(LogicalKeyboardKey k, PhysicalKeyboardKey p) =>
    KeyRepeatEvent(physicalKey: p, logicalKey: k, timeStamp: Duration.zero);

GameEngine _engine() =>
    GameEngine(generator: FixedGenerator([Tetromino.t]))..start();

void main() {
  const left = LogicalKeyboardKey.arrowLeft;
  const leftP = PhysicalKeyboardKey.arrowLeft;

  test('left key down moves once; OS repeat events do not move again', () {
    final e = _engine();
    final x0 = e.current!.x;
    handleGameKey(e, _down(left, leftP));
    expect(e.current!.x, x0 - 1);
    final r = handleGameKey(e, _repeat(left, leftP));
    expect(e.current!.x, x0 - 1);
    expect(r, KeyEventResult.handled);
  });

  test('left key up ends the auto-repeat', () {
    final e = _engine();
    handleGameKey(e, _down(left, leftP));
    handleGameKey(e, _up(left, leftP));
    final x = e.current!.x;
    for (var i = 0; i < 60; i++) {
      e.update(0.01);
    }
    expect(e.current!.x, x);
  });

  test('down arrow is a held soft drop flag', () {
    final e = _engine();
    handleGameKey(
        e, _down(LogicalKeyboardKey.arrowDown, PhysicalKeyboardKey.arrowDown));
    expect(e.softDrop, true);
    handleGameKey(
        e, _up(LogicalKeyboardKey.arrowDown, PhysicalKeyboardKey.arrowDown));
    expect(e.softDrop, false);
  });

  test('Z and X rotate in opposite directions; Space hard drops', () {
    final e = _engine();
    handleGameKey(
        e, _down(LogicalKeyboardKey.keyX, PhysicalKeyboardKey.keyX));
    expect(e.current!.rotation, 1);
    handleGameKey(
        e, _down(LogicalKeyboardKey.keyZ, PhysicalKeyboardKey.keyZ));
    expect(e.current!.rotation, 0);
    handleGameKey(
        e, _down(LogicalKeyboardKey.space, PhysicalKeyboardKey.space));
    expect(e.score, greaterThan(0));
  });

  test('P pauses and resumes', () {
    final e = _engine();
    final p = PhysicalKeyboardKey.keyP;
    handleGameKey(e, _down(LogicalKeyboardKey.keyP, p));
    expect(e.phase, GamePhase.paused);
    handleGameKey(e, _down(LogicalKeyboardKey.keyP, p));
    expect(e.phase, GamePhase.playing);
  });

  test('unknown keys are ignored', () {
    final e = _engine();
    final r = handleGameKey(
        e, _down(LogicalKeyboardKey.keyQ, PhysicalKeyboardKey.keyQ));
    expect(r, KeyEventResult.ignored);
  });
}
