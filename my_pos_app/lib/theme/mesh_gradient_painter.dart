import 'dart:ui';
import 'package:flutter/material.dart';

class LightMeshGradientPainter extends CustomPainter {
  final BuildContext context;
  LightMeshGradientPainter(this.context);

  @override
  void paint(Canvas canvas, Size size) {
    final theme = Theme.of(context);

    // 1. Draw solid light background layer
    final bgPaint = Paint()..color = theme.colorScheme.background;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // 2. Top Right Bloom (Soft Teal Accent)
    final topPaint = Paint()
      ..shader =
          RadialGradient(
            colors: [
              theme.colorScheme.primary.withOpacity(
                0.15,
              ), // Your signature teal softened
              theme.colorScheme.primary.withOpacity(0.0),
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.8, size.height * 0.1),
              radius: size.width * 0.7,
            ),
          );
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), topPaint);

    // 3. Bottom Left Bloom (Soft Blue/Tertiary Accent)
    final bottomPaint = Paint()
      ..shader =
          RadialGradient(
            colors: [
              theme.colorScheme.secondaryContainer.withOpacity(0.25),
              theme.colorScheme.secondaryContainer.withOpacity(0.0),
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.1, size.height * 0.8),
              radius: size.width * 0.8,
            ),
          );
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bottomPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MeshGradientPainter extends CustomPainter {
  final BuildContext context;
  final bool isDark;

  MeshGradientPainter(this.context, {required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final theme = Theme.of(context);

    if (isDark) {
      // ─── DARK MODE MESH GRADIENT ───
      // Base dark layer
      final basePaint = Paint()..color = theme.colorScheme.background;
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), basePaint);

      // Top-right deep blue/indigo bloom
      final topPaint = Paint()
        ..shader =
            RadialGradient(
              colors: [
                const Color(0xFF1E293B).withOpacity(0.6),
                const Color(0xFF11131B).withOpacity(0.0),
              ],
            ).createShader(
              Rect.fromCircle(
                center: Offset(size.width * 0.8, size.height * 0.1),
                radius: size.width * 0.8,
              ),
            );
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), topPaint);

      // Bottom-left brand glow variant
      final bottomPaint = Paint()
        ..shader =
            RadialGradient(
              colors: [
                theme.colorScheme.primary.withOpacity(0.08),
                theme.colorScheme.background.withOpacity(0.0),
              ],
            ).createShader(
              Rect.fromCircle(
                center: Offset(size.width * 0.1, size.height * 0.8),
                radius: size.width * 0.7,
              ),
            );
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        bottomPaint,
      );
    } else {
      // ─── LIGHT MODE MESH GRADIENT ───
      // Solid crisp background base
      final basePaint = Paint()..color = theme.colorScheme.background;
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), basePaint);

      // Top-Right Bloom: Softened version of your signature brand teal
      final topPaint = Paint()
        ..shader =
            RadialGradient(
              colors: [
                theme.colorScheme.primary.withOpacity(0.12),
                theme.colorScheme.primary.withOpacity(0.0),
              ],
            ).createShader(
              Rect.fromCircle(
                center: Offset(size.width * 0.85, size.height * 0.15),
                radius: size.width * 0.75,
              ),
            );
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), topPaint);

      // Bottom-Left Bloom: Ambient secondary container accent mix
      final bottomPaint = Paint()
        ..shader =
            RadialGradient(
              colors: [
                theme.colorScheme.secondaryContainer.withOpacity(0.25),
                theme.colorScheme.secondaryContainer.withOpacity(0.0),
              ],
            ).createShader(
              Rect.fromCircle(
                center: Offset(size.width * 0.15, size.height * 0.75),
                radius: size.width * 0.85,
              ),
            );
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        bottomPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant MeshGradientPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}
