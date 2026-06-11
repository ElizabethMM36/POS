import 'dart:math' as math;
import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:my_pos_app/models/pos_models.dart';
import 'package:my_pos_app/providers/pos_provider.dart';
import 'package:my_pos_app/theme/app_colors.dart';
import 'package:my_pos_app/widgets/glass_card.dart';
import 'package:my_pos_app/widgets/pos_background.dart';

// ─── Accent palette for data viz ─────────────────────────────────────────────
const _coral = Color(0xFFFF6F43);
const _violet = Color(0xFF8B5CF6);
const _emerald = Color(0xFF22C55E);
const _amber = Color(0xFFF59E0B);
const _red = Color(0xFFEF4444);
const _sky = Color(0xFF0EA5E9);
const _pink = Color(0xFFEC4899);
const _teal = Color(0xFF14B8A6);

const _chartColors = [
  _coral,
  _violet,
  _emerald,
  _amber,
  _sky,
  _pink,
  _teal,
  _red,
];

/// Defines the active view within the dashboard
enum ReportViewCategory {
  insights,
  salesSummary,
  foodAndBeverage,
  employeePerformance,
  tenderBreakdown,
  exceptions,
}

extension ReportViewCategoryExt on ReportViewCategory {
  String get displayName {
    switch (this) {
      case ReportViewCategory.insights:
        return 'Live Insights';
      case ReportViewCategory.salesSummary:
        return 'Sales Summary';
      case ReportViewCategory.foodAndBeverage:
        return 'F&B Mix';
      case ReportViewCategory.employeePerformance:
        return 'Staff Performance';
      case ReportViewCategory.tenderBreakdown:
        return 'Tender & Z-Report';
      case ReportViewCategory.exceptions:
        return 'Voids & Discounts';
    }
  }

  IconData get icon {
    switch (this) {
      case ReportViewCategory.insights:
        return Icons.auto_graph_rounded;
      case ReportViewCategory.salesSummary:
        return Icons.request_quote_outlined;
      case ReportViewCategory.foodAndBeverage:
        return Icons.restaurant_menu_rounded;
      case ReportViewCategory.employeePerformance:
        return Icons.badge_outlined;
      case ReportViewCategory.tenderBreakdown:
        return Icons.account_balance_wallet_outlined;
      case ReportViewCategory.exceptions:
        return Icons.assignment_late_outlined;
    }
  }
}

// ─── Metrics derived from live provider state ────────────────────────────────
class _DashboardMetrics {
  final double grossSales;
  final double netSales;
  final double totalDiscounts;
  final double taxesCollected;
  final int receiptsGenerated;
  final double averageOrderValue;
  final int totalCovers;
  final int voidCheckCount;
  final double totalTips;
  final double totalVoidAmt; // NEW
  final double totalRevenue;

  final Duration avgCheckTime;
  final Duration avgTableOccupancy;
  final List<_HourBucket> peakHours;
  final Map<String, double> categoryMix;
  final List<_StationMetric> stationMetrics;

  final int openCheckCount;
  final int savedCheckCount;
  final List<_TableActivity> liveTableActivity;

  final List<_EmployeeMetric> employeeMix;
  final List<_TenderMetric> tenderMix;
  final List<_ExceptionLog> exceptionLogs;
  final List<_FbCategoryItem> fbItems;
  final Map<String, int> fbUnitsByCategory;

  const _DashboardMetrics({
    required this.grossSales,
    required this.netSales,
    required this.totalDiscounts,
    required this.taxesCollected,
    required this.receiptsGenerated,
    required this.averageOrderValue,
    required this.totalCovers,
    required this.voidCheckCount,
    required this.totalTips,
    required this.avgCheckTime,
    required this.avgTableOccupancy,
    required this.peakHours,
    required this.categoryMix,
    required this.stationMetrics,
    required this.openCheckCount,
    required this.savedCheckCount,
    required this.liveTableActivity,
    required this.employeeMix,
    required this.tenderMix,
    required this.exceptionLogs,
    required this.fbItems,
    required this.fbUnitsByCategory,
    required this.totalVoidAmt, // Add to constructor
    required this.totalRevenue,
  });

