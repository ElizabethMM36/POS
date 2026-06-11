import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:my_pos_app/models/pos_models.dart';
import 'package:my_pos_app/providers/pos_provider.dart';
import 'package:my_pos_app/screens/order_summary_screen.dart';
// 1. ADD THIS IMPORT (Adjust the path if your file is in a different folder)
import 'package:my_pos_app/widgets/pos_background.dart';

/// The "Checks" tab — a timeline-style view of all check history,
/// featuring status-driven KPI dashboard boxes, search, and historical filters.
class SavedChecksScreen extends StatefulWidget {
  const SavedChecksScreen({super.key});

  @override
  State<SavedChecksScreen> createState() => _SavedChecksScreenState();
}

class _SavedChecksScreenState extends State<SavedChecksScreen> {
  String _filterStatus = 'All';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final provider = context.watch<POSProvider>();
    final allChecks = provider.checks.toList()
      ..sort((a, b) => b.openedAt.compareTo(a.openedAt));

    // Calculate real-time metrics for KPI summary boxes
    final openChecksCount = allChecks
        .where((c) => c.status == CheckStatus.open)
        .length;
    final savedChecksCount = allChecks
        .where((c) => c.status == CheckStatus.saved)
        .length;
    final totalSalesRevenue = allChecks
        .where((c) => c.status == CheckStatus.closed)
        .fold<double>(0.0, (sum, c) => sum + c.total);

    // Apply active search and category filters
    final filteredChecks = allChecks.where((check) {
      if (_filterStatus != 'All') {
        if (_filterStatus == 'Open' && check.status != CheckStatus.open) {
          return false;
        }
        if (_filterStatus == 'Saved' && check.status != CheckStatus.saved) {
          return false;
        }
        if (_filterStatus == 'Closed' && check.status != CheckStatus.closed) {
          return false;
        }
        if (_filterStatus == 'Voided' && check.status != CheckStatus.voided) {
          return false;
        }
      }

      if (_searchController.text.isNotEmpty) {
        final query = _searchController.text.toLowerCase();
        final matchesTable = check.tableNumber.toString().contains(query);
        final matchesId = check.id.toLowerCase().contains(query);
        final matchesServer = check.serverName.toLowerCase().contains(query);
        if (!matchesTable && !matchesId && !matchesServer) return false;
      }
      return true;
    }).toList();

    return Scaffold(
      // 2. MAKE SCAFFOLD TRANSPARENT so the mesh background shows through
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        // Make the AppBar transparent too so the top bloom gradient isn't cut off
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Check Logs',
          style: TextStyle(
            fontFamily: 'Hanken Grotesk',
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: colors.onSurface,
          ),
        ),
      ),
      // 3. WRAP THE BODY IN POSBACKGROUND
      body: POSBackground(
        child: Column(
          children: [
            // 1. KPI Metric Dashboard Summary Boxes
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: _KpiMetricCard(
                      title: 'Active Open',
                      value: '$openChecksCount',
                      accentColor: const Color(0xFF22C55E),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _KpiMetricCard(
                      title: 'Saved Holds',
                      value: '$savedChecksCount',
                      accentColor: const Color(0xFFF97316),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _KpiMetricCard(
                      title: 'Closed Sales',
                      value: '\$${totalSalesRevenue.toStringAsFixed(0)}',
                      accentColor: colors.primary,
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar Input Area
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: colors.surfaceContainer,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.outlineVariant),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Icon(Icons.search_rounded, size: 18, color: colors.outline),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() {}),
                        style: TextStyle(
                          fontFamily: 'Hanken Grotesk',
                          fontSize: 14,
                          color: colors.onSurface,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search table, check ID, or server...',
                          hintStyle: TextStyle(
                            fontFamily: 'Hanken Grotesk',
                            fontSize: 14,
                            color: colors.outline,
                          ),
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() {});
                        },
                        child: Icon(
                          Icons.clear_rounded,
                          size: 18,
                          color: colors.outline,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Horizontal Filter Row chips
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: ['All', 'Open', 'Saved', 'Closed', 'Voided'].map((
                  status,
                ) {
                  final isSelected = _filterStatus == status;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _FilterChip(
                      label: status,
                      isSelected: isSelected,
                      onTap: () {
                        setState(() {
                          _filterStatus = status;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Historical Logs Timeline Feed
            Expanded(
              child: filteredChecks.isEmpty
                  ? Center(
                      child: Text(
                        'No matching checks found in current shift.',
                        style: TextStyle(
                          fontFamily: 'Hanken Grotesk',
                          fontSize: 14,
                          color: colors.outline,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filteredChecks.length,
                      itemBuilder: (context, index) {
                        final check = filteredChecks[index];
                        final isLast = index == filteredChecks.length - 1;

                        return IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _TimelineDivider(
                                status: check.status,
                                isLast: isLast,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: _CheckHistoryCard(
                                    check: check,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => OrderSummaryScreen(
                                            checkId: check.id,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dynamic metric component card supporting flexible theme container values
class _KpiMetricCard extends StatelessWidget {
  const _KpiMetricCard({
    required this.title,
    required this.value,
    required this.accentColor,
  });

  final String title;
  final String value;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Hanken Grotesk',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.primary.withOpacity(0.15)
              : colors.surfaceContainer,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? colors.primary : colors.outlineVariant,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Hanken Grotesk',
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? colors.primary : colors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _TimelineDivider extends StatelessWidget {
  const _TimelineDivider({required this.status, required this.isLast});

  final CheckStatus status;
  final bool isLast;

  Color _getStatusColor(CheckStatus s) {
    switch (s) {
      case CheckStatus.open:
        return const Color(0xFF22C55E);
      case CheckStatus.saved:
        return const Color(0xFFF97316);
      case CheckStatus.closed:
        return const Color(0xFF64748B);
      case CheckStatus.voided:
        return const Color(0xFFEF4444);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(status);

    return Column(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.dark
                ? theme.colorScheme.surface
                : theme.colorScheme.surfaceContainerHighest,
            shape: BoxShape.circle,
            border: Border.all(color: statusColor, width: 3),
          ),
        ),
        if (!isLast)
          Expanded(
            child: Container(width: 2, color: theme.colorScheme.outlineVariant),
          ),
      ],
    );
  }
}

class _CheckHistoryCard extends StatelessWidget {
  const _CheckHistoryCard({required this.check, required this.onTap});

  final Check check;
  final VoidCallback onTap;

  String _formatTime(DateTime dt) {
    final hr = dt.hour.toString().padLeft(2, '0');
    final mn = dt.minute.toString().padLeft(2, '0');
    return '$hr:$mn';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Table ${check.tableNumber}',
                  style: TextStyle(
                    fontFamily: 'Hanken Grotesk',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: colors.onSurface,
                  ),
                ),
                Text(
                  _formatTime(check.openedAt),
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: colors.outline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'ID: ${check.id.toUpperCase()}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: colors.outlineVariant),
                  ),
                  child: Text(
                    check.status.name.toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(height: 1, color: colors.outlineVariant),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${check.serverName} · ${check.covers} pax',
                  style: TextStyle(
                    fontFamily: 'Hanken Grotesk',
                    fontSize: 12,
                    color: colors.outline,
                  ),
                ),
                Text(
                  '\$${check.total.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
