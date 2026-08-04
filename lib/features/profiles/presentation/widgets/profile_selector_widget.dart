import 'package:flutter/material.dart';
import 'package:smart_fan_cooling/core/theme/app_colors.dart';
import 'package:smart_fan_cooling/features/profiles/domain/models/fan_profile.dart';
import 'package:smart_fan_cooling/shared/widgets/app_text.dart';
import 'package:smart_fan_cooling/shared/widgets/glass_card.dart';

class ProfileSelectorWidget extends StatelessWidget {
  final List<FanProfile> profiles;
  final String activeProfileId;
  final ValueChanged<String> onProfileSelected;

  const ProfileSelectorWidget({
    super.key,
    required this.profiles,
    required this.activeProfileId,
    required this.onProfileSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 6,
          children: [
            AppText.h2('PROFILE CẤU HÌNH LÀM MÁT'),
            AppText.caption('Chọn profile phù hợp cho kịch bản sử dụng'),
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
                childAspectRatio: crossAxisCount == 1 ? 2.8 : 1.4,
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
          ? p.themeColor.withValues(alpha: 0.15)
          : AppColors.cardBg,
      borderColor: isSelected ? p.themeColor : AppColors.border,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            p.icon,
            size: 26,
            color: isSelected ? p.themeColor : AppColors.textMuted,
          ),
          const SizedBox(height: 6),
          AppText(
            p.name,
            fontSize: 13,
            fontWeight: FontWeight.w700,
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: ShapeDecoration(
              color: p.themeColor.withValues(alpha: 0.2),
              shape: RoundedSuperellipseBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: AppText(
              'Max ${p.maxFanPwm}% PWM',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: p.themeColor,
            ),
          ),
        ],
      ),
    );
  }
}
