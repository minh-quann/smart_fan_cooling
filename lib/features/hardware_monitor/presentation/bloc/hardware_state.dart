import 'package:equatable/equatable.dart';
import 'package:smart_fan_cooling/features/hardware_monitor/domain/models/hardware_stats.dart';

enum HardwareStatus { initial, loading, success, failure }

class HardwareState extends Equatable {
  final HardwareStatus status;
  final HardwareStats stats;
  final List<double> cpuTempHistory;
  final List<double> gpuTempHistory;
  final List<double> cpuUsageHistory;
  final List<double> ramUsageHistory;
  final List<double> fanRpmHistory;
  final String? errorMessage;

  const HardwareState({
    required this.status,
    required this.stats,
    required this.cpuTempHistory,
    required this.gpuTempHistory,
    required this.cpuUsageHistory,
    required this.ramUsageHistory,
    required this.fanRpmHistory,
    this.errorMessage,
  });

  factory HardwareState.initial() {
    return HardwareState(
      status: HardwareStatus.initial,
      stats: HardwareStats.initial(),
      cpuTempHistory: List<double>.filled(15, 50.0),
      gpuTempHistory: List<double>.filled(15, 50.0),
      cpuUsageHistory: List<double>.filled(15, 10.0),
      ramUsageHistory: List<double>.filled(15, 60.0),
      fanRpmHistory: List<double>.filled(15, 1400.0),
    );
  }

  HardwareState copyWith({
    HardwareStatus? status,
    HardwareStats? stats,
    List<double>? cpuTempHistory,
    List<double>? gpuTempHistory,
    List<double>? cpuUsageHistory,
    List<double>? ramUsageHistory,
    List<double>? fanRpmHistory,
    String? errorMessage,
  }) {
    return HardwareState(
      status: status ?? this.status,
      stats: stats ?? this.stats,
      cpuTempHistory: cpuTempHistory ?? this.cpuTempHistory,
      gpuTempHistory: gpuTempHistory ?? this.gpuTempHistory,
      cpuUsageHistory: cpuUsageHistory ?? this.cpuUsageHistory,
      ramUsageHistory: ramUsageHistory ?? this.ramUsageHistory,
      fanRpmHistory: fanRpmHistory ?? this.fanRpmHistory,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        stats,
        cpuTempHistory,
        gpuTempHistory,
        cpuUsageHistory,
        ramUsageHistory,
        fanRpmHistory,
        errorMessage,
      ];
}
