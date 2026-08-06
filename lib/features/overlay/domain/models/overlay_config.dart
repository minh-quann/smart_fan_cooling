import 'dart:convert';
import 'package:flutter/material.dart';

class OverlayConfig {
  final bool isEnabled;
  final bool isLocked;
  final bool isAlwaysOnTop;
  final String displayMode; // 'always' (Luôn hiển thị) hoặc 'game_only' (Chỉ hiển thị khi chơi game)
  final String style; // 'horizontal', 'horizontal2', 'upright', 'compact'
  final String fontSizeScale; // '720p', '1080p', '2K', '4K'
  final String positionPreset; // 'top_left', 'top_center', 'top_right', 'bottom_left', 'bottom_center', 'bottom_right', 'custom'
  final double backgroundOpacity;
  final int accentColorValue;

  // Basic Metrics
  final bool showFps;
  final bool showTime;
  final bool showRunningTime;
  final bool showSmartFanRpm;
  final bool showSmartFanPwm;

  // CPU Metrics
  final bool showCpuTemp;
  final bool showCpuUsage;
  final bool showCpuPower;
  final bool showCpuClock;
  final bool showCpuFanRpm;

  // GPU Metrics
  final bool showGpuTemp;
  final bool showGpuUsage;
  final bool showGpuPower;
  final bool showGpuClock;
  final bool showGpuFanRpm;

  // RAM Metrics
  final bool showRamUsage;

  // Position
  final double posX;
  final double posY;

  const OverlayConfig({
    this.isEnabled = true,
    this.isLocked = false,
    this.isAlwaysOnTop = true,
    this.displayMode = 'always',
    this.style = 'horizontal',
    this.fontSizeScale = '2K',
    this.positionPreset = 'custom',
    this.backgroundOpacity = 0.75,
    this.accentColorValue = 0xFF00E5FF, // AppColors.primary
    this.showFps = true,
    this.showTime = true,
    this.showRunningTime = false,
    this.showSmartFanRpm = true,
    this.showSmartFanPwm = true,
    this.showCpuTemp = true,
    this.showCpuUsage = true,
    this.showCpuPower = true,
    this.showCpuClock = true,
    this.showCpuFanRpm = false,
    this.showGpuTemp = true,
    this.showGpuUsage = true,
    this.showGpuPower = true,
    this.showGpuClock = false,
    this.showGpuFanRpm = false,
    this.showRamUsage = true,
    this.posX = 40.0,
    this.posY = 30.0,
  });

  Color get accentColor => Color(accentColorValue);

