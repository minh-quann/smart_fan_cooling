import 'package:flutter/material.dart';

/// AppColors defines the Precision Industrial Gunmetal palette for Smart Fan Cooling.
/// Inspired by professional hardware software (Fan Control, NZXT CAM, Corsair iCUE).
abstract class AppColors {
  // Backgrounds - Precision Matte Gunmetal Palette
  static const Color background = Color(0xFF0A0B0E); // Deep Gunmetal #0A0B0E
  static const Color surface = Color(0xFF0F1117); // Dark Console Surface #0F1117
  static const Color surfaceLight = Color(0xFF171A24); // Technical Container #171A24
  static const Color cardBg = Color(0xFF12141C); // Solid Hardware Card #12141C
  static const Color sidebarBg = Color(0xFF07080B); // Solid Dark Sidebar #07080B

  // Precision 1px Borders
  static const Color border = Color(0xFF1D2230);
  static const Color borderLight = Color(0xFF282F42);
  static const Color borderGlow = Color(0xFF00E599);

  // Sharp Industrial Accents
  static const Color primary = Color(0xFF00E599); // Electric Mint Green
  static const Color secondary = Color(0xFF00B2FF); // Industrial Cyan
  static const Color accentPurple = Color(0xFF9D50FF); // Precision Purple
  static const Color accentPink = Color(0xFFFF2A6D); // Cyber Pink
  static const Color accentBlue = Color(0xFF00B2FF); // Industrial Blue
  static const Color accentOrange = Color(0xFFFF9500); // Industrial Amber
  static const Color accentRed = Color(0xFFFF3B30); // Crimson Hot
  static const Color accentYellow = Color(0xFFFFCC00); // Warning Amber

  // High Density Typography Colors
  static const Color textPrimary = Color(0xFFF0F2F6); // Cool White
  static const Color textSecondary = Color(0xFF8892A4); // Slate Gray
  static const Color textMuted = Color(0xFF525C6E); // Muted Label

  // Status Badges
  static const Color statusOnline = Color(0xFF00E599);
  static const Color statusWarning = Color(0xFFFF9500);
  static const Color statusOffline = Color(0xFFFF3B30);

  // Hardware Telemetry Colors
  static const Color cpuColor = Color(0xFF00B2FF); // Industrial Blue/Cyan
  static const Color gpuColor = Color(0xFF00E599); // Electric Mint Green
  static const Color ramColor = Color(0xFF9D50FF); // Precision Purple
  static const Color fanColor = Color(0xFF00B2FF); // Industrial Blue
}
