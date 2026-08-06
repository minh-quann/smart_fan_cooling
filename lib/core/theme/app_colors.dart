import 'package:flutter/material.dart';

/// AppColors defines the Dark Matte Gunmetal & Electric Blue/Cyan accent palette for Smart Fan Cooling.
/// Clean dark grey cards with high-contrast electric blue highlights.
abstract class AppColors {
  // Backgrounds - Matte Gunmetal Grey Palette (Clean Dark Grey, No Blue Tint)
  static const Color background = Color(0xFF0A0B0E); // Deep Matte Charcoal #0A0B0E
  static const Color surface = Color(0xFF0F1117); // Dark Console Grey #0F1117
  static const Color surfaceLight = Color(0xFF171A24); // Tech Container Grey #171A24
  static const Color cardBg = Color(0xFF12141C); // Solid Hardware Matte Grey Card #12141C
  static const Color sidebarBg = Color(0xFF07080B); // Solid Dark Sidebar #07080B

  // Precision 1px Borders
  static const Color border = Color(0xFF1D2230); // Neutral Technical Border
  static const Color borderLight = Color(0xFF282F42); // Technical Border Highlight
  static const Color borderGlow = Color(0xFF0070F3); // Blue Glow Border

  // Primary Blue & Cyan Accents (Tông Chỉ Số & Nút Nhấn Xanh Lam)
  static const Color primary = Color(0xFF0070F3); // Electric Cobalt Blue (Primary Active Highlight)
  static const Color primaryGlow = Color(0xFF0088FF); // Bright Electric Blue
  static const Color secondary = Color(0xFF00D2FF); // Frost Cyan (Secondary Highlight)
  static const Color accentCyan = Color(0xFF00E5FF); // Ice Neon Cyan
  static const Color accentBlue = Color(0xFF0099FF); // Sapphire Blue
  static const Color accentSky = Color(0xFF38BDF8); // Sky Cyan Blue
  static const Color accentPurple = Color(0xFF8B5CF6); // Precision Purple
  static const Color accentPink = Color(0xFFFF2A6D); // Cyber Pink
  static const Color accentOrange = Color(0xFFFF9500); // Industrial Amber
  static const Color accentRed = Color(0xFFFF3B30); // Crimson Hot
  static const Color accentYellow = Color(0xFFFFCC00); // Warning Amber

  // High Density Typography Colors
  static const Color textPrimary = Color(0xFFF1F5F9); // Slate Pure White
  static const Color textSecondary = Color(0xFF8892A4); // Slate Gray
  static const Color textMuted = Color(0xFF525C6E); // Muted Label

  // Status Badges
  static const Color statusOnline = Color(0xFF00D2FF); // Frost Cyan Active
  static const Color statusWarning = Color(0xFFFF9500);
  static const Color statusOffline = Color(0xFFFF3B30);

  // Hardware Telemetry Colors (Blue/Cyan Highlight Colors)
  static const Color cpuColor = Color(0xFF00D2FF); // Frost Cyan
  static const Color gpuColor = Color(0xFF0070F3); // Electric Cobalt Blue
  static const Color ramColor = Color(0xFF38BDF8); // Sky Blue
  static const Color fanColor = Color(0xFF00E5FF); // Ice Neon Cyan
}


