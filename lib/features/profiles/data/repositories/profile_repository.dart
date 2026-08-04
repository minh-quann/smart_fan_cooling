import 'package:flutter/material.dart';
import 'package:smart_fan_cooling/core/theme/app_colors.dart';
import 'package:smart_fan_cooling/features/profiles/domain/models/app_mapping.dart';
import 'package:smart_fan_cooling/features/profiles/domain/models/fan_curve_point.dart';
import 'package:smart_fan_cooling/features/profiles/domain/models/fan_profile.dart';

class ProfileRepository {
  final List<FanProfile> _profiles = [
    const FanProfile(
      id: 'profile_silent',
      name: 'Silent',
      description: 'Quạt quay êm ái, tối đa 40% PWM, phù hợp làm việc văn phòng, xem phim',
      icon: Icons.volume_off_rounded,
      themeColor: AppColors.primary,
      maxFanPwm: 50,
      fanCurve: [
        FanCurvePoint(30, 15),
        FanCurvePoint(45, 25),
        FanCurvePoint(60, 35),
        FanCurvePoint(75, 40),
        FanCurvePoint(90, 45),
        FanCurvePoint(100, 60),
      ],
      rgbMode: 'Breathing',
      rgbColor: AppColors.primary,
      isDefault: true,
      isFixedSpeed: false,
      fixedPwm: 40,
    ),
    const FanProfile(
      id: 'profile_balanced',
      name: 'Balanced',
      description: 'Tự động cân bằng giữa hiệu năng làm mát và tiếng ồn',
      icon: Icons.tune_rounded,
      themeColor: AppColors.secondary,
      maxFanPwm: 100,
      fanCurve: [
        FanCurvePoint(30, 20),
        FanCurvePoint(45, 35),
        FanCurvePoint(60, 55),
        FanCurvePoint(75, 75),
        FanCurvePoint(90, 85),
        FanCurvePoint(100, 100),
      ],
      rgbMode: 'Rainbow',
      rgbColor: AppColors.secondary,
      isDefault: true,
      isFixedSpeed: false,
      fixedPwm: 60,
    ),
    const FanProfile(
      id: 'profile_turbo',
      name: 'Turbo',
      description: 'Đẩy công suất quạt Llano tối đa 100% khi chơi game nặng hay Render',
      icon: Icons.bolt_rounded,
      themeColor: AppColors.accentRed,
      maxFanPwm: 100,
      fanCurve: [
        FanCurvePoint(30, 35),
        FanCurvePoint(45, 55),
        FanCurvePoint(60, 80),
        FanCurvePoint(75, 95),
        FanCurvePoint(90, 100),
        FanCurvePoint(100, 100),
      ],
      rgbMode: 'ThermalSync',
      rgbColor: AppColors.accentRed,
      isDefault: true,
      isFixedSpeed: false,
      fixedPwm: 100,
    ),
    const FanProfile(
      id: 'profile_adaptive',
      name: 'Adaptive',
      description: 'Tự động điều chỉnh công suất quạt thông minh dựa trên đường cong nhiệt độ thực tế',
      icon: Icons.auto_awesome_rounded,
      themeColor: AppColors.accentPurple,
      maxFanPwm: 100,
      fanCurve: [
        FanCurvePoint(30, 20),
        FanCurvePoint(45, 40),
        FanCurvePoint(60, 65),
        FanCurvePoint(75, 85),
        FanCurvePoint(90, 95),
        FanCurvePoint(100, 100),
      ],
      rgbMode: 'Wave',
      rgbColor: AppColors.accentPurple,
      isDefault: true,
      isFixedSpeed: false,
      fixedPwm: 50,
    ),
  ];

  final List<AppMapping> _appMappings = [
    const AppMapping(
      id: 'app_1',
      appName: 'Google Chrome',
      executableName: 'chrome.exe',
      iconPath: 'chrome',
      profileId: 'profile_silent',
      isEnabled: true,
    ),
    const AppMapping(
      id: 'app_2',
      appName: 'Microsoft Word / Office',
      executableName: 'winword.exe',
      iconPath: 'word',
      profileId: 'profile_silent',
      isEnabled: true,
    ),
    const AppMapping(
      id: 'app_3',
      appName: 'Cyberpunk 2077',
      executableName: 'cyberpunk2077.exe',
      iconPath: 'game',
      profileId: 'profile_turbo',
      isEnabled: true,
    ),
    const AppMapping(
      id: 'app_4',
      appName: 'Adobe Premiere Pro',
      executableName: 'adobe_premiere.exe',
      iconPath: 'video',
      profileId: 'profile_turbo',
      isEnabled: true,
    ),
  ];

  List<FanProfile> getProfiles() => List.unmodifiable(_profiles);

  List<AppMapping> getAppMappings() => List.unmodifiable(_appMappings);

  void addProfile(FanProfile profile) {
    _profiles.add(profile);
  }

  void updateProfile(FanProfile profile) {
    int idx = _profiles.indexWhere((p) => p.id == profile.id);
    if (idx != -1) {
      _profiles[idx] = profile;
    }
  }

  void deleteProfile(String id) {
    _profiles.removeWhere((p) => p.id == id && !p.isDefault);
  }

  void addAppMapping(AppMapping mapping) {
    _appMappings.add(mapping);
  }

  void toggleAppMapping(String id, bool enabled) {
    int idx = _appMappings.indexWhere((a) => a.id == id);
    if (idx != -1) {
      _appMappings[idx] = _appMappings[idx].copyWith(isEnabled: enabled);
    }
  }

  void deleteAppMapping(String id) {
    _appMappings.removeWhere((a) => a.id == id);
  }
}
