import 'package:flutter/material.dart';
import 'package:smart_fan_cooling/core/theme/app_colors.dart';
import 'package:smart_fan_cooling/shared/widgets/app_text.dart';

class DesktopHeader extends StatelessWidget {
  final String activeProfileName;
  final Color activeProfileColor;
  final bool isHardwareConnected;

  const DesktopHeader({
    super.key,
    required this.activeProfileName,
    required this.activeProfileColor,
    this.isHardwareConnected = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 52),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1.0),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Active Profile Status Indicator
            Row(
              children: [
                const AppText(
                  'PROFILE HIỆN TẠI:',
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textMuted,
                  isMonospace: true,
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: ShapeDecoration(
                    color: activeProfileColor.withValues(alpha: 0.12),
                    shape: RoundedSuperellipseBorder(
                      borderRadius: BorderRadius.circular(4),
                      side: BorderSide(color: activeProfileColor, width: 1.0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.bolt_rounded, size: 14, color: activeProfileColor),
                      const SizedBox(width: 4),
                      AppText(
                        activeProfileName.toUpperCase(),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: activeProfileColor,
                        isMonospace: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(width: 24),

            // Hardware & Platform Badges
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: ShapeDecoration(
                    color: AppColors.surfaceLight,
                    shape: RoundedSuperellipseBorder(
                      borderRadius: BorderRadius.circular(4),
                      side: const BorderSide(color: AppColors.border, width: 1.0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Theme.of(context).platform == TargetPlatform.windows
                            ? Icons.window_rounded
                            : Icons.computer_rounded,
                        size: 13,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 5),
                      AppText(
                        Theme.of(context).platform == TargetPlatform.windows
                            ? 'WINDOWS OS'
                            : 'LINUX OS',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                        isMonospace: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: ShapeDecoration(
                    color: isHardwareConnected
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : AppColors.statusOffline.withValues(alpha: 0.12),
                    shape: RoundedSuperellipseBorder(
                      borderRadius: BorderRadius.circular(4),
                      side: BorderSide(
                        color: isHardwareConnected ? AppColors.primary : AppColors.statusOffline,
                        width: 1.0,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isHardwareConnected ? AppColors.primary : AppColors.statusOffline,
                        ),
                      ),
                      const SizedBox(width: 5),
                      AppText(
                        isHardwareConnected ? 'ESP32 ONLINE' : 'OFFLINE',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: isHardwareConnected ? AppColors.primary : AppColors.statusOffline,
                        isMonospace: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
