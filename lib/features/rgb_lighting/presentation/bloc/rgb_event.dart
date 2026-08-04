import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

abstract class RgbEvent extends Equatable {
  const RgbEvent();

  @override
  List<Object?> get props => [];
}

class ChangeRgbModeEvent extends RgbEvent {
  final String mode;

  const ChangeRgbModeEvent(this.mode);

  @override
  List<Object?> get props => [mode];
}

class ChangeRgbPrimaryColorEvent extends RgbEvent {
  final Color color;

  const ChangeRgbPrimaryColorEvent(this.color);

  @override
  List<Object?> get props => [color];
}

class ChangeRgbBrightnessEvent extends RgbEvent {
  final int brightness;

  const ChangeRgbBrightnessEvent(this.brightness);

  @override
  List<Object?> get props => [brightness];
}

class ChangeRgbSpeedEvent extends RgbEvent {
  final int speed;

  const ChangeRgbSpeedEvent(this.speed);

  @override
  List<Object?> get props => [speed];
}
