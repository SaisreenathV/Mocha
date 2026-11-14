import 'package:flutter/material.dart';

class MochaTheme {
  // Espresso (Dark) Palette
  static const Color espressoBackground = Color(0xFF1B120D);
  static const Color espressoSurface = Color(0xFF2A1B14);
  static const Color espressoSurfaceHigh = Color(0xFF3B271C);
  static const Color espressoOutline = Color(0xFF5A3B2A);
  static const Color espressoAccent = Color(0xFFC98B4B);
  static const Color espressoAccentBright = Color(0xFFE0A35F);
  static const Color espressoText = Color(0xFFF3E5D0);
  static const Color espressoTextSecondary = Color(0xFFD9BFA0);

  // Latte (Light) Palette
  static const Color latteBackground = Color(0xFFF9F5F0);
  static const Color latteSurface = Color(0xFFEFE7DD);
  static const Color latteSurfaceHigh = Color(0xFFE3D6C8);
  static const Color latteOutline = Color(0xFFB59D8B);
  static const Color latteAccent = Color(0xFF9E6327);
  static const Color latteAccentBright = Color(0xFFC98B4B);
  static const Color latteText = Color(0xFF2A1B14);
  static const Color latteTextSecondary = Color(0xFF6E5647);

  static ThemeData get espressoTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: espressoBackground,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: espressoAccent,
        onPrimary: espressoBackground,
        secondary: espressoAccentBright,
        onSecondary: espressoBackground,
        surface: espressoSurface,
        onSurface: espressoText,
        onSurfaceVariant: espressoTextSecondary,
        outline: espressoOutline,
        error: Color(0xFFCF6679),
        onError: Colors.black,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: espressoBackground,
        foregroundColor: espressoText,
        elevation: 0,
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: espressoSurface,
        indicatorColor: espressoSurfaceHigh,
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: espressoSurface,
        indicatorColor: espressoSurfaceHigh,
      ),
    );
  }

  static ThemeData get latteTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: latteBackground,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: latteAccent,
        onPrimary: latteBackground,
        secondary: latteAccentBright,
        onSecondary: latteBackground,
        surface: latteSurface,
        onSurface: latteText,
        onSurfaceVariant: latteTextSecondary,
        outline: latteOutline,
        error: Color(0xFFB00020),
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: latteBackground,
        foregroundColor: latteText,
        elevation: 0,
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: latteSurface,
        indicatorColor: latteSurfaceHigh,
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: latteSurface,
        indicatorColor: latteSurfaceHigh,
      ),
    );
  }
}
