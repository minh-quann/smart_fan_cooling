import 'dart:math';
import 'package:flutter/material.dart';
import 'package:smart_fan_cooling/core/theme/app_colors.dart';
import 'package:smart_fan_cooling/shared/widgets/app_text.dart';
import 'package:smart_fan_cooling/shared/widgets/glass_card.dart';

class RpmGaugeWidget extends StatelessWidget {
  final int fanRpm;
  final int pwmPercent;
  final bool isConnected;

  const RpmGaugeWidget({
    super.key,
    required this.fanRpm,
    required this.pwmPercent,
    this.isConnected = true,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: ShapeDecoration(
                      color: isConnected ? AppColors.primary : AppColors.statusOffline,
                      shape: RoundedSuperellipseBorder(
                        borderRadius: BorderRadius.circular(4.5),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AppText.h2('LLANO SMART FAN HUB'),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: ShapeDecoration(
                  color: isConnected
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : AppColors.statusOffline.withValues(alpha: 0.12),
                  shape: RoundedSuperellipseBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: isConnected ? AppColors.primary : AppColors.statusOffline,
                      width: 1.2,
                    ),
                  ),
                ),
                child: AppText(
                  isConnected ? 'ONLINE (ESP32-S3)' : 'OFFLINE',
                  color: isConnected ? AppColors.primary : AppColors.statusOffline,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Custom Radial Gauge with smooth animation
          SizedBox(
            width: 200,
            height: 200,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(end: fanRpm.toDouble()),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              builder: (context, animRpm, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(200, 200),
                      painter: _GaugePainter(
                        rpm: animRpm.toInt(),
                        maxRpm: 2800,
                        pwmPercent: pwmPercent,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.cyclone_rounded,
                          color: AppColors.primary,
                          size: 28,
                        ),
                        const SizedBox(height: 4),
                        AppText(
                          '${animRpm.round()}',
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          isMonospace: true,
                        ),
                        AppText.caption('RPM (TỐC ĐỘ THỰC)'),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: ShapeDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            shape: RoundedSuperellipseBorder(
                              borderRadius: BorderRadius.circular(6),
                              side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                            ),
                          ),
                          child: AppText(
                            'PWM $pwmPercent%',
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                            isMonospace: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatChip('Mức Tải', '$pwmPercent%', AppColors.primary),
              _buildStatChip('Tần Số PWM', '25 kHz', AppColors.secondary),
              _buildStatChip('Điện Áp', '12 VDC', AppColors.accentOrange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Column(
      children: [
        AppText.caption(label),
        const SizedBox(height: 2),
        AppText(
          value,
          fontSize: 13.5,
          fontWeight: FontWeight.w800,
          color: color,
          isMonospace: true,
        ),
      ],
    );
  }
}

class _GaugePainter extends CustomPainter {
  final int rpm;
  final int maxRpm;
  final int pwmPercent;

  _GaugePainter({
    required this.rpm,
    required this.maxRpm,
    required this.pwmPercent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;

    const startAngle = 135 * pi / 180;
    const sweepAngle = 270 * pi / 180;

    // Solid track
    final bgPaint = Paint()
      ..color = AppColors.surfaceLight
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 10;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      bgPaint,
    );

    // Active progress track - Sharp Electric Mint to Industrial Amber / Red on high speed
    double progressRatio = (rpm / maxRpm).clamp(0.0, 1.0);
    final activePaint = Paint()
      ..shader = SweepGradient(
        colors: const [
          AppColors.primary,
          AppColors.primary,
          AppColors.accentOrange,
          AppColors.accentRed,
        ],
        stops: const [0.0, 0.6, 0.85, 1.0],
        transform: GradientRotation(startAngle),
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 10;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle * progressRatio,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.rpm != rpm || oldDelegate.pwmPercent != pwmPercent;
  }
}
