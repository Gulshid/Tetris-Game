import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../engine/engine.dart';

/// Phase 7-8 key mapping.
/// - Left/Right use the OS key repeat (Phase 9 replaces this with DAS/ARR).
/// - Down is a held "soft drop" flag, so key-up is handled too.
/// - Rotate, hard drop, hold and restart fire once per key press.
KeyEventResult handleGameKey(GameEngine engine, KeyEvent event) {
  final key = event.logicalKey;
  final isDown = event is KeyDownEvent;
  final isUp = event is KeyUpEvent;
  final isRepeat = event is KeyRepeatEvent;

  // Soft drop: on while held, off on release.
  if (key == LogicalKeyboardKey.arrowDown) {
    if (isDown) engine.softDrop = true;
    if (isUp) engine.softDrop = false;
    return KeyEventResult.handled;
  }

  if (isUp) return KeyEventResult.ignored;

  // Repeatable keys.
  if (key == LogicalKeyboardKey.arrowLeft) {
    engine.move(-1);
    return KeyEventResult.handled;
  }
  if (key == LogicalKeyboardKey.arrowRight) {
    engine.move(1);
    return KeyEventResult.handled;
  }

  // Everything below fires once per press, not on OS repeat.
  if (isRepeat) return KeyEventResult.ignored;

  if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.keyX) {
    engine.rotate(1);
  } else if (key == LogicalKeyboardKey.keyZ) {
    engine.rotate(-1);
  } else if (key == LogicalKeyboardKey.space) {
    engine.hardDrop();
  } else if (key == LogicalKeyboardKey.keyC) {
    engine.holdPiece();
  } else if (key == LogicalKeyboardKey.keyR) {
    engine.start(); // temporary restart
  } else {
    return KeyEventResult.ignored;
  }
  return KeyEventResult.handled;
}
