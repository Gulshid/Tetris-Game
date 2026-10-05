import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'board.dart';
import 'constants.dart';
import 'piece.dart';
import 'piece_generator.dart';

/// Pure game logic, no widgets. The UI listens to it as a [ChangeNotifier].
///
/// Time is advanced with a fixed step, so behaviour is identical on 60 Hz
/// and 120 Hz displays and is deterministic for tests.
class GameEngine extends ChangeNotifier {
  GameEngine({PieceGenerator? generator, int? seed})
      : _generator = generator ?? SevenBagGenerator(seed: seed);

  /// Simulation step in seconds (120 Hz).
  static const double fixedStep = 1 / 120;

  /// Longest frame we simulate; protects against huge jumps after a stall.
  static const double maxFrame = 0.05;

  final PieceGenerator _generator;

  Board _board = Board.empty();
  Piece? _current;
  GamePhase _phase = GamePhase.ready;

  double _accumulator = 0;
  double _gravityTimer = 0;

  /// Seconds per row of natural fall. Levels change this in Phase 9.
  double gravityInterval = 1.0;

  Board get board => _board;
  Piece? get current => _current;
  GamePhase get phase => _phase;

  /// Upcoming pieces for the NEXT preview (used from Phase 6).
  List<Piece> preview(int count) =>
      _generator.peek(count).map(Piece.new).toList(growable: false);

  bool get _isActive => _phase == GamePhase.playing && _current != null;

  /// Starts a fresh game.
  void start() {
    _board = Board.empty();
    _current = null;
    _accumulator = 0;
    _gravityTimer = 0;
    _phase = GamePhase.playing;
    _spawn();
    notifyListeners();
  }

  /// Advances the simulation by [dt] seconds (call once per frame).
  void update(double dt) {
    if (!_isActive) return;
    _accumulator += math.min(math.max(dt, 0), maxFrame);
    var changed = false;
    while (_accumulator >= fixedStep) {
      _accumulator -= fixedStep;
      changed |= _step(fixedStep);
    }
    if (changed) notifyListeners();
  }

  /// One fixed simulation step. Returns true if visible state changed.
  bool _step(double dt) {
    _gravityTimer += dt;
    if (_gravityTimer < gravityInterval) return false;
    _gravityTimer -= gravityInterval;
    return _tryDown();
  }

  void _spawn() {
    final piece = Piece.spawn(_generator.next());
    _current = piece;
    _gravityTimer = 0;
    if (_board.collides(piece)) _phase = GamePhase.over;
  }

  /// Moves the piece one row down. False if blocked (floor or stack).
  bool _tryDown() {
    final moved = _current!.shifted(0, 1);
    if (_board.collides(moved)) return false;
    _current = moved;
    return true;
  }
}
