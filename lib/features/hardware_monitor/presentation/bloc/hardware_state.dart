import 'package:equatable/equatable.dart';
import 'package:smart_fan_cooling/features/hardware_monitor/domain/models/hardware_stats.dart';

enum HardwareStatus { initial, loading, success, failure }

class HardwareState extends Equatable {
  final HardwareStatus status;
  final HardwareStats stats;
  final List<double> cpuTempHistory;
  final List<double> gpuTempHistory;
  final List<double> fanRpmHistory;
  final String? errorMessage;

  const HardwareState({
    required this.status,
    required this.stats,
    required this.cpuTempHistory,
    required this.gpuTempHistory,
    required this.fanRpmHistory,
    this.errorMessage,
  });

  factory HardwareState.initial() {
    return HardwareState(
      status: HardwareStatus.initial,
      stats: HardwareStats.initial(),
      cpuTempHistory: const [42, 44, 45, 43, 46, 45, 47, 45],
      gpuTempHistory: const [40, 41, 42, 41, 43, 42, 44, 42],
      fanRpmHistory: const [2000, 2100, 2150, 2100, 2200, 2150],
    );
  }

  HardwareState copyWith({
    HardwareStatus? status,
    HardwareStats? stats,
    List<double>? cpuTempHistory,
    List<double>? gpuTempHistory,
    List<double>? fanRpmHistory,
    String? errorMessage,
  }) {
    return HardwareState(
      status: status ?? this.status,
      stats: stats ?? this.stats,
      cpuTempHistory: cpuTempHistory ?? this.cpuTempHistory,
      gpuTempHistory: gpuTempHistory ?? this.gpuTempHistory,
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
        fanRpmHistory,
        errorMessage,
      ];
}
