import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:smart_fan_cooling/core/theme/app_colors.dart';
import 'package:smart_fan_cooling/features/profiles/domain/models/app_mapping.dart';
import 'package:smart_fan_cooling/features/profiles/domain/models/fan_curve_point.dart';
import 'package:smart_fan_cooling/features/profiles/domain/models/fan_profile.dart';

enum ProfileStatus { initial, loading, success, failure }

class ProfileState extends Equatable {
  final ProfileStatus status;
  final List<FanProfile> profiles;
  final String activeProfileId;
  final List<AppMapping> appMappings;
  final String? errorMessage;

  const ProfileState({
    required this.status,
    required this.profiles,
    required this.activeProfileId,
    required this.appMappings,
    this.errorMessage,
  });

  static const _fallbackProfile = FanProfile(
    id: 'profile_silent',
    name: 'Silent / Văn Phòng',
    description: 'Quạt quay êm ái, tối đa 40% PWM, phù hợp làm việc văn phòng, xem phim',
    icon: Icons.volume_off_rounded,
    themeColor: AppColors.primary,
    maxFanPwm: 40,
    fanCurve: [
      FanCurvePoint(30, 15),
      FanCurvePoint(45, 25),
      FanCurvePoint(60, 35),
      FanCurvePoint(75, 40),
      FanCurvePoint(90, 40),
    ],
    rgbMode: 'Breathing',
    rgbColor: AppColors.primary,
    isDefault: true,
    isFixedSpeed: false,
    fixedPwm: 40,
  );

  FanProfile get activeProfile {
    if (profiles.isEmpty) return _fallbackProfile;
    return profiles.firstWhere(
      (p) => p.id == activeProfileId,
      orElse: () => profiles.first,
    );
  }

  factory ProfileState.initial() {
    return const ProfileState(
      status: ProfileStatus.initial,
      profiles: [_fallbackProfile],
      activeProfileId: 'profile_silent',
      appMappings: [],
    );
  }

  ProfileState copyWith({
    ProfileStatus? status,
    List<FanProfile>? profiles,
    String? activeProfileId,
    List<AppMapping>? appMappings,
    String? errorMessage,
  }) {
    return ProfileState(
      status: status ?? this.status,
      profiles: profiles ?? this.profiles,
      activeProfileId: activeProfileId ?? this.activeProfileId,
      appMappings: appMappings ?? this.appMappings,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        profiles,
        activeProfileId,
        appMappings,
        errorMessage,
      ];
}
