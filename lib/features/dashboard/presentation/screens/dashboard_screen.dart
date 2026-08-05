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
import 'package:smart_fan_cooling/features/profiles/domain/models/fan_profile.dart';
import 'package:smart_fan_cooling/features/profiles/presentation/bloc/profile_bloc.dart';
import 'package:smart_fan_cooling/features/profiles/presentation/bloc/profile_event.dart';
import 'package:smart_fan_cooling/features/profiles/presentation/bloc/profile_state.dart';
import 'package:smart_fan_cooling/features/profiles/presentation/widgets/add_app_dialog.dart';
import 'package:smart_fan_cooling/features/profiles/presentation/widgets/add_edit_profile_dialog.dart';
import 'package:smart_fan_cooling/features/profiles/presentation/widgets/app_mapping_list_widget.dart';
import 'package:smart_fan_cooling/features/profiles/presentation/widgets/fan_curve_editor_widget.dart';
import 'package:smart_fan_cooling/features/profiles/presentation/widgets/profile_selector_widget.dart';
import 'package:smart_fan_cooling/features/rgb_lighting/presentation/bloc/rgb_bloc.dart';
import 'package:smart_fan_cooling/features/rgb_lighting/presentation/bloc/rgb_event.dart';
import 'package:smart_fan_cooling/features/rgb_lighting/presentation/bloc/rgb_state.dart';
import 'package:smart_fan_cooling/features/rgb_lighting/presentation/widgets/rgb_controls_widget.dart';
import 'package:smart_fan_cooling/features/rgb_lighting/presentation/widgets/rgb_strip_preview_widget.dart';
import 'package:smart_fan_cooling/features/settings/presentation/screens/settings_screen.dart';
import 'package:smart_fan_cooling/features/connection/presentation/screens/connection_screen.dart';
import 'package:smart_fan_cooling/features/connection/presentation/bloc/connection_bloc.dart';
import 'package:smart_fan_cooling/features/connection/presentation/bloc/connection_event.dart';
import 'package:smart_fan_cooling/features/connection/presentation/bloc/connection_state.dart'
    as conn_state;
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
    // Auto-reconnect to last saved device
    context.read<ConnectionBloc>().add(AutoReconnectEvent());
  }

  void _showConnectionDialog() {
    showDialog(
      context: context,
      builder: (_) => const ConnectionScreen(),
    );
  }

  void _showAddProfileDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AddEditProfileDialog(
        onSave: (newProfile) {
          context.read<ProfileBloc>().add(SaveProfileEvent(newProfile));
        },
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, FanProfile profile) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AddEditProfileDialog(
        profileToEdit: profile,
        onSave: (updatedProfile) {
          context.read<ProfileBloc>().add(SaveProfileEvent(updatedProfile));
        },
      ),
    );
  }

  Widget _buildMetricPill(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: ShapeDecoration(
        color: AppColors.surfaceLight,
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: AppColors.border, width: 1.0),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText(label, fontSize: 10.5, color: AppColors.textMuted, isMonospace: true),
          const SizedBox(width: 4),
          AppText(value, fontSize: 10.5, fontWeight: FontWeight.w800, color: color, isMonospace: true),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: MultiBlocListener(
        listeners: [
          BlocListener<HardwareBloc, HardwareState>(
            listenWhen: (prev, curr) => curr.status == HardwareStatus.success,
            listener: (context, hwState) {
              final connBloc = context.read<ConnectionBloc>();
              if (connBloc.state.status == conn_state.ConnectionStatus.connected) {
                connBloc.add(SendTemperatureEvent(
                  hwState.stats.cpuTemp,
                  hwState.stats.gpuTemp,
                ));
              }
            },
          ),
          BlocListener<ConnectionBloc, conn_state.ConnectionState>(
            listenWhen: (prev, curr) =>
                curr.status == conn_state.ConnectionStatus.connected &&
                prev.status != conn_state.ConnectionStatus.connected,
            listener: (context, connState) {
              final hwState = context.read<HardwareBloc>().state;
              if (hwState.status == HardwareStatus.success) {
                connState.activeService?.sendTemperature(
                  hwState.stats.cpuTemp,
                  hwState.stats.gpuTemp,
                );
              }
            },
          ),
        ],
        child: BlocBuilder<ProfileBloc, ProfileState>(
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
                      onConnectionTap: _showConnectionDialog,
                    ),

                    // Active Tab View Content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: RepaintBoundary(
                          child: _buildTabContent(context, profileState),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
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
      case DashboardTab.settings:
        return const SettingsScreen();
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
              onAddProfilePressed: () => _showAddProfileDialog(context),
              onEditProfilePressed: (p) => _showEditProfileDialog(context, p),
              onDeleteProfilePressed: (id) => context.read<ProfileBloc>().add(DeleteProfileEvent(id)),
            ),
            const SizedBox(height: 20),

            // Responsive Layout: Side-by-side on wide screens, Stacked on narrow screens
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 1050;

                final leftPanel = Column(
                  children: [
                    RepaintBoundary(
                      child: RpmGaugeWidget(
                        fanRpm: hwState.stats.fanRpm,
                        pwmPercent: hwState.stats.pwmPercent,
                        isConnected: hwState.stats.isFanConnected,
                      ),
                    ),
                    const SizedBox(height: 16),
                    RepaintBoundary(
                      child: QuickFanControlWidget(
                        currentPwm: hwState.stats.pwmPercent,
                        onPwmChanged: (pwm) {
                          context.read<HardwareBloc>().add(ChangePwmSpeedEvent(pwm));
                        },
                      ),
                    ),
                  ],
                );

                final rightPanel = Column(
                  children: [
                    // CPU Card (Includes Temp, Speed/Clock, Usage Load, CPU Fan RPM & Power W)
                    HardwareCardWidget(
                      title: 'Nhiệt Độ Vi Xử Lý CPU',
                      subTitle: hwState.stats.cpuName,
                      valueText: '${hwState.stats.cpuTemp}',
                      unitText: '°C',
                      icon: Icons.memory_rounded,
                      accentColor: AppColors.cpuColor,
                      progressPercent: hwState.stats.cpuUsage,
                      extraPills: [
                        _buildMetricPill('Mức sử dụng:', '${hwState.stats.cpuUsage}%', AppColors.accentOrange),
                        _buildMetricPill('Tốc độ Clock:', '${hwState.stats.cpuClock} GHz', AppColors.cpuColor),
                        _buildMetricPill('Quạt CPU Laptop:', '${hwState.stats.cpuFanRpm} RPM', AppColors.primary),
                        _buildMetricPill('Công suất tiêu thụ:', '${hwState.stats.cpuPowerW} W', AppColors.accentRed),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // GPU Card (Includes Temp, GPU Usage, GPU Fan RPM & Power W)
                    HardwareCardWidget(
                      title: 'Nhiệt Độ Card Đồ Họa GPU',
                      subTitle: hwState.stats.gpuName,
                      valueText: '${hwState.stats.gpuTemp}',
                      unitText: '°C',
                      icon: Icons.developer_board_rounded,
                      accentColor: AppColors.gpuColor,
                      progressPercent: hwState.stats.gpuUsage,
                      extraPills: [
                        _buildMetricPill('Mức sử dụng GPU:', '${hwState.stats.gpuUsage}%', AppColors.gpuColor),
                        _buildMetricPill('Xung nhịp GPU:', '${hwState.stats.gpuClock.toInt()} MHz', AppColors.cpuColor),
                        _buildMetricPill('Quạt GPU Laptop:', '${hwState.stats.gpuFanRpm} RPM', AppColors.primary),
                        _buildMetricPill('Công suất tiêu thụ:', '${hwState.stats.gpuPowerW} W', AppColors.accentRed),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // RAM Card
                    HardwareCardWidget(
                      title: 'Mức Sử Dụng RAM Hệ Thống',
                      subTitle: 'DDR4/DDR5 System RAM',
                      valueText: '${hwState.stats.ramUsage}',
                      unitText: '%',
                      icon: Icons.straighten_rounded,
                      accentColor: AppColors.ramColor,
                      progressPercent: hwState.stats.ramUsage,
                      extraPills: [
                        _buildMetricPill('Bộ nhớ:', 'Đang dùng ${hwState.stats.ramUsage}%', AppColors.ramColor),
                        _buildMetricPill('Băng thông:', 'High Performance', AppColors.accentPurple),
                      ],
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
          onAddProfilePressed: () => _showAddProfileDialog(context),
          onEditProfilePressed: (p) => _showEditProfileDialog(context, p),
          onDeleteProfilePressed: (id) => context.read<ProfileBloc>().add(DeleteProfileEvent(id)),
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
