import 'package:flutter/material.dart';
import 'package:smart_fan_cooling/core/theme/app_colors.dart';
import 'package:smart_fan_cooling/shared/widgets/app_button.dart';
import 'package:smart_fan_cooling/shared/widgets/app_text.dart';
import 'package:smart_fan_cooling/shared/widgets/glass_card.dart';

class QuickFanControlWidget extends StatelessWidget {
  final int currentPwm;
  final ValueChanged<int> onPwmChanged;

  const QuickFanControlWidget({
    super.key,
    required this.currentPwm,
    required this.onPwmChanged,
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
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.speed_rounded, color: AppColors.secondary, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AppText.h2(
                        'ĐIỀU TỐC THỦ CÔNG (MANUAL PWM)',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AppText(
                '$currentPwm%',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.secondary,
                isMonospace: true,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Slider
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 8,
              activeTrackColor: AppColors.secondary,
              inactiveTrackColor: AppColors.surfaceLight,
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withValues(alpha: 0.2),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            ),
            child: Slider(
              value: currentPwm.toDouble(),
              min: 0,
              max: 100,
              divisions: 100,
              label: '$currentPwm%',
              onChanged: (val) => onPwmChanged(val.round()),
            ),
          ),
          const SizedBox(height: 12),

          // Quick Preset Buttons with Wrap to prevent horizontal overflow
          Center(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildPresetButton(0, 'OFF'),
                _buildPresetButton(25, '25% Yên Tĩnh'),
                _buildPresetButton(50, '50% Vừa'),
                _buildPresetButton(75, '75% Mạnh'),
                _buildPresetButton(100, 'MAX 100%'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetButton(int pwm, String label) {
    final isSelected = currentPwm == pwm;
    return AppButton(
      label: label,
      isOutlined: !isSelected,
      backgroundColor: isSelected ? AppColors.secondary : null,
      textColor: isSelected ? Colors.black : AppColors.textPrimary,
      onPressed: () => onPwmChanged(pwm),
    );
  }
}
