import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_pos_app/models/pos_models.dart';
import 'package:my_pos_app/providers/pos_provider.dart';
import 'package:my_pos_app/screens/table_grid_screen.dart';

class OutletScreen extends StatelessWidget {
  const OutletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<POSProvider>();
    final user = provider.currentUser;
    final theme = Theme.of(context);

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Session expired. Please sign in again.')),
      );
    }

    final mediaWidth = MediaQuery.of(context).size.width;
    final isTablet = mediaWidth > 640;

    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu_rounded),
              color: const Color(0xFFB4C5FF),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        title: const Text(
          'Table Overview',
          style: TextStyle(
            fontFamily: 'Hanken Grotesk',
            fontWeight: FontWeight.w600,
            color: Color(0xFFB4C5FF),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.storefront_rounded),
            color: const Color(0xFFB4C5FF),
            onPressed: () {},
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: const Color(0xFF434655).withValues(alpha: 0.3),
            height: 1.0,
          ),
        ),
      ),
      drawer: _buildDrawer(context, user, provider),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Select Outlet Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Outlet',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontFamily: 'Hanken Grotesk',
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFE1E2ED),
                    letterSpacing: -0.02,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Choose your station for this shift',
                  style: TextStyle(
                    fontFamily: 'Hanken Grotesk',
                    fontSize: 16,
                    color: Color(0xFFC3C6D7),
                  ),
                ),
              ],
            ),
          ),
          // Outlet Cards Grid/List
          Expanded(
            child: GridView.count(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              crossAxisCount: isTablet ? 2 : 1,
              mainAxisSpacing: 20,
              crossAxisSpacing: 20,
              childAspectRatio: isTablet ? 1.4 : 1.7,
              children: [
                // Card 1: Main Dining
                _buildOutletCard(
                  context: context,
                  title: 'Main Dining Floor',
                  subtitle: '4 Servers Online',
                  badgeText: '85% Occupied',
                  badgeColor: const Color(0xFFEF4444),
                  imageUrl:
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuDA0mBWLGy5i6s964Ush2YtZPmskPBah1KmfGQXvXt8sUWFw7-LiFwOoMKCAmXxCJnPwp-1cVThit4Iff-lSIfD1RaGpXXVrP2u2wIj4BZP_4L5A0iKIsAB3pQd1fwyN3IeLy3MD9Rl1gnQQMt6mlaoZn2KKb4c2ENB_K5-6xKOlQkLA7womrewDgZq2sp7KmO6ssl7dyCDEgUHuSrVc_xYAPJh8zUcXB7C-hwnc5-XdmIQk9i6HfTpjwVdZRRahHa424FUKI6Md2Q',
                  avatars: ['AM', 'JD'],
                  isLocked: false,
                  onTap: () {
                    provider.selectOutlet(provider.mockOutlets[0]);
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const TableGridScreen(),
                      ),
                    );
                  },
                ),
                // Card 2: Bar Area
                _buildOutletCard(
                  context: context,
                  title: 'Terrace & Rooftop Bar',
                  subtitle: '2 Bartenders, 1 Server',
                  badgeText: '40% Occupied',
                  badgeColor: const Color(0xFF22C55E),
                  imageUrl:
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuDnEcCo5kswrpz6S_OygYnM9MpvlPmklWUbjAVwFabwBrtOE2YCSBu-71r0_ASZLT5iH5qJXbI7exaS_CgfpsOfMyY-Eqtqm8iOzsdkqR_hbP8PgVAq-4xkwxhC3iAiviN75D2hT2xEIFKeSnYoV57mw8A6G6N7m1QpskuFQijGBS7t4Fzh0iSl26f1623xGhlrOaGPiGUy1mn_p0NFrSRBbXUwZZBG_mgFuT4NAwA4nSCfk57ifHvgT75YyNAJiYV6iOBqgaTZ1cs',
                  isLocked: false,
                  onTap: () {
                    provider.selectOutlet(provider.mockOutlets[1]);
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const TableGridScreen(),
                      ),
                    );
                  },
                ),
                // Card 3: Outdoor Patio (Locked)
                _buildOutletCard(
                  context: context,
                  title: 'Outdoor Patio',
                  subtitle: 'Opens at 18:00',
                  badgeText: 'Closed for Private Event',
                  badgeColor: const Color(0xFFF59E0B),
                  imageUrl:
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuA_baDp0OIHFHiWQ0IQCE3BmHpfXzc4Fwqn7PHwlSHbsmvjYOOpmpAub42UrPq7-iItmp8yVl6D9Y9dRzl8agI63HIkPZTFGAjJ2bs2y01cWdAH1uq4VM8S-D0F-7kpgAFzwoSAOXtJNCmLRmM-0vWIY1MvWJmDnc4cSa8TUduIzPwk_9HGqh2EHPqXI8F3g6UDvnXOI0C04YB1fddJO8HcB6e5tiA-QtZ-y8hO_lSUvGop56MUtjEdb8BZpZnuDPiSPAp_Q6qiPUo',
                  isLocked: true,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Outdoor Patio is currently closed for private event.'),
                        backgroundColor: Color(0xFF1D1F27),
                      ),
                    );
                  },
                ),
                // Card 4: Wine Cellar (VIP)
                _buildOutletCard(
                  context: context,
                  title: 'Private Dining Room',
                  subtitle: 'VIP Dining',
                  badgeText: '1 Table Active',
                  badgeColor: const Color(0xFF2563EB),
                  imageUrl:
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuC7QmS1hBkYhJ07eNXcjl_NyvvQ9DGAZBPZkx8dmN-qjYPrtOjEU1x8fy2yT4hr_CrYAEt8IiADkHAUJn9VpgveG_xBqrc0CgETr4FsEltKg8rPj6yJz9q6rGK099poruruQiGlOdQk1RY9msPmT8KxGkw-zcMU8fULHpl_QfW5p5uh9EqOPlxs3teag69yGa1DerY2wJstU1CCf8_JdNOKf9hAwt_dDATSar_2gElXLREWSblH0lh-OxJYaM0MCzhZH63dXWGCwww',
                  isLocked: false,
                  onTap: () {
                    provider.selectOutlet(provider.mockOutlets[2]);
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const TableGridScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  Widget _buildOutletCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String badgeText,
    required Color badgeColor,
    required String imageUrl,
    List<String>? avatars,
    required bool isLocked,
    required VoidCallback onTap,
  }) {
    return Card(
      clipBehavior: Clip.antiAlias,
      color: const Color(0xCC1D1F27),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: const Color(0xFF434655).withValues(alpha: 0.3),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            // Image area
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    color: Colors.black.withValues(alpha: 0.35),
                    colorBlendMode: BlendMode.darken,
                    errorBuilder: (context, error, stackTrace) =>
                        Container(color: const Color(0xFF191B23)),
                  ),
                  // Badge overlay
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(9999),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: Text(
                        badgeText,
                        style: const TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Text footer area
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontFamily: 'Hanken Grotesk',
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFE1E2ED),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              if (avatars != null && avatars.isNotEmpty) ...[
                                Row(
                                  children: avatars
                                      .map(
                                        (initials) => Container(
                                          margin: const EdgeInsets.only(right: 6),
                                          width: 20,
                                          height: 20,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF3A4A5F),
                                            shape: BoxShape.circle,
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            initials,
                                            style: const TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFFEEEFFF),
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ],
                              Text(
                                subtitle,
                                style: const TextStyle(
                                  fontFamily: 'Hanken Grotesk',
                                  fontSize: 13,
                                  color: Color(0xFFC3C6D7),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      isLocked ? Icons.lock_outline_rounded : Icons.arrow_forward_ios_rounded,
                      color: isLocked ? const Color(0xFFF59E0B) : const Color(0xFFB4C5FF),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Color(0xFF434655),
            width: 0.5,
          ),
        ),
      ),
      child: BottomNavigationBar(
        backgroundColor: const Color(0xFF191B23),
        selectedItemColor: const Color(0xFFB4C5FF),
        unselectedItemColor: const Color(0xFFC3C6D7),
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(
          fontFamily: 'JetBrains Mono',
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'JetBrains Mono',
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded),
            label: 'Tables',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_rounded),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu_rounded),
            label: 'Menu',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: 'Admin',
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(
      BuildContext context, User user, POSProvider provider) {
    return Drawer(
      backgroundColor: const Color(0xFF1D1F27),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF191B23),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: const Color(0xFFEEEFFF),
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontFamily: 'Hanken Grotesk',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFE1E2ED),
                        ),
                      ),
                      Text(
                        user.role.displayName,
                        style: const TextStyle(
                          fontFamily: 'Hanken Grotesk',
                          fontSize: 14,
                          color: Color(0xFFC3C6D7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard_rounded, color: Color(0xFFB4C5FF)),
            title: const Text('Dashboard'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today_rounded, color: Color(0xFFC3C6D7)),
            title: const Text('Staff Schedule'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.inventory_2_outlined, color: Color(0xFFC3C6D7)),
            title: const Text('Inventory'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.analytics_outlined, color: Color(0xFFC3C6D7)),
            title: const Text('Reports'),
            onTap: () {},
          ),
          const Spacer(),
          const Divider(color: Color(0xFF434655)),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Color(0xFFFFB4AB)),
            title: const Text(
              'Logout',
              style: TextStyle(color: Color(0xFFFFB4AB)),
            ),
            onTap: () {
              provider.clearSession();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
