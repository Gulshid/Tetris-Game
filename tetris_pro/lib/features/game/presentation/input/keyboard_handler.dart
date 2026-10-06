import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../engine/engine.dart';

/// Phase 4-6 key mapping (uses the OS key repeat).
/// Phase 9 replaces this with proper key-down/key-up handling and DAS/ARR.
KeyEventResult handleGameKey(GameEngine engine, KeyEvent event) {
  if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
    return KeyEventResult.ignored;
  }
  final key = event.logicalKey;

  if (key == LogicalKeyboardKey.arrowLeft) {
    engine.move(-1);
  } else if (key == LogicalKeyboardKey.arrowRight) {
    engine.move(1);
  } else if (key == LogicalKeyboardKey.arrowDown) {
    engine.softStep(); // temporary; real soft drop in Phase 7
  } else if (key == LogicalKeyboardKey.arrowUp ||
      key == LogicalKeyboardKey.keyX) {
    engine.rotate(1);
  } else if (key == LogicalKeyboardKey.keyZ) {
    engine.rotate(-1);
  } else if (key == LogicalKeyboardKey.keyC) {
    engine.holdPiece();
  } else if (key == LogicalKeyboardKey.keyR) {
    if (event is KeyDownEvent) engine.start(); // temporary restart
  } else {
    return KeyEventResult.ignored;
  }
  return KeyEventResult.handled;
}
