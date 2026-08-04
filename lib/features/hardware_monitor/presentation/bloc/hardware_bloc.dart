import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_fan_cooling/features/hardware_monitor/data/services/hardware_monitor_service.dart';
import 'package:smart_fan_cooling/features/hardware_monitor/presentation/bloc/hardware_event.dart';
import 'package:smart_fan_cooling/features/hardware_monitor/presentation/bloc/hardware_state.dart';

class HardwareBloc extends Bloc<HardwareEvent, HardwareState> {
  final HardwareMonitorService _service;
  StreamSubscription? _subscription;

  HardwareBloc(this._service) : super(HardwareState.initial()) {
    on<StartHardwareMonitoringEvent>(_onStartMonitoring);
    on<HardwareStatsUpdatedEvent>(_onStatsUpdated);
    on<ChangePwmSpeedEvent>(_onChangePwmSpeed);
  }

  void _onStartMonitoring(
    StartHardwareMonitoringEvent event,
    Emitter<HardwareState> emit,
  ) {
    emit(state.copyWith(status: HardwareStatus.loading));
    _service.startMonitoring();

    _subscription?.cancel();
    _subscription = _service.statsStream.listen((newStats) {
      add(HardwareStatsUpdatedEvent(newStats));
    });
  }

  void _onStatsUpdated(
    HardwareStatsUpdatedEvent event,
    Emitter<HardwareState> emit,
  ) {
    const int maxPoints = 20;

    final newCpuTempHistory = List<double>.from(state.cpuTempHistory)..add(event.stats.cpuTemp);
    if (newCpuTempHistory.length > maxPoints) newCpuTempHistory.removeAt(0);

    final newGpuTempHistory = List<double>.from(state.gpuTempHistory)..add(event.stats.gpuTemp);
    if (newGpuTempHistory.length > maxPoints) newGpuTempHistory.removeAt(0);

    final newCpuUsageHistory = List<double>.from(state.cpuUsageHistory)..add(event.stats.cpuUsage);
    if (newCpuUsageHistory.length > maxPoints) newCpuUsageHistory.removeAt(0);

    final newRamUsageHistory = List<double>.from(state.ramUsageHistory)..add(event.stats.ramUsage);
    if (newRamUsageHistory.length > maxPoints) newRamUsageHistory.removeAt(0);

    final newFanHistory = List<double>.from(state.fanRpmHistory)..add(event.stats.fanRpm.toDouble());
    if (newFanHistory.length > maxPoints) newFanHistory.removeAt(0);

    emit(state.copyWith(
      status: HardwareStatus.success,
      stats: event.stats,
      cpuTempHistory: newCpuTempHistory,
      gpuTempHistory: newGpuTempHistory,
      cpuUsageHistory: newCpuUsageHistory,
      ramUsageHistory: newRamUsageHistory,
      fanRpmHistory: newFanHistory,
    ));
  }

  void _onChangePwmSpeed(
    ChangePwmSpeedEvent event,
    Emitter<HardwareState> emit,
  ) {
    _service.updatePwmPercent(event.pwmPercent);
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    _service.dispose();
    return super.close();
  }
}