  static _DashboardMetrics from(POSProvider p, DateTime date) {
    final checks = p.checks.where((c) {
      return c.openedAt.year == date.year &&
          c.openedAt.month == date.month &&
          c.openedAt.day == date.day;
    }).toList();

    double grossSales = 0;
    double totalDiscounts = 0;
    double taxesCollected = 0;
    double totalTips = 0;
    double totalVoidAmt = 0;

    final checkDurations = <Duration>[];
    final empMap = <String, _EmployeeTemp>{};
    final tenderMap = <String, _TenderTemp>{};
    final exceptions = <_ExceptionLog>[];
    final fbMap = <String, _FbCategoryItemTemp>{};
    final fbUnitCats = <String, int>{};

    int openCount = 0;
    int savedCount = 0;
    final liveActivity = <_TableActivity>[];

    for (final c in checks) {
      if (c.status == CheckStatus.open) openCount++;
      if (c.status == CheckStatus.saved) savedCount++;

      if (c.status == CheckStatus.open || c.status == CheckStatus.saved) {
        liveActivity.add(
          _TableActivity(
            tableNumber: c.tableNumber,
            server: c.serverName,
            covers: c.covers,
            amount: c.total.toDouble(),
            elapsed: DateTime.now().difference(c.openedAt),
            status: c.status,
          ),
        );
        continue;
      }

      if (c.status == CheckStatus.voided) {
        totalVoidAmt += c.subtotal + c.tax;
        exceptions.add(
          _ExceptionLog(
            type: 'VOID',
            reference: c.id,
            server: c.serverName,
            reason: c.voidReason.isNotEmpty ? c.voidReason : 'No reason given',
            amount: c.subtotal + c.tax,
            timestamp: c.closedAt ?? c.openedAt,
          ),
        );
        continue;
      }

      // Calculations for non-voided, non-live checks (closed only at this point)
      grossSales += c.subtotal;
      taxesCollected += c.tax;
      totalDiscounts += c.discountCalculated;

      if (c.status == CheckStatus.closed) {
        totalTips += c.tip;
        final tName = c.paymentMethod.isNotEmpty ? c.paymentMethod : 'Unpaid';
        tenderMap.putIfAbsent(tName, () => _TenderTemp()).count++;
        tenderMap[tName]!.amount += c.total.toDouble();
        tenderMap[tName]!.tips += c.tip;
      }

      if (c.discountCalculated > 0) {
        exceptions.add(
          _ExceptionLog(
            type: 'DISCOUNT',
            reference: c.id,
            server: c.serverName,
            reason: c.discountType?.displayName ?? 'Manual Discount',
            amount: c.discountCalculated,
            timestamp: c.closedAt ?? c.openedAt,
          ),
        );
      }

      final end = c.closedAt ?? DateTime.now();
      checkDurations.add(end.difference(c.openedAt));

      empMap.putIfAbsent(c.serverName, () => _EmployeeTemp()).checks++;
      empMap[c.serverName]!.covers += c.covers;
      empMap[c.serverName]!.sales += c.total.toDouble();

      for (final item in c.items) {
        final cat = _categoryGroup(p, item.name);
        fbMap.putIfAbsent(cat, () => _FbCategoryItemTemp()).units +=
            item.quantity;
        fbMap[cat]!.gross += item.total;
        fbUnitCats[cat] = (fbUnitCats[cat] ?? 0) + item.quantity;
      }
    }

    final netSales = grossSales - totalDiscounts;
    final totalRevenue = netSales + taxesCollected + totalTips;
    final occupiedDurations = <Duration>[];
    if (date.day == DateTime.now().day) {
      for (final table in p.tables) {
        if (table.status == TableStatus.available) continue;
        final check = p.getCheckForTable(table.number);
        if (check != null) {
          occupiedDurations.add(DateTime.now().difference(check.openedAt));
        } else if (table.seatedAt != null) {
          occupiedDurations.add(table.currentOccupancyDuration);
        }
      }
    }

    final hourCounts = <int, double>{};
    for (var h = 0; h <= 23; h++) hourCounts[h] = 0;
    for (final c in checks) {
      if (c.status == CheckStatus.voided) continue;
      final h = c.openedAt.hour;
      hourCounts[h] = (hourCounts[h] ?? 0) + c.total.toDouble();
    }
    final peakHours =
        hourCounts.entries
            .map((e) => _HourBucket(hour: e.key, count: e.value))
            .toList()
          ..sort((a, b) => a.hour.compareTo(b.hour));

    final mixCounts = <String, double>{'Food': 0, 'Drinks': 0, 'Dessert': 0};
    for (final c in checks) {
      if (c.status == CheckStatus.voided) continue;
      for (final item in c.items) {
        final group = _categoryGroup(p, item.name);
        mixCounts[group] = (mixCounts[group] ?? 0) + item.quantity;
      }
    }
    final mixTotal = mixCounts.values.fold<double>(0, (a, b) => a + b);
    final categoryMix = <String, double>{};
    if (mixTotal > 0) {
      for (final e in mixCounts.entries) {
        categoryMix[e.key] = e.value / mixTotal;
      }
    }

    final stationBuckets = <String, List<Duration>>{};
    for (final c in checks) {
      if (c.status == CheckStatus.voided) continue;
      for (final item in c.items) {
        final prep = item.prepTime;
        if (prep == null) continue;
        final station = _stationForItem(p, item.name);
        stationBuckets.putIfAbsent(station, () => []).add(prep);
      }
    }

    const fallbackStations = {
      'Grill': Duration(minutes: 14),
      'Garde Manger': Duration(minutes: 8),
      'Pastry': Duration(minutes: 11),
      'Bar': Duration(minutes: 4),
    };
    final stationMetrics = <_StationMetric>[];
    for (final name in ['Grill', 'Garde Manger', 'Pastry', 'Bar']) {
      final samples = stationBuckets[name];
      final avg = samples != null && samples.isNotEmpty
          ? Duration(
              milliseconds:
                  samples
                      .map((d) => d.inMilliseconds)
                      .reduce((a, b) => a + b) ~/
                  samples.length,
            )
          : fallbackStations[name]!;
      stationMetrics.add(_StationMetric(name: name, avgPrep: avg));
    }

    final empList =
        empMap.entries
            .map(
              (e) => _EmployeeMetric(
                name: e.key,
                checks: e.value.checks,
                covers: e.value.covers,
                sales: e.value.sales,
              ),
            )
            .toList()
          ..sort((a, b) => b.sales.compareTo(a.sales));

    final tenderList =
        tenderMap.entries
            .map(
              (e) => _TenderMetric(
                method: e.key,
                count: e.value.count,
                amount: e.value.amount,
                tips: e.value.tips,
              ),
            )
            .toList()
          ..sort((a, b) => b.amount.compareTo(a.amount));

    double totalFbGross = fbMap.values.fold(0, (sum, f) => sum + f.gross);
    final fbList =
        fbMap.entries
            .map(
              (e) => _FbCategoryItem(
                name: e.key,
                units: e.value.units,
                gross: e.value.gross,
                share: totalFbGross > 0 ? (e.value.gross / totalFbGross) : 0,
              ),
            )
            .toList()
          ..sort((a, b) => b.gross.compareTo(a.gross));

    liveActivity.sort((a, b) => b.elapsed.compareTo(a.elapsed));

    final closedChecks = checks
        .where((c) => c.status == CheckStatus.closed)
        .toList();
    final voidedChecks = checks
        .where((c) => c.status == CheckStatus.voided)
        .toList();
    final receiptsGenerated = closedChecks.length;
    final voidCheckCount = voidedChecks.length;
    final totalCovers = closedChecks.fold<int>(0, (sum, c) => sum + c.covers);
    final averageOrderValue = receiptsGenerated > 0
        ? closedChecks.fold<double>(0, (sum, c) => sum + c.total) /
              receiptsGenerated
        : 0.0;

    return _DashboardMetrics(
      grossSales: grossSales,
      netSales: netSales,
      totalDiscounts: totalDiscounts,
      taxesCollected: taxesCollected,
      totalTips: totalTips,
      totalVoidAmt: totalVoidAmt,
      totalRevenue: totalRevenue,
      receiptsGenerated: receiptsGenerated,
      voidCheckCount: voidCheckCount,
      totalCovers: totalCovers,
      averageOrderValue: averageOrderValue,
      avgCheckTime: _averageDuration(checkDurations),
      avgTableOccupancy: _averageDuration(occupiedDurations),
      peakHours: peakHours,
      categoryMix: categoryMix,
      stationMetrics: stationMetrics,
      openCheckCount: openCount,
      savedCheckCount: savedCount,
      liveTableActivity: liveActivity,
      employeeMix: empList,
      tenderMix: tenderList,
      exceptionLogs: exceptions,
      fbItems: fbList,
      fbUnitsByCategory: fbUnitCats,
    );
  }

