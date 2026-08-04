import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:smart_fan_cooling/core/theme/app_colors.dart';
import 'package:smart_fan_cooling/shared/widgets/app_text.dart';
import 'package:smart_fan_cooling/shared/widgets/glass_card.dart';

class HardwareCardWidget extends StatelessWidget {
  final String title;
  final String subTitle;
  final String valueText;
  final String unitText;
  final IconData icon;
  final Color accentColor;
  final List<double> historyData;

  const HardwareCardWidget({
    super.key,
    required this.title,
    required this.subTitle,
    required this.valueText,
    required this.unitText,
    required this.icon,
    required this.accentColor,
    required this.historyData,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: ShapeDecoration(
                        color: accentColor.withValues(alpha: 0.15),
                        shape: RoundedSuperellipseBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Icon(icon, color: accentColor, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText.h2(
                            title,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          AppText.caption(
                            subTitle,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  AppText(
                    valueText,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: accentColor,
                    isMonospace: true,
                  ),
                  const SizedBox(width: 2),
                  AppText(
                    unitText,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 60,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: historyData.isNotEmpty ? (historyData.length - 1).toDouble() : 1,
                minY: historyData.isNotEmpty
                    ? (historyData.reduce((a, b) => a < b ? a : b) - 5).clamp(0, 100)
                    : 0,
                maxY: historyData.isNotEmpty
                    ? (historyData.reduce((a, b) => a > b ? a : b) + 5).clamp(10, 120)
                    : 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: historyData.isEmpty
                        ? [const FlSpot(0, 0)]
                        : historyData
                            .asMap()
                            .entries
                            .map((e) => FlSpot(e.key.toDouble(), e.value))
                            .toList(),
                    isCurved: true,
                    color: accentColor,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: accentColor.withValues(alpha: 0.15),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
