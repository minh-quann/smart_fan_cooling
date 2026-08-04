import 'package:flutter/material.dart';
import 'package:smart_fan_cooling/core/theme/app_colors.dart';

/// TechCard / GlassCard - Compact, data-dense container for hardware telemetry.
/// Features sharp 8px corners, 1px precision border, and optional left accent indicator bar.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? leftAccentColor;
  final double borderRadius;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderColor,
    this.leftAccentColor,
    this.borderRadius = 8.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardBorder = RoundedSuperellipseBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      side: BorderSide(
        color: borderColor ?? AppColors.border,
        width: 1.0,
      ),
    );

    Widget content = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      padding: padding ?? const EdgeInsets.all(14.0),
      margin: margin,
      decoration: ShapeDecoration(
        color: backgroundColor ?? AppColors.cardBg,
        shape: cardBorder,
      ),
      child: child,
    );

    if (leftAccentColor != null) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: leftAccentColor!, width: 3.5),
            ),
          ),
          child: content,
        ),
      );
    }

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
