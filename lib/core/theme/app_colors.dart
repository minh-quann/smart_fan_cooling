import 'package:flutter/material.dart';

/// AppColors defines the central color palette for the Smart Fan Cooling app.
/// Styled after modern gaming control hubs with TRUE PURE BLACK theme & neon glowing accents.
abstract class AppColors {
  // Backgrounds - True Pure Black Theme
  static const Color background = Color(0xFF000000); // Pure Black #000000
  static const Color surface = Color(0xFF070707); // Dark Surface #070707
  static const Color surfaceLight = Color(0xFF141414); // Dark Card/Accent #141414
  static const Color cardBg = Color(0xFF0C0C0C); // Deep Black Card #0C0C0C
  static const Color sidebarBg = Color(0xFF040404); // Pure Dark Sidebar #040404

  // Borders & Dividers
  static const Color border = Color(0xFF1F1F1F);
  static const Color borderLight = Color(0xFF2A2A2A);
  static const Color borderGlow = Color(0xFF06B6D4);

  // Accent Colors
  static const Color primary = Color(0xFF10B981); // Emerald Green
  static const Color secondary = Color(0xFF06B6D4); // Cyan
  static const Color accentPurple = Color(0xFF8B5CF6); // Purple
  static const Color accentPink = Color(0xFFEC4899); // Pink
  static const Color accentBlue = Color(0xFF3B82F6); // Blue
  static const Color accentOrange = Color(0xFFF97316); // Orange
  static const Color accentRed = Color(0xFFEF4444); // Red/Hot
  static const Color accentYellow = Color(0xFFEAB308); // Warning/Yellow

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA1A1AA);
  static const Color textMuted = Color(0xFF71717A);

  // Status Indicators
  static const Color statusOnline = Color(0xFF10B981);
  static const Color statusWarning = Color(0xFFF59E0B);
  static const Color statusOffline = Color(0xFFEF4444);

  // Gauges & Charts
  static const Color cpuColor = Color(0xFF3B82F6); // Blue
  static const Color gpuColor = Color(0xFF10B981); // Green
  static const Color ramColor = Color(0xFF8B5CF6); // Purple
  static const Color fanColor = Color(0xFF06B6D4); // Cyan
}
