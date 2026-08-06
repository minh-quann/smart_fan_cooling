import 'package:flutter/material.dart';
import 'package:smart_fan_cooling/core/theme/app_colors.dart';
import 'package:smart_fan_cooling/features/profiles/domain/models/fan_curve_point.dart';
import 'package:smart_fan_cooling/shared/widgets/app_text.dart';

/// InteractiveFanCurveChart allows users to drag points both horizontally (Temp °C)
/// and vertically (PWM %) with 100% precise alignment between lines and dots.
class InteractiveFanCurveChart extends StatefulWidget {
  final List<FanCurvePoint> points;
  final Color themeColor;
  final bool isFixedSpeed;
  final Function(int index, double newTemp, double newPwm) onPointChanged;
  final Function(int? activeIndex)? onActivePointChanged;

  const InteractiveFanCurveChart({
    super.key,
    required this.points,
    required this.themeColor,
    this.isFixedSpeed = false,
    required this.onPointChanged,
    this.onActivePointChanged,
  });

  @override
  State<InteractiveFanCurveChart> createState() => _InteractiveFanCurveChartState();
}

class _InteractiveFanCurveChartState extends State<InteractiveFanCurveChart> {
  int? _draggedIndex;

  static const double leftMargin = 42.0;
  static const double rightMargin = 20.0;
  static const double topMargin = 16.0;
  static const double bottomMargin = 32.0;

  double _tempToX(double temp, double plotWidth) {
    return leftMargin + ((temp - 20.0) / 90.0) * plotWidth;
  }

  double _pwmToY(double pwm, double plotHeight) {
    return topMargin + (1.0 - (pwm / 100.0)) * plotHeight;
  }

  double _xToTemp(double x, double plotWidth) {
    return (20.0 + ((x - leftMargin) / plotWidth) * 90.0).clamp(20.0, 100.0);
  }

  double _yToPwm(double y, double plotHeight) {
    return ((1.0 - ((y - topMargin) / plotHeight)) * 100.0).clamp(0.0, 100.0);
  }

  int? _findPointAt(Offset localPos, double plotWidth, double plotHeight) {
    const double hitRadius = 24.0;
    for (int i = 0; i < widget.points.length; i++) {
      final px = _tempToX(widget.points[i].temp, plotWidth);
      final py = _pwmToY(widget.points[i].pwm, plotHeight);
      final dist = (localPos - Offset(px, py)).distance;
      if (dist <= hitRadius) {
        return i;
      }
    }
    return null;
  }

