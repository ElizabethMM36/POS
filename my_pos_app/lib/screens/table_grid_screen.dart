import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_pos_app/models/pos_models.dart';
import 'package:my_pos_app/providers/pos_provider.dart';
import 'package:my_pos_app/screens/order_screen.dart';

// Color guidelines from DESIGN.md
const Color _statusAvailable = Color(0xFF22C55E);
const Color _statusOccupied = Color(0xFFEF4444);
const Color _statusBilling = Color(0xFFF59E0B);
const Color _statusReserved = Color(0xFFF59E0B);
const Color _statusAlert = Color(0xFFEC4899);

class TableGridScreen extends StatefulWidget {
  const TableGridScreen({super.key});

  @override
  State<TableGridScreen> createState() => _TableGridScreenState();
}

class _TableGridScreenState extends State<TableGridScreen>
    with SingleTickerProviderStateMixin {
  String _selectedSection = 'All Sections';
  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;

  final List<String> _sections = [
    'All Sections',
    'Main Dining Floor',
    'Terrace & Rooftop Bar',
    'Private Dining Room',
  ];

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _blinkAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  Color _statusColor(TableStatus status) {
    switch (status) {
      case TableStatus.available:
        return _statusAvailable;
      case TableStatus.occupied:
        return _statusOccupied;
      case TableStatus.billing:
        return _statusBilling;
      case TableStatus.reserved:
        return _statusReserved;
    }
  }

  void _showTableSheet(BuildContext context, RestaurantTable table) {
    final provider = context.read<POSProvider>();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1D1F27),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      showDragHandle: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 8,
            bottom: MediaQuery.of(sheetContext).padding.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Table ${table.number}',
                    style: const TextStyle(
                      fontFamily: 'Hanken Grotesk',
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFE1E2ED),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor(table.status).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(9999),
                      border: Border.all(
                        color: _statusColor(table.status),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      table.status.displayName,
                      style: TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _statusColor(table.status),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _MetadataRow(
                label: 'Covers (Pax)',
                value: table.covers > 0 ? '${table.covers}' : '—',
              ),
              if (table.duration.isNotEmpty) ...[
                const SizedBox(height: 10),
                _MetadataRow(
                  label: 'Duration',
                  value: table.duration,
                ),
              ],
              if (table.billAmount > 0) ...[
                const SizedBox(height: 10),
                _MetadataRow(
                  label: 'Accumulated Bill',
                  value: '\$${table.billAmount.toStringAsFixed(2)}',
                  valueColor: const Color(0xFFB4C5FF),
                ),
              ],
              const SizedBox(height: 12),
              const Divider(color: Color(0xFF434655)),
              const SizedBox(height: 12),
              Text(
                table.orders.isEmpty ? 'No current items' : 'Current ticket items:',
                style: const TextStyle(
                  fontFamily: 'Hanken Grotesk',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFC3C6D7),
                ),
              ),
              if (table.orders.isNotEmpty) ...[
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 160),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: table.orders.length,
                    itemBuilder: (_, i) {
                      final item = table.orders[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF191B23),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: const TextStyle(
                                    fontFamily: 'Hanken Grotesk',
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFE1E2ED),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Course ${item.courseNumber}',
                                  style: const TextStyle(
                                    fontFamily: 'JetBrains Mono',
                                    fontSize: 12,
                                    color: Color(0xFFC3C6D7),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'Qty ×${item.quantity}',
                              style: const TextStyle(
                                fontFamily: 'JetBrains Mono',
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFB4C5FF),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => OrderScreen(tableNumber: table.number),
                    ),
                  );
                },
                icon: const Icon(Icons.restaurant_menu_rounded),
                label: const Text(
                  'Open Kitchen Order Sheet',
                  style: TextStyle(fontFamily: 'Hanken Grotesk', fontWeight: FontWeight.bold),
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: const Color(0xFFEEEFFF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              if (provider.currentUser?.role == UserRole.admin || table.status != TableStatus.available) ...[
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () {
                    provider.updateTableMetadata(
                      table.number,
                      status: TableStatus.available,
                      covers: 0,
                      orders: const [],
                      replaceOrders: true,
                    );
                    Navigator.of(sheetContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Table ${table.number} cleared.'),
                        backgroundColor: const Color(0xFF1D1F27),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    side: const BorderSide(color: Color(0xFFFFB4AB)),
                    foregroundColor: const Color(0xFFFFB4AB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Reset table status'),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showNewTableCheckDialog(BuildContext context) {
    final provider = context.read<POSProvider>();
    int? selectedTableNum;
    final availableTables = provider.tables
        .where((t) => t.status == TableStatus.available)
        .map((t) => t.number)
        .toList();

    if (availableTables.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No tables are currently available.')),
      );
      return;
    }

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1D1F27),
          title: const Text(
            'New Table Order',
            style: TextStyle(fontFamily: 'Hanken Grotesk', fontWeight: FontWeight.bold),
          ),
          content: DropdownButtonFormField<int>(
            decoration: const InputDecoration(
              labelText: 'Select Table Number',
              border: OutlineInputBorder(),
            ),
            items: availableTables
                .map(
                  (tNum) => DropdownMenuItem<int>(
                    value: tNum,
                    child: Text('Table $tNum'),
                  ),
                )
                .toList(),
            onChanged: (val) {
              selectedTableNum = val;
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFFC3C6D7))),
            ),
            FilledButton(
              onPressed: () {
                if (selectedTableNum != null) {
                  Navigator.of(dialogContext).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => OrderScreen(tableNumber: selectedTableNum!),
                    ),
                  );
                }
              },
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<POSProvider>();
    final outlet = provider.selectedOutlet;
    final user = provider.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Session expired. Please sign in again.')),
      );
    }

    // Filter tables based on section filter selection
    final filteredTables = provider.tables.where((table) {
      if (_selectedSection == 'All Sections') return true;
      if (_selectedSection == 'Main Dining Floor') {
        // Mocking: Tables 1-8 belong to main dining
        return table.number <= 8;
      }
      if (_selectedSection == 'Terrace & Rooftop Bar') {
        // Mocking: Tables 9-11 and 13 belong to bar
        return (table.number >= 9 && table.number <= 11) || table.number == 13;
      }
      if (_selectedSection == 'Private Dining Room') {
        // Mocking: Tables 12, 14, 15, 16 belong to private room
        return table.number == 12 || table.number >= 14;
      }
      return true;
    }).toList();

    // Calculations for Stats Overview Bento
    final int availCount =
        provider.tables.where((t) => t.status == TableStatus.available).length;
    final int rsvdCount =
        provider.tables.where((t) => t.status == TableStatus.reserved).length;

    // Recall check metadata (Table 4 active check)
    final table4 = provider.getTableByNumber(4);

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
        title: Text(
          outlet?.name ?? 'Table Overview',
          style: const TextStyle(
            fontFamily: 'Hanken Grotesk',
            fontWeight: FontWeight.w600,
            color: Color(0xFFB4C5FF),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_rounded),
            color: const Color(0xFFB4C5FF),
            tooltip: 'Saved Checks',
            onPressed: () {
              // Conceptual: open check recall sheet / saved list
              if (table4 != null) {
                _showTableSheet(context, table4);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.storefront_rounded),
            color: const Color(0xFFB4C5FF),
            onPressed: () {
              Navigator.of(context).pop(); // Go back to outlet selection
            },
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
          // Section filters capsules
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            color: const Color(0xFF11131B),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _sections.map((section) {
                  final isSelected = _selectedSection == section;
                  // Map to shorter display names
                  String displayName = section;
                  if (section == 'Main Dining Floor') displayName = 'Main Dining';
                  if (section == 'Terrace & Rooftop Bar') displayName = 'Bar Area';
                  if (section == 'Private Dining Room') displayName = 'Private Room';

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedSection = section;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF2563EB)
                            : const Color(0xFF1D1F27),
                        borderRadius: BorderRadius.circular(9999),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF2563EB)
                              : const Color(0xFF434655).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        displayName,
                        style: TextStyle(
                          fontFamily: 'Hanken Grotesk',
                          fontSize: 14,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected
                              ? const Color(0xFFEEEFFF)
                              : const Color(0xFFC3C6D7),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          // Scrollable floor grid & stats view
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Stats Bento row
                  Row(
                    children: [
                      // Available Bento Item
                      Expanded(
                        child: Container(
                          height: 100,
                          decoration: BoxDecoration(
                            color: const Color(0xFF191B23),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF434655).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'AVAIL',
                                style: TextStyle(
                                  fontFamily: 'JetBrains Mono',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _statusAvailable,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                availCount.toString().padLeft(2, '0'),
                                style: const TextStyle(
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
                      ),
                      const SizedBox(width: 12),
                      // Recall Check Table 4 Bento Item
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (table4 != null) {
                              _showTableSheet(context, table4);
                            }
                          },
                          child: Container(
                            height: 100,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF282A32),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFF434655).withValues(alpha: 0.6),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  blurRadius: 8,
                                )
                              ],
                            ),
                            child: Stack(
                              children: [
                                // Translucent table number backdrop
                                Align(
                                  alignment: Alignment.center,
                                  child: Text(
                                    '04',
                                    style: TextStyle(
                                      fontFamily: 'Hanken Grotesk',
                                      fontSize: 64,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFFE1E2ED).withValues(alpha: 0.05),
                                      height: 1,
                                    ),
                                  ),
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'T-04',
                                          style: TextStyle(
                                            fontFamily: 'JetBrains Mono',
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: _statusOccupied,
                                          ),
                                        ),
                                        AnimatedBuilder(
                                          animation: _blinkAnimation,
                                          builder: (context, child) {
                                            return Opacity(
                                              opacity: _blinkAnimation.value,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                  vertical: 1.5,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: _statusAlert,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: const Row(
                                                  children: [
                                                    Icon(
                                                      Icons.receipt_rounded,
                                                      size: 10,
                                                      color: Colors.white,
                                                    ),
                                                    SizedBox(width: 2),
                                                    Text(
                                                      'BILL',
                                                      style: TextStyle(
                                                        fontFamily: 'JetBrains Mono',
                                                        fontSize: 9,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          table4?.duration ?? '42m',
                                          style: const TextStyle(
                                            fontFamily: 'JetBrains Mono',
                                            fontSize: 11,
                                            color: Color(0xFFC3C6D7),
                                          ),
                                        ),
                                        Text(
                                          '\$${(table4?.billAmount ?? 84.50).toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontFamily: 'JetBrains Mono',
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFB4C5FF),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Reserved Bento Item
                      Expanded(
                        child: Container(
                          height: 100,
                          decoration: BoxDecoration(
                            color: const Color(0xFF191B23),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF434655).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'RSVD',
                                style: TextStyle(
                                  fontFamily: 'JetBrains Mono',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _statusReserved,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                rsvdCount.toString().padLeft(2, '0'),
                                style: const TextStyle(
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
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Grid of tables
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.92,
                    ),
                    itemCount: filteredTables.length,
                    itemBuilder: (context, index) {
                      final table = filteredTables[index];
                      return _buildTableCard(context, table);
                    },
                  ),
                  const SizedBox(height: 24),
                  // Quick Status Guide
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xCC1D1F27),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF434655).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'QUICK STATUS GUIDE',
                          style: TextStyle(
                            fontFamily: 'JetBrains Mono',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFC3C6D7),
                            letterSpacing: 0.05,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildLegendItem('Available', _statusAvailable),
                            _buildLegendItem('Occupied', _statusOccupied),
                            _buildLegendItem('Reserved', _statusReserved),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNewTableCheckDialog(context),
        backgroundColor: const Color(0xFFB4C5FF),
        foregroundColor: const Color(0xFF002A78),
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, size: 32),
      ),
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  Widget _buildTableCard(BuildContext context, RestaurantTable table) {
    final isAvailable = table.status == TableStatus.available;
    final isReserved = table.status == TableStatus.reserved;
    final isBilling = table.status == TableStatus.billing;

    Color borderCol = const Color(0xFF434655);
    Color fillCol = const Color(0xFF1D1F27);
    double borderWidth = 1.0;

    if (isAvailable) {
      borderCol = _statusAvailable;
      fillCol = _statusAvailable.withValues(alpha: 0.08);
      borderWidth = 1.5;
    } else if (isBilling) {
      borderCol = _statusBilling;
      borderWidth = 1.5;
    } else if (isReserved) {
      borderCol = _statusReserved;
    }

    return Card(
      margin: EdgeInsets.zero,
      color: fillCol,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderCol, width: borderWidth),
      ),
      child: InkWell(
        onTap: () => _showTableSheet(context, table),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // Status bar strip at top
            if (!isAvailable)
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: _statusColor(table.status),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top stats row (Table no / Covers / Status Badge)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'T-${table.number.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontFamily: 'JetBrains Mono',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _statusColor(table.status),
                          ),
                        ),
                        if (isBilling)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1.0,
                            ),
                            decoration: BoxDecoration(
                              color: _statusAlert,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: const Text(
                              'BILL',
                              style: TextStyle(
                                fontFamily: 'JetBrains Mono',
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        if (table.covers > 0 && !isBilling)
                          Row(
                            children: [
                              const Icon(Icons.groups_rounded,
                                  size: 14, color: Color(0xFFC3C6D7)),
                              const SizedBox(width: 2),
                              Text(
                                '${table.covers}',
                                style: const TextStyle(
                                  fontFamily: 'JetBrains Mono',
                                  fontSize: 11,
                                  color: Color(0xFFC3C6D7),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    // Table ID Number Display
                    Text(
                      table.number.toString().padLeft(2, '0'),
                      style: TextStyle(
                        fontFamily: 'Hanken Grotesk',
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        height: 1,
                        color: isAvailable
                            ? const Color(0xFFE1E2ED)
                            : const Color(0xFFE1E2ED).withValues(alpha: 0.5),
                      ),
                    ),
                    // Bottom status/meta row
                    Column(
                      children: [
                        if (isAvailable)
                          Text(
                            'Available',
                            style: TextStyle(
                              fontFamily: 'Hanken Grotesk',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _statusColor(table.status),
                            ),
                          )
                        else if (isReserved)
                          Text(
                            table.reservationTime,
                            style: TextStyle(
                              fontFamily: 'JetBrains Mono',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _statusColor(table.status),
                            ),
                            textAlign: TextAlign.center,
                          )
                        else ...[
                          // Occupied/billing details row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                table.duration,
                                style: const TextStyle(
                                  fontFamily: 'JetBrains Mono',
                                  fontSize: 10,
                                  color: Color(0xFFC3C6D7),
                                ),
                              ),
                              Text(
                                '\$${table.billAmount.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontFamily: 'JetBrains Mono',
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFB4C5FF),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
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

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Hanken Grotesk',
            fontSize: 13,
            color: Color(0xFFE1E2ED),
          ),
        ),
      ],
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
            label: 'Floor',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_rounded),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_rounded),
            label: 'Checks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: 'Settings',
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
                      const Text(
                        'Lead Server',
                        style: TextStyle(
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

class _MetadataRow extends StatelessWidget {
  const _MetadataRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Hanken Grotesk',
            fontSize: 16,
            color: Color(0xFFC3C6D7),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Hanken Grotesk',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: valueColor ?? const Color(0xFFE1E2ED),
          ),
        ),
      ],
    );
  }
}
