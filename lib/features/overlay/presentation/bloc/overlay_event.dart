import 'package:equatable/equatable.dart';
import 'package:smart_fan_cooling/features/overlay/domain/models/overlay_config.dart';

abstract class OverlayEvent extends Equatable {
  const OverlayEvent();

  @override
  List<Object?> get props => [];
}

class LoadOverlayConfigEvent extends OverlayEvent {
  const LoadOverlayConfigEvent();
}

class UpdateOverlayConfigEvent extends OverlayEvent {
  final OverlayConfig config;
  const UpdateOverlayConfigEvent(this.config);

  @override
  List<Object?> get props => [config];
}

class ToggleOverlayEnabledEvent extends OverlayEvent {
  final bool enabled;
  const ToggleOverlayEnabledEvent(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

class ToggleOverlayLockEvent extends OverlayEvent {
  final bool locked;
  const ToggleOverlayLockEvent(this.locked);

  @override
  List<Object?> get props => [locked];
}

class UpdateOverlayPositionEvent extends OverlayEvent {
  final double posX;
  final double posY;
  const UpdateOverlayPositionEvent(this.posX, this.posY);

  @override
  List<Object?> get props => [posX, posY];
}

class ResetOverlayConfigEvent extends OverlayEvent {
  const ResetOverlayConfigEvent();
}