  static String _categoryGroup(POSProvider p, String itemName) {
    final menu = p.fullMenu.where((m) => m.name == itemName).firstOrNull;
    if (menu == null) return 'Food';
    switch (menu.category) {
      case MenuCategory.beverages:
        return 'Drinks';
      case MenuCategory.desserts:
        return 'Dessert';
      default:
        return 'Food';
    }
  }

  static String _stationForItem(POSProvider p, String itemName) {
    final menu = p.fullMenu.where((m) => m.name == itemName).firstOrNull;
    if (menu == null) return 'Grill';
    switch (menu.category) {
      case MenuCategory.mains:
        return 'Grill';
      case MenuCategory.appetizers:
      case MenuCategory.sides:
        return 'Garde Manger';
      case MenuCategory.desserts:
        return 'Pastry';
      case MenuCategory.beverages:
        return 'Bar';
    }
  }

  static Duration _averageDuration(List<Duration> list) {
    if (list.isEmpty) return Duration.zero;
    final ms = list.map((d) => d.inMilliseconds).reduce((a, b) => a + b);
    return Duration(milliseconds: ms ~/ list.length);
  }
}

// ─── Supporting data models ───────────────────────────────────────────────────

class _HourBucket {
  const _HourBucket({required this.hour, required this.count});
  final int hour;
  final double count;
}

class _StationMetric {
  const _StationMetric({required this.name, required this.avgPrep});
  final String name;
  final Duration avgPrep;
}

class _EmployeeTemp {
  int checks = 0;
  int covers = 0;
  double sales = 0;
}

class _EmployeeMetric {
  const _EmployeeMetric({
    required this.name,
    required this.checks,
    required this.covers,
    required this.sales,
  });
  final String name;
  final int checks;
  final int covers;
  final double sales;
}

class _TenderTemp {
  int count = 0;
  double amount = 0;
  double tips = 0;
}

class _TenderMetric {
  const _TenderMetric({
    required this.method,
    required this.count,
    required this.amount,
    required this.tips,
  });
  final String method;
  final int count;
  final double amount;
  final double tips;
}

