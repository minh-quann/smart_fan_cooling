import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_fan_cooling/core/services/window_service.dart';
import 'package:smart_fan_cooling/core/theme/app_colors.dart';
import 'package:smart_fan_cooling/features/hardware_monitor/presentation/bloc/hardware_bloc.dart';
import 'package:smart_fan_cooling/features/hardware_monitor/presentation/bloc/hardware_state.dart';
import 'package:smart_fan_cooling/features/overlay/domain/models/overlay_config.dart';
import 'package:smart_fan_cooling/features/overlay/presentation/bloc/overlay_bloc.dart';
import 'package:smart_fan_cooling/features/overlay/presentation/bloc/overlay_event.dart';
import 'package:smart_fan_cooling/features/overlay/presentation/bloc/overlay_state.dart';
import 'package:smart_fan_cooling/shared/widgets/app_button.dart';
import 'package:smart_fan_cooling/shared/widgets/app_text.dart';
import 'package:smart_fan_cooling/shared/widgets/glass_card.dart';

class OverlaySettingsScreen extends StatefulWidget {
  const OverlaySettingsScreen({super.key});

  @override
  State<OverlaySettingsScreen> createState() => _OverlaySettingsScreenState();
}

class _OverlaySettingsScreenState extends State<OverlaySettingsScreen> {
  int _activeCategoryTab = 0; // 0: Basic, 1: CPU, 2: GPU, 3: RAM & Fan
  bool _isDragUnlocked = false;
  StreamSubscription<Map<String, double>>? _posSub;
  StreamSubscription<bool>? _hotkeySub;

