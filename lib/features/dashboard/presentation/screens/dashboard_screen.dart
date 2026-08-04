import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_fan_cooling/core/theme/app_colors.dart';
import 'package:smart_fan_cooling/features/dashboard/presentation/widgets/desktop_header.dart';
import 'package:smart_fan_cooling/features/dashboard/presentation/widgets/desktop_sidebar.dart';
import 'package:smart_fan_cooling/features/hardware_monitor/presentation/bloc/hardware_bloc.dart';
import 'package:smart_fan_cooling/features/hardware_monitor/presentation/bloc/hardware_event.dart';
import 'package:smart_fan_cooling/features/hardware_monitor/presentation/bloc/hardware_state.dart';
import 'package:smart_fan_cooling/features/hardware_monitor/presentation/widgets/hardware_card_widget.dart';
import 'package:smart_fan_cooling/features/hardware_monitor/presentation/widgets/quick_fan_control_widget.dart';
import 'package:smart_fan_cooling/features/hardware_monitor/presentation/widgets/rpm_gauge_widget.dart';
import 'package:smart_fan_cooling/features/profiles/presentation/bloc/profile_bloc.dart';
import 'package:smart_fan_cooling/features/profiles/presentation/bloc/profile_event.dart';
import 'package:smart_fan_cooling/features/profiles/presentation/bloc/profile_state.dart';
import 'package:smart_fan_cooling/features/profiles/presentation/widgets/add_app_dialog.dart';
import 'package:smart_fan_cooling/features/profiles/presentation/widgets/app_mapping_list_widget.dart';
import 'package:smart_fan_cooling/features/profiles/presentation/widgets/fan_curve_editor_widget.dart';
import 'package:smart_fan_cooling/features/profiles/presentation/widgets/profile_selector_widget.dart';
import 'package:smart_fan_cooling/features/rgb_lighting/presentation/bloc/rgb_bloc.dart';
import 'package:smart_fan_cooling/features/rgb_lighting/presentation/bloc/rgb_event.dart';
import 'package:smart_fan_cooling/features/rgb_lighting/presentation/bloc/rgb_state.dart';
import 'package:smart_fan_cooling/features/rgb_lighting/presentation/widgets/rgb_controls_widget.dart';
import 'package:smart_fan_cooling/features/rgb_lighting/presentation/widgets/rgb_strip_preview_widget.dart';
import 'package:smart_fan_cooling/shared/widgets/app_text.dart';
import 'package:smart_fan_cooling/shared/widgets/glass_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardTab _selectedTab = DashboardTab.overview;

  @override
  void initState() {
    super.initState();
    context.read<HardwareBloc>().add(const StartHardwareMonitoringEvent());
    context.read<ProfileBloc>().add(const LoadProfilesEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, profileState) {
          final activeProfile = profileState.activeProfile;

          return Row(
            children: [
              // Sidebar Navigation
              DesktopSidebar(
                currentTab: _selectedTab,
                onTabChanged: (tab) => setState(() => _selectedTab = tab),
              ),

              // Main Application Content Area
              Expanded(
                child: Column(
                  children: [
                    // Top Bar Header
                    DesktopHeader(
                      activeProfileName: activeProfile.name,
                      activeProfileColor: activeProfile.themeColor,
                    ),

                    // Active Tab View Content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: _buildTabContent(context, profileState),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTabContent(BuildContext context, ProfileState profileState) {
    switch (_selectedTab) {
      case DashboardTab.overview:
        return _buildOverviewTab(context, profileState);
      case DashboardTab.fanCurve:
        return _buildFanCurveTab(context, profileState);
      case DashboardTab.rgbLighting:
        return _buildRgbLightingTab(context);
      case DashboardTab.appProfile:
        return _buildAppProfileTab(context, profileState);
      case DashboardTab.systemInfo:
        return _buildSystemInfoTab(context);
    }
  }

  Widget _buildOverviewTab(BuildContext context, ProfileState profileState) {
    return BlocBuilder<HardwareBloc, HardwareState>(
      builder: (context, hwState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Selector Row
            ProfileSelectorWidget(
              profiles: profileState.profiles,
              activeProfileId: profileState.activeProfileId,
              onProfileSelected: (id) {
                context.read<ProfileBloc>().add(SelectActiveProfileEvent(id));
                final selectedProf = profileState.profiles.firstWhere(
                  (p) => p.id == id,
                  orElse: () => profileState.activeProfile,
                );
                context.read<HardwareBloc>().add(ChangePwmSpeedEvent(selectedProf.maxFanPwm));
              },
            ),
            const SizedBox(height: 20),

            // Responsive Layout: Side-by-side on wide screens, Stacked on narrow screens
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 1050;

                final leftPanel = Column(
                  children: [
                    RpmGaugeWidget(
                      fanRpm: hwState.stats.fanRpm,
                      pwmPercent: hwState.stats.pwmPercent,
                      isConnected: hwState.stats.isFanConnected,
                    ),
                    const SizedBox(height: 16),
                    QuickFanControlWidget(
                      currentPwm: hwState.stats.pwmPercent,
                      onPwmChanged: (pwm) {
                        context.read<HardwareBloc>().add(ChangePwmSpeedEvent(pwm));
                      },
                    ),
                  ],
                );

                final rightPanel = Column(
                  children: [
                    _buildHardwareCardsRow(
                      context,
                      card1: HardwareCardWidget(
                        title: 'Nhiệt Độ CPU (Trung Bình)',
                        subTitle: hwState.stats.cpuName,
                        valueText: '${hwState.stats.cpuTemp}',
                        unitText: '°C',
                        icon: Icons.memory_rounded,
                        accentColor: AppColors.cpuColor,
                        historyData: hwState.cpuTempHistory,
                      ),
                      card2: HardwareCardWidget(
                        title: 'Nhiệt Độ GPU (Trung Bình)',
                        subTitle: hwState.stats.gpuName,
                        valueText: '${hwState.stats.gpuTemp}',
                        unitText: '°C',
                        icon: Icons.developer_board_rounded,
                        accentColor: AppColors.gpuColor,
                        historyData: hwState.gpuTempHistory,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildHardwareCardsRow(
                      context,
                      card1: HardwareCardWidget(
                        title: 'Mức Sử Dụng CPU',
                        subTitle: 'Clock ${hwState.stats.cpuClock} GHz',
                        valueText: '${hwState.stats.cpuUsage}',
                        unitText: '%',
                        icon: Icons.speed_rounded,
                        accentColor: AppColors.accentOrange,
                        historyData: hwState.cpuTempHistory,
                      ),
                      card2: HardwareCardWidget(
                        title: 'Mức Sử Dụng RAM',
                        subTitle: 'DDR4/DDR5 System RAM',
                        valueText: '${hwState.stats.ramUsage}',
                        unitText: '%',
                        icon: Icons.straighten_rounded,
                        accentColor: AppColors.ramColor,
                        historyData: hwState.gpuTempHistory,
                      ),
                    ),
                  ],
                );

                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: leftPanel),
                      const SizedBox(width: 16),
                      Expanded(flex: 7, child: rightPanel),
                    ],
                  );
                }

                return Column(
                  children: [
                    leftPanel,
                    const SizedBox(height: 16),
                    rightPanel,
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildHardwareCardsRow(
    BuildContext context, {
    required Widget card1,
    required Widget card2,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 550) {
          return Column(
            children: [
              card1,
              const SizedBox(height: 16),
              card2,
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: card1),
            const SizedBox(width: 16),
            Expanded(child: card2),
          ],
        );
      },
    );
  }

  Widget _buildFanCurveTab(BuildContext context, ProfileState profileState) {
    final activeProfile = profileState.activeProfile;

    return Column(
      children: [
        ProfileSelectorWidget(
          profiles: profileState.profiles,
          activeProfileId: profileState.activeProfileId,
          onProfileSelected: (id) {
            context.read<ProfileBloc>().add(SelectActiveProfileEvent(id));
          },
        ),
        const SizedBox(height: 20),
        FanCurveEditorWidget(profile: activeProfile),
      ],
    );
  }

  Widget _buildRgbLightingTab(BuildContext context) {
    return BlocBuilder<RgbBloc, RgbState>(
      builder: (context, rgbState) {
        return Column(
          children: [
            RgbStripPreviewWidget(config: rgbState.config),
            const SizedBox(height: 20),
            RgbControlsWidget(
              config: rgbState.config,
              onModeChanged: (mode) {
                context.read<RgbBloc>().add(ChangeRgbModeEvent(mode));
              },
              onColorChanged: (color) {
                context.read<RgbBloc>().add(ChangeRgbPrimaryColorEvent(color));
              },
              onBrightnessChanged: (brightness) {
                context.read<RgbBloc>().add(ChangeRgbBrightnessEvent(brightness));
              },
              onSpeedChanged: (speed) {
                context.read<RgbBloc>().add(ChangeRgbSpeedEvent(speed));
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildAppProfileTab(BuildContext context, ProfileState profileState) {
    return AppMappingListWidget(
      mappings: profileState.appMappings,
      profiles: profileState.profiles,
      onToggleMapping: (id, enabled) {
        context.read<ProfileBloc>().add(ToggleAppMappingEvent(id, enabled));
      },
      onDeleteMapping: (id) {
        context.read<ProfileBloc>().add(DeleteAppMappingEvent(id));
      },
      onAddAppPressed: () {
        showDialog(
          context: context,
          builder: (dialogCtx) => AddAppDialog(
            profiles: profileState.profiles,
            onAdd: (newMapping) {
              context.read<ProfileBloc>().add(AddAppMappingEvent(newMapping));
            },
          ),
        );
      },
    );
  }

  Widget _buildSystemInfoTab(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.h1('THÔNG TIN PHẦN CỨNG HỆ THỐNG & ĐẦU NỐI ESP32-S3'),
          const SizedBox(height: 16),
          AppText.body('Bo Điều Khiển: YD-ESP32-S3 (44-Pin Terminal Adapter)'),
          const SizedBox(height: 8),
          AppText.body('Giao Tiếp Nạp Code: USB CDC On Boot (Data Cable)'),
          const SizedBox(height: 8),
          AppText.body('Quạt Tản Nhiệt: Llano Laptop 12V High-Speed Fan (3 Dây)'),
          const SizedBox(height: 8),
          AppText.body('Cảm Biến Phản Hồi Xung RPM: Opto PC817 (Chân Ngắt Interrupt GPIO 5)'),
          const SizedBox(height: 8),
          AppText.body('Màn Hình Điều Khiển: OLED 1.3" All-in-One 9 Chân Tích Hợp Encoder'),
        ],
      ),
    );
  }
}
