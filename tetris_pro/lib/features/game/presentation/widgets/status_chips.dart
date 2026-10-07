import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/game_colors.dart';
import '../../../../engine/engine.dart';

/// Two small indicators: BACK-TO-BACK armed, and the running COMBO count.
/// They are always visible (dim when inactive) so the layout never jumps.
class StatusChips extends StatelessWidget {
  const StatusChips({super.key, required this.engine});

  final GameEngine engine;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: engine,
      builder: (context, _) {
        final combo = engine.combo;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Chip(
              label: 'B2B',
              active: engine.backToBack,
              color: GameColors.gold,
            ),
            SizedBox(height: 6.h),
            _Chip(
              label: combo > 0 ? 'COMBO x$combo' : 'COMBO',
              active: combo > 0,
              color: GameColors.orange,
            ),
          ],
        );
      },
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.active,
    required this.color,
  });

  final String label;
  final bool active;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 5.h, horizontal: 4.w),
      decoration: BoxDecoration(
        color: active
            ? color.withValues(alpha: .16)
            : Colors.white.withValues(alpha: .03),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: active ? color.withValues(alpha: .7) : GameColors.border,
        ),
        boxShadow: active
            ? [BoxShadow(color: color.withValues(alpha: .35), blurRadius: 10)]
            : const [],
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          style: TextStyle(
            color: active ? color : GameColors.textFaint,
            fontSize: 10.sp,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}
