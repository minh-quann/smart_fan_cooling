import 'package:equatable/equatable.dart';

/// Represents real-time hardware telemetry data for Laptop system & Llano Fan.
class HardwareStats extends Equatable {
  final String cpuName; // Exact CPU model name
  final String gpuName; // Exact GPU model name
  final double cpuTemp; // Average CPU Temperature (°C)
  final double gpuTemp; // Average GPU Temperature (°C)
  final double cpuUsage; // %
  final double gpuUsage; // %
  final double ramUsage; // %
  final int fanRpm; // Real RPM from Opto PC817 (e.g. 0 to 4500 RPM)
  final int pwmPercent; // Target PWM duty cycle (0 to 100%)
  final double cpuClock; // GHz
  final double gpuClock; // MHz
  final bool isFanConnected; // Connection status

  const HardwareStats({
    required this.cpuName,
    required this.gpuName,
    required this.cpuTemp,
    required this.gpuTemp,
    required this.cpuUsage,
    required this.gpuUsage,
    required this.ramUsage,
    required this.fanRpm,
    required this.pwmPercent,
    required this.cpuClock,
    required this.gpuClock,
    this.isFanConnected = true,
  });

  factory HardwareStats.initial() {
    return const HardwareStats(
      cpuName: 'Intel / AMD Processor',
      gpuName: 'NVIDIA / AMD GPU',
      cpuTemp: 45.0,
      gpuTemp: 42.0,
      cpuUsage: 18.0,
      gpuUsage: 12.0,
      ramUsage: 42.0,
      fanRpm: 1400,
      pwmPercent: 50,
      cpuClock: 3.4,
      gpuClock: 1450,
      isFanConnected: true,
    );
  }

  HardwareStats copyWith({
    String? cpuName,
    String? gpuName,
    double? cpuTemp,
    double? gpuTemp,
    double? cpuUsage,
    double? gpuUsage,
    double? ramUsage,
    int? fanRpm,
    int? pwmPercent,
    double? cpuClock,
    double? gpuClock,
    bool? isFanConnected,
  }) {
    return HardwareStats(
      cpuName: cpuName ?? this.cpuName,
      gpuName: gpuName ?? this.gpuName,
      cpuTemp: cpuTemp ?? this.cpuTemp,
      gpuTemp: gpuTemp ?? this.gpuTemp,
      cpuUsage: cpuUsage ?? this.cpuUsage,
      gpuUsage: gpuUsage ?? this.gpuUsage,
      ramUsage: ramUsage ?? this.ramUsage,
      fanRpm: fanRpm ?? this.fanRpm,
      pwmPercent: pwmPercent ?? this.pwmPercent,
      cpuClock: cpuClock ?? this.cpuClock,
      gpuClock: gpuClock ?? this.gpuClock,
      isFanConnected: isFanConnected ?? this.isFanConnected,
    );
  }

  @override
  List<Object?> get props => [
        cpuName,
        gpuName,
        cpuTemp,
        gpuTemp,
        cpuUsage,
        gpuUsage,
        ramUsage,
        fanRpm,
        pwmPercent,
        cpuClock,
        gpuClock,
        isFanConnected,
      ];
}
