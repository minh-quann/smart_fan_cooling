import 'package:flutter/material.dart';
import 'package:smart_fan_cooling/core/theme/app_colors.dart';

/// GlassCard is a reusable container card widget with subtle border & background glow.
/// Adheres strictly to Flutter rule #10: Always use RoundedSuperellipseBorder.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderRadius;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius = 16.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardBorder = RoundedSuperellipseBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      side: BorderSide(
        color: borderColor ?? AppColors.border,
        width: 1.5,
      ),
    );

    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: padding ?? const EdgeInsets.all(16.0),
      margin: margin,
      decoration: ShapeDecoration(
        color: backgroundColor ?? AppColors.cardBg,
        shape: cardBorder,
        shadows: const [
          BoxShadow(
            color: Color(0x20000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        customBorder: cardBorder,
        child: content,
      );
    }

    return content;
  }
}
