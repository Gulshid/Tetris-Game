import 'dart:collection';
import 'dart:math';

import 'tetromino.dart';

/// Source of upcoming pieces. Swap implementations for tests or daily seeds.
abstract class PieceGenerator {
  /// Removes and returns the next piece.
  Tetromino next();

  /// Looks ahead at the next [count] pieces without consuming them.
  List<Tetromino> peek(int count);
}

/// Guideline "7-bag": every 7 pieces contain each tetromino exactly once.
/// Passing a [seed] makes the sequence fully reproducible.
class SevenBagGenerator implements PieceGenerator {
  SevenBagGenerator({int? seed}) : _rng = Random(seed);

  final Random _rng;
  final Queue<Tetromino> _queue = Queue<Tetromino>();

  void _refill(int needed) {
    while (_queue.length < needed) {
      _queue.addAll(List<Tetromino>.of(Tetromino.values)..shuffle(_rng));
    }
  }

  @override
  Tetromino next() {
    _refill(1);
    return _queue.removeFirst();
  }

  @override
  List<Tetromino> peek(int count) {
    _refill(count);
    return _queue.take(count).toList(growable: false);
  }
}
