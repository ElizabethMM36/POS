import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_pos_app/models/pos_models.dart';
import 'package:my_pos_app/providers/pos_provider.dart';
import 'package:my_pos_app/screens/order_screen.dart';
import 'package:my_pos_app/screens/order_summary_screen.dart';
import 'package:my_pos_app/theme/app_colors.dart';

// ─── Design System Notes ─────────────────────────────────────────────────────
//
// LIGHT MODE — Dynamic Warm Orange Mesh + Glassmorphism
//   Background: off-white warm cream #FDFDFD base
//   Top-right bloom : soft brand orange at 10-12% opacity radial fade
//   Bottom-left bloom: warm amber at 18-22% opacity radial fade
//   Cards: white at 45-55% opacity, 1.5px white border at 65% opacity
//   Shadow: ambient 24px blur, 3-5% opacity black/orange blend
//
// DARK MODE — unchanged from previous deep-navy mesh
//
// ─────────────────────────────────────────────────────────────────────────────

// ── Orange palette constants (used directly in the painter & glass helpers) ──
const Color _orangePrimary = Color(0xFFFF6D00); // brand orange
const Color _amberAccent = Color(0xFFFFB300); // sunlit amber bloom
const Color _warmCream = Color(0xFFFDFBF8); // off-white warm cream base

// ─── Mesh Gradient Painter ───────────────────────────────────────────────────

class _MeshGradientPainter extends CustomPainter {
  final bool isDark;
  const _MeshGradientPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    // ── Base fill ──────────────────────────────────────────────────────────
    final basePaint = Paint()
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
                _warmCream, // off-white warm cream
                const Color(0xFFFFF9F5), // warm pearl
                const Color(0xFFFFFAF6), // barely-there peach white
              ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), basePaint);

    if (isDark) {
      // ── Dark blobs (unchanged deep-navy mesh) ───────────────────────────
      _drawBlob(
        canvas,
        center: Offset(size.width * 0.15, size.height * 0.18),
        radius: size.width * 0.55,
        innerColor: const Color(0xFF1E3A5F).withOpacity(0.55),
      );
      _drawBlob(
        canvas,
        center: Offset(size.width * 0.82, size.height * 0.42),
        radius: size.width * 0.50,
        innerColor: const Color(0xFF162840).withOpacity(0.60),
      );
      _drawBlob(
        canvas,
        center: Offset(size.width * 0.30, size.height * 0.80),
        radius: size.width * 0.45,
        innerColor: const Color(0xFF0E2233).withOpacity(0.50),
      );
    } else {
      // ── Light orange blooms ─────────────────────────────────────────────
      //
      // Top-right: brand orange at 11% — airy, not muddy
      _drawBlob(
        canvas,
        center: Offset(size.width * 0.88, size.height * 0.08),
        radius: size.width * 0.65,
        innerColor: _orangePrimary.withOpacity(0.11),
      );

      // Bottom-left: warm amber at 20% — creates organic depth
      _drawBlob(
        canvas,
        center: Offset(size.width * 0.08, size.height * 0.90),
        radius: size.width * 0.70,
        innerColor: _amberAccent.withOpacity(0.20),
      );

      // Centre: ultra-soft peach whisper for mid-screen warmth
      _drawBlob(
        canvas,
        center: Offset(size.width * 0.50, size.height * 0.50),
        radius: size.width * 0.55,
        innerColor: _orangePrimary.withOpacity(0.04),
      );
    }
  }

  void _drawBlob(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required Color innerColor,
  }) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [innerColor, Colors.transparent],
        radius: 0.7,
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_MeshGradientPainter old) => old.isDark != isDark;
}

