import 'package:tetris_pro/engine/engine.dart';

/// Number of non-empty cells on the board.
int filledCells(Board board) {
  var n = 0;
  for (var y = 0; y < boardRows; y++) {
    for (var x = 0; x < boardCols; x++) {
      if (board.at(x, y) != 0) n++;
    }
  }
  return n;
}

/// Slides the current piece horizontally until its box is at column [x].
void moveTo(GameEngine e, int x) {
  final dx = x - e.current!.x;
  for (var i = 0; i < dx.abs(); i++) {
    e.move(dx.sign);
  }
}

/// Drops the current piece to the bottom and lets gravity lock it.
void dropAndLock(GameEngine e) {
  while (e.softStep()) {}
  for (var i = 0; i < 22; i++) {
    e.update(0.05); // 1.1 s: enough for one gravity tick
  }
}
