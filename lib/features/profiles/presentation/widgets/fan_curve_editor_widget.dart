import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_fan_cooling/core/theme/app_colors.dart';
import 'package:smart_fan_cooling/features/profiles/domain/models/fan_curve_point.dart';
import 'package:smart_fan_cooling/features/profiles/domain/models/fan_profile.dart';
import 'package:smart_fan_cooling/features/profiles/presentation/bloc/profile_bloc.dart';
import 'package:smart_fan_cooling/features/profiles/presentation/bloc/profile_event.dart';
import 'package:smart_fan_cooling/shared/widgets/app_button.dart';
import 'package:smart_fan_cooling/shared/widgets/app_text.dart';
import 'package:smart_fan_cooling/shared/widgets/glass_card.dart';

class FanCurveEditorWidget extends StatefulWidget {
  final FanProfile profile;

  const FanCurveEditorWidget({
    super.key,
    required this.profile,
  });

  @override
  State<FanCurveEditorWidget> createState() => _FanCurveEditorWidgetState();
}

class _FanCurveEditorWidgetState extends State<FanCurveEditorWidget> {
  late List<FanCurvePoint> _curvePoints;
  late bool _isFixedSpeed;
  late int _fixedPwm;
  int? _activePointIndex;
  bool _isModified = false;

  @override
  void initState() {
    super.initState();
    _initCurvePoints();
  }

