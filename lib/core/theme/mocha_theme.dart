import 'package:flutter/material.dart';

class MochaTheme {
  // Obsidian Purple (Dark) Palette
  static const Color espressoBackground = Color(0xFF090610);
  static const Color espressoSurface = Color(0xFF150F24);
  static const Color espressoSurfaceHigh = Color(0xFF241A3D);
  static const Color espressoOutline = Color(0xFF483570);
  static const Color espressoAccent = Color(0xFFA855F7);
  static const Color espressoAccentBright = Color(0xFFC084FC);
  static const Color espressoText = Color(0xFFF6F4FE);
  static const Color espressoTextSecondary = Color(0xFFB5A4D8);

  // Lavender Light Palette
  static const Color latteBackground = Color(0xFFFBF9FF);
  static const Color latteSurface = Color(0xFFF2EDFC);
  static const Color latteSurfaceHigh = Color(0xFFE4D9F8);
  static const Color latteOutline = Color(0xFFB7A4DE);
  static const Color latteAccent = Color(0xFF7E22CE);
  static const Color latteAccentBright = Color(0xFF9333EA);
  static const Color latteText = Color(0xFF1B112C);
  static const Color latteTextSecondary = Color(0xFF5D4E78);

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
        surfaceContainer: espressoSurface,
        surfaceContainerHigh: espressoSurfaceHigh,
        surfaceContainerHighest: Color(0xFF332454),
        error: Color(0xFFCF6679),
        onError: Colors.black,
      ),
      cardTheme: const CardThemeData(
        color: espressoSurface,
        elevation: 0,
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
        surfaceContainer: latteSurface,
        surfaceContainerHigh: latteSurfaceHigh,
        surfaceContainerHighest: Color(0xFFD6C8F2),
        error: Color(0xFFB00020),
        onError: Colors.white,
      ),
      cardTheme: const CardThemeData(
        color: latteSurface,
        elevation: 0,
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
