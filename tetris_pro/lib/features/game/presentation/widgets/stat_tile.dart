import 'dart:math' as math;
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/game_colors.dart';
import 'glass_card.dart';

/// "LABEL / value" glass tile (SCORE, BEST, LEVEL, LINES).
///
/// The value pops briefly whenever it changes. An optional [progress] (0..1)
/// draws a thin bar under it, used by LEVEL for progress to the next level.
class StatTile extends StatefulWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.accent,
    this.progress,
  });

  final String label;
  final String value;

  /// Colour of the value (and of the progress bar). White when null.
  final Color? accent;

  /// 0..1, or null for no bar.
  final double? progress;

  @override
  State<StatTile> createState() => _StatTileState();
}

class _StatTileState extends State<StatTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  );

  @override
  void didUpdateWidget(covariant StatTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) _pulse.forward(from: 0);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.accent ?? Colors.white;
    final progress = widget.progress;

    return SizedBox(
      width: double.infinity,
      child: GlassCard(
        radius: 10.r,
        padding: EdgeInsets.symmetric(vertical: 7.h, horizontal: 4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                widget.label,
                style: TextStyle(
                  color: GameColors.textDim,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.8,
                ),
              ),
            ),
            SizedBox(height: 3.h),
            AnimatedBuilder(
              animation: _pulse,
              builder: (context, child) => Transform.scale(
                scale: 1 + .14 * math.sin(_pulse.value * math.pi),
                child: child,
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  widget.value,
                  style: TextStyle(
                    color: color,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w900,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
            if (progress != null) ...[
              SizedBox(height: 5.h),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(end: progress.clamp(0.0, 1.0).toDouble()),
                duration: const Duration(milliseconds: 300),
                builder: (context, value, _) => ClipRRect(
                  borderRadius: BorderRadius.circular(3.r),
                  child: LinearProgressIndicator(
                    value: value,
                    minHeight: 3.h,
                    backgroundColor: Colors.white.withValues(alpha: .08),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      widget.accent ?? GameColors.accent,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
