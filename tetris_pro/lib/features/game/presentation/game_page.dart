import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/storage/high_score_keeper.dart';
import '../../../core/storage/high_score_store.dart';
import '../../../core/theme/game_colors.dart';
import '../../../engine/engine.dart';
import 'input/keyboard_handler.dart';
import 'input/touch_controls.dart';
import 'painters/board_painter.dart';
import 'painters/pieces_painter.dart';
import 'widgets/ambient_background.dart';
import 'widgets/banner_text.dart';
import 'widgets/control_hints.dart';
import 'widgets/game_overlay.dart';
import 'widgets/level_accent.dart';
import 'widgets/panel_box.dart';
import 'widgets/stat_tile.dart';
import 'widgets/status_chips.dart';

/// Main game screen.
/// - LayoutBuilder works out one cell size; board and side panels derive
///   their sizes from it, so the layout always fits (phone, tablet, desktop).
/// - ScreenUtil (.sp .h .w .r) sizes text, gaps and padding.
/// - Phones (< 600 px wide) get a stats strip above the board and slimmer
///   side panels; larger screens keep the stats in the left panel.
/// - The game starts from the READY overlay (START button / Enter / tap).
/// - The best score is loaded at start-up and saved when a game ends.
class GamePage extends StatefulWidget {
  /// [store] defaults to `shared_preferences`; pass a fake in tests.
  const GamePage({super.key, this.store});

  final HighScoreStore? store;

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage>
    with SingleTickerProviderStateMixin {
  static const int _nextSlots = 5;

  /// Width below which the compact (phone) layout is used.
  static const double _compactWidth = 600;

  static bool get _isTouch =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  final GameEngine _engine = GameEngine();
  late final HighScoreKeeper _keeper = HighScoreKeeper(
    engine: _engine,
    store: widget.store ?? const SharedPrefsHighScoreStore(),
  );
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
    _engine.onEvent = _onEvent;
    _engine.addListener(_keepKeyboardFocus);
    unawaited(_keeper.load()); // fills BEST when the saved value arrives
    _ticker = createTicker(_onTick)..start();
    // No auto-start: the READY overlay shows a START button.
  }

  void _onTick(Duration elapsed) {
    final dt = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    _engine.update(dt); // engine clamps big frame gaps
  }

  /// Clicking an overlay button can leave keyboard focus on that button.
  /// Once the game is running, give it back so the arrow keys work.
  void _keepKeyboardFocus() {
    if (_engine.phase == GamePhase.playing && !_focus.hasPrimaryFocus) {
      _focus.requestFocus();
    }
  }

  /// Haptic feedback for engine events.
  void _onEvent(GameEvent event) {
    switch (event) {
      case GameEvent.rotate:
        HapticFeedback.selectionClick();
      case GameEvent.drop:
        HapticFeedback.lightImpact();
      case GameEvent.clear:
        HapticFeedback.mediumImpact();
      case GameEvent.over:
        HapticFeedback.heavyImpact();
        unawaited(_keeper.saveIfNewBest());
    }
  }

