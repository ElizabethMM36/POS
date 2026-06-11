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
/// Dynamic Warm Orange design system — premium POS Command Center.
/// Primary brand: #FF6D00 orange · Accent: #FFB300 amber
class LightColors {
  LightColors._();

  // ── Surfaces ──
  // Crisp off-white/warm cream base — never cold or blue
  static const Color background = Color(0xFFFDFBF8);
  static const Color surfaceDim = Color(0xFFF0EBE3);
  static const Color surface = Color(0xFFFDFBF8);
  static const Color surfaceBright = Color(0xFFFFFFFF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFFFF8F2); // warm cream
  static const Color surfaceContainer = Color(0xFFFFF3E8); // soft peach
  static const Color surfaceContainerHigh = Color(
    0xFFFFEDD8,
  ); // light amber wash
  static const Color surfaceContainerHighest = Color(0xFFFFE4C4); // deeper warm

  // ── Text & Outlines ──
  static const Color onSurface = Color(0xFF1E2022); // deep charcoal
  static const Color onSurfaceVariant = Color(0xFF686D76); // warm muted gray
  static const Color inverseSurface = Color(0xFF33312E);
  static const Color inverseOnSurface = Color(0xFFFFF0E6);
  static const Color outline = Color(0xFF9E9589); // warm-toned outline
  static const Color outlineVariant = Color(
    0xFFE8DDD4,
  ); // warm parchment divider

  // ── Primary — rich energetic orange ──
  static const Color primary = Color.fromARGB(211, 255, 111, 0); // brand orange
  static const Color onPrimary = Color(0xFFFFFFFF); // white on orange
  static const Color primaryContainer = Color.fromARGB(
    255,
    210,
    105,
    48,
  ); // slightly lighter orange
  static const Color onPrimaryContainer = Color(0xFFFFFFFF);
  static const Color inversePrimary = Color.fromARGB(
    255,
    200,
    102,
    37,
  ); // soft peachy inverse

  // ── Secondary — warm amber sunlit ──
  static const Color secondary = Color(0xFFB36200); // deep amber label
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFFFE0B2); // light golden
  static const Color onSecondaryContainer = Color(0xFF5C3400);

  // ── Tertiary — muted warm sand ──
  static const Color tertiary = Color(0xFF8B6914);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFFFFEFCC); // sunlit glow
  static const Color onTertiaryContainer = Color(0xFF4A3500);

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

class AppColors {
  // Base Palette
  static const Color background = Color(0xFFFAF6F0);
  static const Color cardBg = Color(0xFFFFFDF9);
  static const Color surface = Color(0xFFF3EDE4);

  // High-Contrast Typography
  static const Color textPrimary = Color(0xFF1E1B18);
  static const Color textSecondary = Color(
    0xFF5A524A,
  ); // Darker, high-contrast text for details
  static const Color textMuted = Color(0xFF8C8175);

  // Vibrant Active States (Coral to Deep Orange Gradient)
  static const Color gradientStart = Color(0xFFFF6F43);
  static const Color gradientEnd = Color(0xFFE64A19);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color.fromARGB(255, 209, 113, 84), gradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Glassmorphism Highlights
  static Color glassBackground = Colors.white.withOpacity(0.65);
  static Color glassBorder = Colors.white.withOpacity(0.4);
}
