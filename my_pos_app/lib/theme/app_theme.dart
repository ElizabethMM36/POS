import 'package:flutter/material.dart';
import 'package:my_pos_app/theme/app_colors.dart';

/// Builds complete [ThemeData] objects for both dark and light modes.
class AppTheme {
  AppTheme._();

  // ── Dark Theme ──────────────────────────────────────────────────

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: Color.fromARGB(255, 230, 234, 225),
        onPrimary: Color.from(alpha: 255, red: 178, green: 237, blue: 98),
        primaryContainer: DarkColors.primaryContainer,
        onPrimaryContainer: DarkColors.onPrimaryContainer,
        inversePrimary: DarkColors.inversePrimary,
        secondary: DarkColors.secondary,
        onSecondary: DarkColors.onSecondary,
        secondaryContainer: DarkColors.secondaryContainer,
        onSecondaryContainer: DarkColors.onSecondaryContainer,
        tertiary: DarkColors.tertiary,
        onTertiary: DarkColors.onTertiary,
        tertiaryContainer: DarkColors.tertiaryContainer,
        onTertiaryContainer: DarkColors.onTertiaryContainer,
        error: DarkColors.error,
        onError: DarkColors.onError,
        errorContainer: DarkColors.errorContainer,
        onErrorContainer: DarkColors.onErrorContainer,
        surface: DarkColors.surface,
        onSurface: DarkColors.onSurface,
        onSurfaceVariant: DarkColors.onSurfaceVariant,
        outline: DarkColors.outline,
        outlineVariant: DarkColors.outlineVariant,
        inverseSurface: DarkColors.inverseSurface,
        onInverseSurface: DarkColors.inverseOnSurface,
        surfaceDim: DarkColors.surfaceDim,
        surfaceBright: DarkColors.surfaceBright,
        surfaceContainerLowest: DarkColors.surfaceContainerLowest,
        surfaceContainerLow: DarkColors.surfaceContainerLow,
        surfaceContainer: DarkColors.surfaceContainer,
        surfaceContainerHigh: DarkColors.surfaceContainerHigh,
        surfaceContainerHighest: DarkColors.surfaceContainerHighest,
      ),
      scaffoldBackgroundColor: DarkColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: DarkColors.background,
        foregroundColor: DarkColors.onSurface,
        centerTitle: false,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: DarkColors.surfaceContainer,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: DarkColors.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: DarkColors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: DarkColors.primary, width: 2),
        ),
      ),
      cardTheme: CardThemeData(
        color: DarkColors.surfaceContainer,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: DarkColors.outlineVariant),
        ),
      ),
    );
  }

  // ── Light Theme ─────────────────────────────────────────────────

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: LightColors.primary,
        onPrimary: LightColors.onPrimary,
        primaryContainer: LightColors.primaryContainer,
        onPrimaryContainer: LightColors.onPrimaryContainer,
        inversePrimary: LightColors.inversePrimary,
        secondary: LightColors.secondary,
        onSecondary: LightColors.onSecondary,
        secondaryContainer: LightColors.secondaryContainer,
        onSecondaryContainer: LightColors.onSecondaryContainer,
        tertiary: LightColors.tertiary,
        onTertiary: LightColors.onTertiary,
        tertiaryContainer: LightColors.tertiaryContainer,
        onTertiaryContainer: LightColors.onTertiaryContainer,
        error: LightColors.error,
        onError: LightColors.onError,
        errorContainer: LightColors.errorContainer,
        onErrorContainer: LightColors.onErrorContainer,
        surface: LightColors.surface,
        onSurface: LightColors.onSurface,
        onSurfaceVariant: LightColors.onSurfaceVariant,
        outline: LightColors.outline,
        outlineVariant: LightColors.outlineVariant,
        inverseSurface: LightColors.inverseSurface,
        onInverseSurface: LightColors.inverseOnSurface,
        surfaceDim: LightColors.surfaceDim,
        surfaceBright: LightColors.surfaceBright,
        surfaceContainerLowest: LightColors.surfaceContainerLowest,
        surfaceContainerLow: LightColors.surfaceContainerLow,
        surfaceContainer: LightColors.surfaceContainer,
        surfaceContainerHigh: LightColors.surfaceContainerHigh,
        surfaceContainerHighest: LightColors.surfaceContainerHighest,
      ),
      scaffoldBackgroundColor: LightColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: LightColors.background,
        foregroundColor: LightColors.onSurface,
        centerTitle: false,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: LightColors.surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: LightColors.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: LightColors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: LightColors.primary, width: 2),
        ),
      ),
      cardTheme: CardThemeData(
        color: LightColors.surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: LightColors.outlineVariant),
        ),
      ),
    );
  }
}
