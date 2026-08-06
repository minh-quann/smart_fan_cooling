import 'package:flutter/material.dart';
import 'package:smart_fan_cooling/core/theme/app_colors.dart';
import 'package:smart_fan_cooling/shared/widgets/app_text.dart';

enum DashboardTab { overview, fanCurve, rgbLighting, appProfile, systemInfo, gpioTest, settings }

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
      width: 235,
      color: AppColors.sidebarBg,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Industrial Cockpit Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: ShapeDecoration(
                    color: AppColors.primary,
                    shape: RoundedSuperellipseBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Icon(
                    Icons.cyclone_rounded,
                    color: Colors.black,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        'LLANO SMART FAN',
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        overflow: TextOverflow.ellipsis,
                      ),
                      AppText(
                        'SYSTEM CONTROL HUB',
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        isMonospace: true,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Padding(
            padding: EdgeInsets.only(left: 8, bottom: 8),
            child: AppText(
              'MENU QUẢN TRỊ',
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppColors.textMuted,
              isMonospace: true,
            ),
          ),

          // Navigation Links
          _buildNavItem(
            tab: DashboardTab.overview,
            icon: Icons.dashboard_rounded,
            title: 'Tổng Quan Hệ Thống',
          ),
          _buildNavItem(
            tab: DashboardTab.fanCurve,
            icon: Icons.show_chart_rounded,
            title: 'Profile & Fan Curve',
          ),
          _buildNavItem(
            tab: DashboardTab.rgbLighting,
            icon: Icons.palette_rounded,
            title: 'Đèn LED RGB',
          ),
          _buildNavItem(
            tab: DashboardTab.appProfile,
            icon: Icons.auto_mode_rounded,
            title: 'Gán App Auto-Switch',
          ),
          _buildNavItem(
            tab: DashboardTab.systemInfo,
            icon: Icons.memory_rounded,
            title: 'Thông Số Phần Cứng',
          ),
          _buildNavItem(
            tab: DashboardTab.gpioTest,
            icon: Icons.developer_board_rounded,
            title: 'Test GPIO',
          ),
          _buildNavItem(
            tab: DashboardTab.settings,
            icon: Icons.settings_rounded,
            title: 'Thiết Lập Hệ Thống',
          ),

          const Spacer(),

          // Compact Status Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: ShapeDecoration(
              color: AppColors.cardBg,
              shape: RoundedSuperellipseBorder(
                borderRadius: BorderRadius.circular(6),
                side: const BorderSide(color: AppColors.border, width: 1.0),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: ShapeDecoration(
                    color: AppColors.primary,
                    shape: RoundedSuperellipseBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        'ESP32-S3 BOARD',
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        isMonospace: true,
                      ),
                      AppText(
                        'Firmware v1.3.0',
                        fontSize: 9.5,
                        color: AppColors.textMuted,
                        isMonospace: true,
                      ),
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
      padding: const EdgeInsets.only(bottom: 2),
      child: InkWell(
        onTap: () => onTabChanged(tab),
        borderRadius: BorderRadius.circular(6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.surfaceLight : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border(
              left: BorderSide(
                color: isSelected ? AppColors.primary : Colors.transparent,
                width: 3.0,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? AppColors.primary : AppColors.textMuted,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppText(
                  title,
                  fontSize: 12.5,
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
