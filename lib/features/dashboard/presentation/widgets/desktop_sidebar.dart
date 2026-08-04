import 'package:flutter/material.dart';
import 'package:smart_fan_cooling/core/theme/app_colors.dart';
import 'package:smart_fan_cooling/shared/widgets/app_text.dart';

enum DashboardTab { overview, fanCurve, rgbLighting, appProfile, systemInfo }

class DesktopSidebar extends StatelessWidget {
  final DashboardTab currentTab;
  final ValueChanged<DashboardTab> onTabChanged;

  const DesktopSidebar({
    super.key,
    required this.currentTab,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      color: AppColors.sidebarBg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand Logo
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: ShapeDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                  ),
                  shape: RoundedSuperellipseBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  shadows: const [
                    BoxShadow(
                      color: Color(0x6010B981),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.cyclone_rounded,
                  color: Colors.black,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.h2('LLANO SMART', overflow: TextOverflow.ellipsis, maxLines: 1),
                    AppText(
                      'FAN CONTROL HUB',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Navigation Links
          _buildNavItem(
            tab: DashboardTab.overview,
            icon: Icons.dashboard_rounded,
            title: 'Tổng Quan Hệ Thống',
          ),
          _buildNavItem(
            tab: DashboardTab.fanCurve,
            icon: Icons.show_chart_rounded,
            title: 'Quản Lý Profile & Fan Curve',
          ),
          _buildNavItem(
            tab: DashboardTab.rgbLighting,
            icon: Icons.palette_rounded,
            title: 'Đèn LED RGB',
          ),
          _buildNavItem(
            tab: DashboardTab.appProfile,
            icon: Icons.auto_mode_rounded,
            title: 'Gán App Profile',
          ),
          _buildNavItem(
            tab: DashboardTab.systemInfo,
            icon: Icons.memory_rounded,
            title: 'Thông Số Phần Cứng',
          ),

          const Spacer(),

          // System Info Card Footer
          Container(
            padding: const EdgeInsets.all(12),
            decoration: ShapeDecoration(
              color: AppColors.cardBg,
              shape: RoundedSuperellipseBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.border),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.hub_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText('ESP32-S3 Board', fontSize: 12, fontWeight: FontWeight.w700),
                      AppText('Firmware v1.3.0', fontSize: 10, color: AppColors.textMuted),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required DashboardTab tab,
    required IconData icon,
    required String title,
  }) {
    final isSelected = currentTab == tab;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => onTabChanged(tab),
        customBorder: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: ShapeDecoration(
            color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : Colors.transparent,
            shape: RoundedSuperellipseBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isSelected ? AppColors.primary : Colors.transparent,
                width: 1.5,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? AppColors.primary : AppColors.textMuted,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppText(
                  title,
                  fontSize: 13.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
