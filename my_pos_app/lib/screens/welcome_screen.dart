import 'package:flutter/material.dart';
import 'package:my_pos_app/screens/login_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background atmospheric glows and grids
          Positioned.fill(
            child: Container(
              color: const Color(0xFF11131B),
            ),
          ),
          // Subtle radial glow at the center
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [
                    const Color(0xFF2563EB).withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Subtle dots pattern placeholder using custom painter
          Positioned.fill(
            child: CustomPaint(
              painter: _GridPatternPainter(),
            ),
          ),
          // Scrollable layout
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 32,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 12),
                        // Branding hero section
                        Column(
                          children: [
                            // Glowing Terminal Logo
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF2563EB)
                                        .withValues(alpha: 0.4),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  )
                                ],
                              ),
                              child: const Icon(
                                Icons.terminal_rounded,
                                size: 52,
                                color: Color(0xFFEEEFFF),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Title
                            RichText(
                              textAlign: TextAlign.center,
                              text: const TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Command Center ',
                                    style: TextStyle(
                                      fontFamily: 'Hanken Grotesk',
                                      fontSize: 32,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFFB4C5FF),
                                      letterSpacing: -0.02,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'POS',
                                    style: TextStyle(
                                      fontFamily: 'Hanken Grotesk',
                                      fontSize: 32,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFFE1E2ED),
                                      letterSpacing: -0.02,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Subtitle
                            const Text(
                              'Next-generation restaurant management at your fingertips.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Hanken Grotesk',
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFFC3C6D7),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),

                        // Image card backdrop
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 24),
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF434655).withValues(alpha: 0.3),
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.network(
                                  'https://lh3.googleusercontent.com/aida-public/AB6AXuDL0vYSRDnAYX6uBRjjC07Nakv096Ig9W7nuGOW1CojPcrSwSDO4XygGgddXjAVQopTw9xFMTpiFRdwP1efNegl81928ybKtr1oAiNo-JkBat-LnYr9NhpIq9H8sLGKdYauedC2aijnS25ik4OgYbTlyTJSE5ZzkDUdvybmrhNg0brpD6_xIB6wsjbNF0D8V4KUXXPYN-EVsIEWuGQPPqEcVW-8sbR8U5sRCxA7eCEag3yEenMavc1HwKLEGEIYSrJ35XGgIdB-27c',
                                  fit: BoxFit.cover,
                                  color: Colors.black.withValues(alpha: 0.45),
                                  colorBlendMode: BlendMode.dstATop,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                    color: const Color(0xFF191B23),
                                    child: const Icon(
                                      Icons.restaurant_menu_rounded,
                                      size: 48,
                                      color: Color(0xFF434655),
                                    ),
                                  ),
                                ),
                                Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Color(0xFF11131B),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Action & Footer Area
                        Column(
                          children: [
                            // Staff Login Button
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => const LoginScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.login_rounded, size: 24),
                                label: const Text(
                                  'Staff Login',
                                  style: TextStyle(
                                    fontFamily: 'Hanken Grotesk',
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2563EB),
                                  foregroundColor: const Color(0xFFEEEFFF),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 8,
                                  shadowColor: const Color(0xFF2563EB)
                                      .withValues(alpha: 0.3),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // System Status Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1D1F27),
                                borderRadius: BorderRadius.circular(9999),
                                border: Border.all(
                                  color: const Color(0xFF434655)
                                      .withValues(alpha: 0.2),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AnimatedBuilder(
                                    animation: _pulseAnimation,
                                    builder: (context, child) {
                                      return Opacity(
                                        opacity: _pulseAnimation.value,
                                        child: Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF22C55E),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'SYSTEM STATUS: ONLINE',
                                    style: TextStyle(
                                      fontFamily: 'JetBrains Mono',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFC3C6D7),
                                      letterSpacing: 0.05,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GridPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2563EB).withValues(alpha: 0.04)
      ..strokeWidth = 1.0;

    const spacing = 32.0;

    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
