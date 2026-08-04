import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_fan_cooling/features/rgb_lighting/presentation/bloc/rgb_event.dart';
import 'package:smart_fan_cooling/features/rgb_lighting/presentation/bloc/rgb_state.dart';

class RgbBloc extends Bloc<RgbEvent, RgbState> {
  RgbBloc() : super(RgbState.initial()) {
    on<ChangeRgbModeEvent>(_onChangeMode);
    on<ChangeRgbPrimaryColorEvent>(_onChangePrimaryColor);
    on<ChangeRgbBrightnessEvent>(_onChangeBrightness);
    on<ChangeRgbSpeedEvent>(_onChangeSpeed);
  }

  void _onChangeMode(ChangeRgbModeEvent event, Emitter<RgbState> emit) {
    emit(state.copyWith(config: state.config.copyWith(mode: event.mode)));
  }

  void _onChangePrimaryColor(ChangeRgbPrimaryColorEvent event, Emitter<RgbState> emit) {
    emit(state.copyWith(config: state.config.copyWith(primaryColor: event.color)));
  }

  void _onChangeBrightness(ChangeRgbBrightnessEvent event, Emitter<RgbState> emit) {
    emit(state.copyWith(config: state.config.copyWith(brightness: event.brightness)));
  }

  void _onChangeSpeed(ChangeRgbSpeedEvent event, Emitter<RgbState> emit) {
    emit(state.copyWith(config: state.config.copyWith(animationSpeed: event.speed)));
  }
}
