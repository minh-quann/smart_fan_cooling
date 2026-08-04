import 'package:equatable/equatable.dart';

/// Single point on the Fan Curve graph (Temperature in °C -> Target PWM %).
class FanCurvePoint extends Equatable {
  final double temp; // °C
  final double pwm; // % (0.0 to 100.0)

  const FanCurvePoint(this.temp, this.pwm);

  FanCurvePoint copyWith({double? temp, double? pwm}) {
    return FanCurvePoint(
      temp ?? this.temp,
      pwm ?? this.pwm,
    );
  }

  @override
  List<Object?> get props => [temp, pwm];
}
