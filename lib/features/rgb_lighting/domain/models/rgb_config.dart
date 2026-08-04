import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:smart_fan_cooling/core/theme/app_colors.dart';

class RgbConfig extends Equatable {
  final String mode; // 'Off', 'Static', 'Breathing', 'Rainbow', 'ThermalSync', 'SpeedSync'
  final Color primaryColor;
  final Color secondaryColor;
  final int brightness; // 0-100%
  final int animationSpeed; // 1-10

  const RgbConfig({
    required this.mode,
    required this.primaryColor,
    required this.secondaryColor,
    required this.brightness,
    required this.animationSpeed,
  });

  factory RgbConfig.initial() {
    return const RgbConfig(
      mode: 'Rainbow',
      primaryColor: AppColors.secondary,
      secondaryColor: AppColors.primary,
      brightness: 80,
      animationSpeed: 5,
    );
  }

  RgbConfig copyWith({
    String? mode,
    Color? primaryColor,
    Color? secondaryColor,
    int? brightness,
    int? animationSpeed,
  }) {
    return RgbConfig(
      mode: mode ?? this.mode,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      brightness: brightness ?? this.brightness,
      animationSpeed: animationSpeed ?? this.animationSpeed,
    );
  }

  @override
  List<Object?> get props => [
        mode,
        primaryColor,
        secondaryColor,
        brightness,
        animationSpeed,
      ];
}