  @override
  void dispose() {
    _engine.onEvent = null;
    _engine.removeListener(_keepKeyboardFocus);
    _keeper.dispose();
    _ticker.dispose();
    _focus.dispose();
    _engine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameColors.background,
      body: AmbientBackground(
        engine: _engine,
        child: SafeArea(
          child: Focus(
            autofocus: true,
            focusNode: _focus,
            onKeyEvent: (_, event) => handleGameKey(_engine, event),
            // A key-up is never delivered if the window loses focus mid-press.
            onFocusChange: (hasFocus) {
              if (!hasFocus) _engine.releaseInputs();
            },
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < _compactWidth;
                return Padding(
                  padding: EdgeInsets.all(12.r),
                  child: Column(
                    children: [
                      _Header(engine: _engine),
                      SizedBox(height: 10.h),
                      if (compact) ...[
                        _statsStrip(),
                        SizedBox(height: 10.h),
                      ],
                      Expanded(child: _playfield(compact)),
                      SizedBox(height: 8.h),
                      ControlHints(touch: _isTouch),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// [ left panel | board | right panel ], all sized from one cell size.
  Widget _playfield(bool compact) => LayoutBuilder(
        builder: (context, box) {
          final gap = 10.w;
          final panelCells = compact ? 2.9 : 3.2;
          final totalCells = boardCols + 2 * panelCells;
          final cell = math.min(
            (box.maxWidth - 2 * gap) / totalCells,
            box.maxHeight / visibleRows,
          );
          final boardW = cell * boardCols;
          final boardH = cell * visibleRows;
          final panelW = cell * panelCells;

          return Center(
            child: SizedBox(
              width: boardW + 2 * panelW + 2 * gap,
              height: boardH,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: panelW,
                    child: _leftPanel(panelW, compact),
                  ),
                  SizedBox(width: gap),
                  SizedBox(
                    width: boardW,
                    height: boardH,
                    child: Stack(
                      clipBehavior: Clip.none,
                      fit: StackFit.expand,
                      children: [
                        // Glowing frame, drawn just outside the board.
                        Positioned(
                          left: -4,
                          top: -4,
                          right: -4,
                          bottom: -4,
                          child: IgnorePointer(
                            child: LevelAccent(
                              engine: _engine,
                              builder: (context, accent, _) => DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius:
                                      BorderRadius.circular(cell * .5),
                                  border: Border.all(
                                    color: accent.withValues(alpha: .55),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: accent.withValues(alpha: .28),
                                      blurRadius: cell * .9,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        TouchControls(
                          engine: _engine,
                          cellSize: cell,
                          child: RepaintBoundary(
                            child: CustomPaint(painter: _boardPainter),
                          ),
                        ),
                        BannerText(engine: _engine),
                        // Last, so it covers (and blocks touches to) the
                        // board while READY, PAUSED or GAME OVER.
                        GameOverlay(engine: _engine, showKeyHint: !_isTouch),
                      ],
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

  /// The four stat tiles, in display order.
  List<Widget> _statTiles() => [
        StatTile(label: 'SCORE', value: '${_engine.score}'),
        StatTile(
          label: 'BEST',
          value: '${_engine.best}',
          accent: GameColors.gold,
        ),
        StatTile(
          label: 'LEVEL',
          value: '${_engine.level}',
          accent: GameColors.accentForLevel(_engine.level),
          progress: (_engine.lines % GameEngine.linesPerLevel) /
              GameEngine.linesPerLevel,
        ),
        StatTile(label: 'LINES', value: '${_engine.lines}'),
      ];

  /// Phone layout: the stats in one row above the board.
  Widget _statsStrip() => ListenableBuilder(
        listenable: _engine,
        builder: (_, __) {
          final tiles = _statTiles();
          return Row(
            children: [
              for (var i = 0; i < tiles.length; i++) ...[
                if (i > 0) SizedBox(width: 6.w),
                Expanded(child: tiles[i]),
              ],
            ],
          );
        },
      );

  Widget _leftPanel(double width, bool compact) => Column(
        children: [
          // Tapping the HOLD box swaps the piece (touch control).
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _engine.holdPiece,
            child: PanelBox(
              label: 'HOLD',
              accent: GameColors.accentAlt,
              child: SizedBox(
                height: PiecesPainter.heightFor(width, 1),
                child: CustomPaint(painter: _holdPainter),
              ),
            ),
          ),
          if (!compact) ...[
            SizedBox(height: 16.h),
            ListenableBuilder(
              listenable: _engine,
              builder: (_, __) {
                final tiles = _statTiles();
                return Column(
                  children: [
                    for (var i = 0; i < tiles.length; i++) ...[
                      if (i > 0) SizedBox(height: 12.h),
                      tiles[i],
                    ],
                  ],
                );
              },
            ),
          ],
        ],
      );

  Widget _rightPanel(double width) => Column(
        children: [
          PanelBox(
            label: 'NEXT',
            accent: GameColors.accent,
            child: SizedBox(
              height: PiecesPainter.heightFor(width, _nextSlots),
              child: CustomPaint(painter: _nextPainter),
            ),
          ),
          SizedBox(height: 16.h),
          StatusChips(engine: _engine),
        ],
      );
}

/// Brand bar: logo mark, gradient title, and the pause / restart buttons.
class _Header extends StatelessWidget {
  const _Header({required this.engine});

  final GameEngine engine;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const _LogoMark(),
        SizedBox(width: 10.w),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (rect) => GameColors.brand.createShader(rect),
                child: Text(
                  'TETRIS PRO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                  ),
                ),
              ),
            ),
          ),
        ),
        ListenableBuilder(
          listenable: engine,
          builder: (_, __) {
            final phase = engine.phase;
            final paused = phase == GamePhase.paused;
            final canToggle = paused ||
                phase == GamePhase.playing ||
                phase == GamePhase.clearing;
            final canRestart = phase != GamePhase.ready;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _HeaderButton(
                  tooltip: 'Restart',
                  icon: Icons.refresh_rounded,
                  onPressed: canRestart ? engine.start : null,
                ),
                SizedBox(width: 8.w),
                _HeaderButton(
                  tooltip: paused ? 'Resume' : 'Pause',
                  icon: paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                  onPressed: canToggle ? engine.togglePause : null,
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      tooltip: tooltip,
      onPressed: onPressed,
      iconSize: 22.r,
      icon: Icon(icon),
      style: IconButton.styleFrom(
        backgroundColor: GameColors.surfaceHigh,
        foregroundColor: Colors.white,
        disabledBackgroundColor: GameColors.surface.withValues(alpha: .5),
        disabledForegroundColor: GameColors.textFaint,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
          side: const BorderSide(color: GameColors.border),
        ),
      ),
    );
  }
}

/// Tiny T-tetromino built from the piece colours.
class _LogoMark extends StatelessWidget {
  const _LogoMark();

  @override
  Widget build(BuildContext context) {
    final s = 8.r;
    Widget block(Color? color) => Container(
          width: s,
          height: s,
          margin: EdgeInsets.all(1.r),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2.r),
            boxShadow: color == null
                ? null
                : [BoxShadow(color: color.withValues(alpha: .6), blurRadius: 6)],
          ),
        );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [block(null), block(pieceColors[2]), block(null)],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            block(pieceColors[0]),
            block(pieceColors[5]),
            block(pieceColors[3]),
          ],
        ),
      ],
    );
  }
}
