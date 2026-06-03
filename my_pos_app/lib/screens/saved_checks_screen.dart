import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:my_pos_app/models/pos_models.dart';
import 'package:my_pos_app/providers/pos_provider.dart';
import 'package:my_pos_app/screens/order_summary_screen.dart';

/// The "Checks" tab — a timeline-style view of all check history,
/// with filters, search, and quick-recall for saved checks.
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
    final provider = context.watch<POSProvider>();
    final allChecks = provider.checks.toList()
      ..sort((a, b) => b.openedAt.compareTo(a.openedAt));

    final filteredChecks = allChecks.where((check) {
      if (_filterStatus != 'All') {
        if (_filterStatus == 'Open' && check.status != CheckStatus.open) return false;
        if (_filterStatus == 'Saved' && check.status != CheckStatus.saved) return false;
        if (_filterStatus == 'Closed' && check.status != CheckStatus.closed) return false;
        if (_filterStatus == 'Voided' && check.status != CheckStatus.voided) return false;
      }
      if (_searchController.text.isNotEmpty) {
        final query = _searchController.text.toLowerCase();
        return check.id.toLowerCase().contains(query) ||
            check.serverName.toLowerCase().contains(query) ||
            check.tableNumber.toString().contains(query);
      }
      return true;
    }).toList();

    // Stats
    final totalRevenue = allChecks
        .where((c) => c.status == CheckStatus.closed)
        .fold<double>(0, (s, c) => s + c.total);
    final avgCheck = allChecks.where((c) => c.status == CheckStatus.closed).isEmpty
        ? 0.0
        : totalRevenue / allChecks.where((c) => c.status == CheckStatus.closed).length;

    return Scaffold(
      backgroundColor: const Color(0xFF11131B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF11131B),
        automaticallyImplyLeading: false,
        title: const Text(
          'Check History',
          style: TextStyle(
            fontFamily: 'Hanken Grotesk',
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFFE1E2ED),
          ),
        ),
      ),
      body: Column(
        children: [
          // Stats bento
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _StatCard(
                  label: 'TOTAL REV',
                  value: '\$${totalRevenue.toStringAsFixed(0)}',
                  color: const Color(0xFF22C55E),
                  icon: Icons.trending_up_rounded,
                ),
                const SizedBox(width: 10),
                _StatCard(
                  label: 'AVG CHECK',
                  value: '\$${avgCheck.toStringAsFixed(0)}',
                  color: const Color(0xFFB4C5FF),
                  icon: Icons.analytics_outlined,
                ),
                const SizedBox(width: 10),
                _StatCard(
                  label: 'CHECKS',
                  value: '${allChecks.length}',
                  color: const Color(0xFFF59E0B),
                  icon: Icons.receipt_long_rounded,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1D1F27),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF434655).withValues(alpha: 0.3)),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(
                  fontFamily: 'Hanken Grotesk',
                  fontSize: 14,
                  color: Color(0xFFE1E2ED),
                ),
                decoration: const InputDecoration(
                  hintText: 'Search by ID, server, or table...',
                  hintStyle: TextStyle(
                    fontFamily: 'Hanken Grotesk',
                    color: Color(0xFF8D90A0),
                  ),
                  prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF8D90A0)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', 'Open', 'Saved', 'Closed', 'Voided'].map((filter) {
                  final isSelected = _filterStatus == filter;
                  int count = 0;
                  if (filter == 'All') count = allChecks.length;
                  if (filter == 'Open') count = provider.openChecks.length;
                  if (filter == 'Saved') count = provider.savedChecks.length;
                  if (filter == 'Closed') count = provider.closedChecks.length;
                  if (filter == 'Voided') count = allChecks.where((c) => c.status == CheckStatus.voided).length;

                  return GestureDetector(
                    onTap: () => setState(() => _filterStatus = filter),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                      child: Row(
                        children: [
                          Text(
                            filter,
                            style: TextStyle(
                              fontFamily: 'Hanken Grotesk',
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected
                                  ? const Color(0xFFEEEFFF)
                                  : const Color(0xFFC3C6D7),
                            ),
                          ),
                          if (count > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white.withValues(alpha: 0.2)
                                    : const Color(0xFF434655).withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(9999),
                              ),
                              child: Text(
                                '$count',
                                style: TextStyle(
                                  fontFamily: 'JetBrains Mono',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFFC3C6D7),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Check list
          Expanded(
            child: filteredChecks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.search_off_rounded, size: 48, color: Color(0xFF434655)),
                        const SizedBox(height: 12),
                        Text(
                          _searchController.text.isNotEmpty
                              ? 'No matching checks found'
                              : 'No checks in this category',
                          style: const TextStyle(
                            fontFamily: 'Hanken Grotesk',
                            fontSize: 16,
                            color: Color(0xFFC3C6D7),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredChecks.length,
                    itemBuilder: (context, index) {
                      final check = filteredChecks[index];
                      return _TimelineCheckCard(
                        check: check,
                        isFirst: index == 0,
                        isLast: index == filteredChecks.length - 1,
                        onTap: () => _handleCheckTap(check),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _handleCheckTap(Check check) {
    if (check.status == CheckStatus.saved) {
      // Recall
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1D1F27),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Recall Check?',
            style: TextStyle(
              fontFamily: 'Hanken Grotesk',
              fontWeight: FontWeight.w700,
              color: Color(0xFFE1E2ED),
            ),
          ),
          content: Text(
            'Reopen ${check.id} for Table ${check.tableNumber}?',
            style: const TextStyle(color: Color(0xFFC3C6D7)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFFC3C6D7))),
            ),
            FilledButton(
              onPressed: () {
                context.read<POSProvider>().recallCheck(check.id);
                Navigator.pop(ctx);
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => OrderSummaryScreen(checkId: check.id),
                  ),
                );
              },
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
              child: const Text('Recall'),
            ),
          ],
        ),
      );
    } else if (check.status == CheckStatus.open) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => OrderSummaryScreen(checkId: check.id),
        ),
      );
    }
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF191B23),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFF434655).withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Hanken Grotesk',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFF8D90A0),
                letterSpacing: 0.05,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineCheckCard extends StatelessWidget {
  const _TimelineCheckCard({
    required this.check,
    required this.isFirst,
    required this.isLast,
    required this.onTap,
  });

  final Check check;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;

  Color get _statusColor {
    switch (check.status) {
      case CheckStatus.open:
        return const Color(0xFF22C55E);
      case CheckStatus.saved:
        return const Color(0xFFF59E0B);
      case CheckStatus.closed:
        return const Color(0xFFB4C5FF);
      case CheckStatus.voided:
        return const Color(0xFFEF4444);
    }
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Timeline line + dot
            SizedBox(
              width: 32,
              child: Column(
                children: [
                  // Top line
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isFirst ? Colors.transparent : const Color(0xFF434655).withValues(alpha: 0.3),
                    ),
                  ),
                  // Dot
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _statusColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _statusColor.withValues(alpha: 0.4),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                  // Bottom line
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isLast ? Colors.transparent : const Color(0xFF434655).withValues(alpha: 0.3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Card
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1D1F27),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF434655).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    // Table badge
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'T${check.tableNumber}',
                          style: TextStyle(
                            fontFamily: 'JetBrains Mono',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _statusColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                check.id,
                                style: const TextStyle(
                                  fontFamily: 'JetBrains Mono',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFE1E2ED),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _statusColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  check.status.displayName.toUpperCase(),
                                  style: TextStyle(
                                    fontFamily: 'JetBrains Mono',
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: _statusColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${check.serverName} · ${check.covers} pax',
                                style: const TextStyle(
                                  fontFamily: 'Hanken Grotesk',
                                  fontSize: 12,
                                  color: Color(0xFF8D90A0),
                                ),
                              ),
                              Text(
                                '\$${check.total.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontFamily: 'JetBrains Mono',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFB4C5FF),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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
}
