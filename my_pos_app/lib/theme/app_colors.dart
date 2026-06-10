import 'package:flutter/material.dart';

/// Centralized color palette for the **dark** theme.
/// Derived from DESIGN.md (Command Center POS Dark Mode).
class DarkColors {
  DarkColors._();

  // ── Surfaces ──
  static const Color background = Color(0xFF11131B);
  static const Color surfaceDim = Color(0xFF11131B);
  static const Color surface = Color(0xFF11131B);
  static const Color surfaceBright = Color(0xFF373942);
  static const Color surfaceContainerLowest = Color(0xFF0C0E16);
  static const Color surfaceContainerLow = Color(0xFF191B23);
  static const Color surfaceContainer = Color(0xFF1D1F27);
  static const Color surfaceContainerHigh = Color(0xFF282A32);
  static const Color surfaceContainerHighest = Color(0xFF32343D);

  // ── Text & Outlines ──
  static const Color onSurface = Color.fromARGB(255, 241, 243, 239);
  static const Color onSurfaceVariant = Color(0xFFC3C6D7);
  static const Color inverseSurface = Color.fromARGB(255, 225, 238, 213);
  static const Color inverseOnSurface = Color(0xFF2E3039);
  static const Color outline = Color(0xFF8D90A0);
  static const Color outlineVariant = Color(0xFF434655);

  // ── Primary ──
  static const Color primary = Color(0xFFB4C5FF);
  static const Color onPrimary = Color(0xFF002A78);
  static const Color primaryContainer = Color.fromARGB(255, 110, 141, 208);
  static const Color onPrimaryContainer = Color.fromARGB(255, 97, 187, 65);
  static const Color inversePrimary = Color.fromARGB(255, 137, 161, 203);

  // ── Secondary ──
  static const Color secondary = Color(0xFFB7C8E1);
  static const Color onSecondary = Color(0xFF213145);
  static const Color secondaryContainer = Color(0xFF3A4A5F);
  static const Color onSecondaryContainer = Color(0xFFA9BAD3);

  // ── Tertiary ──
  static const Color tertiary = Color(0xFFFFB596);
  static const Color onTertiary = Color(0xFF581E00);
  static const Color tertiaryContainer = Color(0xFFBC4800);
  static const Color onTertiaryContainer = Color(0xFFFFEDE6);

  // ── Error ──
  static const Color error = Color(0xFFFFB4AB);
  static const Color onError = Color(0xFF690005);
  static const Color errorContainer = Color(0xFF93000A);
  static const Color onErrorContainer = Color(0xFFFFDAD6);
}

/// Centralized color palette for the **light** theme.
/// Derived from DESIGNLite.md (Command Center POS Light Mode).
class LightColors {
  LightColors._();

  // ── Surfaces ──
  static const Color background = Color(0xFFFAF8FF);
  static const Color surfaceDim = Color(0xFFD9D9E5);
  static const Color surface = Color(0xFFFAF8FF);
  static const Color surfaceBright = Color(0xFFFAF8FF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF3F3FE);
  static const Color surfaceContainer = Color(0xFFEDEDF9);
  static const Color surfaceContainerHigh = Color(0xFFE7E7F3);
  static const Color surfaceContainerHighest = Color(0xFFE1E2ED);

  // ── Text & Outlines ──
  static const Color onSurface = Color(0xFF191B23);
  static const Color onSurfaceVariant = Color(0xFF434655);
  static const Color inverseSurface = Color(0xFF2E3039);
  static const Color inverseOnSurface = Color(0xFFF0F0FB);
  static const Color outline = Color(0xFF737686);
  static const Color outlineVariant = Color(0xFFC3C6D7);

  // ── Primary ──
  static const Color primary = Color.fromARGB(255, 36, 152, 127);
  static const Color onPrimary = Color.fromARGB(255, 238, 231, 231);
  static const Color primaryContainer = Color.fromARGB(255, 50, 180, 145);
  static const Color onPrimaryContainer = Color.fromARGB(232, 238, 239, 255);
  static const Color inversePrimary = Color(0xFFB4C5FF);

  // ── Secondary ──
  static const Color secondary = Color(0xFF565E74);
  static const Color onSecondary = Color.fromARGB(234, 255, 255, 255);
  static const Color secondaryContainer = Color(0xFFDAE2FD);
  static const Color onSecondaryContainer = Color(0xFF5C647A);

  // ── Tertiary ──
  static const Color tertiary = Color(0xFF46566C);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFF5E6E85);
  static const Color onTertiaryContainer = Color(0xFFE9F0FF);

  // ── Error ──
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);
}

/// Semantic status colors shared across both themes.
/// These remain constant for operational glanceability.
class StatusColors {
  StatusColors._();

  static const Color available = Color(0xFF22C55E);
  static const Color occupied = Color(0xFFEF4444);
  static const Color reserved = Color(0xFFF59E0B);
  static const Color alert = Color(0xFFEC4899);
}