  @override
  void didUpdateWidget(covariant FanCurveEditorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile.id != widget.profile.id) {
      _initCurvePoints();
    }
  }

  void _initCurvePoints() {
    _curvePoints = List<FanCurvePoint>.from(widget.profile.fanCurve);
    _isFixedSpeed = widget.profile.isFixedSpeed;
    _fixedPwm = widget.profile.fixedPwm;
    _isModified = false;
    _activePointIndex = null;
  }

  void _updatePointPwm(int index, double newPwm) {
    if (_isFixedSpeed) return;
    setState(() {
      _curvePoints[index] = FanCurvePoint(_curvePoints[index].temp, newPwm.clamp(0, 100));
      _isModified = true;
    });
  }

  void _setFixedPwm(int val) {
    setState(() {
      _fixedPwm = val;
      _isFixedSpeed = true;
      _isModified = true;
      _curvePoints = _curvePoints.map((p) => FanCurvePoint(p.temp, val.toDouble())).toList();
    });
  }

  void _toggleFixedSpeedMode(bool isFixed) {
    setState(() {
      _isFixedSpeed = isFixed;
      _isModified = true;
      if (_isFixedSpeed) {
        _curvePoints = _curvePoints.map((p) => FanCurvePoint(p.temp, _fixedPwm.toDouble())).toList();
      }
    });
  }

  void _saveCurve() {
    final updatedProfile = widget.profile.copyWith(
      fanCurve: _curvePoints,
      isFixedSpeed: _isFixedSpeed,
      fixedPwm: _fixedPwm,
    );
    context.read<ProfileBloc>().add(SaveProfileEvent(updatedProfile));
    setState(() {
      _isModified = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.primary,
        content: AppText(
          'Đã lưu cấu hình làm mát cho Profile "${widget.profile.name}"!',
          color: Colors.black,
          fontWeight: FontWeight.w700,
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      _isFixedSpeed ? Icons.lock_clock_rounded : Icons.show_chart_rounded,
                      color: widget.profile.themeColor,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AppText.h2(
                        _isFixedSpeed
                            ? 'CẤU HÌNH KHÓA TỐC ĐỘ CỐ ĐỊNH (FIXED SPEED LOCK)'
                            : 'CẤU HÌNH ĐƯỜNG CONG TỰ ĐỘNG (THERMAL FAN CURVE)',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  if (_isModified)
                    TextButton.icon(
                      onPressed: () => setState(() => _initCurvePoints()),
                      icon: const Icon(Icons.refresh_rounded, size: 16, color: AppColors.textMuted),
                      label: AppText('Hoàn tác', fontSize: 12, color: AppColors.textMuted),
                    ),
                  const SizedBox(width: 8),
                  AppButton(
                    label: _isModified ? 'LƯU CẤU HÌNH' : 'ĐÃ LƯU',
                    backgroundColor: _isModified ? widget.profile.themeColor : AppColors.surfaceLight,
                    textColor: _isModified ? Colors.black : AppColors.textSecondary,
                    onPressed: _isModified ? _saveCurve : () {},
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Mode Selector Switch: Dynamic Fan Curve vs Fixed Lock Speed
          Container(
            padding: const EdgeInsets.all(4),
            decoration: ShapeDecoration(
              color: AppColors.surfaceLight,
              shape: RoundedSuperellipseBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: AppColors.border),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _toggleFixedSpeedMode(false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: ShapeDecoration(
                        color: !_isFixedSpeed ? widget.profile.themeColor.withValues(alpha: 0.2) : Colors.transparent,
                        shape: RoundedSuperellipseBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: !_isFixedSpeed ? widget.profile.themeColor : Colors.transparent,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.show_chart_rounded, size: 16, color: !_isFixedSpeed ? widget.profile.themeColor : AppColors.textMuted),
                          const SizedBox(width: 6),
                          AppText(
                            'TÙY CHỈNH ĐƯỜNG CONG TỰ ĐỘNG',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: !_isFixedSpeed ? AppColors.textPrimary : AppColors.textMuted,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _toggleFixedSpeedMode(true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: ShapeDecoration(
                        color: _isFixedSpeed ? AppColors.secondary.withValues(alpha: 0.2) : Colors.transparent,
                        shape: RoundedSuperellipseBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: _isFixedSpeed ? AppColors.secondary : Colors.transparent,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock_clock_rounded, size: 16, color: _isFixedSpeed ? AppColors.secondary : AppColors.textMuted),
                          const SizedBox(width: 6),
                          AppText(
                            'KHÓA TỐC ĐỘ CỐ ĐỊNH (FIXED PWM)',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _isFixedSpeed ? AppColors.textPrimary : AppColors.textMuted,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (_isFixedSpeed) ...[
            // Fixed Speed Lock Controls
            Container(
              padding: const EdgeInsets.all(16),
              decoration: ShapeDecoration(
                color: AppColors.secondary.withValues(alpha: 0.1),
                shape: RoundedSuperellipseBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.secondary),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_rounded, color: AppColors.secondary, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText.h2('ĐANG KHÓA QUẠT CỐ ĐỊNH Ở MỨC $_fixedPwm% PWM (~${((_fixedPwm / 100.0) * 2800).round()} RPM)'),
                        AppText.caption('Quạt quay cố định mức $_fixedPwm% PWM (~${((_fixedPwm / 100.0) * 2800).round()} RPM) trên mọi dải nhiệt độ hệ thống.'),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 200,
                    child: SliderTheme(
                      data: const SliderThemeData(trackHeight: 6, activeTrackColor: AppColors.secondary),
                      child: Slider(
                        value: _fixedPwm.toDouble(),
                        min: 0,
                        max: 100,
                        divisions: 100,
                        onChanged: (val) => _setFixedPwm(val.round()),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Interactive Chart Container
          LayoutBuilder(
            builder: (context, constraints) {
              final double width = constraints.maxWidth;
              const double height = 260.0;

              const double leftMargin = 45.0;
              const double rightMargin = 16.0;
              const double topMargin = 16.0;
              const double bottomMargin = 38.0;

              final double plotWidth = width - leftMargin - rightMargin;
              final double plotHeight = height - topMargin - bottomMargin;

              return SizedBox(
                width: width,
                height: height,
                child: Stack(
                  children: [
                    LineChart(
                      LineChartData(
                        lineTouchData: const LineTouchData(enabled: false),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: true,
                          horizontalInterval: 20,
                          verticalInterval: 10,
                          getDrawingHorizontalLine: (val) => const FlLine(
                            color: AppColors.border,
                            strokeWidth: 1,
                          ),
                          getDrawingVerticalLine: (val) => const FlLine(
                            color: AppColors.border,
                            strokeWidth: 1,
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              interval: 10,
                              getTitlesWidget: (val, meta) => Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: AppText(
                                  '${val.toInt()}°C',
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              interval: 20,
                              getTitlesWidget: (val, meta) => AppText(
                                '${val.toInt()}%',
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: Border.all(color: AppColors.borderLight, width: 1),
                        ),
                        minX: 20,
                        maxX: 100,
                        minY: 0,
                        maxY: 100,
                        lineBarsData: [
                          LineChartBarData(
                            spots: _curvePoints.map((p) => FlSpot(p.temp, p.pwm)).toList(),
                            isCurved: !_isFixedSpeed,
                            color: _isFixedSpeed ? AppColors.secondary : widget.profile.themeColor,
                            barWidth: 3.5,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: (_isFixedSpeed ? AppColors.secondary : widget.profile.themeColor).withValues(alpha: 0.18),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Draggable Handles when in Dynamic Curve mode
                    if (!_isFixedSpeed)
                      for (int i = 0; i < _curvePoints.length; i++) ...[
                        () {
                          final point = _curvePoints[i];
                          final double posX = leftMargin + ((point.temp - 20.0) / 80.0) * plotWidth;
                          final double posY = topMargin + (1.0 - (point.pwm / 100.0)) * plotHeight;
                          final bool isActive = _activePointIndex == i;
                          const double touchRadius = 24.0;

                          return Positioned(
                            left: posX - touchRadius,
                            top: posY - touchRadius,
                            child: GestureDetector(
                              onPanStart: (_) {
                                setState(() => _activePointIndex = i);
                              },
                              onPanUpdate: (details) {
                                double dyRatio = details.delta.dy / plotHeight;
                                double newPwm = (_curvePoints[i].pwm - (dyRatio * 100)).clamp(0.0, 100.0);
                                _updatePointPwm(i, newPwm);
                              },
                              onPanEnd: (_) {
                                setState(() => _activePointIndex = null);
                              },
                              child: MouseRegion(
                                cursor: SystemMouseCursors.resizeUpDown,
                                child: Container(
                                  width: touchRadius * 2,
                                  height: touchRadius * 2,
                                  color: Colors.transparent,
                                  child: Center(
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        AnimatedContainer(
                                          duration: const Duration(milliseconds: 150),
                                          width: isActive ? 24 : 18,
                                          height: isActive ? 24 : 18,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: widget.profile.themeColor.withValues(alpha: isActive ? 0.4 : 0.2),
                                            border: Border.all(
                                              color: widget.profile.themeColor,
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          width: 10,
                                          height: 10,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.white,
                                          ),
                                        ),
                                        if (isActive)
                                          Positioned(
                                            bottom: 26,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: ShapeDecoration(
                                                color: Colors.black,
                                                shape: RoundedSuperellipseBorder(
                                                  borderRadius: BorderRadius.circular(6),
                                                  side: BorderSide(color: widget.profile.themeColor),
                                                ),
                                              ),
                                              child: AppText(
                                                '${point.pwm.toInt()}% (~${((point.pwm / 100.0) * 2800).round()} RPM)',
                                                fontSize: 11,
                                                fontWeight: FontWeight.w800,
                                                color: widget.profile.themeColor,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }(),
                      ],
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // Interactive Control Points Breakdown with Sliders (Dynamic Curve mode)
          if (!_isFixedSpeed) ...[
            AppText.h2('TÙY CHỈNH TỪNG MỐC NHIỆT ĐỘ PROFILE "${widget.profile.name.toUpperCase()}"'),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 650;

                if (isNarrow) {
                  return Column(
                    children: _curvePoints.asMap().entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildPointControlCard(entry.key, entry.value),
                      );
                    }).toList(),
                  );
                }

                return Row(
                  children: _curvePoints.asMap().entries.map((entry) {
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildPointControlCard(entry.key, entry.value),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPointControlCard(int index, FanCurvePoint point) {
    final isSelected = _activePointIndex == index;
    final color = widget.profile.themeColor;

    return GestureDetector(
      onTap: () => setState(() => _activePointIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: ShapeDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : AppColors.surfaceLight.withValues(alpha: 0.5),
          shape: RoundedSuperellipseBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected ? color : AppColors.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppText(
                  '${point.temp.toInt()}°C',
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
                AppText(
                  '${point.pwm.toInt()}% (~${((point.pwm / 100.0) * 2800).round()} RPM)',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                  isMonospace: true,
                ),
              ],
            ),
            const SizedBox(height: 8),
            SliderTheme(
              data: SliderThemeData(
                trackHeight: 6,
                activeTrackColor: color,
                inactiveTrackColor: AppColors.border,
                thumbColor: Colors.white,
                overlayColor: color.withValues(alpha: 0.2),
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              ),
              child: Slider(
                value: point.pwm.clamp(0, 100),
                min: 0,
                max: 100,
                divisions: 100,
                onChanged: (val) => _updatePointPwm(index, val),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
