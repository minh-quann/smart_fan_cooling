import 'package:flutter/material.dart';
import 'package:smart_fan_cooling/core/theme/app_colors.dart';
import 'package:smart_fan_cooling/features/profiles/domain/models/fan_profile.dart';
import 'package:smart_fan_cooling/shared/widgets/app_button.dart';
import 'package:smart_fan_cooling/shared/widgets/app_text.dart';
import 'package:smart_fan_cooling/shared/widgets/glass_card.dart';

class ProfileSelectorWidget extends StatelessWidget {
  final List<FanProfile> profiles;
  final String activeProfileId;
  final ValueChanged<String> onProfileSelected;
  final VoidCallback? onAddProfilePressed;
  final ValueChanged<FanProfile>? onEditProfilePressed;
  final ValueChanged<String>? onDeleteProfilePressed;

  const ProfileSelectorWidget({
    super.key,
    required this.profiles,
    required this.activeProfileId,
    required this.onProfileSelected,
    this.onAddProfilePressed,
    this.onEditProfilePressed,
    this.onDeleteProfilePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.h2('PROFILE CẤU HÌNH LÀM MÁT'),
                  AppText.caption('Chọn hoặc tạo profile tùy chỉnh phù hợp cho kịch bản sử dụng'),
                ],
              ),
            ),
            if (onAddProfilePressed != null)
              AppButton(
                label: 'TẠO PROFILE MỚI',
                icon: Icons.add_rounded,
                backgroundColor: AppColors.surfaceLight,
                textColor: AppColors.textPrimary,
                onPressed: onAddProfilePressed!,
              ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            int crossAxisCount = 4;
            if (width < 600) {
              crossAxisCount = 1;
            } else if (width < 950) {
              crossAxisCount = 2;
            }

            if (crossAxisCount == 4) {
              return Row(
                children: profiles.map((p) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _buildProfileCard(p),
                    ),
                  );
                }).toList(),
              );
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: crossAxisCount == 1 ? 2.6 : 1.35,
              ),
              itemCount: profiles.length,
              itemBuilder: (context, index) {
                return _buildProfileCard(profiles[index]);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildProfileCard(FanProfile p) {
    final isSelected = p.id == activeProfileId;
    return GlassCard(
      onTap: () => onProfileSelected(p.id),
      backgroundColor: isSelected
          ? p.themeColor.withValues(alpha: 0.12)
          : AppColors.cardBg,
      borderColor: isSelected ? p.themeColor : AppColors.border,
      borderRadius: 12,
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  p.icon,
                  size: 24,
                  color: isSelected ? p.themeColor : AppColors.textMuted,
                ),
                const SizedBox(height: 6),
                AppText(
                  p.name,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 4),
                AppText.caption(
                  p.description,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: ShapeDecoration(
                        color: p.themeColor.withValues(alpha: 0.15),
                        shape: RoundedSuperellipseBorder(
                          borderRadius: BorderRadius.circular(6),
                          side: BorderSide(color: p.themeColor.withValues(alpha: 0.3)),
                        ),
                      ),
                      child: Builder(
                        builder: (context) {
                          final int targetPwm = p.isFixedSpeed ? p.fixedPwm : p.maxFanPwm;
                          final int targetRpm = ((targetPwm / 100.0) * 2800).round();
                          return AppText(
                            p.isFixedSpeed ? 'Cố định $targetPwm% ($targetRpm RPM)' : 'Max $targetPwm% ($targetRpm RPM)',
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: p.themeColor,
                            isMonospace: true,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Edit & Delete Action Buttons
          Positioned(
            top: -4,
            right: -4,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onEditProfilePressed != null)
                  IconButton(
                    icon: const Icon(Icons.edit_rounded, size: 14, color: AppColors.textMuted),
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                    onPressed: () => onEditProfilePressed!(p),
                  ),
                if (onDeleteProfilePressed != null && !p.isDefault)
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 14, color: AppColors.accentRed),
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                    onPressed: () => onDeleteProfilePressed!(p.id),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
