import 'package:flutter/material.dart';
import 'package:smart_fan_cooling/core/theme/app_colors.dart';

/// TechCard / GlassCard - Compact, data-dense container for hardware telemetry.
/// Features sharp 8px corners, 1px precision border, and optional left accent indicator bar.
class GlassCard extends StatefulWidget {
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
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final effectiveBorderColor = widget.borderColor ??
        (_isHovered && widget.onTap != null ? AppColors.borderLight : AppColors.border);

    final cardBorder = RoundedSuperellipseBorder(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      side: BorderSide(
        color: effectiveBorderColor,
        width: 1.0,
      ),
    );

    Widget content = MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        padding: widget.padding ?? const EdgeInsets.all(14.0),
        margin: widget.margin,
        decoration: ShapeDecoration(
          color: widget.backgroundColor ??
              (_isHovered && widget.onTap != null ? AppColors.surfaceLight : AppColors.cardBg),
          shape: cardBorder,
        ),
        child: widget.child,
      ),
    );

    if (widget.leftAccentColor != null) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: widget.leftAccentColor!, width: 3.5),
            ),
          ),
          child: content,
        ),
      );
    }

    if (widget.onTap != null) {
      return InkWell(
        onTap: widget.onTap,
        customBorder: cardBorder,
        child: content,
      );
    }

    return content;
  }
}
