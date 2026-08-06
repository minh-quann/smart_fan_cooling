import 'package:flutter/material.dart';
import 'package:smart_fan_cooling/core/theme/app_colors.dart';
import 'package:smart_fan_cooling/shared/widgets/app_text.dart';

/// SettingSwitchTile renders a modern hardware setting toggle tile matching Image 1 request.
class SettingSwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  const SettingSwitchTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Row(
          children: [
            Icon(
              icon,
              color: value ? AppColors.primary : AppColors.textMuted,
              size: 22,
            ),
            const SizedBox(width: 14),

            // Setting Title & Subtitle Labels
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    title,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  const SizedBox(height: 2),
                  AppText.caption(subtitle),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Modern Switch Toggle Control
            Switch(
              value: value,
              activeTrackColor: AppColors.primary.withValues(alpha: 0.35),
              activeThumbColor: AppColors.primary,
              inactiveTrackColor: AppColors.surfaceLight,
              inactiveThumbColor: AppColors.textMuted,
              trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}
