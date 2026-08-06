import 'package:flutter/material.dart';
import 'package:smart_fan_cooling/core/theme/app_colors.dart';
import 'package:smart_fan_cooling/shared/widgets/app_text.dart';

/// AppButton is a reusable action button widget styled after precision industrial UI controls.
class AppButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? borderColor;
  final bool isOutlined;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;

  const AppButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
    this.isOutlined = false,
    this.borderRadius = 8.0,
    this.padding,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final baseBgColor = widget.isOutlined
        ? Colors.transparent
        : (widget.backgroundColor ?? AppColors.primary);

    final txtColor = widget.textColor ??
        (widget.isOutlined
            ? AppColors.textPrimary
            : (baseBgColor == AppColors.primary ? Colors.white : Colors.black));

    final borderSide = BorderSide(
      color: widget.borderColor ??
          (widget.isOutlined
              ? (_isHovered ? AppColors.primary : AppColors.border)
              : baseBgColor),
      width: 1.2,
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.onPressed != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onPressed,
          customBorder: RoundedSuperellipseBorder(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            side: borderSide,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: ShapeDecoration(
              color: _isHovered && !widget.isOutlined
                  ? Color.alphaBlend(Colors.white.withValues(alpha: 0.12), baseBgColor)
                  : baseBgColor,
              shape: RoundedSuperellipseBorder(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                side: borderSide,
              ),
              shadows: _isHovered && widget.onPressed != null && !widget.isOutlined
                  ? [
                      BoxShadow(
                        color: baseBgColor.withValues(alpha: 0.4),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, size: 16, color: txtColor),
                  const SizedBox(width: 8),
                ],
                AppText(
                  widget.label,
                  color: txtColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
