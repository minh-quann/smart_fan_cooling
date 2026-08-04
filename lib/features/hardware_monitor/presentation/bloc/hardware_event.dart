import 'package:equatable/equatable.dart';
import 'package:smart_fan_cooling/features/hardware_monitor/domain/models/hardware_stats.dart';

abstract class HardwareEvent extends Equatable {
  const HardwareEvent();

  @override
  List<Object?> get props => [];
}

class StartHardwareMonitoringEvent extends HardwareEvent {
  const StartHardwareMonitoringEvent();
}

class HardwareStatsUpdatedEvent extends HardwareEvent {
  final HardwareStats stats;

  const HardwareStatsUpdatedEvent(this.stats);

  @override
  List<Object?> get props => [stats];
}

class ChangePwmSpeedEvent extends HardwareEvent {
  final int pwmPercent;

  const ChangePwmSpeedEvent(this.pwmPercent);

  @override
  List<Object?> get props => [pwmPercent];
}
