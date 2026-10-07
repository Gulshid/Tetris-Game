import 'package:flutter/material.dart';

import '../../../../core/theme/game_colors.dart';

/// Shared "glass" surface: gradient fill, hairline border, soft drop shadow
/// and an optional coloured glow. The border is painted, not laid out, so it
/// never changes the size of [child].
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.radius = 12,
    this.glow,
    this.borderColor,
    this.gradient = GameColors.panel,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  /// When set, a soft halo of this colour surrounds the card.
  final Color? glow;
  final Color? borderColor;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? GameColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .35),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
          if (glow != null)
            BoxShadow(
              color: glow!.withValues(alpha: .20),
              blurRadius: 18,
            ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
