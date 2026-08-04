import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_fan_cooling/core/theme/app_colors.dart';

/// AppText is the standard text component across the entire app.
/// Automatically applies Google Sans / Outfit / Inter fonts depending on style.
/// NOTE: According to project rules, height (lineHeight) is NEVER specified in TextStyle.
class AppText extends StatelessWidget {
  final String text;
  final double? fontSize;
  final FontWeight? fontWeight;
  final Color? color;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;
  final TextStyle? style;
  final bool isMonospace;

  const AppText(
    this.text, {
    super.key,
    this.fontSize,
    this.fontWeight,
    this.color,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.style,
    this.isMonospace = false,
  });

  factory AppText.h1(
    String text, {
    Key? key,
    Color? color,
    TextAlign? textAlign,
    int? maxLines,
    TextOverflow? overflow,
  }) {
    return AppText(
      text,
      key: key,
      fontSize: 24,
      fontWeight: FontWeight.w700,
      color: color ?? AppColors.textPrimary,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  factory AppText.h2(
    String text, {
    Key? key,
    Color? color,
    TextAlign? textAlign,
    int? maxLines,
    TextOverflow? overflow,
  }) {
    return AppText(
      text,
      key: key,
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: color ?? AppColors.textPrimary,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  factory AppText.body(
    String text, {
    Key? key,
    Color? color,
    TextAlign? textAlign,
    int? maxLines,
    TextOverflow? overflow,
  }) {
    return AppText(
      text,
      key: key,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: color ?? AppColors.textSecondary,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  factory AppText.caption(
    String text, {
    Key? key,
    Color? color,
    TextAlign? textAlign,
    int? maxLines,
    TextOverflow? overflow,
  }) {
    return AppText(
      text,
      key: key,
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: color ?? AppColors.textMuted,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  @override
  Widget build(BuildContext context) {
    final defaultStyle = isMonospace
        ? GoogleFonts.firaCode(
            fontSize: fontSize ?? 14,
            fontWeight: fontWeight ?? FontWeight.w400,
            color: color ?? AppColors.textPrimary,
            // height is deliberately omitted as per project rule #9
          )
        : GoogleFonts.outfit(
            fontSize: fontSize ?? 14,
            fontWeight: fontWeight ?? FontWeight.w400,
            color: color ?? AppColors.textPrimary,
            // height is deliberately omitted as per project rule #9
          );

    final effectiveStyle = style != null
        ? style!.copyWith(
            color: color ?? style!.color,
            fontSize: fontSize ?? style!.fontSize,
            fontWeight: fontWeight ?? style!.fontWeight,
            // height is explicitly set to null to avoid lineHeight issues
            height: null,
          )
        : defaultStyle;

    return Text(
      text,
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
      style: effectiveStyle,
    );
  }
}
