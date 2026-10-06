import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'board.dart';
import 'constants.dart';
import 'piece.dart';
import 'piece_generator.dart';
import 'tetromino.dart';

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

  Tetromino? _held;
  bool _canHold = true;
  int _lines = 0;

  double _accumulator = 0;
  double _gravityTimer = 0;

  /// Seconds per row of natural fall. Levels change this in Phase 9.
  double gravityInterval = 1.0;

  Board get board => _board;
  Piece? get current => _current;
  GamePhase get phase => _phase;

  /// The piece in the HOLD slot, if any.
  Tetromino? get held => _held;

  /// False after a hold until the next piece locks (one hold per piece).
  bool get canHold => _canHold;

  /// Total lines cleared this game.
  int get lines => _lines;

  /// The next [count] pieces for the NEXT preview (does not consume them).
  List<Tetromino> upcoming(int count) => _generator.peek(count);

  bool get _isActive => _phase == GamePhase.playing && _current != null;

  /// Starts a fresh game.
  void start() {
    _board = Board.empty();
    _current = null;
    _held = null;
    _canHold = true;
    _lines = 0;
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
    while (_accumulator >= fixedStep && _isActive) {
      _accumulator -= fixedStep;
      changed |= _step(fixedStep);
    }
    if (changed) notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Player actions
  // ---------------------------------------------------------------------

  /// Tries to shift the piece by [dx] columns (-1 left, +1 right).
  bool move(int dx) {
    if (!_isActive) return false;
    return _applyIfFree(_current!.shifted(dx, 0));
  }

  /// Tries to rotate the piece: +1 clockwise, -1 counter-clockwise.
  /// Plain rotation with no wall kicks yet; SRS kicks arrive in Phase 8.
  bool rotate(int direction) {
    if (!_isActive) return false;
    final piece = _current!;
    return _applyIfFree(piece.copyWith(rotation: piece.rotation + direction));
  }

  /// Moves the piece down one row. Temporary helper for testing locks;
  /// Phase 7 turns this into the scored soft drop.
  bool softStep() {
    if (!_isActive) return false;
    final moved = _tryDown();
    if (moved) notifyListeners();
    return moved;
  }

  /// Swaps the current piece with the HOLD slot (once per piece).
  /// With an empty slot the current piece is stored and the next one spawns.
  bool holdPiece() {
    if (!_isActive || !_canHold) return false;
    final outgoing = _current!.type;
    final incoming = _held;
    _held = outgoing;
    _spawn(type: incoming, resetHold: false);
    notifyListeners();
    return true;
  }

  /// Commits [candidate] as the current piece if it fits on the board.
  bool _applyIfFree(Piece candidate) {
    if (_board.collides(candidate)) return false;
    _current = candidate;
    notifyListeners();
    return true;
  }

  // ---------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------

  /// One fixed simulation step. Returns true if visible state changed.
  bool _step(double dt) {
    _gravityTimer += dt;
    if (_gravityTimer < gravityInterval) return false;
    _gravityTimer -= gravityInterval;
    if (!_tryDown()) _lockPiece(); // blocked: lock now (lock delay: Phase 8)
    return true;
  }

  /// Spawns [type], or the next piece from the generator.
  /// [resetHold] is false when the spawn comes from a hold swap.
  void _spawn({Tetromino? type, bool resetHold = true}) {
    final piece = Piece.spawn(type ?? _generator.next());
    _current = piece;
    _canHold = resetHold;
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

  /// Writes the piece into the board, clears full rows and spawns the next.
  void _lockPiece() {
    final piece = _current!;
    final lockedInHiddenRows = piece.cells.every((c) => c.y < hiddenRows);

    var next = _board.lock(piece);
    final full = next.fullRows;
    if (full.isNotEmpty) {
      next = next.removeRows(full);
      _lines += full.length;
    }
    _board = next;
    _current = null;

    // Lock out: the piece came to rest entirely above the visible field.
    if (full.isEmpty && lockedInHiddenRows) {
      _phase = GamePhase.over;
      return;
    }
    _spawn();
  }
}