import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/game_colors.dart';

/// A labelled, framed box used for HOLD and NEXT.
class PanelBox extends StatelessWidget {
  const PanelBox({
    super.key,
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: GameColors.textDim,
            fontSize: 11.sp,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
        SizedBox(height: 6.h),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: GameColors.boardFill,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: const Color(0x1FFFFFFF)),
          ),
          child: child,
        ),
      ],
    );
  }
}
