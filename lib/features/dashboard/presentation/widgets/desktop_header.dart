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
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Active Profile Badge Indicator
            Row(
              children: [
                AppText.caption('PROFILE ĐANG HOẠT ĐỘNG:'),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: ShapeDecoration(
                    color: activeProfileColor.withValues(alpha: 0.15),
                    shape: RoundedSuperellipseBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: activeProfileColor, width: 1.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.bolt_rounded, size: 16, color: activeProfileColor),
                      const SizedBox(width: 6),
                      AppText(
                        activeProfileName.toUpperCase(),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: activeProfileColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(width: 24),

            // Hardware & Platform Connection Status Badges
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: ShapeDecoration(
                    color: AppColors.surfaceLight,
                    shape: RoundedSuperellipseBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: AppColors.border),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Theme.of(context).platform == TargetPlatform.windows
                            ? Icons.window_rounded
                            : Icons.computer_rounded,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      AppText(
                        Theme.of(context).platform == TargetPlatform.windows
                            ? 'WINDOWS MODE'
                            : 'LINUX MODE',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: ShapeDecoration(
                    color: isHardwareConnected
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : AppColors.statusOffline.withValues(alpha: 0.15),
                    shape: RoundedSuperellipseBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: isHardwareConnected ? AppColors.primary : AppColors.statusOffline,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: ShapeDecoration(
                          color: isHardwareConnected ? AppColors.primary : AppColors.statusOffline,
                          shape: RoundedSuperellipseBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      AppText(
                        isHardwareConnected ? 'ESP32 CONNECTED' : 'DISCONNECTED',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isHardwareConnected ? AppColors.primary : AppColors.statusOffline,
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