// ── Glassmorphic card decoration ─────────────────────────────────────────────
//  Light: white 50% fill · 1.5px white border at 65% · 24px ambient shadow
//  Dark:  white 5% fill  · 1px  white border at 10% · 15px shadow
BoxDecoration _glassDecoration({
  required bool isDark,
  double borderRadius = 16,
}) {
  return BoxDecoration(
    color: isDark
        ? Colors.white.withOpacity(0.05)
        : Colors.white.withOpacity(0.50), // 45-55% frosted fill
    borderRadius: BorderRadius.circular(borderRadius),
    border: Border.all(
      color: isDark
          ? Colors.white.withOpacity(0.10)
          : Colors.white.withOpacity(0.65), // crisp 65% white glass edge
      width: isDark ? 1.0 : 1.5,
    ),
    boxShadow: isDark
        ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.22),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ]
        : [
            // Ambient weightless shadow: black 3% + orange 2% blend
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 24,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: _orangePrimary.withOpacity(0.02),
              blurRadius: 24,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
          ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────

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

  // ── Bottom sheet ────────────────────────────────────────────────────────────
  void _showTableSheet(BuildContext context, RestaurantTable table) {
    final provider = context.read<POSProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      showDragHandle: false,
      builder: (sheetContext) {
        final sheetTheme = Theme.of(sheetContext);
        final sc = sheetTheme.colorScheme;
        return Container(
          decoration: BoxDecoration(
            // Light: warm cream with high opacity — frosted panel rising from bloom
            color: isDark
                ? const Color(0xFF141C26).withOpacity(0.96)
                : Colors.white.withOpacity(0.88),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.10)
                  : Colors.white.withOpacity(0.65),
              width: isDark ? 1.0 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.40)
                    : _orangePrimary.withOpacity(0.06),
                blurRadius: 32,
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
                      color: sc.outlineVariant.withOpacity(0.5),
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
                        color: sc.onSurface,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor(table.status).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(9999),
                        border: Border.all(color: _statusColor(table.status)),
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
                    valueColor: sc.primary,
                  ),
                ],
                const SizedBox(height: 12),
                Divider(
                  color: isDark
                      ? sc.outlineVariant
                      : Colors.white.withOpacity(0.30),
                ),
                const SizedBox(height: 12),
                Text(
                  table.orders.isEmpty
                      ? 'No current items'
                      : 'Current ticket items:',
                  style: TextStyle(
                    fontFamily: 'Hanken Grotesk',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: sc.onSurfaceVariant,
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
                                : Colors.white.withOpacity(0.60),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withOpacity(0.09)
                                  : Colors.white.withOpacity(0.65),
                              width: isDark ? 1.0 : 1.5,
                            ),
                            boxShadow: isDark
                                ? []
                                : [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.03),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
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
                                      color: sc.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Course ${item.courseNumber}',
                                    style: TextStyle(
                                      fontFamily: 'JetBrains Mono',
                                      fontSize: 12,
                                      color: sc.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                'Qty ×${item.quantity}',
                                style: TextStyle(
                                  fontFamily: 'JetBrains Mono',
                                  fontWeight: FontWeight.bold,
                                  color: sc.primary,
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
                // Primary action — solid orange (light) / primaryContainer (dark)
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
                      color: Colors.white,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    backgroundColor: isDark
                        ? sc.primaryContainer
                        : _orangePrimary, // solid radiant orange
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: isDark ? 0 : 2,
                    shadowColor: isDark
                        ? Colors.transparent
                        : _orangePrimary.withOpacity(0.30),
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
                        borderRadius: BorderRadius.circular(14),
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
                          backgroundColor: sc.surfaceContainerHigh,
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      side: BorderSide(color: sc.error),
                      foregroundColor: sc.error,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Reset table status',
                      style: TextStyle(fontFamily: 'Hanken Grotesk'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // ── New-table dialog ─────────────────────────────────────────────────────────
  void _showNewTableCheckDialog(BuildContext context) {
    final provider = context.read<POSProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sc = theme.colorScheme;
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
          backgroundColor: isDark
              ? sc.surfaceContainer
              : Colors.white.withOpacity(0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isDark
                  ? Colors.white.withOpacity(0.10)
                  : Colors.white.withOpacity(0.65),
              width: 1.5,
            ),
          ),
          title: Text(
            'New Table Order',
            style: TextStyle(
              fontFamily: 'Hanken Grotesk',
              fontWeight: FontWeight.bold,
              color: sc.onSurface,
            ),
          ),
          content: DropdownButtonFormField<int>(
            dropdownColor: isDark
                ? sc.surfaceContainerHigh
                : const Color(0xFFFFF8F2),
            decoration: InputDecoration(
              labelText: 'Select Table Number',
              labelStyle: TextStyle(color: sc.onSurfaceVariant),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: sc.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: isDark ? sc.primary : _orangePrimary,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: isDark ? sc.surfaceContainerLowest : Colors.white,
            ),
            items: availableTables
                .map(
                  (tNum) => DropdownMenuItem<int>(
                    value: tNum,
                    child: Text(
                      'Table $tNum',
                      style: TextStyle(
                        fontFamily: 'Hanken Grotesk',
                        color: sc.onSurface,
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: (val) => selectedTableNum = val,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontFamily: 'Hanken Grotesk',
                  color: isDark ? sc.primary : _orangePrimary,
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
                backgroundColor: isDark ? sc.primary : _orangePrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Create',
                style: TextStyle(fontFamily: 'Hanken Grotesk'),
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Main build ───────────────────────────────────────────────────────────────
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

    final int availCount = provider.tables
        .where((t) => t.status == TableStatus.available)
        .length;

    final RestaurantTable? activeAlertTable = provider.tables
        .cast<RestaurantTable?>()
        .firstWhere(
          (t) => t?.status == TableStatus.readyForBill,
          orElse: () => provider.tables.cast<RestaurantTable?>().firstWhere(
            (t) => t?.status == TableStatus.occupied,
            orElse: () => null,
          ),
        );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // ── Layer 0: Warm orange mesh gradient ─────────────────────────
          Positioned.fill(
            child: CustomPaint(painter: _MeshGradientPainter(isDark: isDark)),
          ),

          // ── Layer 1: Content ────────────────────────────────────────────
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Section filter bar ──────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.black.withOpacity(0.25)
                      : Colors.white.withOpacity(0.60),
                  border: Border(
                    bottom: BorderSide(
                      color: isDark
                          ? Colors.white.withOpacity(0.07)
                          : Colors.white.withOpacity(0.50),
                    ),
                  ),
                  boxShadow: isDark
                      ? []
                      : [
                          BoxShadow(
                            color: _orangePrimary.withOpacity(0.03),
                            blurRadius: 12,
                            offset: const Offset(0, 2),
                          ),
                        ],
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
                          curve: Curves.easeOut,
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: isSelected
                              ? BoxDecoration(
                                  // Selected: solid orange pill
                                  color: isDark
                                      ? colors.primary
                                      : _orangePrimary,
                                  borderRadius: BorderRadius.circular(9999),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          (isDark
                                                  ? colors.primary
                                                  : _orangePrimary)
                                              .withOpacity(0.30),
                                      blurRadius: 12,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                )
                              : BoxDecoration(
                                  // Unselected: glass pill with warm neutral border
                                  color: isDark
                                      ? Colors.white.withOpacity(0.07)
                                      : Colors.white.withOpacity(0.65),
                                  borderRadius: BorderRadius.circular(9999),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white.withOpacity(0.12)
                                        : Colors.white.withOpacity(0.65),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.03),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
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
                                  ? Colors.white
                                  : colors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // ── Scrollable body ─────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Bento stats row ───────────────────────────────
                      Row(
                        children: [
                          // Available tables count tile
                          Expanded(
                            child: Container(
                              height: 100,
                              decoration: _glassDecoration(isDark: isDark),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'AVAIL',
                                    style: TextStyle(
                                      fontFamily: 'JetBrains Mono',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: StatusColors.available,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    availCount.toString().padLeft(2, '0'),
                                    style: TextStyle(
                                      fontFamily: 'Hanken Grotesk',
                                      fontSize: 32,
                                      fontWeight: FontWeight.w800,
                                      color: colors.onSurface,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Active alert bento tile
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                if (activeAlertTable != null) {
                                  _showTableSheet(context, activeAlertTable);
                                }
                              },
                              child: Container(
                                height: 100,
                                padding: const EdgeInsets.all(10),
                                decoration: _glassDecoration(isDark: isDark),
                                child: Stack(
                                  children: [
                                    // Ghost watermark number
                                    Align(
                                      alignment: Alignment.center,
                                      child: Text(
                                        activeAlertTable != null
                                            ? activeAlertTable.number
                                                  .toString()
                                                  .padLeft(2, '0')
                                            : '--',
                                        style: TextStyle(
                                          fontFamily: 'Hanken Grotesk',
                                          fontSize: 64,
                                          fontWeight: FontWeight.w800,
                                          color: colors.onSurface.withOpacity(
                                            0.05,
                                          ),
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
                                            Text(
                                              activeAlertTable != null
                                                  ? 'T-${activeAlertTable.number.toString().padLeft(2, '0')}'
                                                  : 'T--',
                                              style: TextStyle(
                                                fontFamily: 'JetBrains Mono',
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color:
                                                    activeAlertTable?.status ==
                                                        TableStatus.readyForBill
                                                    ? const Color(0xFF8B5CF6)
                                                    : StatusColors.occupied,
                                              ),
                                            ),
                                            if (activeAlertTable?.status ==
                                                TableStatus.readyForBill)
                                              AnimatedBuilder(
                                                animation: _blinkAnimation,
                                                builder: (context, child) {
                                                  return Opacity(
                                                    opacity:
                                                        _blinkAnimation.value,
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 6,
                                                            vertical: 1.5,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            StatusColors.alert,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              4,
                                                            ),
                                                      ),
                                                      child: const Row(
                                                        children: [
                                                          Icon(
                                                            Icons
                                                                .receipt_rounded,
                                                            size: 10,
                                                            color:
                                                                Color.fromARGB(
                                                                  255,
                                                                  255,
                                                                  255,
                                                                  255,
                                                                ),
                                                          ),
                                                          SizedBox(width: 2),
                                                          Text(
                                                            'BILL',
                                                            style: TextStyle(
                                                              fontFamily:
                                                                  'JetBrains Mono',
                                                              fontSize: 9,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color:
                                                                  Colors.white,
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
                                              activeAlertTable?.duration ??
                                                  '--',
                                              style: TextStyle(
                                                fontFamily: 'JetBrains Mono',
                                                fontSize: 11,
                                                color: colors.onSurfaceVariant,
                                              ),
                                            ),
                                            Text(
                                              '\$${(activeAlertTable?.billAmount ?? 0.00).toStringAsFixed(2)}',
                                              style: TextStyle(
                                                fontFamily: 'JetBrains Mono',
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: isDark
                                                    ? colors.primary
                                                    : _orangePrimary,
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
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ── Table grid ─────────────────────────────────────
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
                          return _buildTableCard(
                            context,
                            filteredTables[index],
                          );
                        },
                      ),
                      const SizedBox(height: 24),

                      // ── Quick status legend ────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: _glassDecoration(isDark: isDark),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'QUICK STATUS GUIDE',
                              style: TextStyle(
                                fontFamily: 'JetBrains Mono',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: colors.onSurfaceVariant,
                                letterSpacing: 0.05,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildLegendItem(
                                  context,
                                  'Available',
                                  StatusColors.available,
                                ),
                                _buildLegendItem(
                                  context,
                                  'Occupied',
                                  StatusColors.occupied,
                                ),
                                _buildLegendItem(
                                  context,
                                  'Ready for Bill',
                                  const Color(0xFF8B5CF6),
                                ),
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
        ],
      ),
      floatingActionButton: FloatingActionButton(
        // Orange FAB in light mode, theme primary in dark
        backgroundColor: isDark ? colors.primary : _orangePrimary,
        foregroundColor: Colors.white,
        onPressed: () => _showNewTableCheckDialog(context),
        elevation: isDark ? 4 : 6,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  // ── Table card ────────────────────────────────────────────────────────────
  Widget _buildTableCard(BuildContext context, RestaurantTable table) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colors = theme.colorScheme;
    final statusColor = _statusColor(table.status);
    final isAvailable = table.status == TableStatus.available;
    final shouldShowPrice = !isAvailable;

    return InkWell(
      onTap: () => _showTableSheet(context, table),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          // Glass fill: lighter for available, warmer for busy
          color: isDark
              ? Colors.white.withOpacity(isAvailable ? 0.04 : 0.07)
              : Colors.white.withOpacity(isAvailable ? 0.50 : 0.62),
          borderRadius: BorderRadius.circular(16),
          // Glass edge: status-tinted for busy tables, white edge for available
          border: Border.all(
            color: isAvailable
                ? (isDark
                      ? Colors.white.withOpacity(0.10)
                      : Colors.white.withOpacity(0.65))
                : statusColor.withOpacity(isDark ? 0.55 : 0.45),
            width: isAvailable ? 1.5 : 1.5,
          ),
          // Ambient floating shadow
          boxShadow: isAvailable
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.18 : 0.03),
                    blurRadius: 24,
                    spreadRadius: 0,
                    offset: const Offset(0, 8),
                  ),
                  if (!isDark)
                    BoxShadow(
                      color: _orangePrimary.withOpacity(0.02),
                      blurRadius: 24,
                      offset: const Offset(0, 4),
                    ),
                ]
              : [
                  BoxShadow(
                    color: statusColor.withOpacity(isDark ? 0.15 : 0.08),
                    blurRadius: 20,
                    spreadRadius: 0,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Glowing status dot
            Container(
              width: 7,
              height: 7,
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: statusColor.withOpacity(0.55),
                    blurRadius: 5,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            // Table number
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
            // Covers
            Text(
              table.covers > 0 ? '${table.covers} Pax' : 'Vacant',
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 11,
                color: colors.onSurfaceVariant,
              ),
            ),
            // Duration (occupied/bill tables)
            if (shouldShowPrice && table.duration.isNotEmpty)
              Text(
                table.duration,
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 11,
                  color: colors.onSurfaceVariant,
                ),
              ),
            // Bill amount
            if (shouldShowPrice) ...[
              const SizedBox(height: 6),
              Text(
                '\$${table.billAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? colors.primary : _orangePrimary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Legend dot + label ────────────────────────────────────────────────────
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
                color: color.withOpacity(0.45),
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

// ── Metadata row (bottom sheet) ───────────────────────────────────────────────
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
    final isDark = theme.brightness == Brightness.dark;
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
            color:
                valueColor ??
                (isDark
                    ? theme.colorScheme.onSurface
                    : const Color(0xFF1E2022)),
          ),
        ),
      ],
    );
  }
}
