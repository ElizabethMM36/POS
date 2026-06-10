import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:my_pos_app/models/pos_models.dart';
import 'package:my_pos_app/providers/pos_provider.dart';
import 'package:my_pos_app/theme/app_colors.dart';

// ─── Semantic status colors adapted for optimal contrast ───────────────────
Color _itemStatusColor(BuildContext context, OrderItemStatus s) {
  final isLight = Theme.of(context).brightness == Brightness.light;
  switch (s) {
    case OrderItemStatus.pending:
      return isLight ? const Color(0xFF475569) : const Color(0xFF64748B);
    case OrderItemStatus.fired:
      return const Color(0xFFF97316);
    case OrderItemStatus.preparing:
      return isLight ? const Color(0xFFB45309) : const Color(0xFFEAB308);
    case OrderItemStatus.ready:
      return const Color(0xFF8B5CF6);
    case OrderItemStatus.served:
      return const Color(0xFF22C55E);
  }
}

Color _tableStatusColor(BuildContext context, TableStatus s) {
  switch (s) {
    case TableStatus.available:
      return StatusColors.available;
    case TableStatus.occupied:
      return StatusColors.occupied;
    case TableStatus.readyForBill:
      return const Color(0xFF8B5CF6);
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
  final String _courseFilter = 'All Courses';
  bool _analyticsExpanded = true;

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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _buildAppBar(context, provider.openChecks.length),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Search & Filter Input Bar ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              style: TextStyle(color: theme.colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Search by check ID, table, or server...',
                hintStyle: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: theme.colorScheme.primary,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
            ),
          ),

          // ── 1. Floor monitor strip ──
          _FloorMonitorStrip(
            tables: tables,
            pulseAnim: _pulseAnim,
            selectedTable: _selectedTableNumber,
            onTableSelected: (tableNum) {
              setState(() {
                _selectedTableNumber = _selectedTableNumber == tableNum
                    ? null
                    : tableNum;
              });
            },
          ),

          // ── 2. Analytics panel ──
          _AnalyticsSection(
            stats: stats,
            expanded: _analyticsExpanded,
            onToggle: () =>
                setState(() => _analyticsExpanded = !_analyticsExpanded),
          ),

          // ── 3. Order-tracking pipeline ──
          _OrderPipeline(stats: stats),

          // ── 4. Ticket grid ──
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
                          mainAxisExtent: 500,
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

  PreferredSizeWidget _buildAppBar(BuildContext context, int liveCount) {
    final theme = Theme.of(context);
    return AppBar(
      backgroundColor: theme.colorScheme.surfaceContainer,
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 16,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.layers_outlined,
              color: theme.colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Order Dashboard',
            style: TextStyle(
              fontFamily: 'Hanken Grotesk',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '$liveCount LIVE CHECKS',
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.secondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Floor Monitor Strip — Interactive table selector
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
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surfaceContainer,
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'FLOOR · LIVE',
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 1.4,
                ),
              ),
              if (selectedTable != null) ...[
                const Spacer(),
                Text(
                  'Filtering by Table $selectedTable',
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
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
                final color = _tableStatusColor(context, t.status);
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
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : color.withOpacity(0.4),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'T${t.number}',
                            style: TextStyle(
                              fontFamily: 'JetBrains Mono',
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                          if (t.status != TableStatus.available) ...[
                            const SizedBox(width: 6),
                            Text(
                              '\$${t.billAmount.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontFamily: 'JetBrains Mono',
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.secondary,
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
    final theme = Theme.of(context);
    return Container(
      color: theme.scaffoldBackgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Text(
                    'SHIFT ANALYTICS',
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurfaceVariant,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 14,
                    color: theme.colorScheme.outline,
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _KpiTile(
                      label: 'Live Revenue',
                      value: '\$${stats.liveRevenue.toStringAsFixed(2)}',
                      icon: Icons.monetization_on_outlined,
                      color: StatusColors.available,
                    ),
                    const SizedBox(width: 8),
                    _KpiTile(
                      label: 'Open Checks',
                      value: '${stats.openChecks} Tickets',
                      icon: Icons.receipt_long_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    _KpiTile(
                      label: 'Total Covers',
                      value: '${stats.totalCovers} Guests',
                      icon: Icons.people_alt_outlined,
                      color: const Color(0xFF8B5CF6),
                    ),
                    const SizedBox(width: 8),
                    _CompletionRingTile(stats: stats),
                    const SizedBox(width: 8),
                    _TableOccupancyTile(stats: stats),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 10),
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

  const _KpiTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 110,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
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
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Hanken Grotesk',
              fontSize: 9,
              color: theme.colorScheme.onSurfaceVariant,
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
    final theme = Theme.of(context);
    return Container(
      width: 124,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: StatusColors.available.withOpacity(0.3)),
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
                  backgroundColor: theme.colorScheme.outlineVariant,
                  color: StatusColors.available,
                ),
                Text(
                  '${stats.servedPct}%',
                  style: const TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Served',
                  style: TextStyle(
                    fontFamily: 'Hanken Grotesk',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  '${stats.itemsServed}/${stats.totalItems} Items',
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 9,
                    color: theme.colorScheme.onSurfaceVariant,
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

class _TableOccupancyTile extends StatelessWidget {
  final _ShiftStats stats;
  const _TableOccupancyTile({required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total =
        stats.availableTables + stats.occupiedTables + stats.billReadyTables;
    final occPct = total > 0
        ? ((stats.occupiedTables + stats.billReadyTables) / total * 100).round()
        : 0;

    return Container(
      width: 150,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Occupancy',
                style: TextStyle(
                  fontFamily: 'Hanken Grotesk',
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Text(
                '$occPct%',
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 10,
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: SizedBox(
              height: 4,
              child: Row(
                children: [
                  if (stats.occupiedTables > 0)
                    Expanded(
                      flex: stats.occupiedTables,
                      child: Container(color: StatusColors.occupied),
                    ),
                  if (stats.billReadyTables > 0)
                    Expanded(
                      flex: stats.billReadyTables,
                      child: Container(color: const Color(0xFF8B5CF6)),
                    ),
                  if (stats.availableTables > 0)
                    Expanded(
                      flex: stats.availableTables,
                      child: Container(
                        color: StatusColors.available.withOpacity(0.3),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _dot(StatusColors.available, 'A:${stats.availableTables}', theme),
              _dot(StatusColors.occupied, 'O:${stats.occupiedTables}', theme),
              _dot(
                const Color(0xFF8B5CF6),
                'B:${stats.billReadyTables}',
                theme,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dot(Color c, String label, ThemeData theme) => Row(
    children: [
      Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
      ),
      const SizedBox(width: 3),
      Text(
        label,
        style: TextStyle(
          fontFamily: 'JetBrains Mono',
          fontSize: 8,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Order-Tracking Pipeline — Stage visual progress with live metrics
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
    OrderItemStatus.preparing: 'Prep',
    OrderItemStatus.ready: 'Ready',
    OrderItemStatus.served: 'Served',
  };

  @override
  Widget build(BuildContext context) {
    final total = stats.totalItems;
    final theme = Theme.of(context);

    return Container(
      color: theme.colorScheme.surfaceContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PIPELINE PIPELINE WORKFLOW',
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: OrderItemStatus.values.map((status) {
              final count = stats.statusCounts[status] ?? 0;
              final pct = total > 0 ? (count / total * 100).round() : 0;
              final color = _itemStatusColor(context, status);
              final active = count > 0;

              return Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: active
                          ? color.withOpacity(0.15)
                          : theme.colorScheme.outlineVariant.withOpacity(0.5),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: active
                            ? color
                            : theme.colorScheme.outlineVariant,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        _icons[status],
                        size: 14,
                        color: active ? color : theme.colorScheme.outline,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _labels[status]!,
                    style: TextStyle(
                      fontFamily: 'Hanken Grotesk',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: active
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.outline,
                    ),
                  ),
                  Text(
                    '$count ($pct%)',
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 9,
                      color: active
                          ? color
                          : theme.colorScheme.outline.withOpacity(0.5),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ticket Card Grid
// ─────────────────────────────────────────────────────────────────────────────
class _TicketCard extends StatelessWidget {
  final Check ticket;
  final String courseFilter;

  const _TicketCard({required this.ticket, required this.courseFilter});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = ticket.items.fold(0, (sum, item) => sum + item.quantity);
    final served = ticket.items
        .where((i) => i.status == OrderItemStatus.served)
        .fold(0, (sum, item) => sum + item.quantity);
    final progress = total > 0 ? served / total : 0.0;

    final Map<int, List<OrderItem>> byCourse = {};
    for (final item in ticket.items) {
      byCourse.putIfAbsent(item.courseNumber, () => []).add(item);
    }
    final sortedCourses = byCourse.keys.toList()..sort();

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outlineVariant, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              theme.brightness == Brightness.dark ? 0.25 : 0.05,
            ),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Card Header ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHigh,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(9),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'TABLE ${ticket.tableNumber}',
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ticket.serverName,
                        style: TextStyle(
                          fontFamily: 'Hanken Grotesk',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'ID: ${ticket.id.substring(math.max(0, ticket.id.length - 6))}',
                        style: TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 10,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '\$${ticket.total.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),

          // Progress Tracker Strip
          LinearProgressIndicator(
            value: progress,
            minHeight: 3,
            backgroundColor: theme.colorScheme.outlineVariant.withOpacity(0.3),
            color: StatusColors.available,
          ),

          // ── Course Items List ──
          Expanded(
            child: sortedCourses.isEmpty
                ? Center(
                    child: Text(
                      'No items ordered.',
                      style: TextStyle(
                        color: theme.colorScheme.outline,
                        fontSize: 12,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    itemCount: sortedCourses.length,
                    itemBuilder: (_, ci) {
                      final courseNum = sortedCourses[ci];
                      final items = byCourse[courseNum]!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.restaurant_menu,
                                  size: 12,
                                  color: theme.colorScheme.secondary,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'COURSE $courseNum',
                                  style: TextStyle(
                                    fontFamily: 'JetBrains Mono',
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.secondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...items.map(
                            (item) => _ItemRow(ticket: ticket, item: item),
                          ),
                          const Divider(height: 12),
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
// Individual Item Tracker Row with Context Menu Modifier
// ─────────────────────────────────────────────────────────────────────────────
class _ItemRow extends StatelessWidget {
  final Check ticket;
  final OrderItem item;

  const _ItemRow({required this.ticket, required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _itemStatusColor(context, item.status);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '${item.quantity}x',
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              item.name,
              style: TextStyle(
                fontFamily: 'Hanken Grotesk',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          PopupMenuButton<OrderItemStatus>(
            onSelected: (newStatus) {
              final itemIndex = ticket.items.indexOf(item);
              context.read<POSProvider>().updateItemStatus(
                ticket.id,
                itemIndex,
                newStatus,
              );
            },
            itemBuilder: (context) => OrderItemStatus.values.map((s) {
              return PopupMenuItem(
                value: s,
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _itemStatusColor(context, s),
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
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: color.withOpacity(0.4), width: 1),
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

// ─────────────────────────────────────────────────────────────────────────────
// Empty State Widget
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String query;
  final int? selectedTable;

  const _EmptyState({required this.query, this.selectedTable});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
            size: 44,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 12),
          Text(
            mainMsg,
            style: TextStyle(
              fontFamily: 'Hanken Grotesk',
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          if (subMsg.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subMsg,
              style: TextStyle(
                fontFamily: 'Hanken Grotesk',
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Inside _CheckManagementScreenState
  Widget _buildCoursePerformance(List<OrderItem> items) {
    // Example: Find the earliest order time vs latest serve time for a course
    final orderedTimes = items.map((i) => i.orderedAt).whereType<DateTime>();
    final servedTimes = items.map((i) => i.servedAt).whereType<DateTime>();

    if (orderedTimes.isEmpty || servedTimes.isEmpty)
      return const SizedBox.shrink();

    final start = orderedTimes.reduce((a, b) => a.isBefore(b) ? a : b);
    final end = servedTimes.reduce((a, b) => a.isAfter(b) ? a : b);

    final duration = end.difference(start);

    return Text("Course prep time: ${duration.inMinutes} mins");
  }
}
