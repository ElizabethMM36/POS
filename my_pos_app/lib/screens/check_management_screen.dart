import 'dart:math' as math;
import 'dart:ui';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:my_pos_app/models/pos_models.dart';
import 'package:my_pos_app/providers/pos_provider.dart';
import 'package:my_pos_app/screens/analytics_dashboard_screen.dart';
import 'package:my_pos_app/theme/app_colors.dart';
import 'package:my_pos_app/widgets/pos_background.dart';

// ─── Route helper ─────────────────────────────────────────────────────────────
// Was referenced on line 361 but never defined. Defined here as a top-level
// function so both CheckManagementScreen and any future screen can call it.
Route<void> frostedAnalyticsRoute() {
  return PageRouteBuilder<void>(
    pageBuilder: (context, animation, secondaryAnimation) =>
        const AnalyticsDashboardScreen(),
    transitionDuration: const Duration(milliseconds: 380),
    reverseTransitionDuration: const Duration(milliseconds: 280),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
      final slide = Tween<Offset>(
        begin: const Offset(0.0, 0.04),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
      return FadeTransition(
        opacity: fade,
        child: SlideTransition(position: slide, child: child),
      );
    },
  );
}

// ─── Semantic status colors ───────────────────────────────────────────────────
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

// ─── Daily Summary Report builder ────────────────────────────────────────────
// Produces a plain-text daily summary report suitable for printing / exporting.
String _buildDailySummaryReport(POSProvider provider) {
  final now = DateTime.now();
  final dateStr =
      '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  final timeStr =
      '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

  final closed = provider.closedChecks;
  final open = provider.openChecks;
  final allToday = [...closed, ...open];

  double grossSales = 0;
  double totalDiscounts = 0;
  double totalTax = 0;
  double totalTips = 0;
  int totalCovers = 0;
  final Map<String, int> paymentMethodCounts = {};
  final Map<String, double> paymentMethodTotals = {};
  final Map<String, double> serverTotals = {};

  for (final c in allToday) {
    grossSales += c.subtotal;
    totalDiscounts += c.discountCalculated;
    totalTax += c.tax;
    totalTips += c.tip;
    totalCovers += c.covers;

    final pm = c.paymentMethod.isEmpty ? 'Unpaid' : c.paymentMethod;
    paymentMethodCounts[pm] = (paymentMethodCounts[pm] ?? 0) + 1;
    paymentMethodTotals[pm] = (paymentMethodTotals[pm] ?? 0) + c.total;

    serverTotals[c.serverName] = (serverTotals[c.serverName] ?? 0) + c.subtotal;
  }

  final netSales = grossSales - totalDiscounts;
  final avgCheck = allToday.isNotEmpty ? grossSales / allToday.length : 0.0;

  final buf = StringBuffer();

  // Header
  buf.writeln('═' * 48);
  buf.writeln('         DAILY SUMMARY REPORT');
  buf.writeln('═' * 48);
  buf.writeln('  Date     : $dateStr');
  buf.writeln('  Time     : $timeStr');
  buf.writeln('  Outlet   : ${provider.selectedOutlet?.name ?? "—"}');
  buf.writeln('─' * 48);

  // Sales summary
  buf.writeln('  SALES SUMMARY');
  buf.writeln('─' * 48);
  buf.writeln('  Gross Sales        : \$${grossSales.toStringAsFixed(2)}');
  buf.writeln('  Total Discounts    : -\$${totalDiscounts.toStringAsFixed(2)}');
  buf.writeln('  Net Sales          : \$${netSales.toStringAsFixed(2)}');
  buf.writeln('  Tax Collected      : \$${totalTax.toStringAsFixed(2)}');
  buf.writeln('  Tips               : \$${totalTips.toStringAsFixed(2)}');
  buf.writeln('─' * 48);

  // Covers & checks
  buf.writeln('  COVERS & CHECKS');
  buf.writeln('─' * 48);
  buf.writeln('  Total Checks       : ${allToday.length}');
  buf.writeln('  Open Checks        : ${open.length}');
  buf.writeln('  Closed Checks      : ${closed.length}');
  buf.writeln('  Total Covers       : $totalCovers');
  buf.writeln('  Avg Check Value    : \$${avgCheck.toStringAsFixed(2)}');
  buf.writeln('─' * 48);

  // Tender breakdown
  buf.writeln('  TENDER BREAKDOWN');
  buf.writeln('─' * 48);
  for (final entry in paymentMethodTotals.entries) {
    final count = paymentMethodCounts[entry.key] ?? 0;
    buf.writeln(
      '  ${entry.key.padRight(18)} : \$${entry.value.toStringAsFixed(2)} ($count txns)',
    );
  }
  buf.writeln('─' * 48);

  // Staff performance
  buf.writeln('  STAFF PERFORMANCE');
  buf.writeln('─' * 48);
  final sortedServers = serverTotals.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  for (final e in sortedServers) {
    buf.writeln('  ${e.key.padRight(20)} : \$${e.value.toStringAsFixed(2)}');
  }
  buf.writeln('─' * 48);

  // Open checks detail
  if (open.isNotEmpty) {
    buf.writeln('  OPEN CHECKS (Live)');
    buf.writeln('─' * 48);
    for (final c in open) {
      buf.writeln(
        '  T${c.tableNumber} | ${c.serverName} | \$${c.total.toStringAsFixed(2)} | ${c.covers} pax',
      );
    }
    buf.writeln('─' * 48);
  }

  buf.writeln('═' * 48);
  buf.writeln('  END OF REPORT');
  buf.writeln('═' * 48);

  return buf.toString();
}

