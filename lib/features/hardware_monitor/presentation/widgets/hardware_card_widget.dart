import 'package:flutter/material.dart';
import 'package:smart_fan_cooling/core/theme/app_colors.dart';
import 'package:smart_fan_cooling/shared/widgets/app_text.dart';
import 'package:smart_fan_cooling/shared/widgets/glass_card.dart';

class HardwareCardWidget extends StatelessWidget {
  final String title;
  final String subTitle;
  final String valueText;
  final String unitText;
  final IconData icon;
  final Color accentColor;
  final double? progressPercent; // 0.0 to 100.0
  final List<Widget>? extraPills;

  const HardwareCardWidget({
    super.key,
    required this.title,
    required this.subTitle,
    required this.valueText,
    required this.unitText,
    required this.icon,
    required this.accentColor,
    this.progressPercent,
    this.extraPills,
  });

  Widget _buildAnimatedValue(String text, String unit, Color color) {
    final double? targetVal = double.tryParse(text);
    if (targetVal == null) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          AppText(
            text,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: color,
            isMonospace: true,
          ),
          const SizedBox(width: 2),
          AppText(
            unit,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ],
      );
    }

    final int decimals = text.contains('.') ? text.split('.')[1].length : 0;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: targetVal),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, animVal, child) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            AppText(
              animVal.toStringAsFixed(decimals),
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: color,
              isMonospace: true,
            ),
            const SizedBox(width: 2),
            AppText(
              unit,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      borderRadius: 8,
      leftAccentColor: accentColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: ShapeDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        shape: RoundedSuperellipseBorder(
                          borderRadius: BorderRadius.circular(6),
                          side: BorderSide(color: accentColor.withValues(alpha: 0.25)),
                        ),
                      ),
                      child: Icon(icon, color: accentColor, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(
                            title,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          const SizedBox(height: 1),
                          AppText(
                            subTitle,
                            fontSize: 10.5,
                            color: AppColors.textMuted,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _buildAnimatedValue(valueText, unitText, accentColor),
            ],
          ),
          const SizedBox(height: 12),

          // Progress Bar with smooth animation
          if (progressPercent != null) ...[
            TweenAnimationBuilder<double>(
              tween: Tween<double>(end: (progressPercent! / 100.0).clamp(0.0, 1.0)),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              builder: (context, animProgress, child) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: animProgress,
                    backgroundColor: AppColors.surfaceLight,
                    valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                    minHeight: 4,
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
          ],

          // Extra Telemetry Metrics Row
          if (extraPills != null && extraPills!.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: extraPills!,
            ),
        ],
      ),
    );
  }
}
