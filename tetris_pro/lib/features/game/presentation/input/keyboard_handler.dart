import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../engine/engine.dart';

// Key groups. Final (not const) because LogicalKeyboardKey overrides ==.
final Set<LogicalKeyboardKey> _leftKeys = {
  LogicalKeyboardKey.arrowLeft,
  LogicalKeyboardKey.keyA,
};
final Set<LogicalKeyboardKey> _rightKeys = {
  LogicalKeyboardKey.arrowRight,
  LogicalKeyboardKey.keyD,
};
final Set<LogicalKeyboardKey> _softDropKeys = {
  LogicalKeyboardKey.arrowDown,
  LogicalKeyboardKey.keyS,
};
final Set<LogicalKeyboardKey> _rotateCwKeys = {
  LogicalKeyboardKey.arrowUp,
  LogicalKeyboardKey.keyX,
  LogicalKeyboardKey.keyW,
};
final Set<LogicalKeyboardKey> _rotateCcwKeys = {
  LogicalKeyboardKey.keyZ,
  LogicalKeyboardKey.controlLeft,
  LogicalKeyboardKey.controlRight,
};
final Set<LogicalKeyboardKey> _holdKeys = {
  LogicalKeyboardKey.keyC,
  LogicalKeyboardKey.shiftLeft,
  LogicalKeyboardKey.shiftRight,
};
final Set<LogicalKeyboardKey> _pauseKeys = {
  LogicalKeyboardKey.keyP,
  LogicalKeyboardKey.escape,
};

/// Phase 9 key mapping.
///
/// | Action        | Keys                       |
/// |---------------|----------------------------|
/// | Move          | Left / Right, A / D        |
/// | Soft drop     | Down, S (hold)             |
/// | Hard drop     | Space                      |
/// | Rotate CW     | Up, X, W                   |
/// | Rotate CCW    | Z, Ctrl                    |
/// | Hold          | C, Shift                   |
/// | Pause         | P, Esc                     |
/// | Restart       | R                          |
///
/// Left/Right and Down are *held* keys: key-down and key-up are both sent to
/// the engine, and the engine does DAS/ARR itself. The OS key repeat events
/// are therefore ignored for movement. Every other key fires once per press.
KeyEventResult handleGameKey(GameEngine engine, KeyEvent event) {
  final key = event.logicalKey;
  final isDown = event is KeyDownEvent;
  final isUp = event is KeyUpEvent;

  // Held keys: react to down and up, swallow OS repeats.
  if (_leftKeys.contains(key)) {
    if (isDown) engine.setDir(-1);
    if (isUp) engine.releaseDir(-1);
    return KeyEventResult.handled;
  }
  if (_rightKeys.contains(key)) {
    if (isDown) engine.setDir(1);
    if (isUp) engine.releaseDir(1);
    return KeyEventResult.handled;
  }
  if (_softDropKeys.contains(key)) {
    if (isDown) engine.softDrop = true;
    if (isUp) engine.softDrop = false;
    return KeyEventResult.handled;
  }

  // One-shot keys: only the initial key-down counts.
  if (!isDown) return KeyEventResult.ignored;

  if (_rotateCwKeys.contains(key)) {
    engine.rotate(1);
  } else if (_rotateCcwKeys.contains(key)) {
    engine.rotate(-1);
  } else if (key == LogicalKeyboardKey.space) {
    engine.hardDrop();
  } else if (_holdKeys.contains(key)) {
    engine.holdPiece();
  } else if (_pauseKeys.contains(key)) {
    engine.togglePause();
  } else if (key == LogicalKeyboardKey.keyR) {
    engine.start(); // temporary restart (Phase 12 adds overlays)
  } else {
    return KeyEventResult.ignored;
  }
  return KeyEventResult.handled;
}
