import 'package:flutter/material.dart';
import 'package:smart_fan_cooling/core/theme/app_colors.dart';
import 'package:smart_fan_cooling/features/profiles/domain/models/app_mapping.dart';
import 'package:smart_fan_cooling/features/profiles/domain/models/fan_profile.dart';
import 'package:smart_fan_cooling/shared/widgets/app_button.dart';
import 'package:smart_fan_cooling/shared/widgets/app_text.dart';
import 'package:smart_fan_cooling/shared/widgets/glass_card.dart';

class AppMappingListWidget extends StatelessWidget {
  final List<AppMapping> mappings;
  final List<FanProfile> profiles;
  final Function(String id, bool enabled) onToggleMapping;
  final Function(String id) onDeleteMapping;
  final VoidCallback onAddAppPressed;

  const AppMappingListWidget({
    super.key,
    required this.mappings,
    required this.profiles,
    required this.onToggleMapping,
    required this.onDeleteMapping,
    required this.onAddAppPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_mode_rounded, color: AppColors.primary, size: 22),
                  const SizedBox(width: 8),
                  AppText.h2('TỰ ĐỘNG KÍCH HOẠT PROFILE THEO ỨNG DỤNG (APP AUTO-SWITCH)'),
                ],
              ),
              AppButton(
                label: '+ THÊM ỨNG DỤNG MỚI',
                icon: Icons.add_rounded,
                backgroundColor: AppColors.primary,
                onPressed: onAddAppPressed,
              ),
            ],
          ),
          const SizedBox(height: 6),
          AppText.caption(
            'Ứng dụng tự động chuyển đổi Profile làm mát ngay khi phát hiện game hay phần mềm đang chạy',
          ),
          const SizedBox(height: 16),

          if (mappings.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: AppText.body('Chưa có ứng dụng nào được gán profile. Bấm "+ Thêm ứng dụng mới" để tạo mốc.'),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: mappings.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final mapping = mappings[index];
                final profile = profiles.firstWhere(
                  (p) => p.id == mapping.profileId,
                  orElse: () => profiles.first,
                );

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: ShapeDecoration(
                    color: AppColors.surfaceLight.withValues(alpha: 0.4),
                    shape: RoundedSuperellipseBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppColors.border),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: ShapeDecoration(
                          color: profile.themeColor.withValues(alpha: 0.15),
                          shape: RoundedSuperellipseBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Icon(
                          _getAppIcon(mapping.iconPath),
                          color: profile.themeColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(
                              mapping.appName,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                            const SizedBox(height: 2),
                            AppText(
                              'File chạy: ${mapping.executableName}',
                              fontSize: 12,
                              color: AppColors.textMuted,
                              isMonospace: true,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: ShapeDecoration(
                          color: profile.themeColor.withValues(alpha: 0.2),
                          shape: RoundedSuperellipseBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: profile.themeColor, width: 1),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(profile.icon, size: 14, color: profile.themeColor),
                            const SizedBox(width: 6),
                            AppText(
                              profile.name,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: profile.themeColor,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Switch(
                        value: mapping.isEnabled,
                        activeTrackColor: AppColors.primary,
                        onChanged: (val) => onToggleMapping(mapping.id, val),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.accentRed, size: 20),
                        onPressed: () => onDeleteMapping(mapping.id),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  IconData _getAppIcon(String type) {
    switch (type) {
      case 'game':
        return Icons.sports_esports_rounded;
      case 'video':
        return Icons.movie_creation_rounded;
      case 'chrome':
        return Icons.web_rounded;
      case 'word':
        return Icons.description_rounded;
      default:
        return Icons.apps_rounded;
    }
  }
}
