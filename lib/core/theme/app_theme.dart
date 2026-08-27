import 'package:flutter/material.dart';

class AppTheme {
  static const _seed = Color(0xFF00C805);
  static const _ink = Color(0xFF0B0E0F);

  static ThemeData light = _build(Brightness.light);
  static ThemeData dark = _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(seedColor: _seed, brightness: brightness);
    return ThemeData(
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: isDark ? const Color(0xFF0B0E0F) : const Color(0xFFF9FAFB),
      useMaterial3: true,
      fontFamily: 'Inter',
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? const Color(0xFF0B0E0F) : Colors.white,
        foregroundColor: isDark ? Colors.white : _ink,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
      ),
      cardTheme: CardTheme(
        color: isDark ? const Color(0xFF14181B) : Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: isDark ? const Color(0xFF23282D) : const Color(0xFFE5E7EB)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF14181B) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? const Color(0xFF23282D) : const Color(0xFFE5E7EB))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _seed, width: 1.4)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? const Color(0xFF1A1F24) : const Color(0xFFF9FAFB),
        selectedColor: const Color(0xFF0B0E0F),
        shape: const StadiumBorder(),
      ),
      textTheme: TextTheme(
        headlineSmall: TextStyle(fontWeight: FontWeight.w900, color: isDark ? Colors.white : _ink, letterSpacing: -0.5),
        titleMedium: TextStyle(fontWeight: FontWeight.w800, color: isDark ? Colors.white : _ink),
        bodySmall: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF6B7280)),
      ),
    );
  }
}
