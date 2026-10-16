import 'package:flutter/material.dart';

class TVTheme {
  static const Color background = Color(0xFF0A0F1D);
  static const Color sidebarBackground = Color(0xFF0F172A);
  static const Color cardBackground = Color(0xFF1E293B);
  static const Color cardFocusBackground = Color(0xFF334155);
  
  static const Color focusColor = Color(0xFF38BDF8); // Electric cyan
  static const Color focusGlow = Color(0x6638BDF8);
  static const Color accentRed = Color(0xFFEF4444); // Live tag
  static const Color gold = Color(0xFFFBBF24); // Favorite star
  
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  static ThemeData get theme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: focusColor,
      canvasColor: sidebarBackground,
      colorScheme: const ColorScheme.dark(
        primary: focusColor,
        secondary: accentRed,
        surface: cardBackground,
      ),
      fontFamily: 'Roboto',
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          letterSpacing: 0.5,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: textSecondary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: textSecondary,
        ),
      ),
    );
  }
}
