import 'package:flutter/material.dart';

class AppTheme {
  // Dark palette matching rgba(20, 1, 31) base and deep obsidian
  static const Color background = Color(0xFF090712);
  static const Color surfaceDark = Color(0xFF100D1F);
  static const Color surfaceElevated = Color(0xFF19142E);
  
  // Liquid Glass Tint from CSS: rgba(20, 1, 31, 0.308)
  static const Color glassTint = Color.fromRGBO(20, 1, 31, 0.31);
  static const Color glassBorderLight = Color(0x5AFFFFFF); // 0.356 opacity
  static const Color glassBorderDim = Color(0x2AFFFFFF);   // 0.15 opacity

  // Vibrant Accents
  static const Color primaryCyan = Color(0xFF00E5FF);
  static const Color primaryPurple = Color(0xFFA855F7);
  static const Color accentNeonGreen = Color(0xFF10B981);
  static const Color accentAmber = Color(0xFFFBBF24);
  static const Color accentCrimson = Color(0xFFFF2A6D);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textTertiary = Color(0xFF64748B);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: primaryCyan,
        secondary: primaryPurple,
        surface: surfaceDark,
        error: accentCrimson,
        onPrimary: Colors.black,
        onSurface: textPrimary,
      ),
      fontFamily: 'Roboto',
      cardTheme: CardThemeData(
        color: surfaceDark.withValues(alpha: 0.6),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      iconTheme: const IconThemeData(color: Colors.white),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.3,
        ),
        titleLarge: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.normal,
          color: textSecondary,
        ),
        bodyMedium: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.normal,
          color: textSecondary,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: textTertiary,
        ),
      ),
    );
  }
}
