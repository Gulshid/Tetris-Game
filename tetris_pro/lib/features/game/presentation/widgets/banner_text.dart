import 'package:flutter/material.dart';

import '../../../../core/theme/game_colors.dart';
import '../../../../engine/engine.dart';

/// Floating text for "TETRIS", "T-SPIN DOUBLE", "BACK-TO-BACK", "COMBO x3".
/// Lives on top of the board, ignores touches, pops in, and fades out with
/// the engine's banner timer. Each line gets its own colour.
class BannerText extends StatelessWidget {
  const BannerText({super.key, required this.engine});

  final GameEngine engine;

  static Color _lineColor(String line) {
    if (line.contains('T-SPIN')) return GameColors.accentAlt;
    if (line.contains('TETRIS')) return GameColors.accent;
    if (line.startsWith('COMBO')) return GameColors.orange;
    if (line.contains('BACK-TO-BACK')) return GameColors.gold;
    if (line.startsWith('LEVEL')) return GameColors.success;
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ListenableBuilder(
        listenable: engine,
        builder: (context, _) {
          final text = engine.banner;
          final fade = engine.bannerFade;
          if (text.isEmpty || fade <= 0) return const SizedBox.shrink();

          return LayoutBuilder(
            builder: (context, box) {
              final u = box.maxWidth / 10;
              final lines = text.split('\n');
              return Align(
                alignment: const Alignment(0, -.45),
                child: Opacity(
                  opacity: fade,
                  child: TweenAnimationBuilder<double>(
                    key: ValueKey(text),
                    tween: Tween<double>(begin: .65, end: 1),
                    duration: const Duration(milliseconds: 380),
                    curve: Curves.easeOutBack,
                    builder: (context, scale, child) =>
                        Transform.scale(scale: scale, child: child),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: u * .4),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (var i = 0; i < lines.length; i++)
                              Text(
                                lines[i],
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: i == 0
                                      ? Colors.white
                                      : _lineColor(lines[i]),
                                  fontSize: i == 0 ? u * .95 : u * .55,
                                  height: 1.3,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: i == 0 ? 1.5 : 2,
                                  shadows: [
                                    Shadow(
                                      color: _lineColor(lines[i]),
                                      blurRadius: 14,
                                    ),
                                    const Shadow(
                                      color: Colors.black,
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
