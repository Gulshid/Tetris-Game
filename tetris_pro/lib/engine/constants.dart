/// Board geometry. Row 0 is the top, y grows downward.
const int boardCols = 10;
const int boardRows = 22;

/// The top rows are the hidden spawn area.
const int hiddenRows = 2;
const int visibleRows = boardRows - hiddenRows;

/// A single (x, y) coordinate on the board or inside a piece box.
typedef Cell = ({int x, int y});

/// High level state of a game session.
enum GamePhase { ready, playing, clearing, paused, over }
