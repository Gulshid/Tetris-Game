import '../../engine/engine.dart';
import 'high_score_store.dart';

/// Connects a [GameEngine] to a [HighScoreStore].
///
/// - [load] runs once at start-up and feeds the saved record to the engine.
/// - [saveIfNewBest] runs when a game ends.
///
/// No widgets here, so the rules are easy to unit-test.
class HighScoreKeeper {
  HighScoreKeeper({required this.engine, required this.store});

  final GameEngine engine;
  final HighScoreStore store;

  bool _disposed = false;

  /// Reads the saved best score into the engine.
  ///
  /// Loading is asynchronous, so the player may already have finished a game
  /// by the time it completes. The higher of the two values always wins.
  Future<void> load() async {
    final saved = await store.load();
    if (_disposed) return; // the screen is gone; don't touch the engine
    if (saved > engine.best) engine.best = saved; // setter notifies the UI
  }

  /// Writes the best score if the game that just ended set a new record.
  /// Call it from the engine's game-over event.
  Future<void> saveIfNewBest() async {
    if (!engine.newBest) return;
    await store.save(engine.best);
  }

  /// Stops [load] from touching the engine after the screen is closed.
  void dispose() => _disposed = true;
}
