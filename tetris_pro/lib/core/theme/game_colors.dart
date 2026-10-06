import 'package:flutter/material.dart';
import 'package:tetris_pro/engine/tetromino.dart';


/// Neon piece colors in piece order: I, O, T, S, Z, J, L.
const List<Color> pieceColors = [
  Color(0xFF00E5FF), // I
  Color(0xFFFFD600), // O
  Color(0xFFB347FF), // T
  Color(0xFF00E676), // S
  Color(0xFFFF5252), // Z
  Color(0xFF448AFF), // J
  Color(0xFFFF9100), // L
];

abstract final class GameColors {
  static const Color background = Color(0xFF0B0E1A);
  static const Color boardFill = Color(0xFF10152B);
  static const Color grid = Color(0x14FFFFFF);
  static const Color textDim = Color(0xB3FFFFFF);
}

extension TetrominoColor on Tetromino {
  Color get color => pieceColors[index];
}
