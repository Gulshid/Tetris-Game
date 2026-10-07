import 'package:flutter/foundation.dart' show debugPrint;
import 'package:shared_preferences/shared_preferences.dart';

/// Where the best score lives between app launches.
///
/// An interface so the game (and its tests) never depend on the plugin
/// directly. Implementations must never throw: a broken or missing storage
/// should cost the player their saved record, not crash the game.
abstract interface class HighScoreStore {
  /// The saved best score, or 0 if there is none (or it can't be read).
  Future<int> load();

  /// Saves [score] as the new best. Failures are swallowed.
  Future<void> save(int score);
}

/// Saves the best score with `shared_preferences`
/// (SharedPreferences on Android, NSUserDefaults on iOS, localStorage on web,
/// a small file on desktop).
class SharedPrefsHighScoreStore implements HighScoreStore {
  const SharedPrefsHighScoreStore();

  /// Storage key. Kept as `best` to match the build guide.
  static const String key = 'best';

  @override
  Future<int> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getInt(key) ?? 0;
      return value < 0 ? 0 : value;
    } catch (e) {
      debugPrint('HighScoreStore.load failed: $e');
      return 0;
    }
  }

  @override
  Future<void> save(int score) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(key, score);
    } catch (e) {
      debugPrint('HighScoreStore.save failed: $e');
    }
  }
}

/// Keeps the score in memory only. For tests, previews and as a fallback.
class MemoryHighScoreStore implements HighScoreStore {
  MemoryHighScoreStore([this.value = 0]);

  /// The "saved" score; readable in tests.
  int value;

  @override
  Future<int> load() async => value;

  @override
  Future<void> save(int score) async => value = score;
}
