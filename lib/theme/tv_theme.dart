import 'package:flutter/material.dart';

/// TVTheme inspired by Free-My-TV dark launcher aesthetic:
/// Deep OLED charcoal (#0B0B0D), frosted glass surfaces (#1B1C22),
/// crisp off-white typography (#F5F5F7), Apple-style emerald live indicators (#30D158),
/// and luminous high-contrast remote focus rings.
class TVTheme {
  // Deep OLED Night palette
  static const Color background = Color(0xFF0B0B0D);
  static const Color backgroundSecondary = Color(0xFF141519);
  static const Color sidebarBackground = Color(0xFF111216);
  static const Color cardBackground = Color(0xFF1B1C22);
  static const Color cardFocusBackground = Color(0xFF282932);
  
  // Accents & Indicators
  static const Color focusColor = Color(0xFF38BDF8); // Electric sky cyan
  static const Color focusWhite = Color(0xFFFFFFFF);
  static const Color focusGlow = Color(0x6638BDF8);
  static const Color liveGreen = Color(0xFF30D158); // Free-My-TV Apple live emerald
  static const Color accentRed = Color(0xFFFF453A); // Live alert red
  static const Color gold = Color(0xFFFFD60A); // Apple gold star
  
  // Glassmorphic borders & fills
  static const Color glassFill = Color(0x0FFFFFFF);
  static const Color glassFillActive = Color(0x22FFFFFF);
  static const Color glassBorder = Color(0x1AFFFFFF);
  static const Color cardBorder = Color(0x14FFFFFF);

  // Typography Colors
  static const Color textPrimary = Color(0xFFF5F5F7);
  static const Color textSecondary = Color(0xA6F5F5F7); // ~65% opacity
  static const Color textMuted = Color(0x6BF5F5F7);     // ~42% opacity

  static ThemeData get theme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: focusColor,
      canvasColor: sidebarBackground,
      colorScheme: const ColorScheme.dark(
        primary: focusColor,
        secondary: liveGreen,
        surface: cardBackground,
      ),
      fontFamily: 'Inter',
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