  void _handleDrag(Offset localPos, double plotWidth, double plotHeight) {
    if (_draggedIndex == null || widget.isFixedSpeed) return;

    final idx = _draggedIndex!;
    final rawTemp = _xToTemp(localPos.dx, plotWidth);
    final rawPwm = _yToPwm(localPos.dy, plotHeight);

    // Calculate temp bounds based on neighboring points
    double minTemp = 20.0;
    double maxTemp = 100.0;

    if (idx > 0) {
      minTemp = widget.points[idx - 1].temp + 2.0;
    }
    if (idx < widget.points.length - 1) {
      maxTemp = widget.points[idx + 1].temp - 2.0;
    }

    final newTemp = rawTemp.clamp(minTemp, maxTemp);
    final newPwm = rawPwm.clamp(0.0, 100.0);

    widget.onPointChanged(idx, newTemp, newPwm);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        const double height = 260.0;

        final double plotWidth = width - leftMargin - rightMargin;
        final double plotHeight = height - topMargin - bottomMargin;

        return SizedBox(
          width: width,
          height: height,
          child: GestureDetector(
            onPanStart: (details) {
              final idx = _findPointAt(details.localPosition, plotWidth, plotHeight);
              setState(() => _draggedIndex = idx);
              widget.onActivePointChanged?.call(idx);
              if (idx != null) {
                _handleDrag(details.localPosition, plotWidth, plotHeight);
              }
            },
            onPanUpdate: (details) {
              _handleDrag(details.localPosition, plotWidth, plotHeight);
            },
            onPanEnd: (_) {
              setState(() => _draggedIndex = null);
              widget.onActivePointChanged?.call(null);
            },
            onPanCancel: () {
              setState(() => _draggedIndex = null);
              widget.onActivePointChanged?.call(null);
            },
            child: MouseRegion(
              cursor: widget.isFixedSpeed
                  ? SystemMouseCursors.basic
                  : (_draggedIndex != null
                      ? SystemMouseCursors.grabbing
                      : SystemMouseCursors.grab),
              child: Stack(
                children: [
                  CustomPaint(
                    size: Size(width, height),
                    painter: _CurveChartPainter(
                      points: widget.points,
                      themeColor: widget.themeColor,
                      isFixedSpeed: widget.isFixedSpeed,
                      activeIndex: _draggedIndex,
                      leftMargin: leftMargin,
                      rightMargin: rightMargin,
                      topMargin: topMargin,
                      bottomMargin: bottomMargin,
                    ),
                  ),

                  // Floating Tooltip for active dragged point
                  if (_draggedIndex != null && !_isFixedSpeedIndexValid(_draggedIndex!)) ...[
                    () {
                      final point = widget.points[_draggedIndex!];
                      final px = _tempToX(point.temp, plotWidth);
                      final py = _pwmToY(point.pwm, plotHeight);

                      return Positioned(
                        left: (px - 65).clamp(8.0, width - 138.0),
                        top: (py - 42).clamp(4.0, height - 48.0),
                        child: IgnorePointer(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: ShapeDecoration(
                              color: AppColors.cardBg,
                              shape: RoundedSuperellipseBorder(
                                borderRadius: BorderRadius.circular(6),
                                side: BorderSide(color: widget.themeColor, width: 1.5),
                              ),
                              shadows: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: AppText(
                              '${point.temp.toInt()}°C : ${point.pwm.toInt()}% (~${((point.pwm / 100.0) * 2800).round()} RPM)',
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: widget.themeColor,
                            ),
                          ),
                        ),
                      );
                    }(),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  bool _isFixedSpeedIndexValid(int idx) {
    return widget.isFixedSpeed || idx < 0 || idx >= widget.points.length;
  }
}

class _CurveChartPainter extends CustomPainter {
  final List<FanCurvePoint> points;
  final Color themeColor;
  final bool isFixedSpeed;
  final int? activeIndex;
  final double leftMargin;
  final double rightMargin;
  final double topMargin;
  final double bottomMargin;

  _CurveChartPainter({
    required this.points,
    required this.themeColor,
    required this.isFixedSpeed,
    required this.activeIndex,
    required this.leftMargin,
    required this.rightMargin,
    required this.topMargin,
    required this.bottomMargin,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double plotWidth = size.width - leftMargin - rightMargin;
    final double plotHeight = size.height - topMargin - bottomMargin;

    double tempToX(double temp) => leftMargin + ((temp - 20.0) / 90.0) * plotWidth;
    double pwmToY(double pwm) => topMargin + (1.0 - (pwm / 100.0)) * plotHeight;

    // 1. Draw Grid Lines
    final gridPaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1.0;

    // Horizontal Grid Lines (0%, 20%, 40%, 60%, 80%, 100%)
    for (int p = 0; p <= 100; p += 20) {
      final y = pwmToY(p.toDouble());
      canvas.drawLine(Offset(leftMargin, y), Offset(size.width - rightMargin, y), gridPaint);

      // Y-axis Label Text
      final textPainter = TextPainter(
        text: TextSpan(
          text: '$p%',
          style: const TextStyle(color: AppColors.textMuted, fontSize: 10.5, fontWeight: FontWeight.w600),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(leftMargin - textPainter.width - 6, y - textPainter.height / 2));
    }

    // Vertical Grid Lines (20°C to 110°C, interval 10)
    for (int t = 20; t <= 110; t += 10) {
      final x = tempToX(t.toDouble());
      canvas.drawLine(Offset(x, topMargin), Offset(x, size.height - bottomMargin), gridPaint);

      // X-axis Label Text
      final textPainter = TextPainter(
        text: TextSpan(
          text: '$t°C',
          style: const TextStyle(color: AppColors.textMuted, fontSize: 10.5, fontWeight: FontWeight.w600),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, size.height - bottomMargin + 8));
    }

    // 2. Outer Border Box
    final borderPaint = Paint()
      ..color = AppColors.borderLight
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRect(
      Rect.fromLTRB(leftMargin, topMargin, size.width - rightMargin, size.height - bottomMargin),
      borderPaint,
    );

    if (points.isEmpty) return;

    // 3. Curve Line (Clean Smooth Spline or Segment Line connecting dot centers)
    final color = isFixedSpeed ? AppColors.secondary : themeColor;
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 3.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final p0 = Offset(tempToX(points.first.temp), pwmToY(points.first.pwm));
    path.moveTo(p0.dx, p0.dy);

    for (int i = 0; i < points.length - 1; i++) {
      final pCurrent = Offset(tempToX(points[i].temp), pwmToY(points[i].pwm));
      final pNext = Offset(tempToX(points[i + 1].temp), pwmToY(points[i + 1].pwm));

      final controlX = (pCurrent.dx + pNext.dx) / 2;
      path.cubicTo(controlX, pCurrent.dy, controlX, pNext.dy, pNext.dx, pNext.dy);
    }

    canvas.drawPath(path, linePaint);

    // 4. Control Point Dots (100% aligned with curve path)
    for (int i = 0; i < points.length; i++) {
      final center = Offset(tempToX(points[i].temp), pwmToY(points[i].pwm));
      final bool isActive = activeIndex == i;

      // Outer Ring
      final ringPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      final fillPaint = Paint()
        ..color = color.withValues(alpha: isActive ? 0.4 : 0.2)
        ..style = PaintingStyle.fill;

      final dotCenterPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      final double outerRadius = isActive ? 10.0 : 7.5;
      final double innerRadius = isActive ? 4.0 : 3.0;

      canvas.drawCircle(center, outerRadius, fillPaint);
      canvas.drawCircle(center, outerRadius, ringPaint);
      canvas.drawCircle(center, innerRadius, dotCenterPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CurveChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.themeColor != themeColor ||
        oldDelegate.isFixedSpeed != isFixedSpeed ||
        oldDelegate.activeIndex != activeIndex;
  }
}
