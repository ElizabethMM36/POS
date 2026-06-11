import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_pos_app/models/pos_models.dart';
import 'package:my_pos_app/providers/pos_provider.dart';
import 'package:my_pos_app/screens/order_screen.dart';
import 'package:my_pos_app/screens/order_summary_screen.dart';
import 'package:my_pos_app/theme/app_colors.dart';
import 'package:my_pos_app/widgets/pos_background.dart';

// ─── Glass card decoration ────────────────────────────────────────────────────
// Light: pure white 72% fill · 1px white border 60% · soft 20px ambient shadow
// Dark : white 5% fill        · 1px white border 10% · deeper shadow
// ─────────────────────────────────────────────────────────────────────────────
BoxDecoration _glassDecoration({
  required bool isDark,
  double borderRadius = 16,
}) {
  return BoxDecoration(
    color: isDark
        ? Colors.white.withOpacity(0.05)
        : Colors.white.withOpacity(0.72),
    borderRadius: BorderRadius.circular(borderRadius),
    border: Border.all(
      color: isDark
          ? Colors.white.withOpacity(0.10)
          : Colors.white.withOpacity(0.60),
      width: 1.0,
    ),
    boxShadow: [
      BoxShadow(
        color: isDark
            ? Colors.black.withOpacity(0.22)
            : Colors.black.withOpacity(0.06),
        blurRadius: 20,
        spreadRadius: 0,
        offset: const Offset(0, 4),
      ),
    ],
  );
}

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
        return StatusColors.available;
      case TableStatus.occupied:
        return StatusColors.occupied;
      case TableStatus.readyForBill:
        return const Color(0xFF8B5CF6);
    }
  }

  void _showTableSheet(BuildContext context, RestaurantTable table) {
    final provider = context.read<POSProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      showDragHandle: false,
      builder: (sheetContext) {
        final sheetTheme = Theme.of(sheetContext);
        return Container(
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF141C26).withOpacity(0.96)
                : Colors.white.withOpacity(0.88),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.10)
                  : Colors.white.withOpacity(0.6),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
                blurRadius: 24,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 20,
              bottom: MediaQuery.of(sheetContext).padding.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: sheetTheme.colorScheme.outlineVariant.withOpacity(
                        0.5,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Table ${table.number}',
                      style: TextStyle(
                        fontFamily: 'Hanken Grotesk',
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: sheetTheme.colorScheme.onSurface,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor(
                          table.status,
                        ).withValues(alpha: 0.2),
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
                    valueColor: sheetTheme.colorScheme.primary,
                  ),
                ],
                const SizedBox(height: 12),
                Divider(color: sheetTheme.colorScheme.outlineVariant),
                const SizedBox(height: 12),
                Text(
                  table.orders.isEmpty
                      ? 'No current items'
                      : 'Current ticket items:',
                  style: TextStyle(
                    fontFamily: 'Hanken Grotesk',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: sheetTheme.colorScheme.onSurfaceVariant,
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
                            color: isDark
                                ? Colors.white.withOpacity(0.06)
                                : Colors.white.withOpacity(0.65),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withOpacity(0.09)
                                  : Colors.white.withOpacity(0.5),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: TextStyle(
                                      fontFamily: 'Hanken Grotesk',
                                      fontWeight: FontWeight.w600,
                                      color: sheetTheme.colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Course ${item.courseNumber}',
                                    style: TextStyle(
                                      fontFamily: 'JetBrains Mono',
                                      fontSize: 12,
                                      color: sheetTheme
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                'Qty ×${item.quantity}',
                                style: TextStyle(
                                  fontFamily: 'JetBrains Mono',
                                  fontWeight: FontWeight.bold,
                                  color: sheetTheme.colorScheme.primary,
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
                  icon: Icon(
                    table.status == TableStatus.occupied
                        ? Icons.add_to_photos_rounded
                        : Icons.restaurant_menu_rounded,
                  ),
                  label: Text(
                    table.status == TableStatus.occupied
                        ? 'Add Items to Order'
                        : 'Open Kitchen Order Sheet',
                    style: const TextStyle(
                      fontFamily: 'Hanken Grotesk',
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFFFFF),
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    backgroundColor: sheetTheme.colorScheme.primaryContainer,
                    foregroundColor: sheetTheme.colorScheme.onPrimaryContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                if (table.status == TableStatus.occupied ||
                    table.status == TableStatus.readyForBill) ...[
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => OrderSummaryScreen(
                            checkId: table.activeCheckId ?? '',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.point_of_sale_rounded),
                    label: const Text(
                      'Proceed to Checkout',
                      style: TextStyle(
                        fontFamily: 'Hanken Grotesk',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      backgroundColor: StatusColors.available,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
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
                          backgroundColor:
                              sheetTheme.colorScheme.surfaceContainerHigh,
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      side: BorderSide(color: sheetTheme.colorScheme.error),
                      foregroundColor: sheetTheme.colorScheme.error,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Reset table status'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _showNewTableCheckDialog(BuildContext context) {
    final provider = context.read<POSProvider>();
    final theme = Theme.of(context);
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
          backgroundColor: theme.colorScheme.surfaceContainer,
          title: Text(
            'New Table Order',
            style: TextStyle(
              fontFamily: 'Hanken Grotesk',
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          content: DropdownButtonFormField<int>(
            dropdownColor: theme.colorScheme.surfaceContainerHigh,
            decoration: InputDecoration(
              labelText: 'Select Table Number',
              labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: theme.colorScheme.primary,
                  width: 2,
                ),
              ),
            ),
            items: availableTables
                .map(
                  (tNum) => DropdownMenuItem<int>(
                    value: tNum,
                    child: Text(
                      'Table $tNum',
                      style: TextStyle(color: theme.colorScheme.onSurface),
                    ),
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
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
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
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colors = theme.colorScheme;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Session expired. Please sign in again.')),
      );
    }

    // 1. Filtered Tables Logic
    final filteredTables = provider.tables.where((table) {
      if (_selectedSection == 'All Sections') return true;
      if (_selectedSection == 'Main Dining Floor') return table.number <= 8;
      if (_selectedSection == 'Terrace & Rooftop Bar') {
        return (table.number >= 9 && table.number <= 11) || table.number == 13;
      }
      if (_selectedSection == 'Private Dining Room') {
        return table.number == 12 || table.number >= 14;
      }
      return true;
    }).toList();

    // 2. Count Available
    final int availCount = provider.tables
        .where((t) => t.status == TableStatus.available)
        .length;

    // 3. RECTIFIED: Active Alert Logic
    // We use firstWhereOrNull (from collection package) or a standard try/catch logic.
    // Here is the cleanest way without extra packages:
    RestaurantTable? getActiveTable() {
      try {
        return provider.tables.firstWhere(
          (t) => t.status == TableStatus.readyForBill,
        );
      } catch (_) {
        try {
          return provider.tables.firstWhere(
            (t) => t.status == TableStatus.occupied,
          );
        } catch (_) {
          return null;
        }
      }
    }

    final RestaurantTable? activeAlertTable = getActiveTable();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: POSBackground(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Section filter bar
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withOpacity(0.25)
                    : Colors.white.withOpacity(0.55),
                border: Border(
                  bottom: BorderSide(
                    color: isDark
                        ? Colors.white.withOpacity(0.07)
                        : Colors.white.withOpacity(0.5),
                  ),
                ),
              ),
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
                      onTap: () => setState(() => _selectedSection = section),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colors.primary
                              : (isDark
                                    ? Colors.white.withOpacity(0.07)
                                    : Colors.white.withOpacity(0.65)),
                          borderRadius: BorderRadius.circular(9999),
                          border: isSelected
                              ? null
                              : Border.all(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.12)
                                      : Colors.white.withOpacity(0.55),
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
                                ? colors.onPrimary
                                : colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Avail Box
                        Expanded(
                          child: Container(
                            height: 100,
                            decoration: _glassDecoration(isDark: isDark),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'AVAIL',
                                  style: TextStyle(
                                    fontFamily: 'JetBrains Mono',
                                    fontSize: 12,
                                    color: StatusColors.available,
                                  ),
                                ),
                                Text(
                                  availCount.toString().padLeft(2, '0'),
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Alert Box
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              if (activeAlertTable != null)
                                _showTableSheet(context, activeAlertTable);
                            },
                            child: Container(
                              height: 100,
                              decoration: _glassDecoration(isDark: isDark),
                              child: Stack(
                                children: [
                                  Align(
                                    alignment: Alignment.center,
                                    child: Text(
                                      activeAlertTable?.number
                                              .toString()
                                              .padLeft(2, '0') ??
                                          '--',
                                      style: TextStyle(
                                        fontSize: 64,
                                        fontWeight: FontWeight.w800,
                                        // Fixed withOpacity for newer Flutter
                                        color: colors.onSurface.withOpacity(
                                          0.05,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              activeAlertTable != null
                                                  ? 'T-${activeAlertTable.number}'
                                                  : 'T--',
                                              style: TextStyle(
                                                color:
                                                    activeAlertTable?.status ==
                                                        TableStatus.readyForBill
                                                    ? Colors.deepPurple
                                                    : StatusColors.occupied,
                                              ),
                                            ),
                                            if (activeAlertTable?.status ==
                                                TableStatus.readyForBill)
                                              const Icon(
                                                Icons.receipt_rounded,
                                                size: 16,
                                                color: Colors.orange,
                                              ),
                                          ],
                                        ),
                                        Text(
                                          '\$${(activeAlertTable?.billAmount ?? 0.0).toStringAsFixed(2)}',
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
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
                      itemBuilder: (context, index) =>
                          _buildTableCard(context, filteredTables[index]),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: colors.primary,
        onPressed: () => _showNewTableCheckDialog(context),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildTableCard(BuildContext context, RestaurantTable table) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colors = theme.colorScheme;
    final statusColor = _statusColor(table.status);
    final shouldShowPrice = table.status != TableStatus.available;

    return InkWell(
      onTap: () => _showTableSheet(context, table),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          // Glass fill — lighter opacity for available, slightly more for busy
          color: isDark
              ? Colors.white.withOpacity(
                  table.status == TableStatus.available ? 0.04 : 0.07,
                )
              : Colors.white.withOpacity(
                  table.status == TableStatus.available ? 0.65 : 0.75,
                ),
          borderRadius: BorderRadius.circular(14),
          // Status-tinted border for occupied/bill tables, glass-edge for available
          border: Border.all(
            color: table.status == TableStatus.available
                ? (isDark
                      ? Colors.white.withOpacity(0.10)
                      : Colors.white.withOpacity(0.55))
                : statusColor.withOpacity(isDark ? 0.55 : 0.45),
            width: table.status == TableStatus.available ? 1.0 : 1.5,
          ),
          // Soft floating shadow
          boxShadow: [
            BoxShadow(
              color: table.status == TableStatus.available
                  ? Colors.black.withOpacity(isDark ? 0.18 : 0.04)
                  : statusColor.withOpacity(isDark ? 0.15 : 0.08),
              blurRadius: 15,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Status dot
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: statusColor.withOpacity(0.5),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            Text(
              '${table.number}',
              style: TextStyle(
                fontFamily: 'Hanken Grotesk',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              table.covers > 0 ? '${table.covers} Pax' : 'Vacant',
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 11,
                color: colors.onSurfaceVariant,
              ),
            ),

            // 👈 NEW: Display the live duration under the Covers text
            if (shouldShowPrice && table.duration.isNotEmpty) ...[
              Text(
                table.duration,
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 11,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],

            if (shouldShowPrice) ...[
              const SizedBox(height: 6),
              Text(
                '\$${table.billAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: colors.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(BuildContext context, String label, Color color) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Hanken Grotesk',
            fontSize: 12,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

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
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Hanken Grotesk',
            fontSize: 14,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: valueColor ?? theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildLightGlassCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        // Frosted white fill with high transparency
        color: Colors.white.withOpacity(0.45),
        borderRadius: BorderRadius.circular(16),
        // Sharp, micro-thin bright white border to catch the edge light
        border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
        // Ambient shadow to separate the card from the gradient blooms underneath
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(16), child: child),
    );
  }
}