  OverlayConfig copyWith({
    bool? isEnabled,
    bool? isLocked,
    bool? isAlwaysOnTop,
    String? displayMode,
    String? style,
    String? fontSizeScale,
    String? positionPreset,
    double? backgroundOpacity,
    int? accentColorValue,
    bool? showFps,
    bool? showTime,
    bool? showRunningTime,
    bool? showSmartFanRpm,
    bool? showSmartFanPwm,
    bool? showCpuTemp,
    bool? showCpuUsage,
    bool? showCpuPower,
    bool? showCpuClock,
    bool? showCpuFanRpm,
    bool? showGpuTemp,
    bool? showGpuUsage,
    bool? showGpuPower,
    bool? showGpuClock,
    bool? showGpuFanRpm,
    bool? showRamUsage,
    double? posX,
    double? posY,
  }) {
    return OverlayConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      isLocked: isLocked ?? this.isLocked,
      isAlwaysOnTop: isAlwaysOnTop ?? this.isAlwaysOnTop,
      displayMode: displayMode ?? this.displayMode,
      style: style ?? this.style,
      fontSizeScale: fontSizeScale ?? this.fontSizeScale,
      positionPreset: positionPreset ?? this.positionPreset,
      backgroundOpacity: backgroundOpacity ?? this.backgroundOpacity,
      accentColorValue: accentColorValue ?? this.accentColorValue,
      showFps: showFps ?? this.showFps,
      showTime: showTime ?? this.showTime,
      showRunningTime: showRunningTime ?? this.showRunningTime,
      showSmartFanRpm: showSmartFanRpm ?? this.showSmartFanRpm,
      showSmartFanPwm: showSmartFanPwm ?? this.showSmartFanPwm,
      showCpuTemp: showCpuTemp ?? this.showCpuTemp,
      showCpuUsage: showCpuUsage ?? this.showCpuUsage,
      showCpuPower: showCpuPower ?? this.showCpuPower,
      showCpuClock: showCpuClock ?? this.showCpuClock,
      showCpuFanRpm: showCpuFanRpm ?? this.showCpuFanRpm,
      showGpuTemp: showGpuTemp ?? this.showGpuTemp,
      showGpuUsage: showGpuUsage ?? this.showGpuUsage,
      showGpuPower: showGpuPower ?? this.showGpuPower,
      showGpuClock: showGpuClock ?? this.showGpuClock,
      showGpuFanRpm: showGpuFanRpm ?? this.showGpuFanRpm,
      showRamUsage: showRamUsage ?? this.showRamUsage,
      posX: posX ?? this.posX,
      posY: posY ?? this.posY,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isEnabled': isEnabled,
      'isLocked': isLocked,
      'isAlwaysOnTop': isAlwaysOnTop,
      'displayMode': displayMode,
      'style': style,
      'fontSizeScale': fontSizeScale,
      'positionPreset': positionPreset,
      'backgroundOpacity': backgroundOpacity,
      'accentColorValue': accentColorValue,
      'showFps': showFps,
      'showTime': showTime,
      'showRunningTime': showRunningTime,
      'showSmartFanRpm': showSmartFanRpm,
      'showSmartFanPwm': showSmartFanPwm,
      'showCpuTemp': showCpuTemp,
      'showCpuUsage': showCpuUsage,
      'showCpuPower': showCpuPower,
      'showCpuClock': showCpuClock,
      'showCpuFanRpm': showCpuFanRpm,
      'showGpuTemp': showGpuTemp,
      'showGpuUsage': showGpuUsage,
      'showGpuPower': showGpuPower,
      'showGpuClock': showGpuClock,
      'showGpuFanRpm': showGpuFanRpm,
      'showRamUsage': showRamUsage,
      'posX': posX,
      'posY': posY,
    };
  }

  factory OverlayConfig.fromMap(Map<String, dynamic> map) {
    return OverlayConfig(
      isEnabled: map['isEnabled'] ?? true,
      isLocked: map['isLocked'] ?? false,
      isAlwaysOnTop: map['isAlwaysOnTop'] ?? true,
      displayMode: map['displayMode'] ?? 'always',
      style: map['style'] ?? 'horizontal',
      fontSizeScale: map['fontSizeScale'] ?? '2K',
      positionPreset: map['positionPreset'] ?? 'custom',
      backgroundOpacity: (map['backgroundOpacity'] as num?)?.toDouble() ?? 0.75,
      accentColorValue: map['accentColorValue'] ?? 0xFF00E5FF,
      showFps: map['showFps'] ?? true,
      showTime: map['showTime'] ?? true,
      showRunningTime: map['showRunningTime'] ?? false,
      showSmartFanRpm: map['showSmartFanRpm'] ?? true,
      showSmartFanPwm: map['showSmartFanPwm'] ?? true,
      showCpuTemp: map['showCpuTemp'] ?? true,
      showCpuUsage: map['showCpuUsage'] ?? true,
      showCpuPower: map['showCpuPower'] ?? true,
      showCpuClock: map['showCpuClock'] ?? true,
      showCpuFanRpm: map['showCpuFanRpm'] ?? false,
      showGpuTemp: map['showGpuTemp'] ?? true,
      showGpuUsage: map['showGpuUsage'] ?? true,
      showGpuPower: map['showGpuPower'] ?? true,
      showGpuClock: map['showGpuClock'] ?? false,
      showGpuFanRpm: map['showGpuFanRpm'] ?? false,
      showRamUsage: map['showRamUsage'] ?? true,
      posX: (map['posX'] as num?)?.toDouble() ?? 40.0,
      posY: (map['posY'] as num?)?.toDouble() ?? 30.0,
    );
  }

  String toJson() => json.encode(toMap());

  factory OverlayConfig.fromJson(String source) =>
      OverlayConfig.fromMap(json.decode(source));
}
