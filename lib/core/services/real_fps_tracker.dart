import 'package:flutter/scheduler.dart';

/// Real High-Precision FPS Tracker for Flutter Desktop
class RealFpsTracker {
  static final RealFpsTracker _instance = RealFpsTracker._internal();
  factory RealFpsTracker() => _instance;
  RealFpsTracker._internal();

  int _currentFps = 120;
  int get currentFps => _currentFps;

  int _frameCount = 0;
  DateTime _lastMeasurementTime = DateTime.now();
  bool _isInitialized = false;

  void init() {
    if (_isInitialized) return;
    _isInitialized = true;
    SchedulerBinding.instance.addTimingsCallback(_onReportTimings);
  }

  void _onReportTimings(List<FrameTiming> timings) {
    _frameCount += timings.length;
    final now = DateTime.now();
    final elapsedMs = now.difference(_lastMeasurementTime).inMilliseconds;
    if (elapsedMs >= 1000) {
      final calculated = ((_frameCount * 1000) / elapsedMs).round();
      if (calculated > 0) {
        _currentFps = calculated.clamp(1, 360);
      }
      _frameCount = 0;
      _lastMeasurementTime = now;
    }
  }
}
