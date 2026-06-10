import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_pos_app/models/pos_models.dart';
import 'package:my_pos_app/providers/pos_provider.dart';
import 'package:my_pos_app/screens/outlet_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  String _currentPin = '';
  final int _maxPinLength = 4;
  bool _isAuthenticating = false;
  bool _biometricScanning = false;

  void _handleKeypadTap(String value) {
    if (_isAuthenticating) return;
    if (_currentPin.length < _maxPinLength) {
      setState(() {
        _currentPin += value;
      });

      if (_currentPin.length == _maxPinLength) {
        _triggerLogin();
      }
    }
  }

  void _handleBackspace() {
    if (_isAuthenticating) return;
    if (_currentPin.isNotEmpty) {
      setState(() {
        _currentPin = _currentPin.substring(0, _currentPin.length - 1);
      });
    }
  }

  void _handleBiometric() async {
    if (_isAuthenticating) return;
    setState(() {
      _biometricScanning = true;
    });

    // Simulate biometric scanning duration
    await Future<void>.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;

    setState(() {
      _biometricScanning = false;
      _currentPin = '1234';
    });

    _triggerLogin();
  }

  void _triggerLogin() async {
    setState(() {
      _isAuthenticating = true;
    });

    // Authenticate user in POSProvider
    final provider = context.read<POSProvider>();
    provider.authenticateUser(
      staffIdOrName: 'Alex Miller',
      role: UserRole.server,
    );

    // Show beautiful success overlay for 1.8 seconds (matching HTML description)
    await Future<void>.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const OutletScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaWidth = MediaQuery.of(context).size.width;
    final isDesktop = mediaWidth > 768;
    final cs = Theme.of(context).colorScheme;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          Row(
            children: [
              // Left Side: Branding (Only visible on wide layouts)
              if (isDesktop)
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Backdrop photo
                      Image.network(
                        'https://lh3.googleusercontent.com/aida-public/AB6AXuBV-q4fVndozZJMjVKAFx1IIOD1wRhJq8nXLwqccHv6EESWywsViY-x91SVfI-IkeU7oo9OD_HQBL4NwWIIv1d0n5VwWU8nYVZDwAMmHy6r7YaQfXEJmrC3dFUkdlzUjDhXDZ5KeV62blS0IlcfGObJZAYKoNJQIkKLpVLWqC10yiXpixovEiAICHErssGWG265nFycRDiSyiG6j5_Th1nZqMyqD-0AJpcTcNocmROl-Kv6tAUtMMT3hCH9JAcsd7UaPA63qAu29-U',
                        fit: BoxFit.cover,
                        color: Colors.black.withValues(alpha: 0.5),
                        colorBlendMode: BlendMode.darken,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(color: cs.surfaceContainerLowest),
                      ),
                      // Left Gradient Overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [Colors.transparent, scaffoldBg],
                          ),
                        ),
                      ),
                      // Brand branding text
                      Padding(
                        padding: const EdgeInsets.all(48.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.storefront_rounded,
                                  size: 52,
                                  color: Color(0xFFFFFFFF),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  'Main Dining',
                                  style: TextStyle(
                                    fontFamily: 'Hanken Grotesk',
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFFFFFFFF),
                                    letterSpacing: -0.02,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Terminal #04',
                              style: TextStyle(
                                fontFamily: 'Hanken Grotesk',
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: cs.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Ready for service. Please enter your employee PIN to begin your shift.',
                              style: TextStyle(
                                fontFamily: 'Hanken Grotesk',
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: cs.onSurfaceVariant,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 48),
                            // System Online Badge
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF22C55E),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'SYSTEM ONLINE',
                                  style: TextStyle(
                                    fontFamily: 'JetBrains Mono',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF22C55E),
                                    letterSpacing: 0.05,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.sync_rounded,
                                  size: 14,
                                  color: cs.onSurfaceVariant,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'SYNCED: 2 MINS AGO',
                                  style: TextStyle(
                                    fontFamily: 'JetBrains Mono',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: cs.onSurfaceVariant,
                                    letterSpacing: 0.05,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              // Right Side: Numeric keypad section
              Expanded(
                child: Container(
                  color: scaffoldBg,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SafeArea(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 340),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Mobile logo Header
                            if (!isDesktop) ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.storefront_rounded,
                                    size: 32,
                                    color: Color(0xFFFFFFFF),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Main Dining',
                                    style: TextStyle(
                                      fontFamily: 'Hanken Grotesk',
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFFFFFFF),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 32),
                            ],
                            // User Profile Avatar Card
                            Column(
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: cs.surfaceContainer,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: cs.outlineVariant,
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.person_outline_rounded,
                                    size: 40,
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Staff Login',
                                  style: TextStyle(
                                    fontFamily: 'Hanken Grotesk',
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: cs.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'ENTER 4-DIGIT PIN',
                                  style: TextStyle(
                                    fontFamily: 'JetBrains Mono',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            // PIN display dots
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(_maxPinLength, (index) {
                                final active = index < _currentPin.length;
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: active
                                        ? cs.primary
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: active
                                          ? cs.primary
                                          : cs.outlineVariant,
                                      width: 2,
                                    ),
                                    boxShadow: active
                                        ? [
                                            BoxShadow(
                                              color: cs.primary.withValues(
                                                alpha: 0.5,
                                              ),
                                              blurRadius: 8,
                                            ),
                                          ]
                                        : null,
                                  ),
                                );
                              }),
                            ),
                            const SizedBox(height: 48),
                            // Keypad
                            GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: 3,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: 1.3,
                              children: [
                                ...List.generate(9, (index) {
                                  final num = '${index + 1}';
                                  return _buildKeypadButton(
                                    text: num,
                                    onTap: () => _handleKeypadTap(num),
                                  );
                                }),
                                // Biometric button
                                _buildBiometricButton(),
                                // Zero
                                _buildKeypadButton(
                                  text: '0',
                                  onTap: () => _handleKeypadTap('0'),
                                ),
                                // Backspace
                                _buildIconKeypadButton(
                                  icon: Icons.backspace_outlined,
                                  onTap: _handleBackspace,
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            // Forgot PIN Link
                            TextButton(
                              onPressed: () {},
                              child: Text(
                                'Forgot PIN?',
                                style: TextStyle(
                                  fontFamily: 'JetBrains Mono',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: 96,
                              height: 4,
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(9999),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Access Granted Success Overlay
          if (_isAuthenticating)
            Positioned.fill(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _isAuthenticating ? 1.0 : 0.0,
                child: Container(
                  color:
                      (isDark
                              ? const Color(0xFF0C0E16)
                              : const Color(0xFF191B23))
                          .withValues(alpha: 0.95),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Glowing success check circle
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.elasticOut,
                        tween: Tween(begin: 0.0, end: 1.0),
                        builder: (context, scale, child) {
                          return Transform.scale(scale: scale, child: child);
                        },
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(
                              0xFF22C55E,
                            ).withValues(alpha: 0.15),
                            border: Border.all(
                              color: const Color(
                                0xFF22C55E,
                              ).withValues(alpha: 0.3),
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF22C55E),
                            size: 64,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Access Granted',
                        style: TextStyle(
                          fontFamily: 'Hanken Grotesk',
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          // Always light text on the dark overlay
                          color: Color(0xFFE1E2ED),
                          letterSpacing: -0.02,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Synchronizing floor plan...',
                        style: TextStyle(
                          fontFamily: 'Hanken Grotesk',
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          // Always light text on the dark overlay
                          color: Color(0xFFC3C6D7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildKeypadButton({
    required String text,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'Hanken Grotesk',
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconKeypadButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          alignment: Alignment.center,
          child: Icon(icon, size: 28, color: cs.onSurfaceVariant),
        ),
      ),
    );
  }

  Widget _buildBiometricButton() {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: _handleBiometric,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          alignment: Alignment.center,
          child: Icon(
            Icons.fingerprint_rounded,
            size: 32,
            color: _biometricScanning
                ? const Color(0xFF22C55E)
                : cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
