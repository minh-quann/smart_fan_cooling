import 'package:flutter/material.dart';
import 'package:smart_fan_cooling/core/theme/app_colors.dart';
import 'package:smart_fan_cooling/features/rgb_lighting/domain/models/rgb_config.dart';
import 'package:smart_fan_cooling/shared/widgets/app_text.dart';
import 'package:smart_fan_cooling/shared/widgets/glass_card.dart';

class RgbStripPreviewWidget extends StatelessWidget {
  final RgbConfig config;

  const RgbStripPreviewWidget({
    super.key,
    required this.config,
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
                  const Icon(Icons.palette_rounded, color: AppColors.accentPink, size: 22),
                  const SizedBox(width: 8),
                  AppText.h2('MÔ PHỎNG DẢI LED RGB (WS2812B / FASTLED)'),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: ShapeDecoration(
                  color: AppColors.accentPink.withValues(alpha: 0.2),
                  shape: RoundedSuperellipseBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: AppColors.accentPink),
                  ),
                ),
                child: AppText(
                  'MODE: ${config.mode.toUpperCase()}',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accentPink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Glowing LED Strip Simulation Box
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: ShapeDecoration(
              color: Colors.black,
              shape: RoundedSuperellipseBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.border, width: 1.5),
              ),
              shadows: [
                BoxShadow(
                  color: (config.mode == 'Off')
                      ? Colors.transparent
                      : config.primaryColor.withValues(alpha: (config.brightness / 100 * 0.6)),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(16, (i) {
                Color ledColor;
                if (config.mode == 'Off') {
                  ledColor = AppColors.surfaceLight;
                } else if (config.mode == 'Rainbow') {
                  ledColor = HSVColor.fromAHSV(1.0, (i * 22.5) % 360, 1.0, 1.0).toColor();
                } else if (config.mode == 'ThermalSync') {
                  ledColor = (i < 8) ? AppColors.primary : (i < 12 ? AppColors.accentOrange : AppColors.accentRed);
                } else {
                  ledColor = config.primaryColor;
                }

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ledColor.withValues(alpha: config.brightness / 100),
                    boxShadow: config.mode == 'Off'
                        ? []
                        : [
                            BoxShadow(
                              color: ledColor.withValues(alpha: config.brightness / 100),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
