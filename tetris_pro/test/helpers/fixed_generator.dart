import 'package:tetris_pro/engine/engine.dart';

/// Deterministic generator for tests: cycles through a fixed list.
class FixedGenerator implements PieceGenerator {
  FixedGenerator(this._pieces);

  final List<Tetromino> _pieces;
  int _index = 0;

  @override
  Tetromino next() => _pieces[_index++ % _pieces.length];

  @override
  List<Tetromino> peek(int count) => [
        for (var k = 0; k < count; k++) _pieces[(_index + k) % _pieces.length],
      ];
}
