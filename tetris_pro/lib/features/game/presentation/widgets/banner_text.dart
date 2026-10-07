import 'package:flutter/material.dart';

import '../../../../engine/engine.dart';

/// Floating text for "TETRIS", "T-SPIN DOUBLE", "BACK-TO-BACK", "COMBO x3".
/// Lives on top of the board, ignores touches, and fades out with the
/// engine's banner timer.
class BannerText extends StatelessWidget {
  const BannerText({super.key, required this.engine});

  final GameEngine engine;

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
              return Align(
                alignment: const Alignment(0, -.45),
                child: Opacity(
                  opacity: fade,
                  child: Text(
                    text,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: u * .9,
                      height: 1.25,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      shadows: const [
                        Shadow(color: Color(0xFF00E5FF), blurRadius: 12),
                        Shadow(color: Colors.black, blurRadius: 4),
                      ],
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
