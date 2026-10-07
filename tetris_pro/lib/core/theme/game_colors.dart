import 'dart:math' as math;

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
  // Backgrounds
  static const Color background = Color(0xFF0B0E1A);
  static const Color backgroundDeep = Color(0xFF060813);
  static const Color boardFill = Color(0xFF10152B);
  static const Color boardFillTop = Color(0xFF161D3D);

  // Surfaces and lines
  static const Color surface = Color(0xFF151B36);
  static const Color surfaceHigh = Color(0xFF1F2850);
  static const Color border = Color(0x1FFFFFFF);
  static const Color borderStrong = Color(0x33FFFFFF);
  static const Color grid = Color(0x14FFFFFF);
  static const Color gridDot = Color(0x2EFFFFFF);

  // Text
  static const Color textDim = Color(0xB3FFFFFF);
  static const Color textFaint = Color(0x66FFFFFF);

  // Brand / semantic accents
  static const Color accent = Color(0xFF00E5FF);
  static const Color accentAlt = Color(0xFFB347FF);
  static const Color gold = Color(0xFFFFD600);
  static const Color orange = Color(0xFFFF9100);
  static const Color success = Color(0xFF00E676);
  static const Color danger = Color(0xFFFF5252);

  /// Glass-like panel fill.
  static const LinearGradient panel = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1B2348), Color(0xFF10152B)],
  );

  /// Brand gradient (title, primary button).
  static const LinearGradient brand = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [accent, accentAlt],
  );

  /// Gradient for the game-over title.
  static const LinearGradient alert = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [danger, orange],
  );

  /// The accent that tints the UI at [level]; it cycles through the piece
  /// colors, so every new level gives the game a new mood.
  static Color accentForLevel(int level) =>
      pieceColors[(math.max(level, 1) - 1) % pieceColors.length];
}

extension TetrominoColor on Tetromino {
  Color get color => pieceColors[index];
}
