import 'package:flutter/material.dart';
import 'package:smart_fan_cooling/core/theme/app_colors.dart';
import 'package:smart_fan_cooling/features/rgb_lighting/domain/models/rgb_config.dart';
import 'package:smart_fan_cooling/shared/widgets/app_button.dart';
import 'package:smart_fan_cooling/shared/widgets/app_text.dart';
import 'package:smart_fan_cooling/shared/widgets/glass_card.dart';

class RgbControlsWidget extends StatelessWidget {
  final RgbConfig config;
  final ValueChanged<String> onModeChanged;
  final ValueChanged<Color> onColorChanged;
  final ValueChanged<int> onBrightnessChanged;
  final ValueChanged<int> onSpeedChanged;

  static const List<Color> _presetColors = [
    AppColors.primary,
    AppColors.secondary,
    AppColors.accentPurple,
    AppColors.accentPink,
    AppColors.accentOrange,
    AppColors.accentRed,
    AppColors.accentYellow,
    Colors.white,
  ];

  const RgbControlsWidget({
    super.key,
    required this.config,
    required this.onModeChanged,
    required this.onColorChanged,
    required this.onBrightnessChanged,
    required this.onSpeedChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.h2('CHẾ ĐỘ HIỆU ỨNG ĐÈN LED (RGB MODES)'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildModeButton('Static', 'Màu Đơn'),
              _buildModeButton('Breathing', 'Nhịp Thở'),
              _buildModeButton('Rainbow', 'Cầu Vồng (Chroma)'),
              _buildModeButton('ThermalSync', 'Đổi Theo Nhiệt Độ'),
              _buildModeButton('SpeedSync', 'Đổi Theo Tốc Độ Quạt'),
              _buildModeButton('Off', 'Tắt Đèn'),
            ],
          ),
          const SizedBox(height: 24),

          // Palette Color Presets
          AppText.h2('BẢNG MÀU TÙY CHỈNH'),
          const SizedBox(height: 12),
          Row(
            children: _presetColors.map((color) {
              final isSelected = config.primaryColor == color;
              return GestureDetector(
                onTap: () => onColorChanged(color),
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Brightness Slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText.body('Độ Sáng (Brightness)'),
              AppText('${config.brightness}%', fontWeight: FontWeight.w700, isMonospace: true),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 6,
              activeTrackColor: AppColors.accentPink,
              inactiveTrackColor: AppColors.surfaceLight,
              thumbColor: AppColors.accentPink,
            ),
            child: Slider(
              value: config.brightness.toDouble(),
              min: 0,
              max: 100,
              divisions: 100,
              onChanged: (val) => onBrightnessChanged(val.round()),
            ),
          ),
          const SizedBox(height: 12),

          // Speed Slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText.body('Tốc Độ Hiệu Ứng (Animation Speed)'),
              AppText('${config.animationSpeed}x', fontWeight: FontWeight.w700, isMonospace: true),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 6,
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.surfaceLight,
              thumbColor: AppColors.primary,
            ),
            child: Slider(
              value: config.animationSpeed.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              onChanged: (val) => onSpeedChanged(val.round()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton(String modeKey, String label) {
    final isSelected = config.mode == modeKey;
    return AppButton(
      label: label,
      isOutlined: !isSelected,
      backgroundColor: isSelected ? AppColors.accentPink : null,
      textColor: isSelected ? Colors.white : AppColors.textPrimary,
      onPressed: () => onModeChanged(modeKey),
    );
  }
}
