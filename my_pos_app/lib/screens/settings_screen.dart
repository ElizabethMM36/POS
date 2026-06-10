import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:my_pos_app/models/pos_models.dart';
import 'package:my_pos_app/providers/pos_provider.dart';
import 'package:my_pos_app/providers/theme_provider.dart';
import 'package:my_pos_app/screens/admin_rbac_screen.dart';

/// The "Settings" tab — profile card, outlet info, app configuration,
/// and admin access for RBAC management.

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<POSProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final user = provider.currentUser;
    final outlet = provider.selectedOutlet;
    final cs = Theme.of(context).colorScheme;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        automaticallyImplyLeading: false,
        title: Text(
          'Settings & Profile',
          style: TextStyle(
            fontFamily: 'Hanken Grotesk',
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: cs.onSurface,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    cs.primaryContainer.withValues(alpha: 0.2),
                    cs.surfaceContainerLow,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: cs.primaryContainer.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: cs.primaryContainer.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        user?.name.isNotEmpty == true
                            ? user!.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontFamily: 'Hanken Grotesk',
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'Unknown',
                          style: TextStyle(
                            fontFamily: 'Hanken Grotesk',
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: cs.primaryContainer.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(9999),
                            border: Border.all(
                              color: cs.primaryContainer.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            user?.role.displayName ?? 'Staff',
                            style: TextStyle(
                              fontFamily: 'JetBrains Mono',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: cs.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Online status
                  Column(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF22C55E,
                              ).withValues(alpha: 0.5),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Active',
                        style: TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 10,
                          color: Color(0xFF22C55E),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Current Outlet
            _SectionHeader(title: 'ACTIVE OUTLET'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surfaceContainer,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.storefront_rounded,
                      color: Color(0xFFF59E0B),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          outlet?.name ?? 'No outlet selected',
                          style: TextStyle(
                            fontFamily: 'Hanken Grotesk',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                        ),
                        Text(
                          outlet?.location ?? '',
                          style: TextStyle(
                            fontFamily: 'JetBrains Mono',
                            fontSize: 11,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.swap_horiz_rounded, color: cs.outline),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Session Info
            _SectionHeader(title: 'SESSION INFO'),
            const SizedBox(height: 8),
            _InfoTile(
              icon: Icons.access_time_rounded,
              label: 'Session Started',
              value: _formatTime(DateTime.now()),
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 8),
            _InfoTile(
              icon: Icons.receipt_long_rounded,
              label: 'Open Checks',
              value: '${provider.openChecks.length}',
              color: const Color(0xFF22C55E),
            ),
            const SizedBox(height: 8),
            _InfoTile(
              icon: Icons.attach_money_rounded,
              label: 'Session Revenue',
              value:
                  '\$${provider.closedChecks.fold<double>(0, (s, c) => s + c.total).toStringAsFixed(2)}',
              color: const Color(0xFF22C55E),
            ),
            const SizedBox(height: 24),

            // App Settings
            _SectionHeader(title: 'PREFERENCES'),
            const SizedBox(height: 8),
            // ── Theme Toggle ──
            _SettingsTile(
              icon: themeProvider.isDarkMode
                  ? Icons.dark_mode_rounded
                  : Icons.light_mode_rounded,
              label: themeProvider.isDarkMode ? 'Dark Mode' : 'Light Mode',
              subtitle: 'Switch between dark and light appearance',
              trailing: Switch(
                value: themeProvider.isDarkMode,
                onChanged: (_) => themeProvider.toggleTheme(),
                activeColor: cs.primaryContainer,
              ),
            ),
            _SettingsTile(
              icon: Icons.notifications_outlined,
              label: 'Order Notifications',
              trailing: Switch(
                value: true,
                onChanged: (_) {},
                activeColor: cs.primaryContainer,
              ),
            ),
            _SettingsTile(
              icon: Icons.vibration_rounded,
              label: 'Haptic Feedback',
              trailing: Switch(
                value: true,
                onChanged: (_) {},
                activeColor: cs.primaryContainer,
              ),
            ),
            _SettingsTile(
              icon: Icons.print_outlined,
              label: 'Auto-Print Tickets',
              trailing: Switch(
                value: false,
                onChanged: (_) {},
                activeColor: cs.primaryContainer,
              ),
            ),
            const SizedBox(height: 24),

            // Admin Section (only for admin/manager)
            if (user?.role == UserRole.admin ||
                user?.role == UserRole.manager) ...[
              _SectionHeader(title: 'ADMINISTRATION'),
              const SizedBox(height: 8),
              _SettingsTile(
                icon: Icons.admin_panel_settings_rounded,
                label: 'Staff & Permissions (RBAC)',
                subtitle: 'Manage team roles and access',
                trailing: Icon(Icons.chevron_right_rounded, color: cs.outline),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AdminRBACScreen(),
                    ),
                  );
                },
              ),
              _SettingsTile(
                icon: Icons.menu_book_outlined,
                label: 'Menu Management',
                subtitle: 'Edit items, pricing, availability',
                trailing: Icon(Icons.chevron_right_rounded, color: cs.outline),
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.analytics_outlined,
                label: 'Reports & Analytics',
                subtitle: 'Sales, covers, and performance',
                trailing: Icon(Icons.chevron_right_rounded, color: cs.outline),
                onTap: () {},
              ),
              const SizedBox(height: 24),
            ],

            // Logout
            FilledButton.icon(
              onPressed: () {
                showDialog<void>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: cs.surfaceContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: Text(
                      'End Session?',
                      style: TextStyle(
                        fontFamily: 'Hanken Grotesk',
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    content: Text(
                      'You have ${provider.openChecks.length} open checks. Logging out will end your session.',
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(
                          'Cancel',
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
                      ),
                      FilledButton(
                        onPressed: () {
                          provider.clearSession();
                          Navigator.pop(ctx);
                          Navigator.of(
                            context,
                          ).popUntil((route) => route.isFirst);
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                        ),
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.logout_rounded, size: 20),
              label: const Text(
                'End Session & Logout',
                style: TextStyle(
                  fontFamily: 'Hanken Grotesk',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                backgroundColor: const Color(
                  0xFFEF4444,
                ).withValues(alpha: 0.15),
                foregroundColor: cs.error,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: Color(0xFFEF4444), width: 1),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // App version
            Center(
              child: Text(
                'Command Center POS v1.0.0',
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 11,
                  color: cs.outlineVariant,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm';
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontFamily: 'JetBrains Mono',
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.outline,
        letterSpacing: 0.08,
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Hanken Grotesk',
                fontSize: 14,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: cs.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: cs.primary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Hanken Grotesk',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 11,
                        color: cs.outline,
                      ),
                    ),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}
