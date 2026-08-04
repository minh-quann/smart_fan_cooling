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
    // Keep max 20 history data points for fl_chart line graphs
    final newCpuHistory = List<double>.from(state.cpuTempHistory)..add(event.stats.cpuTemp);
    if (newCpuHistory.length > 20) newCpuHistory.removeAt(0);

    final newGpuHistory = List<double>.from(state.gpuTempHistory)..add(event.stats.gpuTemp);
    if (newGpuHistory.length > 20) newGpuHistory.removeAt(0);

    final newFanHistory = List<double>.from(state.fanRpmHistory)..add(event.stats.fanRpm.toDouble());
    if (newFanHistory.length > 20) newFanHistory.removeAt(0);

    emit(state.copyWith(
      status: HardwareStatus.success,
      stats: event.stats,
      cpuTempHistory: newCpuHistory,
      gpuTempHistory: newGpuHistory,
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
