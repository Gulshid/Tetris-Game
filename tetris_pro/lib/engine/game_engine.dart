import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'board.dart';
import 'constants.dart';
import 'piece.dart';
import 'piece_generator.dart';
import 'srs_kicks.dart';
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

  // Phase 7: drops
  /// Soft drop makes gravity this many times faster.
  static const double softDropFactor = 20;

  /// Soft drop never falls faster than one row per this many seconds.
  static const double minSoftDropInterval = 0.02;

  static const int softDropPointsPerRow = 1;
  static const int hardDropPointsPerRow = 2;

  // Phase 8: lock delay
  /// Seconds a grounded piece may rest before it locks.
  static const double lockDelay = 0.5;

  /// Successful moves/rotations that may restart the lock timer per piece.
  static const int maxLockResets = 15;

  final PieceGenerator _generator;

  Board _board = Board.empty();
  Piece? _current;
  GamePhase _phase = GamePhase.ready;

  Tetromino? _held;
  bool _canHold = true;
  int _lines = 0;
  int _score = 0;

  double _accumulator = 0;
  double _gravityTimer = 0;

  bool _softDrop = false;

  // Lock delay state (reset for every new piece).
  double _lockTimer = 0;
  int _lockResets = 0;
  int _lowestY = 0;
  bool _lastActionWasRotation = false;

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

  /// Current score (soft drop and hard drop points for now; Phase 11 adds
  /// line clears, combos and T-spins).
  int get score => _score;

  /// True while the soft drop key is held. Set from the input layer.
  bool get softDrop => _softDrop;
  set softDrop(bool value) => _softDrop = value;

  /// True if the last successful action of the current piece was a rotation.
  /// Phase 11 uses this for T-spin detection.
  bool get lastActionWasRotation => _lastActionWasRotation;

  /// Where the current piece would land if dropped straight down, or null
  /// when there is no active piece.
  Piece? get ghost {
    if (!_isActive) return null;
    var landed = _current!;
    while (true) {
      final next = landed.shifted(0, 1);
      if (_board.collides(next)) return landed;
      landed = next;
    }
  }

  /// The next [count] pieces for the NEXT preview (does not consume them).
  List<Tetromino> upcoming(int count) => _generator.peek(count);

  bool get _isActive => _phase == GamePhase.playing && _current != null;

  /// True if the current piece rests on the floor or the stack.
  bool get _isGrounded => _board.collides(_current!.shifted(0, 1));

  /// Seconds per row right now, taking soft drop into account.
  double get _fallInterval => _softDrop
      ? math.min(
          gravityInterval,
          math.max(gravityInterval / softDropFactor, minSoftDropInterval),
        )
      : gravityInterval;

  /// Starts a fresh game.
  void start() {
    _board = Board.empty();
    _current = null;
    _held = null;
    _canHold = true;
    _lines = 0;
    _score = 0;
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
    final candidate = _current!.shifted(dx, 0);
    if (_board.collides(candidate)) return false;
    _commit(candidate, rotated: false);
    return true;
  }

  /// Rotates the piece: +1 clockwise, -1 counter-clockwise.
  /// Uses SRS wall kicks: the first collision-free offset wins.
  bool rotate(int direction) {
    if (!_isActive) return false;
    final piece = _current!;
    final to = (piece.rotation + direction) & 3;
    for (final kick in srsKicks(piece.type, piece.rotation, to)) {
      // Kick tables are y-up, our board is y-down, so subtract kick.y.
      final candidate = piece.copyWith(
        rotation: to,
        x: piece.x + kick.x,
        y: piece.y - kick.y,
      );
      if (!_board.collides(candidate)) {
        _commit(candidate, rotated: true);
        return true;
      }
    }
    return false;
  }

  /// Moves the piece down one row for [softDropPointsPerRow] point.
  /// The input layer uses the [softDrop] flag for held keys; this is for
  /// single steps (touch drag in Phase 10).
  bool softStep() {
    if (!_isActive) return false;
    if (!_tryDown()) return false;
    _score += softDropPointsPerRow;
    notifyListeners();
    return true;
  }

  /// Drops the piece to the ghost position and locks it instantly.
  bool hardDrop() {
    if (!_isActive) return false;
    final landed = ghost!;
    final rows = landed.y - _current!.y;
    _score += rows * hardDropPointsPerRow;
    if (rows > 0) _lastActionWasRotation = false;
    _current = landed;
    _lockPiece();
    notifyListeners();
    return true;
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

  // ---------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------

  /// Commits a successful move or rotation and applies lock-delay rules:
  /// while grounded, each success restarts the timer (up to [maxLockResets]).
  void _commit(Piece piece, {required bool rotated}) {
    _current = piece;
    _lastActionWasRotation = rotated;
    _trackLowest(piece);
    if (_isGrounded && _lockResets < maxLockResets) {
      _lockTimer = 0;
      _lockResets++;
    }
    notifyListeners();
  }

  /// Reaching a new lowest row earns a fresh set of lock resets.
  void _trackLowest(Piece piece) {
    if (piece.y > _lowestY) {
      _lowestY = piece.y;
      _lockResets = 0;
    }
  }

  /// One fixed simulation step. Returns true if visible state changed.
  bool _step(double dt) {
    // Resting on something: no gravity, count down the lock delay instead.
    if (_isGrounded) {
      _gravityTimer = 0;
      _lockTimer += dt;
      if (_lockTimer < lockDelay) return false;
      _lockPiece();
      return true;
    }

    _lockTimer = 0;
    _gravityTimer += dt;
    final interval = _fallInterval;
    var moved = false;
    while (_gravityTimer >= interval && _tryDown()) {
      _gravityTimer -= interval;
      moved = true;
      if (_softDrop) _score += softDropPointsPerRow;
    }
    return moved;
  }

  /// Spawns [type], or the next piece from the generator.
  /// [resetHold] is false when the spawn comes from a hold swap.
  void _spawn({Tetromino? type, bool resetHold = true}) {
    final piece = Piece.spawn(type ?? _generator.next());
    _current = piece;
    _canHold = resetHold;
    _gravityTimer = 0;
    _lockTimer = 0;
    _lockResets = 0;
    _lowestY = piece.y;
    _lastActionWasRotation = false;
    if (_board.collides(piece)) _phase = GamePhase.over;
  }

  /// Moves the piece one row down. False if blocked (floor or stack).
  bool _tryDown() {
    final moved = _current!.shifted(0, 1);
    if (_board.collides(moved)) return false;
    _current = moved;
    _lastActionWasRotation = false;
    _trackLowest(moved);
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
