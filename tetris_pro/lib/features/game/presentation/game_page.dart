import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/game_colors.dart';
import '../../../engine/engine.dart';
import 'input/keyboard_handler.dart';
import 'painters/board_painter.dart';
import 'painters/pieces_painter.dart';
import 'widgets/panel_box.dart';
import 'widgets/stat_tile.dart';

/// Main game screen.
/// - LayoutBuilder works out one cell size; board and side panels derive
///   their sizes from it, so the layout always fits (phone, tablet, desktop).
/// - ScreenUtil (.sp .h .w .r) sizes text, gaps and padding.
class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage>
    with SingleTickerProviderStateMixin {
  static const int _nextSlots = 5;

  /// Side panel width measured in board cells.
  static const double _panelCells = 3.2;

  final GameEngine _engine = GameEngine();
  late final BoardPainter _boardPainter = BoardPainter(_engine);
  late final PiecesPainter _holdPainter = PiecesPainter(
    engine: _engine,
    pick: _pickHeld,
    dimWhen: (e) => !e.canHold,
  );
  late final PiecesPainter _nextPainter = PiecesPainter(
    engine: _engine,
    pick: (e) => e.upcoming(_nextSlots),
  );
  late final Ticker _ticker;
  final FocusNode _focus = FocusNode();
  Duration _last = Duration.zero;

  static List<Tetromino> _pickHeld(GameEngine e) {
    final held = e.held;
    return held == null ? const <Tetromino>[] : [held];
  }

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
                Expanded(child: _playfield()),
                SizedBox(height: 8.h),
                Text(
                  '← →  move    ↓  step    ↑ / X  rotate    Z  rotate back\n'
                  'C  hold    R  restart',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: GameColors.textDim, fontSize: 11.sp),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// [ left panel | board | right panel ], all sized from one cell size.
  Widget _playfield() => LayoutBuilder(
        builder: (context, box) {
          final gap = 8.w;
          const double totalCells = boardCols + 2 * _panelCells;
          final cell = math.min(
            (box.maxWidth - 2 * gap) / totalCells,
            box.maxHeight / visibleRows,
          );
          final boardW = cell * boardCols;
          final boardH = cell * visibleRows;
          final panelW = cell * _panelCells;

          return Center(
            child: SizedBox(
              width: boardW + 2 * panelW + 2 * gap,
              height: boardH,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: panelW, child: _leftPanel(panelW)),
                  SizedBox(width: gap),
                  SizedBox(
                    width: boardW,
                    height: boardH,
                    child: RepaintBoundary(
                      child: CustomPaint(painter: _boardPainter),
                    ),
                  ),
                  SizedBox(width: gap),
                  SizedBox(width: panelW, child: _rightPanel(panelW)),
                ],
              ),
            ),
          );
        },
      );

  Widget _leftPanel(double width) => Column(
        children: [
          PanelBox(
            label: 'HOLD',
            child: SizedBox(
              height: PiecesPainter.heightFor(width, 1),
              child: CustomPaint(painter: _holdPainter),
            ),
          ),
          SizedBox(height: 16.h),
          ListenableBuilder(
            listenable: _engine,
            builder: (_, __) =>
                StatTile(label: 'LINES', value: '${_engine.lines}'),
          ),
        ],
      );

  Widget _rightPanel(double width) => PanelBox(
        label: 'NEXT',
        child: SizedBox(
          height: PiecesPainter.heightFor(width, _nextSlots),
          child: CustomPaint(painter: _nextPainter),
        ),
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
            engine.phase == GamePhase.over
                ? 'GAME OVER - press R'
                : engine.phase.name.toUpperCase(),
            style: TextStyle(color: GameColors.textDim, fontSize: 12.sp),
          ),
        ),
      ],
    );
  }
}
