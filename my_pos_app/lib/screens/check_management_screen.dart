import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:my_pos_app/models/pos_models.dart';
import 'package:my_pos_app/providers/pos_provider.dart';

// ─── Shared design tokens (matches table_grid_screen.dart) ───────────────────
const _kBg = Color(0xFF11131B);
const _kSurface = Color(0xFF1D1F27);
const _kSurface2 = Color(0xFF282A32);
const _kBorder = Color(0xFF434655);
const _kTextPrimary = Color(0xFFE1E2ED);
const _kTextSub = Color(0xFFC3C6D7);
const _kTextMuted = Color(0xFF6B7280);
const _kBrandGreen = Color(0xFFB2ED62); // Clean hex format applied here
const _kBlueLight = Color(0xFFB4C5FF);
const _kGreen = Color(0xFF22C55E);
const _kRed = Color(0xFFEF4444);
const _kPurple = Color(0xFF8B5CF6);
const _kOrange = Color(0xFFF97316);
const _kAmber = Color(0xFFEAB308);
const _kSlate = Color(0xFF64748B);

// ─── Item-status palette ─────────────────────────────────────────────────────
Color _itemStatusColor(OrderItemStatus s) {
  switch (s) {
    case OrderItemStatus.pending:
      return _kSlate;
    case OrderItemStatus.fired:
      return _kOrange;
    case OrderItemStatus.preparing:
      return _kAmber;
    case OrderItemStatus.ready:
      return _kPurple;
    case OrderItemStatus.served:
      return _kGreen;
  }
}

Color _tableStatusColor(TableStatus s) {
  switch (s) {
    case TableStatus.available:
      return _kGreen;
    case TableStatus.occupied:
      return _kRed;
    case TableStatus.readyForBill:
      return _kPurple;
  }
}

// ─── Derived analytics computed purely from provider state ───────────────────
class _ShiftStats {
  final int openChecks;
  final int totalCovers;
  final double liveRevenue;
  final double avgCheckValue;
  final int itemsInKitchen; // fired + preparing
  final int itemsReady;
  final int itemsServed;
  final int totalItems;
  final Map<OrderItemStatus, int> statusCounts;
  // Table-level
  final int availableTables;
  final int occupiedTables;
  final int billReadyTables;

  const _ShiftStats({
    required this.openChecks,
    required this.totalCovers,
    required this.liveRevenue,
    required this.avgCheckValue,
    required this.itemsInKitchen,
    required this.itemsReady,
    required this.itemsServed,
    required this.totalItems,
    required this.statusCounts,
    required this.availableTables,
    required this.occupiedTables,
    required this.billReadyTables,
  });

  double get kitchenLoadPct => totalItems > 0 ? itemsInKitchen / totalItems : 0;
  double get completionPct => totalItems > 0 ? itemsServed / totalItems : 0;
  int get servedPct =>
      totalItems > 0 ? (itemsServed / totalItems * 100).round() : 0;

