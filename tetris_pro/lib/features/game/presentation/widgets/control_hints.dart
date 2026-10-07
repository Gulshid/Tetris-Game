import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/game_colors.dart';

/// Controls cheat-sheet drawn as key caps with short labels.
class ControlHints extends StatelessWidget {
  const ControlHints({super.key, required this.touch});

  /// True on phones/tablets (gesture hints), false for keyboard hints.
  final bool touch;

  static const List<(String, String)> _keyboard = [
    ('← →', 'Move'),
    ('↓', 'Soft drop'),
    ('Space', 'Hard drop'),
    ('↑ / X', 'Rotate'),
    ('Z', 'Rotate back'),
    ('C', 'Hold'),
    ('P', 'Pause'),
    ('R', 'Restart'),
  ];

  static const List<(String, String)> _touch = [
    ('TAP', 'Rotate'),
    ('DRAG', 'Move / soft drop'),
    ('FLICK ↓', 'Hard drop'),
    ('HOLD BOX', 'Hold'),
  ];

  @override
  Widget build(BuildContext context) {
    final items = touch ? _touch : _keyboard;
    return Wrap(
      alignment: WrapAlignment.center,
      runAlignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 14.w,
      runSpacing: 6.h,
      children: [
        for (final (keys, label) in items) _Hint(keys: keys, label: label),
      ],
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.keys, required this.label});

  final String keys;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
          decoration: BoxDecoration(
            color: GameColors.surfaceHigh,
            borderRadius: BorderRadius.circular(5.r),
            border: Border.all(color: GameColors.borderStrong),
            boxShadow: const [
              BoxShadow(color: Colors.black54, offset: Offset(0, 1.5)),
            ],
          ),
          child: Text(
            keys,
            style: TextStyle(
              color: Colors.white,
              fontSize: 10.sp,
              fontWeight: FontWeight.w800,
              letterSpacing: .5,
            ),
          ),
        ),
        SizedBox(width: 5.w),
        Text(
          label,
          style: TextStyle(
            color: GameColors.textDim,
            fontSize: 10.5.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