void _showExportReportSheet(BuildContext context, POSProvider provider) {
  final report = _buildDailySummaryReport(provider); // existing text builder
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return Container(
        height: MediaQuery.of(ctx).size.height * 0.75,
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF141C26).withOpacity(0.97)
              : Colors.white.withOpacity(0.96),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.10)
                : Colors.white.withOpacity(0.65),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
              blurRadius: 32,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Title row
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.summarize_rounded,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Daily Summary Report',
                          style: TextStyle(
                            fontFamily: 'Hanken Grotesk',
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'Generated ${DateTime.now().toString().substring(0, 16)}',
                          style: TextStyle(
                            fontFamily: 'JetBrains Mono',
                            fontSize: 11,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Copy plain-text to clipboard
                  IconButton(
                    icon: Icon(
                      Icons.copy_rounded,
                      color: theme.colorScheme.primary,
                    ),
                    tooltip: 'Copy to clipboard',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: report));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                            'Report copied to clipboard',
                            style: TextStyle(fontFamily: 'Hanken Grotesk'),
                          ),
                          backgroundColor: StatusColors.available,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            Divider(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.black.withOpacity(0.06),
              height: 1,
            ),
            // Report preview
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.black.withOpacity(0.25)
                        : const Color(0xFFFFF8F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.06)
                          : Colors.orange.withOpacity(0.15),
                    ),
                  ),
                  child: SelectableText(
                    report,
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 12,
                      height: 1.6,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),
            // Export button
            Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                8,
                20,
                MediaQuery.of(ctx).padding.bottom + 16,
              ),
              child: FilledButton.icon(
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  await _exportToTxt(context, report);
                },
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text(
                  'Export Report (.txt)',
                  style: TextStyle(
                    fontFamily: 'Hanken Grotesk',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

// -- Core export logic -------------------------------------------------------

/// Writes [report] to a .txt file on the Windows Desktop.
/// Shows a SnackBar with the saved filename on success, or an error message.
Future<void> _exportToTxt(BuildContext context, String report) async {
  try {
    final file = await _saveTxtToDesktop(report);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Saved to Desktop: ${file.path.split(Platform.pathSeparator).last}',
            style: const TextStyle(fontFamily: 'Hanken Grotesk'),
          ),
          backgroundColor: StatusColors.available,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Export failed: $e',
            style: const TextStyle(fontFamily: 'Hanken Grotesk'),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }
}

/// Resolves the Windows Desktop path, creates a timestamped .txt file,
/// writes [report] into it, and returns the [File].
Future<File> _saveTxtToDesktop(String report) async {
  final now = DateTime.now();
  final dateStr =
      '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  final timeStr =
      '${now.hour.toString().padLeft(2, '0')}-${now.minute.toString().padLeft(2, '0')}';
  final fileName = 'DailySummary_${dateStr}_$timeStr.txt';

  final saveDir = await _resolveWritableDir();
  final filePath = '${saveDir.path}${Platform.pathSeparator}$fileName';
  final file = File(filePath)..writeAsStringSync(report);
  return file;
}

Future<Directory> _resolveWritableDir() async {
  // Android emulator — use Downloads folder via external storage
  if (Platform.isAndroid) {
    // /storage/emulated/0/Download is always writable on Android emulator
    final downloadsDir = Directory('/storage/emulated/0/Download');
    if (downloadsDir.existsSync()) {
      try {
        final probe = File('${downloadsDir.path}/._poswrite_probe');
        probe.writeAsStringSync('');
        probe.deleteSync();
        return downloadsDir;
      } catch (_) {}
    }
    // Fallback to app documents dir
    return await getApplicationDocumentsDirectory();
  }

  // Windows desktop
  if (Platform.isWindows) {
    final env = Platform.environment;
    final candidates = <String>[
      if (env['USERPROFILE'] != null) '${env['USERPROFILE']}\\Desktop',
      if (env['HOMEDRIVE'] != null && env['HOMEPATH'] != null)
        '${env['HOMEDRIVE']}${env['HOMEPATH']}\\Desktop',
      if (env['USERPROFILE'] != null) env['USERPROFILE']!,
    ];
    for (final path in candidates) {
      if (path.isEmpty) continue;
      final dir = Directory(path);
      if (!dir.existsSync()) continue;
      try {
        final probe = File('$path\\._poswrite_probe');
        probe.writeAsStringSync('');
        probe.deleteSync();
        return dir;
      } catch (_) {
        continue;
      }
    }
  }

  // macOS / Linux
  if (Platform.isMacOS || Platform.isLinux) {
    final home = Platform.environment['HOME'];
    if (home != null) {
      final desktop = Directory('$home/Desktop');
      if (desktop.existsSync()) return desktop;
      return Directory(home);
    }
  }

  return await getApplicationDocumentsDirectory();
}

// ─── Derived analytics ────────────────────────────────────────────────────────
class _ShiftStats {
  final int openChecks;
  final int totalCovers;
  final double liveRevenue;
  final double avgCheckValue;
  final int itemsInKitchen;
  final int itemsReady;
  final int itemsServed;
  final int totalItems;
  final Map<OrderItemStatus, int> statusCounts;
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
  bool _analyticsExpanded = false;
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
    final isDark = theme.brightness == Brightness.dark;

    return POSBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: _buildAppBar(context, provider),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Glass search bar ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.white.withOpacity(0.45),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontFamily: 'Hanken Grotesk',
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search by check ID, table, or server...',
                    hintStyle: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(
                        0.6,
                      ),
                      fontFamily: 'Hanken Grotesk',
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              size: 18,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),

            // ── Floor monitor strip ───────────────────────────────────────
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

            // ── Analytics panel (collapsible) ─────────────────────────────
            _AnalyticsSection(
              stats: stats,
              expanded: _analyticsExpanded,
              onToggle: () =>
                  setState(() => _analyticsExpanded = !_analyticsExpanded),
            ),

            // ── Order pipeline ────────────────────────────────────────────

            // ── Ticket grid ───────────────────────────────────────────────
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
                            mainAxisExtent: 400,
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
      ),
    );
  }

  // ── AppBar — now receives provider for report export button ──────────────
  PreferredSizeWidget _buildAppBar(BuildContext context, POSProvider provider) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppBar(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 16,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark
                  ? theme.colorScheme.primary.withOpacity(0.15)
                  : theme.colorScheme.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.layers_rounded,
              color: theme.colorScheme.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Order Dashboard',
            style: TextStyle(
              fontFamily: 'Hanken Grotesk',
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
      actions: [
        // ── Export daily summary report ────────────────────────────────
        IconButton(
          icon: Icon(Icons.summarize_rounded, color: theme.colorScheme.primary),
          tooltip: 'Export Daily Summary Report',
          onPressed: () => _showExportReportSheet(context, provider),
        ),
        // ── Analytics dashboard ────────────────────────────────────────
        IconButton(
          icon: Icon(Icons.insights_rounded, color: theme.colorScheme.primary),
          tooltip: 'Shift Analytics',
          // Uses the now-defined frostedAnalyticsRoute() top-level function
          onPressed: () => Navigator.of(context).push(frostedAnalyticsRoute()),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

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
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
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
          const SizedBox(height: 10),
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
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : (isDark
                                  ? Colors.white.withOpacity(0.05)
                                  : Colors.white.withOpacity(0.50)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'T${t.number}',
                            style: TextStyle(
                              fontFamily: 'JetBrains Mono',
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: isSelected
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                          if (t.status != TableStatus.available) ...[
                            const SizedBox(width: 8),
                            Text(
                              '\$${t.billAmount.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontFamily: 'JetBrains Mono',
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? theme.colorScheme.onPrimary.withOpacity(
                                        0.8,
                                      )
                                    : theme.colorScheme.onSurfaceVariant,
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
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedCrossFade(
            crossFadeState: expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
            firstChild: const SizedBox(height: 0, width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _KpiTile(
                      label: 'Live Revenue',
                      value: '\$${stats.liveRevenue.toStringAsFixed(2)}',
                      icon: Icons.monetization_on_rounded,
                      color: StatusColors.available,
                    ),
                    const SizedBox(width: 10),
                    _KpiTile(
                      label: 'Open Checks',
                      value: '${stats.openChecks} Tickets',
                      icon: Icons.receipt_long_rounded,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    _KpiTile(
                      label: 'Total Covers',
                      value: '${stats.totalCovers} Guests',
                      icon: Icons.people_alt_rounded,
                      color: const Color(0xFF8B5CF6),
                    ),
                    const SizedBox(width: 10),
                    _CompletionRingTile(stats: stats),
                    const SizedBox(width: 10),
                    _TableOccupancyTile(stats: stats),
                  ],
                ),
              ),
            ),
          ),
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
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: 120,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.04)
            : Colors.white.withOpacity(0.45),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Hanken Grotesk',
              fontSize: 10,
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
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
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: 135,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.04)
            : Colors.white.withOpacity(0.45),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: stats.completionPct,
                  strokeWidth: 3.5,
                  backgroundColor: theme.colorScheme.outlineVariant.withOpacity(
                    isDark ? 0.2 : 0.5,
                  ),
                  color: StatusColors.available,
                ),
                Text(
                  '${stats.servedPct}%',
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Served',
                  style: TextStyle(
                    fontFamily: 'Hanken Grotesk',
                    fontSize: 12,
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
    final isDark = theme.brightness == Brightness.dark;
    final total =
        stats.availableTables + stats.occupiedTables + stats.billReadyTables;
    final occPct = total > 0
        ? ((stats.occupiedTables + stats.billReadyTables) / total * 100).round()
        : 0;

    return Container(
      width: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.04)
            : Colors.white.withOpacity(0.45),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Occupancy',
                style: TextStyle(
                  fontFamily: 'Hanken Grotesk',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Text(
                '$occPct%',
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 11,
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 6,
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
          const SizedBox(height: 6),
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
      const SizedBox(width: 4),
      Text(
        label,
        style: TextStyle(
          fontFamily: 'JetBrains Mono',
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────────────────
class _TicketCard extends StatelessWidget {
  final Check ticket;
  final String courseFilter;

  const _TicketCard({required this.ticket, required this.courseFilter});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
        // Glassmorphic — no Border.all, no solid fill
        color: isDark
            ? Colors.white.withOpacity(0.04)
            : Colors.white.withOpacity(0.45),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.08 : 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Card header ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'T${ticket.tableNumber}',
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ticket.serverName,
                        style: TextStyle(
                          fontFamily: 'Hanken Grotesk',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ID: ${ticket.id.substring(math.max(0, ticket.id.length - 6)).toUpperCase()}',
                        style: TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 11,
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
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),

          // Progress bar
          LinearProgressIndicator(
            value: progress,
            minHeight: 2,
            backgroundColor: theme.colorScheme.outlineVariant.withOpacity(
              isDark ? 0.2 : 0.5,
            ),
            color: StatusColors.available,
          ),

          // ── Course items ─────────────────────────────────────────────
          Expanded(
            child: sortedCourses.isEmpty
                ? Center(
                    child: Text(
                      'No items ordered.',
                      style: TextStyle(
                        color: theme.colorScheme.outline,
                        fontSize: 13,
                        fontFamily: 'Hanken Grotesk',
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: sortedCourses.length,
                    itemBuilder: (_, ci) {
                      final courseNum = sortedCourses[ci];
                      final items = byCourse[courseNum]!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 10, bottom: 8),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.restaurant_menu_rounded,
                                  size: 14,
                                  color: theme.colorScheme.secondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'COURSE $courseNum',
                                  style: TextStyle(
                                    fontFamily: 'JetBrains Mono',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: theme.colorScheme.secondary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...items.map(
                            (item) => _ItemRow(ticket: ticket, item: item),
                          ),
                          if (ci != sortedCourses.length - 1)
                            Divider(
                              height: 24,
                              color: theme.colorScheme.outlineVariant
                                  .withOpacity(0.4),
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
class _ItemRow extends StatelessWidget {
  final Check ticket;
  final OrderItem item;

  const _ItemRow({required this.ticket, required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _itemStatusColor(context, item.status);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.black.withOpacity(0.04),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${item.quantity}x',
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                item.name,
                style: TextStyle(
                  fontFamily: 'Hanken Grotesk',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                  height: 1.2,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<OrderItemStatus>(
            onSelected: (newStatus) {
              final itemIndex = ticket.items.indexOf(item);
              context.read<POSProvider>().updateItemStatus(
                ticket.id,
                itemIndex,
                newStatus,
              );
            },
            color: isDark
                ? theme.colorScheme.surfaceContainerHigh
                : theme.colorScheme.surfaceContainerLowest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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
                    const SizedBox(width: 10),
                    Text(
                      s.displayName,
                      style: const TextStyle(
                        fontFamily: 'Hanken Grotesk',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(isDark ? 0.15 : 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.status.displayName,
                    style: TextStyle(
                      fontFamily: 'Hanken Grotesk',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 14,
                    color: color,
                  ),
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
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark
                  ? Colors.white.withOpacity(0.03)
                  : Colors.black.withOpacity(0.03),
              shape: BoxShape.circle,
            ),
            child: Icon(
              (query.isEmpty && selectedTable == null)
                  ? Icons.receipt_long_rounded
                  : Icons.search_off_rounded,
              size: 48,
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            mainMsg,
            style: TextStyle(
              fontFamily: 'Hanken Grotesk',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          if (subMsg.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              subMsg,
              style: TextStyle(
                fontFamily: 'Hanken Grotesk',
                fontSize: 13,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