  static _ShiftStats from(POSProvider p) {
    final open = p.openChecks;
    int covers = 0;
    double revenue = 0;
    final Map<OrderItemStatus, int> counts = {
      for (var s in OrderItemStatus.values) s: 0,
    };

    for (final c in open) {
      covers += c.covers;
      revenue += c.total;
      for (final item in c.items) {
        counts[item.status] = (counts[item.status] ?? 0) + item.quantity;
      }
    }

    final total = counts.values.fold(0, (a, b) => a + b);
    final served = counts[OrderItemStatus.served] ?? 0;
    final ready = counts[OrderItemStatus.ready] ?? 0;
    final inKit =
        (counts[OrderItemStatus.fired] ?? 0) +
        (counts[OrderItemStatus.preparing] ?? 0);

    final tables = p.tables;
    final avail = tables.where((t) => t.status == TableStatus.available).length;
    final occ = tables.where((t) => t.status == TableStatus.occupied).length;
    final billRdy = tables
        .where((t) => t.status == TableStatus.readyForBill)
        .length;

    return _ShiftStats(
      openChecks: open.length,
      totalCovers: covers,
      liveRevenue: revenue,
      avgCheckValue: open.isEmpty ? 0 : revenue / open.length,
      itemsInKitchen: inKit,
      itemsReady: ready,
      itemsServed: served,
      totalItems: total,
      statusCounts: counts,
      availableTables: avail,
      occupiedTables: occ,
      billReadyTables: billRdy,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class CheckManagementScreen extends StatefulWidget {
  const CheckManagementScreen({super.key});

  @override
  State<CheckManagementScreen> createState() => _CheckManagementScreenState();
}

class _CheckManagementScreenState extends State<CheckManagementScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _courseFilter = 'All Courses';
  bool _analyticsExpanded = true;

  // Track the currently selected table from the floor monitor
  int? _selectedTableNumber;

  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  List<Check> _filter(List<Check> checks) {
    var filtered = checks;

    // Filter by selected table if a server taps a floor node
    if (_selectedTableNumber != null) {
      filtered = filtered
          .where((c) => c.tableNumber == _selectedTableNumber)
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered
          .where(
            (c) =>
                c.id.toLowerCase().contains(q) ||
                c.tableNumber.toString().contains(q) ||
                c.serverName.toLowerCase().contains(q),
          )
          .toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<POSProvider>();
    final stats = _ShiftStats.from(provider);
    final tickets = _filter(provider.openChecks);
    final tables = provider.tables;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: _buildAppBar(provider.openChecks.length),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 1. Floor monitor strip (Interactive) ────────────
          _FloorMonitorStrip(
            tables: tables,
            pulseAnim: _pulseAnim,
            selectedTable: _selectedTableNumber,
            onTableSelected: (tableNum) {
              setState(() {
                // Toggle selection off if tapped again
                _selectedTableNumber = _selectedTableNumber == tableNum
                    ? null
                    : tableNum;
              });
            },
          ),

          // ── 2. Analytics panel ────────────────────────────────────────
          _AnalyticsSection(
            stats: stats,
            expanded: _analyticsExpanded,
            onToggle: () =>
                setState(() => _analyticsExpanded = !_analyticsExpanded),
          ),

          // ── 3. Order-tracking pipeline ────────────────────────────────
          _OrderPipeline(stats: stats),

          // ── 4. Ticket grid ────────────────────────────────────────────
          Expanded(
            child: tickets.isEmpty
                ? _EmptyState(
                    query: _searchQuery,
                    selectedTable: _selectedTableNumber,
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 440,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          mainAxisExtent: 540,
                        ),
                    itemCount: tickets.length,
                    itemBuilder: (_, i) => _TicketCard(
                      ticket: tickets[i],
                      courseFilter: _courseFilter,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(int liveCount) {
    return AppBar(
      backgroundColor: _kSurface,
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 16,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _kBrandGreen.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.layers_outlined,
              color: _kBrandGreen,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'Order Dashboard',
            style: TextStyle(
              fontFamily: 'Hanken Grotesk',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _kTextPrimary,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _kBrandGreen.withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '$liveCount LIVE CHECKS',
              style: const TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: _kBlueLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Floor Monitor Strip  — Interactive table selector
// ─────────────────────────────────────────────────────────────────────────────
class _FloorMonitorStrip extends StatelessWidget {
  final List<RestaurantTable> tables;
  final Animation<double> pulseAnim;
  final int? selectedTable;
  final ValueChanged<int> onTableSelected;

  const _FloorMonitorStrip({
    required this.tables,
    required this.pulseAnim,
    required this.selectedTable,
    required this.onTableSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kSurface,
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'FLOOR · LIVE',
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color.fromARGB(255, 240, 242, 246),
                  letterSpacing: 1.4,
                ),
              ),
              if (selectedTable != null) ...[
                const Spacer(),
                Text(
                  'Filtering by Table $selectedTable',
                  style: const TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _kBlueLight,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 38,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: tables.length,
              itemBuilder: (_, i) {
                final t = tables[i];
                final color = _tableStatusColor(t.status);
                final isBillReady = t.status == TableStatus.readyForBill;
                final isSelected = selectedTable == t.number;

                return GestureDetector(
                  onTap: () => onTableSelected(t.number),
                  child: AnimatedBuilder(
                    animation: pulseAnim,
                    builder: (_, child) => Opacity(
                      opacity: isBillReady ? pulseAnim.value : 1.0,
                      child: child,
                    ),
                    child: Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 0,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withOpacity(0.20)
                            : color.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isSelected ? color : color.withOpacity(0.45),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'T${t.number}',
                            style: TextStyle(
                              fontFamily: 'JetBrains Mono',
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.w900
                                  : FontWeight.w700,
                              color: isSelected ? Colors.white : color,
                            ),
                          ),
                          if (t.status != TableStatus.available) ...[
                            const SizedBox(width: 4),
                            Text(
                              '\$${t.billAmount.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontFamily: 'JetBrains Mono',
                                fontSize: 10,
                                color: _kBlueLight,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Analytics Section — KPI horizontal strip + table occupancy bar
// ─────────────────────────────────────────────────────────────────────────────
class _AnalyticsSection extends StatelessWidget {
  final _ShiftStats stats;
  final bool expanded;
  final VoidCallback onToggle;

  const _AnalyticsSection({
    required this.stats,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with toggle
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  const Text(
                    'SHIFT ANALYTICS',
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color.fromARGB(255, 231, 233, 236),
                      letterSpacing: 1.4,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    size: 16,
                    color: const Color.fromARGB(255, 230, 231, 235),
                  ),
                ],
              ),
            ),
          ),

          if (expanded) ...[
            const SizedBox(height: 10),
            // 🔥 FIX: Height bumped from 62 to 76 to eliminate the 9px vertical overflow
            SizedBox(
              height: 76,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _KpiTile(
                    label: 'Checks',
                    value: '${stats.openChecks}',
                    icon: Icons.receipt_long_outlined,
                    color: _kBrandGreen,
                  ),
                  const SizedBox(width: 8),
                  _KpiTile(
                    label: 'Covers',
                    value: '${stats.totalCovers}',
                    icon: Icons.people_outline,
                    color: const Color(0xFF06B6D4),
                  ),
                  const SizedBox(width: 8),
                  _KpiTile(
                    label: 'Revenue',
                    value: '\$${stats.liveRevenue.toStringAsFixed(0)}',
                    icon: Icons.attach_money_rounded,
                    color: const Color(0xFF10B981),
                    valueSmall: true,
                  ),
                  const SizedBox(width: 8),
                  _KpiTile(
                    label: 'Avg/Check',
                    value: '\$${stats.avgCheckValue.toStringAsFixed(0)}',
                    icon: Icons.bar_chart_rounded,
                    color: _kAmber,
                    valueSmall: true,
                  ),
                  const SizedBox(width: 8),
                  _KpiTile(
                    label: 'In Kitchen',
                    value: '${stats.itemsInKitchen}',
                    icon: Icons.soup_kitchen_outlined,
                    color: _kOrange,
                  ),
                  const SizedBox(width: 8),
                  _CompletionRingTile(stats: stats),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Table occupancy summary bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: _TableOccupancyBar(stats: stats),
            ),
          ],
        ],
      ),
    );
  }
}

class _KpiTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool valueSmall;

  const _KpiTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.valueSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96, // Controlled uniform layout boundary
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: valueSmall ? 13 : 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Hanken Grotesk',
              fontSize: 9,
              color: Color.fromARGB(255, 239, 241, 244),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletionRingTile extends StatelessWidget {
  final _ShiftStats stats;
  const _CompletionRingTile({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 124, // Prevents horizontal clipping of text/gauge elements
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kGreen.withOpacity(0.22)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: stats.completionPct,
                  strokeWidth: 3,
                  backgroundColor: _kBorder,
                  valueColor: const AlwaysStoppedAnimation<Color>(_kGreen),
                ),
                Text(
                  '${stats.servedPct}',
                  style: const TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 7,
                    fontWeight: FontWeight.bold,
                    color: _kGreen,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${stats.servedPct}%',
                style: const TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _kGreen,
                ),
              ),
              const Text(
                'Served',
                style: TextStyle(
                  fontFamily: 'Hanken Grotesk',
                  fontSize: 9,
                  color: Color.fromARGB(255, 246, 247, 251),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TableOccupancyBar extends StatelessWidget {
  final _ShiftStats stats;
  const _TableOccupancyBar({required this.stats});

  @override
  Widget build(BuildContext context) {
    final total =
        stats.availableTables + stats.occupiedTables + stats.billReadyTables;
    if (total == 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'TABLE OCCUPANCY',
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 10,
                color: Color.fromARGB(255, 245, 245, 245),
                letterSpacing: 0.8,
              ),
            ),
            Text(
              '${stats.occupiedTables + stats.billReadyTables}/$total occupied',
              style: const TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 9,
                color: Color.fromARGB(255, 234, 235, 240),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: SizedBox(
            height: 6,
            child: Row(
              children: [
                if (stats.occupiedTables > 0)
                  Flexible(
                    flex: stats.occupiedTables,
                    child: Container(color: _kRed),
                  ),
                if (stats.billReadyTables > 0)
                  Flexible(
                    flex: stats.billReadyTables,
                    child: Container(color: _kPurple),
                  ),
                if (stats.availableTables > 0)
                  Flexible(
                    flex: stats.availableTables,
                    child: Container(color: _kBorder),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            _dot(_kRed, '${stats.occupiedTables} Occupied'),
            const SizedBox(width: 12),
            _dot(_kPurple, '${stats.billReadyTables} Bill Ready'),
            const SizedBox(width: 12),
            _dot(_kBorder, '${stats.availableTables} Available'),
          ],
        ),
      ],
    );
  }

  Widget _dot(Color c, String label) => Row(
    children: [
      Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
      ),
      const SizedBox(width: 4),
      Text(
        label,
        style: const TextStyle(
          fontFamily: 'JetBrains Mono',
          fontSize: 9,
          color: Color.fromARGB(255, 237, 238, 241),
        ),
      ),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Order-Tracking Pipeline  — 5-stage visual with live counts
// ─────────────────────────────────────────────────────────────────────────────
class _OrderPipeline extends StatelessWidget {
  final _ShiftStats stats;
  const _OrderPipeline({required this.stats});

  static const _icons = {
    OrderItemStatus.pending: Icons.hourglass_empty_rounded,
    OrderItemStatus.fired: Icons.local_fire_department_rounded,
    OrderItemStatus.preparing: Icons.soup_kitchen_rounded,
    OrderItemStatus.ready: Icons.done_all_rounded,
    OrderItemStatus.served: Icons.restaurant_rounded,
  };

  static const _labels = {
    OrderItemStatus.pending: 'Pending',
    OrderItemStatus.fired: 'Fired',
    OrderItemStatus.preparing: 'Preparing',
    OrderItemStatus.ready: 'Ready',
    OrderItemStatus.served: 'Served',
  };

  @override
  Widget build(BuildContext context) {
    final total = stats.totalItems;

    return Container(
      color: _kSurface,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ORDER TRACKING PIPELINE',
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color.fromARGB(255, 254, 254, 254),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(OrderItemStatus.values.length * 2 - 1, (i) {
              if (i.isOdd) {
                final leftStatus = OrderItemStatus.values[(i - 1) ~/ 2];
                final rightStatus = OrderItemStatus.values[(i + 1) ~/ 2];
                return Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _itemStatusColor(leftStatus).withOpacity(0.45),
                          _itemStatusColor(rightStatus).withOpacity(0.45),
                        ],
                      ),
                    ),
                  ),
                );
              }
              final status = OrderItemStatus.values[i ~/ 2];
              final count = stats.statusCounts[status] ?? 0;
              final active = count > 0;
              final color = _itemStatusColor(status);
              final pct = total > 0 ? (count / total * 100).round() : 0;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: active ? color.withOpacity(0.14) : _kSurface2,
                          border: Border.all(
                            color: active ? color : _kBorder,
                            width: active ? 2 : 1,
                          ),
                          boxShadow: active
                              ? [
                                  BoxShadow(
                                    color: color.withOpacity(0.22),
                                    blurRadius: 8,
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(
                          _icons[status],
                          size: 16,
                          color: active ? color : _kTextMuted,
                        ),
                      ),
                      if (active && count > 0)
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              count > 99 ? '99+' : '$count',
                              style: const TextStyle(
                                fontFamily: 'JetBrains Mono',
                                fontSize: 7,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _labels[status]!,
                    style: TextStyle(
                      fontFamily: 'Hanken Grotesk',
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: active ? color : _kTextMuted,
                    ),
                  ),
                  Text(
                    '$pct%',
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 9,
                      color: active ? color.withOpacity(0.65) : _kBorder,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty State
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String query;
  final int? selectedTable;
  const _EmptyState({required this.query, this.selectedTable});

  @override
  Widget build(BuildContext context) {
    String mainMsg = 'No active tickets';
    String subMsg = '';

    if (selectedTable != null) {
      mainMsg = 'Table $selectedTable has no active orders';
      subMsg = 'Wait for the server to open a new check.';
    } else if (query.isNotEmpty) {
      mainMsg = 'No results for "$query"';
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            (query.isEmpty && selectedTable == null)
                ? Icons.receipt_long_outlined
                : Icons.search_off_rounded,
            size: 40,
            color: _kTextMuted,
          ),
          const SizedBox(height: 12),
          Text(
            mainMsg,
            style: const TextStyle(
              fontFamily: 'Hanken Grotesk',
              color: _kTextMuted,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          if (subMsg.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              subMsg,
              style: const TextStyle(
                fontFamily: 'Hanken Grotesk',
                color: _kTextMuted,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ticket Card  — per-ticket mini pipeline + item list
// ─────────────────────────────────────────────────────────────────────────────
class _TicketCard extends StatelessWidget {
  final Check ticket;
  final String courseFilter;

  const _TicketCard({required this.ticket, required this.courseFilter});

  // Per-ticket status counts derived from check items
  Map<OrderItemStatus, int> get _counts {
    final m = {for (var s in OrderItemStatus.values) s: 0};
    for (final item in ticket.items) {
      m[item.status] = (m[item.status] ?? 0) + item.quantity;
    }
    return m;
  }

  // Elapsed time display
  String get _elapsed {
    final diff = DateTime.now().difference(ticket.openedAt);
    if (diff.inHours > 0)
      return '${diff.inHours}h ${diff.inMinutes.remainder(60)}m';
    return '${diff.inMinutes}m';
  }

  // Check overall urgency colour based on time and status
  Color get _urgencyColor {
    final mins = DateTime.now().difference(ticket.openedAt).inMinutes;
    final hasBillReady = ticket.items.any(
      (i) => i.status == OrderItemStatus.ready,
    );
    if (hasBillReady) return _kPurple;
    if (mins >= 60) return _kOrange;
    return _kBorder;
  }

  static int _idLen(String v) => math.min(v.length, 8);

  @override
  Widget build(BuildContext context) {
    final counts = _counts;
    final total = counts.values.fold(0, (a, b) => a + b);
    final served = counts[OrderItemStatus.served] ?? 0;
    final ready = counts[OrderItemStatus.ready] ?? 0;
    final progress = total > 0 ? served / total : 0.0;

    // Filter items by course
    final Map<int, List<OrderItem>> byCourse = {};
    for (final item in ticket.items) {
      if (courseFilter != 'All Courses') {
        final target =
            int.tryParse(courseFilter.replaceAll('Course ', '')) ?? 1;
        if (item.courseNumber != target) continue;
      }
      byCourse.putIfAbsent(item.courseNumber, () => []).add(item);
    }
    final sortedCourses = byCourse.keys.toList()..sort();

    return Container(
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _urgencyColor.withOpacity(0.5), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Card header ─────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: const BoxDecoration(
              color: _kSurface2,
              borderRadius: BorderRadius.vertical(top: Radius.circular(9)),
            ),
            child: Row(
              children: [
                // Table badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _kRed,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'T-${ticket.tableNumber}',
                    style: const TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(width: 7),
                // Ticket ID
                Text(
                  ticket.id.substring(0, _idLen(ticket.id)),
                  style: const TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 10,
                    color: Color.fromARGB(255, 249, 250, 251),
                  ),
                ),
                const Spacer(),
                // Elapsed time
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _kBg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.timer_outlined,
                        size: 9,
                        color: Color.fromARGB(255, 230, 232, 234),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        _elapsed,
                        style: const TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 9,
                          color: Color.fromARGB(255, 231, 232, 235),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 7),
                // Server name
                Text(
                  ticket.serverName,
                  style: const TextStyle(
                    fontFamily: 'Hanken Grotesk',
                    fontSize: 11,
                    color: _kTextSub,
                  ),
                ),
              ],
            ),
          ),

          // ── Mini progress bar ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
            child: _TicketProgressRow(
              counts: counts,
              total: total,
              served: served,
              ready: ready,
              progress: progress,
            ),
          ),

          // Divider
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Divider(color: _kBorder, height: 1, thickness: 1),
          ),

          // ── Bill total + covers info ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Icon(
                  Icons.people_outline,
                  size: 11,
                  color: Color.fromARGB(255, 235, 236, 238),
                ),
                const SizedBox(width: 4),
                Text(
                  '${ticket.covers} covers',
                  style: const TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 10,
                    color: _kTextMuted,
                  ),
                ),
                const Spacer(),
                Text(
                  '\$${ticket.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _kBlueLight,
                  ),
                ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Divider(color: _kBorder, height: 1, thickness: 1),
          ),

          // ── Course breakdown + status dropdowns ──────────────────────
          Expanded(
            child: sortedCourses.isEmpty
                ? const Center(
                    child: Text(
                      'No items for this filter',
                      style: TextStyle(color: _kTextMuted, fontSize: 11),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    itemCount: sortedCourses.length,
                    itemBuilder: (_, ci) {
                      final courseNum = sortedCourses[ci];
                      final items = byCourse[courseNum]!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.restaurant_menu,
                                  size: 12,
                                  color: _kBlueLight,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'COURSE $courseNum',
                                  style: const TextStyle(
                                    fontFamily: 'Hanken Grotesk',
                                    fontWeight: FontWeight.w800,
                                    color: _kBlueLight,
                                    fontSize: 10,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                                const Expanded(
                                  child: Divider(
                                    indent: 6,
                                    color: _kBorder,
                                    thickness: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...items.map(
                            (item) => _ItemRow(ticket: ticket, item: item),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Per-ticket mini progress bar
// ─────────────────────────────────────────────────────────────────────────────
class _TicketProgressRow extends StatelessWidget {
  final Map<OrderItemStatus, int> counts;
  final int total;
  final int served;
  final int ready;
  final double progress;

  const _TicketProgressRow({
    required this.counts,
    required this.total,
    required this.served,
    required this.ready,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stacked colour bar
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: SizedBox(
            height: 4,
            child: Row(
              children: OrderItemStatus.values.map((s) {
                final cnt = counts[s] ?? 0;
                return Flexible(
                  flex: total > 0
                      ? (cnt / total * 1000).round().clamp(0, 1000)
                      : 0,
                  child: Container(color: _itemStatusColor(s)),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            Text(
              '$served/$total served',
              style: const TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 9,
                color: _kTextMuted,
              ),
            ),
            const Spacer(),
            if (ready > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: _kPurple.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: _kPurple.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.notifications_active_outlined,
                      size: 9,
                      color: _kPurple,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '$ready READY',
                      style: const TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: _kPurple,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(width: 6),
            Text(
              '${(progress * 100).round()}%',
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 9,
                color: progress >= 1.0 ? _kGreen : _kTextMuted,
                fontWeight: progress >= 1.0
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual item row with status dropdown
// ─────────────────────────────────────────────────────────────────────────────
class _ItemRow extends StatelessWidget {
  final Check ticket;
  final OrderItem item;

  const _ItemRow({required this.ticket, required this.item});

  @override
  Widget build(BuildContext context) {
    final color = _itemStatusColor(item.status);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(
            '${item.quantity}×',
            style: const TextStyle(
              fontFamily: 'JetBrains Mono',
              color: Color.fromARGB(255, 250, 250, 251),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontFamily: 'Hanken Grotesk',
                    color: _kTextPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.tags.isNotEmpty)
                  Text(
                    item.tags.join(' · '),
                    style: const TextStyle(
                      fontFamily: 'Hanken Grotesk',
                      fontSize: 9,
                      color: _kAmber,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          // Status dropdown  — calls provider.updateOrderItemStatus via name+course key
          PopupMenuButton<OrderItemStatus>(
            onSelected: (next) {
              context.read<POSProvider>().updateOrderItemStatus(
                checkId: ticket.id,
                itemName: item.name,
                courseNumber: item.courseNumber,
                newStatus: next,
              );
            },
            itemBuilder: (_) => OrderItemStatus.values.map((s) {
              return PopupMenuItem<OrderItemStatus>(
                value: s,
                child: Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: _itemStatusColor(s),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      s.displayName,
                      style: const TextStyle(
                        fontFamily: 'Hanken Grotesk',
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: color.withOpacity(0.38), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.status.displayName,
                    style: TextStyle(
                      fontFamily: 'Hanken Grotesk',
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Icon(Icons.arrow_drop_down, size: 12, color: color),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
