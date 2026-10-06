import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/game_colors.dart';
import '../../../engine/engine.dart';
import 'input/keyboard_handler.dart';
import 'painters/board_painter.dart';

/// Main game screen.
/// - LayoutBuilder sizes the board (always 1:2, cell = width / 10).
/// - ScreenUtil (.sp .h .r) sizes the surrounding text and padding.
class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage>
    with SingleTickerProviderStateMixin {
  final GameEngine _engine = GameEngine();
  late final BoardPainter _painter = BoardPainter(_engine);
  late final Ticker _ticker;
  final FocusNode _focus = FocusNode();
  Duration _last = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
    _engine.start();
  }

  void _onTick(Duration elapsed) {
    final dt = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    _engine.update(dt); // engine clamps big frame gaps
  }

  @override
  void dispose() {
    _ticker.dispose();
    _focus.dispose();
    _engine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameColors.background,
      body: SafeArea(
        child: Focus(
          autofocus: true,
          focusNode: _focus,
          onKeyEvent: (_, event) => handleGameKey(_engine, event),
          child: Padding(
            padding: EdgeInsets.all(12.r),
            child: Column(
              children: [
                _Header(engine: _engine),
                SizedBox(height: 8.h),
                Expanded(child: _boardArea()),
                SizedBox(height: 8.h),
                Text(
                  '← →  move     ↑ / X  rotate     Z  rotate back',
                  style: TextStyle(color: GameColors.textDim, fontSize: 11.sp),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _boardArea() => LayoutBuilder(
        builder: (context, box) {
          final width = math.min(box.maxWidth, box.maxHeight * boardCols / visibleRows);
          final height = width * visibleRows / boardCols;
          return Center(
            child: SizedBox(
              width: width,
              height: height,
              child: RepaintBoundary(child: CustomPaint(painter: _painter)),
            ),
          );
        },
      );
}

class _Header extends StatelessWidget {
  const _Header({required this.engine});

  final GameEngine engine;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'TETRIS PRO',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22.sp,
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
          ),
        ),
        ListenableBuilder(
          listenable: engine,
          builder: (_, __) => Text(
            engine.phase.name.toUpperCase(),
            style: TextStyle(color: GameColors.textDim, fontSize: 12.sp),
          ),
        ),
      ],
    );
  }
}
