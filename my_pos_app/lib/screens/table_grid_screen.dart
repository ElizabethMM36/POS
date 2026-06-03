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
                _MetadataRow(label: 'Duration', value: table.duration),
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
                table.orders.isEmpty
                    ? 'No current items'
                    : 'Current ticket items:',
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
                  style: TextStyle(
                    fontFamily: 'Hanken Grotesk',
                    fontWeight: FontWeight.bold,
                  ),
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
              if (provider.currentUser?.role == UserRole.admin ||
                  table.status != TableStatus.available) ...[
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
            style: TextStyle(
              fontFamily: 'Hanken Grotesk',
              fontWeight: FontWeight.bold,
            ),
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
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xFFC3C6D7)),
              ),
            ),
            FilledButton(
              onPressed: () {
                if (selectedTableNum != null) {
                  Navigator.of(dialogContext).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          OrderScreen(tableNumber: selectedTableNum!),
                    ),
                  );
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
              ),
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
        return table.number <= 8;
      }
      if (_selectedSection == 'Terrace & Rooftop Bar') {
        return (table.number >= 9 && table.number <= 11) || table.number == 13;
      }
      if (_selectedSection == 'Private Dining Room') {
        return table.number == 12 || table.number >= 14;
      }
      return true;
    }).toList();

    final int availCount = provider.tables
        .where((t) => t.status == TableStatus.available)
        .length;
    final int rsvdCount = provider.tables
        .where((t) => t.status == TableStatus.reserved)
        .length;
    final table4 = provider.getTableByNumber(4);

    // FIX: Removed duplicate Scaffold AppBar and Drawer here.
    // Instead, we retain a clean nested Scaffold *without* an appBar, allowing the view to pass its FAB safely up.
    return Scaffold(
      backgroundColor:
          Colors.transparent, // Blends seamlessly into the parent background
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
                  String displayName = section;
                  if (section == 'Main Dining Floor')
                    displayName = 'Main Dining';
                  if (section == 'Terrace & Rooftop Bar')
                    displayName = 'Bar Area';
                  if (section == 'Private Dining Room')
                    displayName = 'Private Room';

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
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
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
                      Expanded(
                        child: Container(
                          height: 100,
                          decoration: BoxDecoration(
                            color: const Color(0xFF191B23),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(
                                0xFF434655,
                              ).withValues(alpha: 0.3),
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
                                color: const Color(
                                  0xFF434655,
                                ).withValues(alpha: 0.6),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                Align(
                                  alignment: Alignment.center,
                                  child: Text(
                                    '04',
                                    style: TextStyle(
                                      fontFamily: 'Hanken Grotesk',
                                      fontSize: 64,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(
                                        0xFFE1E2ED,
                                      ).withValues(alpha: 0.05),
                                      height: 1,
                                    ),
                                  ),
                                ),
                                Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
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
                                                padding:
                                                    const EdgeInsets.symmetric(
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
                                                        fontFamily:
                                                            'JetBrains Mono',
                                                        fontSize: 9,
                                                        fontWeight:
                                                            FontWeight.bold,
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
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
                              color: const Color(
                                0xFF434655,
                              ).withValues(alpha: 0.3),
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
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
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
      // Completing the truncated FloatingActionButton
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        onPressed: () => _showNewTableCheckDialog(context),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  // --- Missing Helper Methods added for cross-file build parity ---

  Widget _buildTableCard(BuildContext context, RestaurantTable table) {
    Color statusColor = _statusColor(table.status);
    return InkWell(
      onTap: () => _showTableSheet(context, table),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1D1F27),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: statusColor, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${table.number}',
              style: const TextStyle(
                fontFamily: 'Hanken Grotesk',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE1E2ED),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              table.covers > 0 ? '${table.covers} Pax' : 'Vacant',
              style: const TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 11,
                color: Color(0xFFC3C6D7),
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
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Hanken Grotesk',
            fontSize: 12,
            color: Color(0xFFC3C6D7),
          ),
        ),
      ],
    );
  }
}

// Metadata row component utilized in sheet
class _MetadataRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _MetadataRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Hanken Grotesk',
            fontSize: 14,
            color: Color(0xFFC3C6D7),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: valueColor ?? const Color(0xFFE1E2ED),
          ),
        ),
      ],
    );
  }
}
