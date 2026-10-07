import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tetris_pro/core/storage/high_score_keeper.dart';
import 'package:tetris_pro/core/storage/high_score_store.dart';
import 'package:tetris_pro/engine/engine.dart';

import 'helpers/fixed_generator.dart';

GameEngine _engine() =>
    GameEngine(generator: FixedGenerator([Tetromino.o]));

/// Plays O pieces straight down until the stack reaches the top.
void _playUntilGameOver(GameEngine e) {
  e.start();
  while (e.phase == GamePhase.playing) {
    e.hardDrop();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SharedPrefsHighScoreStore', () {
    test('returns 0 when nothing was saved', () async {
      SharedPreferences.setMockInitialValues({});
      expect(await const SharedPrefsHighScoreStore().load(), 0);
    });

    test('loads an existing value', () async {
      SharedPreferences.setMockInitialValues({'best': 1234});
      expect(await const SharedPrefsHighScoreStore().load(), 1234);
    });

    test('a saved score survives a "restart" (new store instance)', () async {
      SharedPreferences.setMockInitialValues({});
      await const SharedPrefsHighScoreStore().save(4200);
      expect(await const SharedPrefsHighScoreStore().load(), 4200);
    });

    test('a corrupt value is ignored instead of crashing', () async {
      SharedPreferences.setMockInitialValues({'best': 'not a number'});
      expect(await const SharedPrefsHighScoreStore().load(), 0);
    });

    test('a negative value is treated as 0', () async {
      SharedPreferences.setMockInitialValues({'best': -50});
      expect(await const SharedPrefsHighScoreStore().load(), 0);
    });
  });

  group('HighScoreKeeper', () {
    test('load puts the saved score into the engine', () async {
      final e = _engine();
      final keeper = HighScoreKeeper(
        engine: e,
        store: MemoryHighScoreStore(900),
      );
      await keeper.load();
      expect(e.best, 900);
    });

    test('load notifies listeners so BEST redraws', () async {
      final e = _engine();
      var notified = 0;
      e.addListener(() => notified++);
      await HighScoreKeeper(engine: e, store: MemoryHighScoreStore(900)).load();
      expect(notified, greaterThan(0));
    });

    test('a slow load never lowers a record set in the meantime', () async {
      final e = _engine()..best = 5000;
      await HighScoreKeeper(engine: e, store: MemoryHighScoreStore(900)).load();
      expect(e.best, 5000);
    });

    test('load after dispose does not touch the engine', () async {
      final e = _engine();
      final keeper =
          HighScoreKeeper(engine: e, store: MemoryHighScoreStore(900));
      keeper.dispose();
      await keeper.load();
      expect(e.best, 0);
    });

    test('a new record is saved when the game ends', () async {
      final store = MemoryHighScoreStore(0);
      final e = _engine();
      final keeper = HighScoreKeeper(engine: e, store: store);

      _playUntilGameOver(e);
      expect(e.newBest, true);
      await keeper.saveIfNewBest();
      expect(store.value, e.best);
      expect(store.value, greaterThan(0));
    });

    test('a lower score does not overwrite the saved record', () async {
      final store = MemoryHighScoreStore(1000000);
      final e = _engine();
      final keeper = HighScoreKeeper(engine: e, store: store);
      await keeper.load();

      _playUntilGameOver(e);
      expect(e.newBest, false);
      await keeper.saveIfNewBest();
      expect(store.value, 1000000);
    });

    test('full cycle: play, save, "relaunch", BEST is still there', () async {
      SharedPreferences.setMockInitialValues({});
      const store = SharedPrefsHighScoreStore();

      final first = _engine();
      final keeper1 = HighScoreKeeper(engine: first, store: store);
      await keeper1.load();
      _playUntilGameOver(first);
      await keeper1.saveIfNewBest();
      final record = first.best;
      expect(record, greaterThan(0));

      final second = _engine(); // a fresh launch
      await HighScoreKeeper(engine: second, store: store).load();
      expect(second.best, record);
    });

    test('works with the engine game-over event, as the page wires it',
        () async {
      final store = MemoryHighScoreStore(0);
      final e = _engine();
      final keeper = HighScoreKeeper(engine: e, store: store);
      e.onEvent = (event) {
        if (event == GameEvent.over) keeper.saveIfNewBest();
      };

      _playUntilGameOver(e);
      await Future<void>.delayed(Duration.zero); // let the save finish
      expect(store.value, e.best);
    });
  });
}
