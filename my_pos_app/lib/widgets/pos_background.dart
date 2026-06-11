import 'package:flutter/material.dart';

// ─── Shared warm-cream mesh background ──────────────────────────────────────
//
// Reference: the two-screen UI reference image with:
//   • Base: ultra-warm cream #FDF6F0 → #FFF8F4 (not white, not orange)
//   • Top-right bloom : soft coral-rose at 14% — RGB(255,160,130)
//   • Bottom-left bloom: deeper warm rose-amber at 22% — RGB(255,120,90)
//   • No hard circle edges — every bloom uses drawRect + RadialGradient alignment
//
// Dark mode keeps the existing deep-navy mesh unchanged.
// ─────────────────────────────────────────────────────────────────────────────

class POSBackground extends StatelessWidget {
  const POSBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(painter: _WarmMeshPainter(isDark: isDark)),
        ),
        child,
      ],
    );
  }
}

class _WarmMeshPainter extends CustomPainter {
  final bool isDark;
  const _WarmMeshPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final full = Rect.fromLTWH(0, 0, size.width, size.height);

    // ── Base gradient ────────────────────────────────────────────────────────
    canvas.drawRect(
      full,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF0F1621),
                  const Color(0xFF131A24),
                  const Color(0xFF0D1B2A),
                ]
              : [
                  // Warm cream — matches the reference image base
                  const Color(0xFFFDF6EF),
                  const Color(0xFFFFF9F5),
                  const Color(0xFFFEF5EE),
                ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(full),
    );

    if (isDark) {
      // Dark blobs — unchanged navy mesh
      _bloom(
        canvas,
        full,
        const Alignment(-0.70, -0.64),
        const Color(0xFF1E3A5F),
        0.55,
        0.75,
      );
      _bloom(
        canvas,
        full,
        const Alignment(0.64, -0.16),
        const Color(0xFF162840),
        0.55,
        0.70,
      );
      _bloom(
        canvas,
        full,
        const Alignment(-0.24, 0.51),
        const Color(0xFF151D2A),
        0.45,
        0.75,
      );
    } else {
      // ── Light warm-cream blooms (matching reference image) ────────────────
      //
      // Top-right: soft coral glow — like the reference's pink-peach corner
      _bloom(
        canvas,
        full,
        const Alignment(0.90, -0.85),
        const Color(0xFFFF9A7A),
        0.14,
        0.80,
      );

      // Bottom-left: deeper warm amber-rose — reference's lower left warmth
      _bloom(
        canvas,
        full,
        const Alignment(-0.85, 0.90),
        const Color(0xFFFF7850),
        0.20,
        0.85,
      );

      // Centre: barely-there whisper of warmth so mid-screen is never stark
      _bloom(
        canvas,
        full,
        const Alignment(0.10, 0.05),
        const Color(0xFFFFB090),
        0.04,
        0.65,
      );
    }
  }

  /// Draws a full-canvas RadialGradient bloom — no hard circle clip.
  void _bloom(
    Canvas canvas,
    Rect full,
    Alignment center,
    Color color,
    double opacity,
    double radiusScale,
  ) {
    canvas.drawRect(
      full,
      Paint()
        ..shader = RadialGradient(
          center: center,
          radius: radiusScale,
          colors: [
            color.withOpacity(opacity),
            color.withOpacity(opacity * 0.5),
            color.withOpacity(0.0),
          ],
          stops: const [0.0, 0.4, 1.0],
        ).createShader(full)
        ..blendMode = BlendMode.srcOver,
    );
  }

  @override
  bool shouldRepaint(covariant _WarmMeshPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}
