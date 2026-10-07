import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/game_colors.dart';
import 'glass_card.dart';

/// A labelled glass box used for HOLD and NEXT.
///
/// The [child] gets the full width of the box (no inner padding), because the
/// piece painters size themselves from it.
class PanelBox extends StatelessWidget {
  const PanelBox({
    super.key,
    required this.label,
    required this.child,
    this.accent,
  });

  final String label;
  final Widget child;

  /// Colour of the label dot and of the soft halo around the box.
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final radius = 12.r;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 5.r,
                height: 5.r,
                decoration: BoxDecoration(
                  color: accent ?? GameColors.accent,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 5.w),
              Text(
                label,
                style: TextStyle(
                  color: GameColors.textDim,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 6.h),
        SizedBox(
          width: double.infinity,
          child: GlassCard(
            radius: radius,
            glow: accent,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: child,
            ),
          ),
        ),
      ],
    );
  }
}