  @override
  void initState() {
    super.initState();
    WindowService.init();

    // Listen to mouse drag position updates from native Win32 window
    _posSub = WindowService.onPositionChanged.listen((pos) {
      if (mounted) {
        final currentConfig = context.read<OverlayBloc>().state.config;
        _updateConfig(
          context,
          currentConfig.copyWith(
            posX: pos['posX']!,
            posY: pos['posY']!,
            positionPreset: 'custom',
          ),
        );
      }
    });

    // Listen to Ctrl+Shift+O hotkey toggles
    _hotkeySub = WindowService.onHotkeyPressed.listen((isInteractive) {
      if (mounted) {
        setState(() {
          _isDragUnlocked = isInteractive;
        });
      }
    });
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _hotkeySub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OverlayBloc, OsdOverlayState>(
      builder: (context, overlayState) {
        final config = overlayState.config;

        return GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Title & Master Controls Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.desktop_windows_rounded,
                          color: AppColors.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppText.h2('CẤU HÌNH HIỂN THỊ HUD OVERLAY (IN-GAME OSD TELEMETRY)'),
                              AppText.caption(
                                'Tùy chỉnh các chỉ số nhiệt độ, quạt, công suất hiển thị thả nổi trên game và các ứng dụng khác',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      // Master Enable Switch
                      Row(
                        children: [
                          AppText(
                            config.isEnabled ? 'BẬT OVERLAY' : 'TẮT OVERLAY',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: config.isEnabled ? AppColors.primary : AppColors.textMuted,
                          ),
                          const SizedBox(width: 6),
                          Switch(
                            value: config.isEnabled,
                            activeTrackColor: AppColors.primary,
                            onChanged: (val) {
                              context.read<OverlayBloc>().add(
                                    ToggleOverlayEnabledEvent(val),
                                  );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      AppButton(
                        label: 'KHÔI PHỤC MẶC ĐỊNH',
                        backgroundColor: AppColors.surfaceLight,
                        textColor: AppColors.textSecondary,
                        onPressed: () {
                          context.read<OverlayBloc>().add(
                                const ResetOverlayConfigEvent(),
                              );
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Main Responsive Layout: Left Live Preview & Settings vs Right Metric Checkboxes
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 1000;

                  final leftSection = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Live Preview Card
                      AppText.h2('PREVIEW MÀN HÌNH HUD OVERLAY THỰC TẾ'),
                      const SizedBox(height: 8),
                      Container(
                        height: 180,
                        width: double.infinity,
                        decoration: ShapeDecoration(
                          color: const Color(0xFF10141D),
                          shape: RoundedSuperellipseBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: AppColors.border),
                          ),
                        ),
                        child: Stack(
                          children: [
                            // Background Game Image Pattern Simulation
                            Positioned.fill(
                              child: Opacity(
                                opacity: 0.15,
                                child: Image.network(
                                  'https://images.unsplash.com/photo-1542751371-adc38448a05e?q=80&w=1000&auto=format&fit=crop',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const Center(
                                    child: Icon(Icons.sports_esports_rounded, size: 64, color: AppColors.textMuted),
                                  ),
                                ),
                              ),
                            ),

                            // Simulated HUD Badge inside preview
                            BlocBuilder<HardwareBloc, HardwareState>(
                              builder: (context, hwState) {
                                return Positioned(
                                  left: 20,
                                  top: 20,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: ShapeDecoration(
                                      color: Colors.black.withValues(alpha: config.backgroundOpacity),
                                      shape: RoundedSuperellipseBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        side: BorderSide(
                                          color: config.accentColor.withValues(alpha: 0.5),
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (config.showTime) ...[
                                          _buildPreviewBadge('TIME', '16:30:00', Colors.white),
                                          const SizedBox(width: 10),
                                        ],
                                        if (config.showCpuTemp || config.showCpuUsage || config.showCpuPower) ...[
                                          _buildPreviewBadge(
                                            'CPU',
                                            '${hwState.stats.cpuUsage.round()}%  ${hwState.stats.cpuTemp.round()}°C  ${hwState.stats.cpuPowerW.round()}W',
                                            AppColors.cpuColor,
                                          ),
                                          const SizedBox(width: 10),
                                        ],
                                        if (config.showGpuTemp || config.showGpuUsage || config.showGpuPower) ...[
                                          _buildPreviewBadge(
                                            'GPU',
                                            '${hwState.stats.gpuUsage.round()}%  ${hwState.stats.gpuTemp.round()}°C  ${hwState.stats.gpuPowerW.round()}W',
                                            AppColors.gpuColor,
                                          ),
                                          const SizedBox(width: 10),
                                        ],
                                        if (config.showSmartFanRpm) ...[
                                          _buildPreviewBadge(
                                            'LLANO FAN',
                                            '${hwState.stats.pwmPercent}%  ${hwState.stats.fanRpm} RPM',
                                            AppColors.primary,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // POSITION CONTROL SECTION (DRAG UNLOCK & PRESETS)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          AppText.h2('VỊ TRÍ VÀ DI CHUYỂN HUD (POSITION & DRAG)'),
                          AppText(
                            'Tọa độ: X: ${config.posX.round()}, Y: ${config.posY.round()}',
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            isMonospace: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Interactive Drag Unlock Button
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isDragUnlocked = !_isDragUnlocked;
                          });
                          WindowService.setClickThrough(!_isDragUnlocked);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: ShapeDecoration(
                            color: _isDragUnlocked
                                ? AppColors.primary.withValues(alpha: 0.15)
                                : AppColors.surfaceLight,
                            shape: RoundedSuperellipseBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color: _isDragUnlocked ? AppColors.primary : AppColors.border,
                                width: _isDragUnlocked ? 2 : 1,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isDragUnlocked ? Icons.open_with_rounded : Icons.lock_outline_rounded,
                                color: _isDragUnlocked ? AppColors.primary : AppColors.textSecondary,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              AppText(
                                _isDragUnlocked
                                    ? '❖ ĐANG MỞ KHÓA: KÉO CHUỘT TRÊN HUD ĐỂ DI CHUYỂN (NHẤN ĐỂ KHÓA LẠI)'
                                    : '❖ BẤM VÀO ĐÂY ĐỂ MỞ KHÓA KÉO DI CHUYỂN HUD (HOẶC PHÍM Ctrl + Shift + O)',
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: _isDragUnlocked ? AppColors.primary : AppColors.textPrimary,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Native Win32 Preset Position Chips
                      AppText.caption('HOẶC CHỌN NHANH VỊ TRÍ MẶC ĐỊNH (TỰ ĐỘNG CHÍNH XÁC 100%):'),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildPresetChip('Góc Trên Trái', 'top_left', config),
                          _buildPresetChip('Giữa Bên Trên', 'top_center', config),
                          _buildPresetChip('Góc Trên Phải', 'top_right', config),
                          _buildPresetChip('Góc Dưới Trái', 'bottom_left', config),
                          _buildPresetChip('Giữa Bên Dưới', 'bottom_center', config),
                          _buildPresetChip('Góc Dưới Phải', 'bottom_right', config),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Style Selector Options
                      AppText.h2('KỂU DÁNG GIAO DIỆN (STYLE)'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildRadioOption(
                            label: 'Nằm ngang (Horizontal)',
                            isSelected: config.style == 'horizontal',
                            onTap: () => _updateConfig(context, config.copyWith(style: 'horizontal')),
                          ),
                          const SizedBox(width: 12),
                          _buildRadioOption(
                            label: 'Nằm dọc (Upright)',
                            isSelected: config.style == 'upright',
                            onTap: () => _updateConfig(context, config.copyWith(style: 'upright')),
                          ),
                          const SizedBox(width: 12),
                          _buildRadioOption(
                            label: 'Thu gọn (Compact)',
                            isSelected: config.style == 'compact',
                            onTap: () => _updateConfig(context, config.copyWith(style: 'compact')),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Font Size Resolution Scaling
                      AppText.h2('KÍCH THƯỚC CHỮ / ĐỘ PHÂN GIẢI MÀN HÌNH'),
                      const SizedBox(height: 8),
                      Row(
                        children: ['720p', '1080p', '2K', '4K'].map((res) {
                          final isSelected = config.fontSizeScale == res;
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: _buildRadioOption(
                              label: res,
                              isSelected: isSelected,
                              onTap: () => _updateConfig(context, config.copyWith(fontSizeScale: res)),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Background Opacity Slider
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          AppText.h2('ĐỘ TRONG SUỐT NỀN HUD (OPACITY)'),
                          AppText(
                            '${(config.backgroundOpacity * 100).round()}%',
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                            isMonospace: true,
                          ),
                        ],
                      ),
                      SliderTheme(
                        data: const SliderThemeData(
                          trackHeight: 6,
                          activeTrackColor: AppColors.primary,
                          thumbColor: Colors.white,
                        ),
                        child: Slider(
                          value: config.backgroundOpacity,
                          min: 0.1,
                          max: 1.0,
                          divisions: 18,
                          onChanged: (val) {
                            _updateConfig(context, config.copyWith(backgroundOpacity: val));
                          },
                        ),
                      ),
                    ],
                  );

                  final rightSection = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText.h2('CHỌN THÔNG SỐ NỘI DUNG HIỂN THỊ (MONITORING CONTENT)'),
                      const SizedBox(height: 12),

                      // Category Tabs
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: ShapeDecoration(
                          color: AppColors.surfaceLight,
                          shape: RoundedSuperellipseBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: const BorderSide(color: AppColors.border),
                          ),
                        ),
                        child: Row(
                          children: [
                            _buildTabItem(0, 'Cơ Bản (Basic)'),
                            _buildTabItem(1, 'Vi Xử Lý CPU'),
                            _buildTabItem(2, 'Card Đồ Họa GPU'),
                            _buildTabItem(3, 'RAM & Quạt Llano'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Category Checkbox Content Panel
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: ShapeDecoration(
                          color: AppColors.cardBg,
                          shape: RoundedSuperellipseBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: const BorderSide(color: AppColors.border),
                          ),
                        ),
                        child: _buildCategoryContent(context, config),
                      ),
                    ],
                  );

                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 5, child: leftSection),
                        const SizedBox(width: 24),
                        Expanded(flex: 5, child: rightSection),
                      ],
                    );
                  }

                  return Column(
                    children: [
                      leftSection,
                      const SizedBox(height: 24),
                      rightSection,
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPresetChip(String label, String presetKey, OverlayConfig config) {
    final isSelected = config.positionPreset == presetKey;
    return ChoiceChip(
      label: AppText(
        label,
        fontSize: 11.5,
        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
      ),
      selected: isSelected,
      selectedColor: AppColors.primary.withValues(alpha: 0.2),
      backgroundColor: AppColors.surfaceLight,
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.border,
      ),
      onSelected: (_) {
        _updateConfig(context, config.copyWith(positionPreset: presetKey));
      },
    );
  }

  Widget _buildTabItem(int index, String label) {
    final isSelected = _activeCategoryTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeCategoryTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: ShapeDecoration(
            color: isSelected ? AppColors.primary.withValues(alpha: 0.2) : Colors.transparent,
            shape: RoundedSuperellipseBorder(
              borderRadius: BorderRadius.circular(6),
              side: BorderSide(
                color: isSelected ? AppColors.primary : Colors.transparent,
              ),
            ),
          ),
          child: Center(
            child: AppText(
              label,
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
              color: isSelected ? AppColors.primary : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryContent(BuildContext context, OverlayConfig config) {
    switch (_activeCategoryTab) {
      case 0: // Basic
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(
              'CHẾ ĐỘ HIỂN THỊ OVERLAY',
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildRadioOption(
                  label: 'Luôn hiển thị trên màn hình',
                  isSelected: config.displayMode == 'always',
                  onTap: () => _updateConfig(context, config.copyWith(displayMode: 'always')),
                ),
                const SizedBox(width: 12),
                _buildRadioOption(
                  label: 'Chỉ tự động hiển thị khi chơi Game',
                  isSelected: config.displayMode == 'game_only',
                  onTap: () => _updateConfig(context, config.copyWith(displayMode: 'game_only')),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 12),
            _buildCheckboxRow(
              label: 'Tốc Độ Khung Hình Game (FPS Frame Rate)',
              value: config.showFps,
              onChanged: (v) => _updateConfig(context, config.copyWith(showFps: v)),
            ),
            _buildCheckboxRow(
              label: 'Đồng Hồ Thời Gian Thực (Current Time)',
              value: config.showTime,
              onChanged: (v) => _updateConfig(context, config.copyWith(showTime: v)),
            ),
            _buildCheckboxRow(
              label: 'Thời Gian Chạy Ứng Dụng (Running Time)',
              value: config.showRunningTime,
              onChanged: (v) => _updateConfig(context, config.copyWith(showRunningTime: v)),
            ),
          ],
        );
      case 1: // CPU
        return Column(
          children: [
            _buildCheckboxRow(
              label: 'Nhiệt Độ CPU (°C Temperature)',
              value: config.showCpuTemp,
              onChanged: (v) => _updateConfig(context, config.copyWith(showCpuTemp: v)),
            ),
            _buildCheckboxRow(
              label: 'Mức Sử Dụng CPU (% Occupancy Load)',
              value: config.showCpuUsage,
              onChanged: (v) => _updateConfig(context, config.copyWith(showCpuUsage: v)),
            ),
            _buildCheckboxRow(
              label: 'Công Suất Tiêu Thụ CPU (Thermal Power W)',
              value: config.showCpuPower,
              onChanged: (v) => _updateConfig(context, config.copyWith(showCpuPower: v)),
            ),
            _buildCheckboxRow(
              label: 'Xung Nhịp CPU (Frequency GHz)',
              value: config.showCpuClock,
              onChanged: (v) => _updateConfig(context, config.copyWith(showCpuClock: v)),
            ),
            _buildCheckboxRow(
              label: 'Tốc Độ Quạt CPU Laptop (Laptop Fan RPM)',
              value: config.showCpuFanRpm,
              onChanged: (v) => _updateConfig(context, config.copyWith(showCpuFanRpm: v)),
            ),
          ],
        );
      case 2: // GPU
        return Column(
          children: [
            _buildCheckboxRow(
              label: 'Nhiệt Độ Card Đồ Họa GPU (°C Temperature)',
              value: config.showGpuTemp,
              onChanged: (v) => _updateConfig(context, config.copyWith(showGpuTemp: v)),
            ),
            _buildCheckboxRow(
              label: 'Mức Sử Dụng GPU (% Occupancy Load)',
              value: config.showGpuUsage,
              onChanged: (v) => _updateConfig(context, config.copyWith(showGpuUsage: v)),
            ),
            _buildCheckboxRow(
              label: 'Công Suất Tiêu Thụ GPU (Thermal Power W)',
              value: config.showGpuPower,
              onChanged: (v) => _updateConfig(context, config.copyWith(showGpuPower: v)),
            ),
            _buildCheckboxRow(
              label: 'Xung Nhịp Core GPU (Frequency MHz)',
              value: config.showGpuClock,
              onChanged: (v) => _updateConfig(context, config.copyWith(showGpuClock: v)),
            ),
            _buildCheckboxRow(
              label: 'Tốc Độ Quạt GPU Laptop (Laptop Fan RPM)',
              value: config.showGpuFanRpm,
              onChanged: (v) => _updateConfig(context, config.copyWith(showGpuFanRpm: v)),
            ),
          ],
        );
      case 3: // RAM & Smart Fan
      default:
        return Column(
          children: [
            _buildCheckboxRow(
              label: 'Tốc Độ Tản Nhiệt Llano Smart Fan (RPM)',
              value: config.showSmartFanRpm,
              onChanged: (v) => _updateConfig(context, config.copyWith(showSmartFanRpm: v)),
            ),
            _buildCheckboxRow(
              label: 'Công Suất Tản Nhiệt Llano (% PWM)',
              value: config.showSmartFanPwm,
              onChanged: (v) => _updateConfig(context, config.copyWith(showSmartFanPwm: v)),
            ),
            _buildCheckboxRow(
              label: 'Mức Sử Dụng RAM Hệ Thống (Memory Usage %)',
              value: config.showRamUsage,
              onChanged: (v) => _updateConfig(context, config.copyWith(showRamUsage: v)),
            ),
          ],
        );
    }
  }

  Widget _buildCheckboxRow({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Checkbox(
            value: value,
            activeColor: AppColors.primary,
            onChanged: (val) {
              if (val != null) onChanged(val);
            },
          ),
          Expanded(
            child: AppText(
              label,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: value ? AppColors.textPrimary : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadioOption({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
            size: 16,
            color: isSelected ? AppColors.primary : AppColors.textMuted,
          ),
          const SizedBox(width: 6),
          AppText(
            label,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.textPrimary : AppColors.textMuted,
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewBadge(String label, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppText('$label ', fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textMuted, isMonospace: true),
        AppText(value, fontSize: 11, fontWeight: FontWeight.w800, color: color, isMonospace: true),
      ],
    );
  }

  void _updateConfig(BuildContext context, OverlayConfig updated) {
    context.read<OverlayBloc>().add(UpdateOverlayConfigEvent(updated));
  }
}