class _ExceptionLog {
  const _ExceptionLog({
    required this.type,
    required this.reference,
    required this.server,
    required this.reason,
    required this.amount,
    required this.timestamp,
  });
  final String type;
  final String reference;
  final String server;
  final String reason;
  final double amount;
  final DateTime timestamp;
}

class _FbCategoryItemTemp {
  int units = 0;
  double gross = 0;
}

class _FbCategoryItem {
  const _FbCategoryItem({
    required this.name,
    required this.units,
    required this.gross,
    required this.share,
  });
  final String name;
  final int units;
  final double gross;
  final double share;
}

class _TableActivity {
  const _TableActivity({
    required this.tableNumber,
    required this.server,
    required this.covers,
    required this.amount,
    required this.elapsed,
    required this.status,
  });
  final int tableNumber;
  final String server;
  final int covers;
  final double amount;
  final Duration elapsed;
  final CheckStatus status;
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _formatDuration(Duration d) {
  if (d == Duration.zero) return '—';
  if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
  return '${d.inMinutes}m';
}

String _fmtTime(DateTime dt) {
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

String _hourLabel(int h) {
  if (h == 0) return '12a';
  if (h < 12) return '${h}a';
  if (h == 12) return '12p';
  return '${h - 12}p';
}

// ─── Main Screen ──────────────────────────────────────────────────────────────

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});
  @override
  State<AnalyticsDashboardScreen> createState() =>
      _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  DateTime _selectedDate = DateTime.now();
  ReportViewCategory _selectedCategory = ReportViewCategory.insights;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<POSProvider>();
    final metrics = _DashboardMetrics.from(provider, _selectedDate);
    final theme = Theme.of(context);

    return Scaffold(
      body: POSBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 900;
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildHeader(context, provider),
                    const SizedBox(height: 12),
                    _buildViewSelector(theme),
                    const SizedBox(height: 14),
                    Expanded(
                      child: isWide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 240,
                                  child: _buildNavigationSidebar(),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: SingleChildScrollView(
                                    child: _buildActiveWorkspace(
                                      metrics,
                                      provider,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                _buildNavigationDropdown(),
                                const SizedBox(height: 12),
                                Expanded(
                                  child: SingleChildScrollView(
                                    child: _buildActiveWorkspace(
                                      metrics,
                                      provider,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, POSProvider provider) {
    final theme = Theme.of(context);
    return Row(
      children: [
        // Wrapping in Expanded prevents pixel overflow
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Analytics',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                overflow:
                    TextOverflow.ellipsis, // Ensures text doesn't break layout
              ),
              Text(
                "Date: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16), // Adds breathing room
        // Styled Button
        OutlinedButton.icon(
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            );
            if (picked != null) setState(() => _selectedDate = picked);
          },
          icon: const Icon(Icons.calendar_today, size: 16),
          label: const Text('Select Date'),
        ),
      ],
    );
  }

  Widget _buildNavigationSidebar() {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 8),
      borderRadius: 16,
      child: ListView(
        shrinkWrap: true,
        children: ReportViewCategory.values.map((cat) {
          final isSelected = _selectedCategory == cat;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: isSelected ? _coral.withOpacity(0.15) : Colors.transparent,
            ),
            child: ListTile(
              dense: true,
              leading: Icon(
                cat.icon,
                color: isSelected ? _coral : Colors.grey,
                size: 20,
              ),
              title: Text(
                cat.displayName,
                style: TextStyle(
                  color: isSelected ? _coral : null,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
              selected: isSelected,
              onTap: () => setState(() => _selectedCategory = cat),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNavigationDropdown() {
    return GlassCard(
      borderRadius: 12,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ReportViewCategory>(
          value: _selectedCategory,
          isExpanded: true,
          items: ReportViewCategory.values.map((cat) {
            return DropdownMenuItem(
              value: cat,
              child: Row(
                children: [
                  Icon(cat.icon, size: 18),
                  const SizedBox(width: 8),
                  Text(cat.displayName),
                ],
              ),
            );
          }).toList(),
          onChanged: (cat) {
            if (cat != null) setState(() => _selectedCategory = cat);
          },
        ),
      ),
    );
  }

  Widget _buildViewSelector(ThemeData theme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: ReportViewCategory.values.map((cat) {
          final isSelected = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              avatar: Icon(
                cat.icon,
                size: 16,
                color: isSelected ? Colors.white : null,
              ),
              label: Text(cat.displayName),
              selected: isSelected,
              onSelected: (val) {
                if (val) setState(() => _selectedCategory = cat);
              },
              selectedColor: _coral,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : null,
                fontSize: 12,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActiveWorkspace(
    _DashboardMetrics metrics,
    POSProvider provider,
  ) {
    switch (_selectedCategory) {
      case ReportViewCategory.insights:
        return _LiveInsightsView(metrics: metrics, provider: provider);
      case ReportViewCategory.salesSummary:
        return _FinancialSummaryView(metrics: metrics);
      case ReportViewCategory.foodAndBeverage:
        return _FAndBCategoryView(metrics: metrics, provider: provider);
      case ReportViewCategory.employeePerformance:
        return _EmployeePerformanceView(metrics: metrics);
      case ReportViewCategory.tenderBreakdown:
        return _TenderZReportView(metrics: metrics);
      case ReportViewCategory.exceptions:
        return _ExceptionsView(metrics: metrics);
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// LIVE INSIGHTS VIEW
// ═══════════════════════════════════════════════════════════════════════════════

class _LiveInsightsView extends StatelessWidget {
  const _LiveInsightsView({required this.metrics, required this.provider});
  final _DashboardMetrics metrics;
  final POSProvider provider;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final occupiedTables = provider.tables
        .where((t) => t.status != TableStatus.available)
        .length;
    final totalTables = provider.tables.length;
    final occupancyPct = totalTables > 0 ? occupiedTables / totalTables : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Live status header ──────────────────────────────────────
        GlassCard(
          borderRadius: 20,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: _emerald,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'LIVE — ${_fmtTime(now)}',
                style: const TextStyle(
                  color: _emerald,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Text(
                '${metrics.openCheckCount} open · ${metrics.savedCheckCount} saved',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── KPI tiles ───────────────────────────────────────────────
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.2,
          children: [
            _kpiTile(
              'Floor Occupancy',
              '${(occupancyPct * 100).toStringAsFixed(0)}%',
              Icons.table_restaurant_rounded,
              _coral,
            ),
            _kpiTile(
              'Open Checks',
              '${metrics.openCheckCount}',
              Icons.receipt_long_rounded,
              _violet,
            ),
            _kpiTile(
              'Live Revenue',
              '\$${metrics.totalRevenue.toStringAsFixed(0)}',
              Icons.attach_money_rounded,
              _emerald,
            ),
            _kpiTile(
              'Total Covers',
              '${metrics.totalCovers}',
              Icons.people_outline_rounded,
              _sky,
            ),
          ],
        ),
        const SizedBox(height: 14),

        // ── Occupancy bar ────────────────────────────────────────────
        GlassCard(
          borderRadius: 18,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.table_restaurant_rounded,
                    size: 16,
                    color: _coral,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Table Occupancy',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Text(
                    '$occupiedTables / $totalTables tables',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: occupancyPct,
                  minHeight: 14,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  valueColor: const AlwaysStoppedAnimation<Color>(_coral),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _statusDot(_emerald, 'Available'),
                  const SizedBox(width: 12),
                  _statusDot(_coral, 'Occupied'),
                  const SizedBox(width: 12),
                  _statusDot(_amber, 'Ready for Bill'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ── Active checks list ────────────────────────────────────────
        GlassCard(
          borderRadius: 18,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.timer_outlined, size: 16, color: _amber),
                  SizedBox(width: 6),
                  Text(
                    'Active Checks',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              metrics.liveTableActivity.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          'No active checks at this time.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  : Column(
                      children: metrics.liveTableActivity.map((ta) {
                        final isLong = ta.elapsed.inMinutes > 60;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: _coral.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    'T${ta.tableNumber}',
                                    style: const TextStyle(
                                      color: _coral,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ta.server,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      '${ta.covers} covers · ${_formatDuration(ta.elapsed)}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isLong ? _amber : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '\$${ta.amount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: _emerald,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ── Sales by hour ─────────────────────────────────────────────
        GlassCard(
          borderRadius: 18,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.bar_chart_rounded, size: 16, color: _violet),
                  SizedBox(width: 6),
                  Text(
                    'Revenue by Hour',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _HourlyBarChart(buckets: metrics.peakHours),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ── Kitchen station prep times ─────────────────────────────────
        GlassCard(
          borderRadius: 18,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.restaurant_rounded, size: 16, color: _teal),
                  SizedBox(width: 6),
                  Text(
                    'Station Avg Prep Time',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...metrics.stationMetrics.asMap().entries.map((e) {
                final s = e.value;
                final maxMin = 20.0;
                final pct = (s.avgPrep.inSeconds / (maxMin * 60)).clamp(
                  0.0,
                  1.0,
                );
                final color = _chartColors[e.key % _chartColors.length];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 90,
                        child: Text(
                          s.name,
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: pct,
                            minHeight: 10,
                            backgroundColor: Colors.white.withOpacity(0.08),
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 40,
                        child: Text(
                          _formatDuration(s.avgPrep),
                          style: TextStyle(
                            fontSize: 12,
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _kpiTile(String label, String value, IconData icon, Color color) {
    return GlassCard(
      borderRadius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 18,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// FINANCIAL SUMMARY VIEW
// ═══════════════════════════════════════════════════════════════════════════════

class _FinancialSummaryView extends StatelessWidget {
  const _FinancialSummaryView({required this.metrics});
  final _DashboardMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Total Revenue hero ─────────────────────────────────────────
        GlassCard(
          borderRadius: 24,
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TOTAL REVENUE',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 11,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '\$${metrics.totalRevenue.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: _emerald,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Gross: \$${metrics.grossSales.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _badgePill('${metrics.receiptsGenerated} receipts', _coral),
                  const SizedBox(height: 6),
                  _badgePill('${metrics.totalCovers} covers', _violet),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── 4 stat tiles ─────────────────────────────────────────────
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.3,
          children: [
            _statTile(
              'Avg Order Value',
              '\$${metrics.averageOrderValue.toStringAsFixed(2)}',
              Icons.pie_chart_outline_rounded,
              _coral,
            ),
            _statTile(
              'Tax Collected',
              '\$${metrics.taxesCollected.toStringAsFixed(2)}',
              Icons.percent_rounded,
              _amber,
            ),
            _statTile(
              'Total Discounts',
              '-\$${metrics.totalDiscounts.toStringAsFixed(2)}',
              Icons.discount_outlined,
              _violet,
            ),
            _statTile(
              'Total Tips',
              '\$${metrics.totalTips.toStringAsFixed(2)}',
              Icons.volunteer_activism_rounded,
              _emerald,
            ),
          ],
        ),
        const SizedBox(height: 14),

        // ── Sales breakdown table ─────────────────────────────────────
        GlassCard(
          borderRadius: 18,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sales Breakdown',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              _summaryRow('Gross Sales', metrics.grossSales, _emerald),
              _summaryRow('Tax (8.5%)', metrics.taxesCollected, _amber),
              _summaryRow('Discounts', -metrics.totalDiscounts, _red),
              _summaryRow('Tips', metrics.totalTips, _violet),
              const Divider(height: 1),
              _summaryRow(
                'Total Revenue',
                metrics.totalRevenue,
                _emerald,
                bold: true,
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ── Void summary ──────────────────────────────────────────────
        GlassCard(
          borderRadius: 18,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _red.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.cancel_outlined, color: _red),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Voided Checks',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  Text(
                    '${metrics.voidCheckCount}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _red,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Avg Check Time',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  Text(
                    _formatDuration(metrics.avgCheckTime),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _sky,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _badgePill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _statTile(String label, String value, IconData icon, Color color) {
    return GlassCard(
      borderRadius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 15,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(
    String label,
    double amount,
    Color color, {
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              fontSize: bold ? 14 : 13,
            ),
          ),
          const Spacer(),
          Text(
            amount < 0
                ? '-\$${(-amount).toStringAsFixed(2)}'
                : '\$${amount.toStringAsFixed(2)}',
            style: TextStyle(
              color: color,
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
              fontSize: bold ? 15 : 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// F&B MIX VIEW
// ═══════════════════════════════════════════════════════════════════════════════

class _FAndBCategoryView extends StatelessWidget {
  const _FAndBCategoryView({required this.metrics, required this.provider});
  final _DashboardMetrics metrics;
  final POSProvider provider;

  @override
  Widget build(BuildContext context) {
    final totalUnits = metrics.fbUnitsByCategory.values.fold<int>(
      0,
      (a, b) => a + b,
    );
    final totalGross = metrics.fbItems.fold<double>(0, (a, b) => a + b.gross);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Category donut summary ────────────────────────────────────
        GlassCard(
          borderRadius: 20,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Category Revenue Mix',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 14),
              metrics.fbItems.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'No item sales recorded for this date.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  : Column(
                      children: metrics.fbItems.asMap().entries.map((e) {
                        final item = e.value;
                        final color = _chartColors[e.key % _chartColors.length];
                        final pct = totalGross > 0
                            ? (item.gross / totalGross)
                            : 0.0;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
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
                                  Expanded(
                                    child: Text(
                                      item.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${item.units} units',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '\$${item.gross.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: color,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: pct,
                                  minHeight: 8,
                                  backgroundColor: Colors.white.withOpacity(
                                    0.08,
                                  ),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    color,
                                  ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  '${(pct * 100).toStringAsFixed(1)}%',
                                  style: TextStyle(fontSize: 10, color: color),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ── Units by category donut visual ─────────────────────────────
        if (metrics.fbUnitsByCategory.isNotEmpty) ...[
          GlassCard(
            borderRadius: 20,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Units Sold by Category',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: CustomPaint(
                        painter: _DonutPainter(
                          data: metrics.fbUnitsByCategory.values
                              .map((v) => v.toDouble())
                              .toList(),
                          colors: _chartColors,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: metrics.fbUnitsByCategory.entries
                            .toList()
                            .asMap()
                            .entries
                            .map((e) {
                              final idx = e.key;
                              final entry = e.value;
                              final color =
                                  _chartColors[idx % _chartColors.length];
                              final pct = totalUnits > 0
                                  ? entry.value / totalUnits
                                  : 0.0;
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 3,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        entry.key,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                    Text(
                                      '${entry.value}u',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: color,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${(pct * 100).toStringAsFixed(0)}%',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            })
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // ── Top selling items by category ──────────────────────────────
        GlassCard(
          borderRadius: 20,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Top Items by Category',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 12),
              ...MenuCategory.values.map((cat) {
                final items = provider.getMenuByCategory(cat);
                if (items.isEmpty) return const SizedBox.shrink();
                return ExpansionTile(
                  leading: Text(cat.icon, style: const TextStyle(fontSize: 18)),
                  title: Text(
                    cat.displayName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  children: items.take(4).map((item) {
                    return ListTile(
                      dense: true,
                      title: Text(
                        item.name,
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Text(
                        '\$${item.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: _emerald,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }).toList(),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// EMPLOYEE PERFORMANCE VIEW
// ═══════════════════════════════════════════════════════════════════════════════

class _EmployeePerformanceView extends StatelessWidget {
  const _EmployeePerformanceView({required this.metrics});
  final _DashboardMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final maxSales = metrics.employeeMix.isNotEmpty
        ? metrics.employeeMix.first.sales
        : 1.0;
    final totalSales = metrics.employeeMix.fold<double>(
      0,
      (a, b) => a + b.sales,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Summary bar ──────────────────────────────────────────────
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(), // Important!
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.2, // Slightly adjusted for better fit
            children: [
              _miniKpi(
                'Staff Active',
                '${metrics.employeeMix.length}',
                _coral,
                Icons.badge_outlined,
              ),
              _miniKpi(
                'Total Checks',
                '${metrics.employeeMix.fold<int>(0, (a, b) => a + b.checks)}',
                _violet,
                Icons.receipt_long_rounded,
              ),
              _miniKpi(
                'Team Revenue',
                '\$${totalSales.toStringAsFixed(0)}',
                _emerald,
                Icons.attach_money_rounded,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Leaderboard ──────────────────────────────────────────────
          GlassCard(
            borderRadius: 18,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ... (Keep your leaderboard code exactly as is)
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Detailed Metrics Table ──────────────────────────────────
          if (metrics.employeeMix.isNotEmpty)
            GlassCard(
              borderRadius: 18,
              padding: const EdgeInsets.all(16),
              child: Table(
                columnWidths: const {
                  0: FlexColumnWidth(3),
                  1: FlexColumnWidth(1.5),
                  2: FlexColumnWidth(1.5),
                  3: FlexColumnWidth(2),
                },
                children: [
                  // Header row
                  TableRow(
                    children: ['Server', 'Checks', 'Covers', 'Sales']
                        .map(
                          (h) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              h,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  // Data rows
                  ...metrics.employeeMix.map(
                    (emp) => TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            emp.name,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            '${emp.checks}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: _violet,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            '${emp.covers}',
                            style: const TextStyle(fontSize: 12, color: _sky),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            '\$${emp.sales.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: _coral,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _miniKpi(String label, String value, Color color, IconData icon) {
    return GlassCard(
      borderRadius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 16,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TENDER & Z-REPORT VIEW
// ═══════════════════════════════════════════════════════════════════════════════

class _TenderZReportView extends StatelessWidget {
  const _TenderZReportView({required this.metrics});
  final _DashboardMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final totalTender = metrics.tenderMix.fold<double>(
      0,
      (a, b) => a + b.amount,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Tender summary hero ───────────────────────────────────────
        GlassCard(
          borderRadius: 20,
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.account_balance_wallet_outlined, color: _emerald),
                  SizedBox(width: 8),
                  Text(
                    'Tender Totals',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              metrics.tenderMix.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text(
                          'No closed transactions yet.\nClose some checks to see tender data.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  : Column(
                      children: metrics.tenderMix.asMap().entries.map((e) {
                        final idx = e.key;
                        final t = e.value;
                        final color = _chartColors[idx % _chartColors.length];
                        final pct = totalTender > 0
                            ? t.amount / totalTender
                            : 0.0;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  _tenderIcon(t.method, color),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          t.method,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          '${t.count} transaction${t.count != 1 ? 's' : ''}',
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '\$${t.amount.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          color: color,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      if (t.tips > 0)
                                        Text(
                                          '+ \$${t.tips.toStringAsFixed(2)} tips',
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 11,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: pct,
                                  minHeight: 8,
                                  backgroundColor: Colors.white.withOpacity(
                                    0.08,
                                  ),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    color,
                                  ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  '${(pct * 100).toStringAsFixed(1)}%',
                                  style: TextStyle(fontSize: 10, color: color),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ── Z-Report card ─────────────────────────────────────────────
        GlassCard(
          borderRadius: 20,
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.summarize_outlined, color: _amber),
                  const SizedBox(width: 8),
                  const Text(
                    'Z-Report Summary',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _amber.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'END OF DAY',
                      style: TextStyle(
                        color: _amber,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _zRow('Opening Balance', '\$0.00'),
              _zRow(
                'Gross Sales',
                '\$${metrics.grossSales.toStringAsFixed(2)}',
              ),
              _zRow(
                'Tax Collected (8.5%)',
                '\$${metrics.taxesCollected.toStringAsFixed(2)}',
              ),
              _zRow(
                'Discounts',
                '-\$${metrics.totalDiscounts.toStringAsFixed(2)}',
                valueColor: _red,
              ),
              _zRow(
                'Void Amount',
                '-\$${metrics.totalVoidAmt.toStringAsFixed(2)}',
                valueColor: _red,
              ),
              _zRow(
                'Tips',
                '\$${metrics.totalTips.toStringAsFixed(2)}',
                valueColor: _emerald,
              ),
              const Divider(),
              _zRow(
                'Total Revenue',
                '\$${metrics.totalRevenue.toStringAsFixed(2)}',
                bold: true,
                valueColor: _emerald,
              ),
              const Divider(),
              _zRow('Receipts Issued', '${metrics.receiptsGenerated}'),
              _zRow('Void Count', '${metrics.voidCheckCount}'),
              _zRow('Total Covers', '${metrics.totalCovers}'),
              _zRow('Avg Check Time', _formatDuration(metrics.avgCheckTime)),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _tenderIcon(String method, Color color) {
    final m = method.toLowerCase();
    IconData icon;
    if (m.contains('cash')) {
      icon = Icons.payments_outlined;
    } else if (m.contains('card') ||
        m.contains('credit') ||
        m.contains('visa')) {
      icon = Icons.credit_card_rounded;
    } else if (m.contains('amex') || m.contains('master')) {
      icon = Icons.credit_score_rounded;
    } else {
      icon = Icons.account_balance_wallet_outlined;
    }
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _zRow(
    String label,
    String value, {
    bool bold = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: bold ? 14 : 13,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? (bold ? _emerald : null),
              fontWeight: bold ? FontWeight.bold : FontWeight.w500,
              fontSize: bold ? 15 : 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// VOIDS & DISCOUNTS VIEW
// ═══════════════════════════════════════════════════════════════════════════════

class _ExceptionsView extends StatelessWidget {
  const _ExceptionsView({required this.metrics});
  final _DashboardMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final voids = metrics.exceptionLogs.where((e) => e.type == 'VOID').toList();
    final discounts = metrics.exceptionLogs
        .where((e) => e.type == 'DISCOUNT')
        .toList();
    final totalVoidAmt = voids.fold<double>(0, (a, b) => a + b.amount);
    final totalDiscAmt = discounts.fold<double>(0, (a, b) => a + b.amount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Summary tiles ─────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: GlassCard(
                borderRadius: 16,
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: _red.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.cancel_outlined,
                            color: _red,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Voids',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${voids.length}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: _red,
                      ),
                    ),
                    Text(
                      '-\$${totalVoidAmt.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GlassCard(
                borderRadius: 16,
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: _amber.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.discount_outlined,
                            color: _amber,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Discounts',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${discounts.length}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: _amber,
                      ),
                    ),
                    Text(
                      '-\$${totalDiscAmt.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // ── Void logs ─────────────────────────────────────────────────
        GlassCard(
          borderRadius: 18,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.cancel_outlined, color: _red, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Void Log',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              voids.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          'No voided checks for this date.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  : Column(
                      children: voids
                          .map((log) => _exceptionTile(log, _red))
                          .toList(),
                    ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ── Discount logs ─────────────────────────────────────────────
        GlassCard(
          borderRadius: 18,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.discount_outlined, color: _amber, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Discount Log',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              discounts.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          'No discounts applied for this date.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  : Column(
                      children: discounts
                          .map((log) => _exceptionTile(log, _amber))
                          .toList(),
                    ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _exceptionTile(_ExceptionLog log, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        log.type,
                        style: TextStyle(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      log.reference,
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                    const Spacer(),
                    Text(
                      _fmtTime(log.timestamp),
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  log.server,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
                Text(
                  log.reason,
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '-\$${log.amount.toStringAsFixed(2)}',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CUSTOM PAINTERS
// ═══════════════════════════════════════════════════════════════════════════════

class _HourlyBarChart extends StatelessWidget {
  const _HourlyBarChart({required this.buckets});
  final List<_HourBucket> buckets;

  @override
  Widget build(BuildContext context) {
    // Only show hours with > 0 revenue or typical service hours (11-23)
    final relevant = buckets
        .where((b) => b.hour >= 11 && b.hour <= 23)
        .toList();
    final maxVal = relevant.fold<double>(0, (m, b) => math.max(m, b.count));

    return SizedBox(
      height: 120,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: relevant.map((b) {
          final ratio = maxVal > 0 ? b.count / maxVal : 0.0;
          final isNow = b.hour == DateTime.now().hour;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (b.count > 0)
                    Text(
                      '\$${b.count.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 7, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: 2),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    height: (ratio * 80).clamp(4.0, 80.0),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: isNow
                            ? [_coral, _amber]
                            : [_violet.withOpacity(0.5), _violet],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _hourLabel(b.hour),
                    style: TextStyle(
                      fontSize: 8,
                      color: isNow ? _coral : Colors.grey,
                      fontWeight: isNow ? FontWeight.bold : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({required this.data, required this.colors});
  final List<double> data;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final total = data.fold<double>(0, (a, b) => a + b);
    if (total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    const strokeWidth = 18.0;
    final rect = Rect.fromCircle(
      center: center,
      radius: radius - strokeWidth / 2,
    );

    double startAngle = -math.pi / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < data.length; i++) {
      final sweep = (data[i] / total) * 2 * math.pi;
      paint.color = colors[i % colors.length];
      canvas.drawArc(rect, startAngle, sweep - 0.05, false, paint);
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
