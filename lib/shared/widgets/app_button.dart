import 'package:flutter/material.dart';
import 'package:smart_fan_cooling/core/theme/app_colors.dart';
import 'package:smart_fan_cooling/shared/widgets/app_text.dart';

/// AppButton is a reusable action button widget.
/// Adheres strictly to Flutter rule #10: Always use RoundedSuperellipseBorder.
class AppButton extends StatelessWidget {
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
    this.borderRadius = 12.0,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isOutlined
        ? Colors.transparent
        : (backgroundColor ?? AppColors.primary);
    final txtColor = textColor ??
        (isOutlined ? AppColors.textPrimary : Colors.black);
    final borderSide = BorderSide(
      color: borderColor ?? (isOutlined ? AppColors.borderLight : bgColor),
      width: 1.5,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        customBorder: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: borderSide,
        ),
        child: Ink(
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: ShapeDecoration(
            color: bgColor,
            shape: RoundedSuperellipseBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              side: borderSide,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: txtColor),
                const SizedBox(width: 8),
              ],
              AppText(
                label,
                color: txtColor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
