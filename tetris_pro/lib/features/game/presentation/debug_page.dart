import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../engine/engine.dart';

/// Temporary Phase 2 screen: draws the engine as monospaced text so you can
/// verify spawning and gravity before real rendering arrives in Phase 3.
/// Replaced by the real GamePage in Phase 3.
class DebugPage extends StatefulWidget {
  const DebugPage({super.key});

  @override
  State<DebugPage> createState() => _DebugPageState();
}

class _DebugPageState extends State<DebugPage>
    with SingleTickerProviderStateMixin {
  final GameEngine engine = GameEngine();
  late final Ticker _ticker;
  Duration _last = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      final dt = (elapsed - _last).inMicroseconds / 1e6;
      _last = elapsed;
      engine.update(dt);
    })..start();
    engine.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    engine.dispose();
    super.dispose();
  }

  String _ascii() {
    final piece = engine.current;
    final live = {for (final c in piece?.cells ?? const <Cell>[]) c};
    final buf = StringBuffer();
    for (var y = hiddenRows; y < boardRows; y++) {
      for (var x = 0; x < boardCols; x++) {
        final isLive = live.contains((x: x, y: y));
        buf.write(isLive || engine.board.at(x, y) != 0 ? '[]' : ' .');
      }
      buf.writeln();
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        // LayoutBuilder sizes the board; ScreenUtil (.sp/.h) sizes the HUD.
        child: LayoutBuilder(
          builder: (context, box) {
            // 20 monospace chars wide (glyph width ~ 0.6 x font size)
            final byWidth = box.maxWidth * .9 / (boardCols * 2 * .6);
            final byHeight = box.maxHeight * .8 / (visibleRows * 1.1);
            final boardFont = math.min(byWidth, byHeight).clamp(8.0, 40.0);

            return Center(
              child: ListenableBuilder(
                listenable: engine,
                builder: (context, _) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${engine.phase.name}  ${engine.current}',
                      style: TextStyle(color: Colors.white70, fontSize: 14.sp),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      _ascii(),
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: boardFont.toDouble(),
                        height: 1.1,
                        color: Colors.cyanAccent,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
