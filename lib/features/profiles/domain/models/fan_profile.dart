import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:smart_fan_cooling/features/profiles/domain/models/fan_curve_point.dart';

/// Fan Profile model representing a complete cooling & lighting profile preset.
class FanProfile extends Equatable {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color themeColor;
  final int maxFanPwm; // Max allowed PWM speed (0-100%)
  final List<FanCurvePoint> fanCurve;
  final String rgbMode; // 'Static', 'Breathing', 'Rainbow', 'ThermalSync'
  final Color rgbColor;
  final bool isDefault;

  const FanProfile({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.themeColor,
    required this.maxFanPwm,
    required this.fanCurve,
    required this.rgbMode,
    required this.rgbColor,
    this.isDefault = false,
  });

  FanProfile copyWith({
    String? id,
    String? name,
    String? description,
    IconData? icon,
    Color? themeColor,
    int? maxFanPwm,
    List<FanCurvePoint>? fanCurve,
    String? rgbMode,
    Color? rgbColor,
    bool? isDefault,
  }) {
    return FanProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      themeColor: themeColor ?? this.themeColor,
      maxFanPwm: maxFanPwm ?? this.maxFanPwm,
      fanCurve: fanCurve ?? this.fanCurve,
      rgbMode: rgbMode ?? this.rgbMode,
      rgbColor: rgbColor ?? this.rgbColor,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        icon,
        themeColor,
        maxFanPwm,
        fanCurve,
        rgbMode,
        rgbColor,
        isDefault,
      ];
}
