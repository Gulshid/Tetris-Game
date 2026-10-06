import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import '../../../../engine/engine.dart';

/// Phase 10: touch gestures for the playfield. Wrap the board with it.
///
/// | Gesture                         | Action                       |
/// |---------------------------------|------------------------------|
/// | Tap left half                   | rotate counter-clockwise     |
/// | Tap right half                  | rotate clockwise             |
/// | Drag sideways                   | one column per cell of drag  |
/// | Drag down                       | one soft-drop row per 0.8 cell |
/// | Fast downward flick             | hard drop                    |
/// | Tap while READY / GAME OVER     | (re)start the game           |
///
/// All logic lives in the engine; this widget only turns gestures into calls.
class TouchControls extends StatefulWidget {
  const TouchControls({
    super.key,
    required this.engine,
    required this.cellSize,
    required this.child,
  });

  final GameEngine engine;

  /// Size of one board cell in logical pixels. Drag distances are measured
  /// in cells, so the feel is the same on every screen size.
  final double cellSize;

  final Widget child;

  /// A soft-drop row is triggered every this many cells of downward drag.
  static const double softDropCells = 0.8;

  /// Flick speed (px/s) that counts as a hard drop.
  static const double hardDropVelocity = 1600;

  /// A hard-drop flick must be mostly vertical: sideways speed under this.
  static const double hardDropMaxSideways = 600;

  /// After game over, taps are ignored this long so a last frantic tap
  /// doesn't instantly restart the game.
  static const Duration restartDelay = Duration(milliseconds: 700);

  @override
  State<TouchControls> createState() => _TouchControlsState();
}

class _TouchControlsState extends State<TouchControls> {
  double _dragX = 0;
  double _dragY = 0;
  DateTime? _overSince;

  GameEngine get _engine => widget.engine;

  @override
  void initState() {
    super.initState();
    _engine.addListener(_watchPhase);
  }

  @override
  void didUpdateWidget(covariant TouchControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.engine != widget.engine) {
      oldWidget.engine.removeListener(_watchPhase);
      widget.engine.addListener(_watchPhase);
    }
  }

  @override
  void dispose() {
    _engine.removeListener(_watchPhase);
    super.dispose();
  }

  /// Remembers when the game ended (cheap check, runs on every engine tick).
  void _watchPhase() {
    if (_engine.phase == GamePhase.over) {
      _overSince ??= DateTime.now();
    } else {
      _overSince = null;
    }
  }

  void _onTapUp(TapUpDetails details) {
    switch (_engine.phase) {
      case GamePhase.ready:
        _engine.start();
      case GamePhase.over:
        final since = _overSince;
        if (since == null ||
            DateTime.now().difference(since) >= TouchControls.restartDelay) {
          _engine.start();
        }
      case GamePhase.playing:
        final half = widget.cellSize * boardCols / 2;
        _engine.rotate(details.localPosition.dx < half ? -1 : 1);
      case GamePhase.clearing:
      case GamePhase.paused:
        break;
    }
  }

  void _resetDrag() {
    _dragX = 0;
    _dragY = 0;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final cell = widget.cellSize;

    // Sideways: one column per cell width.
    _dragX += details.delta.dx;
    while (_dragX.abs() >= cell) {
      final dir = _dragX.sign.toInt();
      _engine.move(dir);
      _dragX -= dir * cell;
      _dragY = 0; // a sideways step cancels downward drift
    }

    // Down: one soft-drop row per 0.8 cell. Dragging up never "banks" credit.
    _dragY = math.max(0, _dragY + details.delta.dy);
    final rowDistance = cell * TouchControls.softDropCells;
    while (_dragY >= rowDistance) {
      _engine.softStep();
      _dragY -= rowDistance;
    }
  }

  void _onPanEnd(DragEndDetails details) {
    _resetDrag();
    final v = details.velocity.pixelsPerSecond;
    if (v.dy > TouchControls.hardDropVelocity &&
        v.dx.abs() < TouchControls.hardDropMaxSideways) {
      _engine.hardDrop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      // Count the finger's movement from the moment it touches down, so the
      // first few pixels of a drag are not swallowed by the touch slop.
      dragStartBehavior: DragStartBehavior.down,
      onTapUp: _onTapUp,
      onPanStart: (_) => _resetDrag(),
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      onPanCancel: _resetDrag,
      child: widget.child,
    );
  }
}
