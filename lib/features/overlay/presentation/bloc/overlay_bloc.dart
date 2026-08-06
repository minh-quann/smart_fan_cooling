import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_fan_cooling/features/overlay/domain/models/overlay_config.dart';
import 'package:smart_fan_cooling/features/overlay/presentation/bloc/overlay_event.dart';
import 'package:smart_fan_cooling/features/overlay/presentation/bloc/overlay_state.dart';

class OverlayBloc extends Bloc<OverlayEvent, OsdOverlayState> {
  static const String _prefKey = 'smart_fan_overlay_config_v1';

  OverlayBloc() : super(const OsdOverlayState()) {
    on<LoadOverlayConfigEvent>(_onLoadConfig);
    on<UpdateOverlayConfigEvent>(_onUpdateConfig);
    on<ToggleOverlayEnabledEvent>(_onToggleEnabled);
    on<ToggleOverlayLockEvent>(_onToggleLock);
    on<UpdateOverlayPositionEvent>(_onUpdatePosition);
    on<ResetOverlayConfigEvent>(_onResetConfig);

    add(const LoadOverlayConfigEvent());
  }

  Future<void> _onLoadConfig(
    LoadOverlayConfigEvent event,
    Emitter<OsdOverlayState> emit,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawJson = prefs.getString(_prefKey);
      if (rawJson != null && rawJson.isNotEmpty) {
        final config = OverlayConfig.fromJson(rawJson);
        emit(state.copyWith(config: config));
      }
    } catch (_) {}
  }

  Future<void> _onUpdateConfig(
    UpdateOverlayConfigEvent event,
    Emitter<OsdOverlayState> emit,
  ) async {
    emit(state.copyWith(config: event.config));
    await _saveToPrefs(event.config);
  }

  Future<void> _onToggleEnabled(
    ToggleOverlayEnabledEvent event,
    Emitter<OsdOverlayState> emit,
  ) async {
    final updated = state.config.copyWith(isEnabled: event.enabled);
    emit(state.copyWith(config: updated));
    await _saveToPrefs(updated);
  }

  Future<void> _onToggleLock(
    ToggleOverlayLockEvent event,
    Emitter<OsdOverlayState> emit,
  ) async {
    final updated = state.config.copyWith(isLocked: event.locked);
    emit(state.copyWith(config: updated));
    await _saveToPrefs(updated);
  }

  Future<void> _onUpdatePosition(
    UpdateOverlayPositionEvent event,
    Emitter<OsdOverlayState> emit,
  ) async {
    final updated = state.config.copyWith(posX: event.posX, posY: event.posY);
    emit(state.copyWith(config: updated));
    await _saveToPrefs(updated);
  }

  Future<void> _onResetConfig(
    ResetOverlayConfigEvent event,
    Emitter<OsdOverlayState> emit,
  ) async {
    const defaultConfig = OverlayConfig();
    emit(state.copyWith(config: defaultConfig));
    await _saveToPrefs(defaultConfig);
  }

  Future<void> _saveToPrefs(OverlayConfig config) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, config.toJson());
    } catch (_) {}
  }
}
