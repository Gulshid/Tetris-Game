import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tetris_pro/engine/engine.dart';
import 'package:tetris_pro/features/game/presentation/input/touch_controls.dart';

import 'helpers/engine_helpers.dart';
import 'helpers/fixed_generator.dart';

const double _cell = 20;
const double _w = _cell * boardCols;
const double _h = _cell * visibleRows;

GameEngine _engine() =>
    GameEngine(generator: FixedGenerator([Tetromino.t]))..start();

Future<void> _pump(WidgetTester tester, GameEngine e) => tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: _w,
            height: _h,
            child: TouchControls(
              engine: e,
              cellSize: _cell,
              child: const ColoredBox(color: Colors.black),
            ),
          ),
        ),
      ),
    );

void main() {
  testWidgets('tap right half rotates clockwise, left half back', (t) async {
    final e = _engine();
    await _pump(t, e);
    final box = t.getRect(find.byType(TouchControls));

    await t.tapAt(box.topLeft + const Offset(_w * .75, 100));
    expect(e.current!.rotation, 1);

    await t.tapAt(box.topLeft + const Offset(_w * .25, 100));
    expect(e.current!.rotation, 0);
  });

  testWidgets('dragging sideways moves the piece', (t) async {
    final e = _engine();
    await _pump(t, e);
    final x0 = e.current!.x;
    await t.drag(find.byType(TouchControls), const Offset(-_cell * 2.5, 0));
    expect(e.current!.x, lessThan(x0));
  });

  testWidgets('dragging down soft drops the piece', (t) async {
    final e = _engine();
    await _pump(t, e);
    final y0 = e.current!.y;
    await t.drag(find.byType(TouchControls), const Offset(0, _cell * 3));
    expect(e.current!.y, greaterThan(y0));
    expect(e.score, greaterThan(0));
  });

  testWidgets('fast downward flick hard drops and locks', (t) async {
    final e = _engine();
    await _pump(t, e);
    await t.fling(find.byType(TouchControls), const Offset(0, 200), 3000);
    expect(filledCells(e.board), 4);
    expect(e.current, isNotNull); // next piece already spawned
  });

  testWidgets('tapping a finished game restarts it after the delay',
      (t) async {
    final e = _engine();
    await _pump(t, e);
    // Stack pieces in the spawn column until the game ends.
    while (e.phase == GamePhase.playing) {
      e.hardDrop();
    }
    expect(e.phase, GamePhase.over);

    final centre = t.getCenter(find.byType(TouchControls));
    await t.tapAt(centre); // too soon: ignored
    expect(e.phase, GamePhase.over);

    await t.runAsync(
      () => Future<void>.delayed(
        TouchControls.restartDelay + const Duration(milliseconds: 50),
      ),
    );
    await t.tapAt(centre);
    expect(e.phase, GamePhase.playing);
  });
}
