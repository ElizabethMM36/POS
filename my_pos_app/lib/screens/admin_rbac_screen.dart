import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:my_pos_app/models/pos_models.dart';
import 'package:my_pos_app/providers/pos_provider.dart';

/// The Admin Role-Based Access Control (RBAC) screen.
/// Allows administrators to manage staff profiles, change PINs, toggle active states,
/// and edit specific operational permissions per staff member or by role.
class AdminRBACScreen extends StatefulWidget {
  const AdminRBACScreen({super.key});

  @override
  State<AdminRBACScreen> createState() => _AdminRBACScreenState();
}

class _AdminRBACScreenState extends State<AdminRBACScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Local state for Roles Tab
  UserRole _selectedRoleForPermissions = UserRole.admin;
  Map<UserRole, List<String>> _rolePermissionsCache = {};

  // Selected staff member for detailed editing on tablet, or for bottom sheet
  StaffMember? _selectedStaffMember;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });

    // Initialize role permissions cache from provider's current staff data
    // to simulate standard role configurations.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncRolePermissionsFromProvider();
    });
  }

  void _syncRolePermissionsFromProvider() {
    final provider = Provider.of<POSProvider>(context, listen: false);
    final staffList = provider.staff;

    final Map<UserRole, List<String>> temp = {};
    for (final role in UserRole.values) {
      // Find staff members with this role to extract common permissions
      final ofRole = staffList.where((s) => s.role == role).toList();
      if (ofRole.isNotEmpty) {
        temp[role] = List<String>.from(ofRole.first.permissions);
      } else {
        // Fallbacks
        switch (role) {
          case UserRole.admin:
            temp[role] = ['all'];
            break;
          case UserRole.manager:
            temp[role] = ['void_check', 'apply_discount', 'view_reports', 'manage_menu'];
            break;
          case UserRole.server:
            temp[role] = ['create_check', 'add_items', 'save_check'];
            break;
          case UserRole.kitchen:
            temp[role] = ['view_orders', 'update_status'];
            break;
        }
      }
    }
    setState(() {
      _rolePermissionsCache = temp;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return const Color(0xFF2563EB); // Blue
      case UserRole.manager:
        return const Color(0xFFF59E0B); // Amber
      case UserRole.server:
        return const Color(0xFF22C55E); // Green
      case UserRole.kitchen:
        return const Color(0xFFEC4899); // Pink
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<POSProvider>();
    final isTablet = MediaQuery.of(context).size.width > 768;

    return Scaffold(
      backgroundColor: const Color(0xFF11131B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF11131B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFFB4C5FF)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Role Management',
              style: TextStyle(
                fontFamily: 'Hanken Grotesk',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFFE1E2ED),
              ),
            ),
            Text(
              'Manage staff access, credentials, & permissions',
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 11,
                color: Color(0xFF8D90A0),
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFF434655), width: 0.5),
              ),
            ),
            child: Row(
              children: [
                // Premium custom segmented tab control
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF191B23),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF434655), width: 0.5),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _tabController.animateTo(0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _tabController.index == 0
                                    ? const Color(0xFF2563EB)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Center(
                                child: Text(
                                  'Staff Members',
                                  style: TextStyle(
                                    fontFamily: 'Hanken Grotesk',
                                    fontSize: 14,
                                    fontWeight: _tabController.index == 0
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: _tabController.index == 0
                                        ? Colors.white
                                        : const Color(0xFFC3C6D7),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _tabController.animateTo(1),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _tabController.index == 1
                                    ? const Color(0xFF2563EB)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Center(
                                child: Text(
                                  'Role Templates',
                                  style: TextStyle(
                                    fontFamily: 'Hanken Grotesk',
                                    fontSize: 14,
                                    fontWeight: _tabController.index == 1
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: _tabController.index == 1
                                        ? Colors.white
                                        : const Color(0xFFC3C6D7),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildStaffTab(provider, isTablet),
          _buildRolesTab(provider),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: () => _showAddStaffSheet(context, provider),
              backgroundColor: const Color(0xFF2563EB),
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text(
                'Add Staff',
                style: TextStyle(
                  fontFamily: 'Hanken Grotesk',
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            )
          : null,
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // STAFF TAB IMPLEMENTATION
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildStaffTab(POSProvider provider, bool isTablet) {
    final filteredStaff = provider.staff.where((s) {
      final nameMatch = s.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final roleMatch = s.role.displayName.toLowerCase().contains(_searchQuery.toLowerCase());
      return nameMatch || roleMatch;
    }).toList();

    Widget staffListWidget = Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
              });
            },
            style: const TextStyle(color: Color(0xFFE1E2ED), fontFamily: 'Hanken Grotesk'),
            decoration: InputDecoration(
              hintText: 'Search staff by name or role...',
              hintStyle: const TextStyle(color: Color(0xFF8D90A0)),
              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF8D90A0)),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, color: Color(0xFF8D90A0)),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFF1D1F27),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF434655), width: 0.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF434655), width: 0.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
              ),
            ),
          ),
        ),

        // Staff List Cards
        Expanded(
          child: filteredStaff.isEmpty
              ? _buildEmptyState('No staff members found matching search.')
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredStaff.length,
                  itemBuilder: (ctx, index) {
                    final member = filteredStaff[index];
                    final isSelected = _selectedStaffMember?.id == member.id;
                    return _buildStaffCard(member, provider, isSelected, isTablet);
                  },
                ),
        ),
      ],
    );

    if (isTablet) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 5,
            child: Container(
              decoration: const BoxDecoration(
                border: Border(
                  right: BorderSide(color: Color(0xFF434655), width: 0.5),
                ),
              ),
              child: staffListWidget,
            ),
          ),
          Expanded(
            flex: 6,
            child: _selectedStaffMember != null
                ? _buildStaffDetailPane(_selectedStaffMember!, provider)
                : _buildEmptyState('Select a staff member to view and edit detailed credentials.'),
          ),
        ],
      );
    }

    return staffListWidget;
  }

  Widget _buildStaffCard(StaffMember member, POSProvider provider, bool isSelected, bool isTablet) {
    final roleColor = _getRoleColor(member.role);
    final count = member.permissions.contains('all')
        ? 'Unrestricted'
        : '${member.permissions.length} Permissions';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isSelected && isTablet ? const Color(0xFF282A32) : const Color(0xFF1D1F27),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected && isTablet
              ? const Color(0xFF2563EB)
              : const Color(0xFF434655).withValues(alpha: 0.3),
          width: isSelected && isTablet ? 1.5 : 1.0,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: () {
          if (isTablet) {
            setState(() {
              _selectedStaffMember = member;
            });
          } else {
            _showEditStaffSheet(context, member, provider);
          }
        },
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: roleColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: roleColor.withValues(alpha: 0.4), width: 1),
          ),
          child: Center(
            child: Text(
              member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
              style: TextStyle(
                fontFamily: 'Hanken Grotesk',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: roleColor,
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                member.name,
                style: TextStyle(
                  fontFamily: 'Hanken Grotesk',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: member.isActive ? const Color(0xFFE1E2ED) : const Color(0xFF8D90A0),
                  decoration: member.isActive ? TextDecoration.none : TextDecoration.lineThrough,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: roleColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                member.role.displayName,
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: roleColor,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              const Icon(Icons.key_rounded, color: Color(0xFF8D90A0), size: 12),
              const SizedBox(width: 4),
              Text(
                'PIN: ${member.pin}',
                style: const TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 12,
                  color: Color(0xFFC3C6D7),
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.shield_outlined, color: Color(0xFF8D90A0), size: 12),
              const SizedBox(width: 4),
              Text(
                count,
                style: const TextStyle(
                  fontFamily: 'Hanken Grotesk',
                  fontSize: 12,
                  color: Color(0xFFC3C6D7),
                ),
              ),
            ],
          ),
        ),
        trailing: Switch(
          value: member.isActive,
          onChanged: (active) {
            provider.toggleStaffActive(member.id);
            // Sync local selected staff view if editing
            if (_selectedStaffMember?.id == member.id) {
              setState(() {
                _selectedStaffMember!.isActive = active;
              });
            }
          },
          activeThumbColor: const Color(0xFF22C55E),
          activeTrackColor: const Color(0xFF22C55E).withValues(alpha: 0.2),
          inactiveThumbColor: const Color(0xFF8D90A0),
          inactiveTrackColor: const Color(0xFF191B23),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // DETAILED VIEW FOR TABLETS
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildStaffDetailPane(StaffMember member, POSProvider provider) {
    return Container(
      color: const Color(0xFF191B23),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Detail Header
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: _getRoleColor(member.role).withValues(alpha: 0.15),
                child: Text(
                  member.name.isNotEmpty ? member.name[0] : '?',
                  style: TextStyle(
                    fontFamily: 'Hanken Grotesk',
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: _getRoleColor(member.role),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.name,
                      style: const TextStyle(
                        fontFamily: 'Hanken Grotesk',
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFE1E2ED),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${member.id} • ${member.role.displayName}',
                      style: const TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 12,
                        color: Color(0xFF8D90A0),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Text(
                    member.isActive ? 'ACTIVE' : 'INACTIVE',
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: member.isActive ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Switch(
                    value: member.isActive,
                    onChanged: (active) {
                      provider.toggleStaffActive(member.id);
                      setState(() {
                        member.isActive = active;
                      });
                    },
                    activeThumbColor: const Color(0xFF22C55E),
                  ),
                ],
              ),
            ],
          ),
          const Divider(color: Color(0xFF434655), height: 32),

          // Edit Form
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildEditFormFields(member, provider, inline: true),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // ROLES & ACCESS TEMPLATES TAB
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildRolesTab(POSProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Role Templates',
            style: TextStyle(
              fontFamily: 'Hanken Grotesk',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFFE1E2ED),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Configure default permission policies mapping to job titles.',
            style: TextStyle(
              fontFamily: 'Hanken Grotesk',
              fontSize: 14,
              color: Color(0xFFC3C6D7),
            ),
          ),
          const SizedBox(height: 16),

          // Role Selection Cards
          GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            shrinkWrap: true,
            childAspectRatio: 1.3,
            physics: const NeverScrollableScrollPhysics(),
            children: UserRole.values.map((role) {
              final isSelected = _selectedRoleForPermissions == role;
              final roleColor = _getRoleColor(role);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedRoleForPermissions = role;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF1D1F27) : const Color(0xFF191B23),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? roleColor : const Color(0xFF434655).withValues(alpha: 0.3),
                      width: isSelected ? 1.5 : 1.0,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: roleColor.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ]
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            role.displayName,
                            style: TextStyle(
                              fontFamily: 'Hanken Grotesk',
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: isSelected ? roleColor : const Color(0xFFE1E2ED),
                            ),
                          ),
                          Icon(
                            _getRoleIcon(role),
                            color: isSelected ? roleColor : const Color(0xFF8D90A0),
                            size: 20,
                          ),
                        ],
                      ),
                      Text(
                        _getRoleDescription(role),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Hanken Grotesk',
                          fontSize: 11,
                          color: Color(0xFF8D90A0),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: roleColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _getRoleLabel(role),
                          style: TextStyle(
                            fontFamily: 'JetBrains Mono',
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: roleColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Role Permissions Matrix Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1D1F27),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF434655).withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_selectedRoleForPermissions.displayName} Policy Map',
                          style: TextStyle(
                            fontFamily: 'Hanken Grotesk',
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: _getRoleColor(_selectedRoleForPermissions),
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Toggle granular overrides applied to this role.',
                          style: TextStyle(
                            fontFamily: 'Hanken Grotesk',
                            fontSize: 13,
                            color: Color(0xFF8D90A0),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getRoleColor(_selectedRoleForPermissions).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Text(
                        _selectedRoleForPermissions == UserRole.admin
                            ? 'Root Administrator'
                            : 'Standard Authority',
                        style: TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _getRoleColor(_selectedRoleForPermissions),
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(color: Color(0xFF434655), height: 32),

                // Matrix list grouped by Category
                ..._buildRolePermissionMatrix(provider),

                const SizedBox(height: 24),
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _saveRoleChanges(provider),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Save Role Changes',
                          style: TextStyle(
                            fontFamily: 'Hanken Grotesk',
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _syncRolePermissionsFromProvider();
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Permissions reset to provider values.'),
                            backgroundColor: Color(0xFF1D1F27),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFE1E2ED),
                        side: const BorderSide(color: Color(0xFF434655)),
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Reset',
                        style: TextStyle(
                          fontFamily: 'Hanken Grotesk',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  List<Widget> _buildRolePermissionMatrix(POSProvider provider) {
    // Group permissions by category
    final Map<String, List<Permission>> grouped = {};
    for (final perm in POSProvider.allPermissions) {
      grouped.putIfAbsent(perm.category, () => []).add(perm);
    }

    final currentRolePerms = _rolePermissionsCache[_selectedRoleForPermissions] ?? [];

    return grouped.entries.map((entry) {
      final category = entry.key;
      final perms = entry.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              category.toUpperCase(),
              style: const TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8D90A0),
                letterSpacing: 0.1,
              ),
            ),
          ),
          ...perms.map((p) {
            final isChecked = currentRolePerms.contains(p.id) || currentRolePerms.contains('all');
            final isRootAdmin = _selectedRoleForPermissions == UserRole.admin;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF191B23),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF434655).withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D1F27),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      _getPermissionIcon(p.id),
                      size: 16,
                      color: isChecked ? const Color(0xFFB4C5FF) : const Color(0xFF8D90A0),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          style: const TextStyle(
                            fontFamily: 'Hanken Grotesk',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFE1E2ED),
                          ),
                        ),
                        Text(
                          p.description,
                          style: const TextStyle(
                            fontFamily: 'Hanken Grotesk',
                            fontSize: 11,
                            color: Color(0xFF8D90A0),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: isChecked,
                    onChanged: isRootAdmin
                        ? null // Admin permissions are permanently 'all'
                        : (val) {
                            setState(() {
                              final updatedList = List<String>.from(currentRolePerms);
                              if (val) {
                                updatedList.add(p.id);
                              } else {
                                updatedList.remove(p.id);
                              }
                              _rolePermissionsCache[_selectedRoleForPermissions] = updatedList;
                            });
                          },
                    activeThumbColor: const Color(0xFF2563EB),
                    inactiveThumbColor: const Color(0xFF8D90A0),
                    inactiveTrackColor: const Color(0xFF11131B),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 12),
        ],
      );
    }).toList();
  }

  void _saveRoleChanges(POSProvider provider) {
    // Apply changes locally: update permissions for all staff members matching the selected role
    final selectedRole = _selectedRoleForPermissions;
    final newPerms = _rolePermissionsCache[selectedRole] ?? [];

    if (selectedRole == UserRole.admin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Admin role permissions are absolute and cannot be modified.'),
          backgroundColor: Color(0xFFEC4899),
        ),
      );
      return;
    }

    final staffToUpdate = provider.staff.where((s) => s.role == selectedRole).toList();
    for (final staff in staffToUpdate) {
      provider.updateStaffMember(staff.id, permissions: newPerms);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Successfully updated permissions for ${staffToUpdate.length} ${selectedRole.displayName}s.',
        ),
        backgroundColor: const Color(0xFF22C55E),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // DIALOGS & FORM UTILS
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildEmptyState(String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.badge_outlined, size: 64, color: Color(0xFF434655)),
            const SizedBox(height: 16),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Hanken Grotesk',
                fontSize: 15,
                color: Color(0xFF8D90A0),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Icons.lock_open_rounded;
      case UserRole.manager:
        return Icons.supervisor_account_rounded;
      case UserRole.server:
        return Icons.person_rounded;
      case UserRole.kitchen:
        return Icons.restaurant_menu_rounded;
    }
  }

  String _getRoleDescription(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Full system access, reports, settings, audit logs.';
      case UserRole.manager:
        return 'Operational oversight, discount/void approvals.';
      case UserRole.server:
        return 'Standard order entry, seat management, checkout.';
      case UserRole.kitchen:
        return 'Kitchen screen view, ticket status tracking.';
    }
  }

  String _getRoleLabel(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'LVL 10 UNRESTRICTED';
      case UserRole.manager:
        return 'LVL 7 SUPERVISOR';
      case UserRole.server:
        return 'LVL 3 SERVER';
      case UserRole.kitchen:
        return 'LVL 2 PREP';
    }
  }

  IconData _getPermissionIcon(String permId) {
    switch (permId) {
      case 'create_check':
        return Icons.add_circle_outline_rounded;
      case 'add_items':
        return Icons.post_add_rounded;
      case 'save_check':
        return Icons.save_rounded;
      case 'void_check':
        return Icons.cancel_rounded;
      case 'void_item':
        return Icons.delete_outline_rounded;
      case 'apply_discount':
        return Icons.percent_rounded;
      case 'view_reports':
        return Icons.bar_chart_rounded;
      case 'manage_menu':
        return Icons.edit_note_rounded;
      case 'manage_staff':
        return Icons.manage_accounts_rounded;
      case 'view_orders':
        return Icons.receipt_long_rounded;
      case 'update_status':
        return Icons.published_with_changes_rounded;
      default:
        return Icons.shield_outlined;
    }
  }

  // Common Edit Form Fields for Bottom Sheets and Tablet Pane
  Widget _buildEditFormFields(StaffMember member, POSProvider provider, {required bool inline}) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: member.name);
    final pinController = TextEditingController(text: member.pin);
    UserRole selectedRole = member.role;
    List<String> selectedPerms = List<String>.from(member.permissions);

    return StatefulBuilder(
      builder: (ctx, setFormState) {
        final roleColor = _getRoleColor(selectedRole);

        return Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Full Name
              const Text(
                'Full Name',
                style: TextStyle(
                  fontFamily: 'Hanken Grotesk',
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFC3C6D7),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: nameController,
                validator: (val) => val == null || val.trim().isEmpty ? 'Name is required' : null,
                style: const TextStyle(color: Color(0xFFE1E2ED), fontFamily: 'Hanken Grotesk'),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF1D1F27),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF434655), width: 0.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF434655), width: 0.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // PIN & Role selector side-by-side
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '4-Digit PIN',
                          style: TextStyle(
                            fontFamily: 'Hanken Grotesk',
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFC3C6D7),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: pinController,
                          maxLength: 4,
                          keyboardType: TextInputType.number,
                          validator: (val) {
                            if (val == null || val.length != 4) return 'PIN must be 4 digits';
                            if (int.tryParse(val) == null) return 'Must be numeric';
                            return null;
                          },
                          buildCounter: (ctx, {required currentLength, required isFocused, maxLength}) => null,
                          style: const TextStyle(
                            color: Color(0xFFE1E2ED),
                            fontFamily: 'JetBrains Mono',
                            letterSpacing: 4,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFF1D1F27),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFF434655), width: 0.5),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFF434655), width: 0.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Staff Role',
                          style: TextStyle(
                            fontFamily: 'Hanken Grotesk',
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFC3C6D7),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<UserRole>(
                          initialValue: selectedRole,
                          dropdownColor: const Color(0xFF1D1F27),
                          style: const TextStyle(color: Color(0xFFE1E2ED), fontFamily: 'Hanken Grotesk'),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFF1D1F27),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFF434655), width: 0.5),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFF434655), width: 0.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                            ),
                          ),
                          items: UserRole.values.map((r) {
                            return DropdownMenuItem(
                              value: r,
                              child: Text(r.displayName),
                            );
                          }).toList(),
                          onChanged: (role) {
                            if (role != null) {
                              setFormState(() {
                                selectedRole = role;
                                // Reset to default permissions of that role template
                                selectedPerms = List<String>.from(_rolePermissionsCache[role] ?? []);
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Permissions Overrides header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Permissions Assignment',
                    style: TextStyle(
                      fontFamily: 'Hanken Grotesk',
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFE1E2ED),
                      fontSize: 16,
                    ),
                  ),
                  if (selectedRole == UserRole.admin)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: roleColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'ALL PERMISSIONS',
                        style: TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: roleColor,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Permissions List grouped by category
              Container(
                constraints: BoxConstraints(maxHeight: inline ? 400.0 : 250.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF11131B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF434655).withValues(alpha: 0.3)),
                ),
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(8),
                  children: POSProvider.allPermissions.map((p) {
                    final isChecked = selectedPerms.contains(p.id) || selectedPerms.contains('all');
                    final isDisabled = selectedRole == UserRole.admin;

                    return CheckboxListTile(
                      value: isChecked,
                      onChanged: isDisabled
                          ? null
                          : (checked) {
                              setFormState(() {
                                if (checked == true) {
                                  selectedPerms.add(p.id);
                                } else {
                                  selectedPerms.remove(p.id);
                                }
                              });
                            },
                      title: Text(
                        p.name,
                        style: const TextStyle(
                          fontFamily: 'Hanken Grotesk',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFE1E2ED),
                        ),
                      ),
                      subtitle: Text(
                        p.description,
                        style: const TextStyle(
                          fontFamily: 'Hanken Grotesk',
                          fontSize: 11,
                          color: Color(0xFF8D90A0),
                        ),
                      ),
                      activeColor: const Color(0xFF2563EB),
                      checkColor: Colors.white,
                      dense: true,
                      controlAffinity: ListTileControlAffinity.trailing,
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),

              // Form Action Save/Cancel
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (formKey.currentState?.validate() == true) {
                          provider.updateStaffMember(
                            member.id,
                            name: nameController.text.trim(),
                            pin: pinController.text.trim(),
                            role: selectedRole,
                            permissions: selectedPerms,
                          );
                          // Sync selectedStaffMember state if in inline view
                          if (inline) {
                            setState(() {
                              _selectedStaffMember = provider.staff.firstWhere((s) => s.id == member.id);
                            });
                          } else {
                            Navigator.pop(ctx);
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Staff member details saved.'),
                              backgroundColor: Color(0xFF22C55E),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Save Staff Member',
                        style: TextStyle(
                          fontFamily: 'Hanken Grotesk',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  if (!inline) ...[
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Color(0xFFC3C6D7), fontFamily: 'Hanken Grotesk'),
                      ),
                    ),
                  ]
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditStaffSheet(BuildContext context, StaffMember member, POSProvider provider) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF191B23),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Edit ${member.name}',
                      style: const TextStyle(
                        fontFamily: 'Hanken Grotesk',
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFE1E2ED),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFF8D90A0)),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Divider(color: Color(0xFF434655), height: 20),
                _buildEditFormFields(member, provider, inline: false),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddStaffSheet(BuildContext context, POSProvider provider) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final pinController = TextEditingController();
    UserRole selectedRole = UserRole.server;
    List<String> selectedPerms = ['create_check', 'add_items', 'save_check'];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF191B23),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (sCtx, setModalState) {
                final roleColor = _getRoleColor(selectedRole);

                return Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Add Staff Member',
                            style: TextStyle(
                              fontFamily: 'Hanken Grotesk',
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFE1E2ED),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Color(0xFF8D90A0)),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const Divider(color: Color(0xFF434655), height: 20),

                      // Name input
                      const Text(
                        'Full Name',
                        style: TextStyle(
                          fontFamily: 'Hanken Grotesk',
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFC3C6D7),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: nameController,
                        validator: (val) =>
                            val == null || val.trim().isEmpty ? 'Name is required' : null,
                        style: const TextStyle(color: Color(0xFFE1E2ED), fontFamily: 'Hanken Grotesk'),
                        decoration: InputDecoration(
                          hintText: 'e.g. John Doe',
                          hintStyle: const TextStyle(color: Color(0xFF434655)),
                          filled: true,
                          fillColor: const Color(0xFF1D1F27),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFF434655), width: 0.5),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFF434655), width: 0.5),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // PIN and Role
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '4-Digit PIN',
                                  style: TextStyle(
                                    fontFamily: 'Hanken Grotesk',
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFC3C6D7),
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: pinController,
                                  maxLength: 4,
                                  keyboardType: TextInputType.number,
                                  validator: (val) {
                                    if (val == null || val.length != 4) return 'PIN must be 4 digits';
                                    if (int.tryParse(val) == null) return 'Must be numeric';
                                    return null;
                                  },
                                  buildCounter: (ctx,
                                          {required currentLength,
                                          required isFocused,
                                          maxLength}) =>
                                      null,
                                  style: const TextStyle(
                                    color: Color(0xFFE1E2ED),
                                    fontFamily: 'JetBrains Mono',
                                    letterSpacing: 4,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: '0000',
                                    hintStyle: const TextStyle(color: Color(0xFF434655), letterSpacing: 0),
                                    filled: true,
                                    fillColor: const Color(0xFF1D1F27),
                                    contentPadding:
                                        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(color: Color(0xFF434655), width: 0.5),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(color: Color(0xFF434655), width: 0.5),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Staff Role',
                                  style: TextStyle(
                                    fontFamily: 'Hanken Grotesk',
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFC3C6D7),
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<UserRole>(
                                  initialValue: selectedRole,
                                  dropdownColor: const Color(0xFF1D1F27),
                                  style: const TextStyle(
                                      color: Color(0xFFE1E2ED), fontFamily: 'Hanken Grotesk'),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: const Color(0xFF1D1F27),
                                    contentPadding:
                                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(color: Color(0xFF434655), width: 0.5),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(color: Color(0xFF434655), width: 0.5),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                                    ),
                                  ),
                                  items: UserRole.values.map((r) {
                                    return DropdownMenuItem(
                                      value: r,
                                      child: Text(r.displayName),
                                    );
                                  }).toList(),
                                  onChanged: (role) {
                                    if (role != null) {
                                      setModalState(() {
                                        selectedRole = role;
                                        // Reset to defaults
                                        selectedPerms =
                                            List<String>.from(_rolePermissionsCache[role] ?? []);
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Permissions overrides header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Grant Permissions',
                            style: TextStyle(
                              fontFamily: 'Hanken Grotesk',
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFE1E2ED),
                              fontSize: 16,
                            ),
                          ),
                          if (selectedRole == UserRole.admin)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: roleColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'ALL ACCESS',
                                style: TextStyle(
                                  fontFamily: 'JetBrains Mono',
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: roleColor,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Permissions
                      Container(
                        constraints: const BoxConstraints(maxHeight: 250.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFF11131B),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF434655).withValues(alpha: 0.3)),
                        ),
                        child: ListView(
                          shrinkWrap: true,
                          padding: const EdgeInsets.all(8),
                          children: POSProvider.allPermissions.map((p) {
                            final isChecked =
                                selectedPerms.contains(p.id) || selectedPerms.contains('all');
                            final isDisabled = selectedRole == UserRole.admin;

                            return CheckboxListTile(
                              value: isChecked,
                              onChanged: isDisabled
                                  ? null
                                  : (checked) {
                                      setModalState(() {
                                        if (checked == true) {
                                          selectedPerms.add(p.id);
                                        } else {
                                          selectedPerms.remove(p.id);
                                        }
                                      });
                                    },
                              title: Text(
                                p.name,
                                style: const TextStyle(
                                  fontFamily: 'Hanken Grotesk',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFE1E2ED),
                                ),
                              ),
                              subtitle: Text(
                                p.description,
                                style: const TextStyle(
                                  fontFamily: 'Hanken Grotesk',
                                  fontSize: 11,
                                  color: Color(0xFF8D90A0),
                                ),
                              ),
                              activeColor: const Color(0xFF2563EB),
                              checkColor: Colors.white,
                              dense: true,
                              controlAffinity: ListTileControlAffinity.trailing,
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Actions
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                if (formKey.currentState?.validate() == true) {
                                  final newId = 's${provider.staff.length + 1}';
                                  final newMember = StaffMember(
                                    id: newId,
                                    name: nameController.text.trim(),
                                    pin: pinController.text.trim(),
                                    role: selectedRole,
                                    permissions: selectedPerms,
                                  );
                                  provider.addStaffMember(newMember);
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Staff member ${newMember.name} added.'),
                                      backgroundColor: const Color(0xFF22C55E),
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                'Add Staff Member',
                                style: TextStyle(
                                  fontFamily: 'Hanken Grotesk',
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                  color: Color(0xFFC3C6D7), fontFamily: 'Hanken Grotesk'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
