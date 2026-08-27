import 'package:flutter/material.dart';

abstract class AppConstants {
  static const double maxContentWidth = 1180;
  static const double horizontalPadding = 16;
  static const double cardRadius = 16;
  static const double cardRadiusLarge = 20;
  static const double borderRadiusSmall = 8;
  static const double borderRadiusMedium = 12;
  static const Duration animationDuration = Duration(milliseconds: 280);
  static const Duration debounceDuration = Duration(milliseconds: 350);
}

abstract class AppColors {
  static const seed = Color(0xFF00C805);
  static const ink = Color(0xFF0B0E0F);
  static const success = Color(0xFF00A63E);
  static const error = Color(0xFFDC2626);
  static const warning = Color(0xFFF59E0B);
  static const info = Color(0xFF2563EB);
  static const bgLight = Color(0xFFF9FAFB);
  static const bgDark = Color(0xFF0B0E0F);
  static const borderLight = Color(0xFFE5E7EB);
  static const borderDark = Color(0xFF23282D);
  static const muted = Color(0xFF6B7280);
  static const textSecondary = Color(0xFF9CA3AF);
}

abstract class AppTypography {
  static const appFontFamily = 'Inter';
}
