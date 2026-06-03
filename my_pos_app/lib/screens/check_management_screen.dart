import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:my_pos_app/models/pos_models.dart';
import 'package:my_pos_app/providers/pos_provider.dart';
import 'package:my_pos_app/screens/order_summary_screen.dart';
import 'package:my_pos_app/screens/order_entry_screen.dart';

/// The "Orders" tab — a live view of all open checks across the floor,
/// with real-time status tracking and quick actions.
class CheckManagementScreen extends StatefulWidget {
  const CheckManagementScreen({super.key});

  @override
  State<CheckManagementScreen> createState() => _CheckManagementScreenState();
}

class _CheckManagementScreenState extends State<CheckManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _checkStatusColor(CheckStatus status) {
    switch (status) {
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
    final provider = context.watch<POSProvider>();
    final openChecks = provider.openChecks;
    final savedChecks = provider.savedChecks;
    final closedChecks = provider.closedChecks;

    return Scaffold(
      backgroundColor: const Color(0xFF11131B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF11131B),
        automaticallyImplyLeading: false,
        title: const Text(
          'Check Management',
          style: TextStyle(
            fontFamily: 'Hanken Grotesk',
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFFE1E2ED),
          ),
        ),
        actions: [
          // Revenue pill
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9999),
              border: Border.all(
                color: const Color(0xFF22C55E).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.trending_up_rounded, size: 14, color: Color(0xFF22C55E)),
                const SizedBox(width: 4),
                Text(
                  '\$${closedChecks.fold<double>(0, (s, c) => s + c.total).toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF22C55E),
                  ),
                ),
              ],
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFF434655), width: 0.5),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF2563EB),
              indicatorWeight: 3,
              labelColor: const Color(0xFFB4C5FF),
              unselectedLabelColor: const Color(0xFFC3C6D7),
              labelStyle: const TextStyle(
                fontFamily: 'Hanken Grotesk',
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: const TextStyle(
                fontFamily: 'Hanken Grotesk',
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Active'),
                      if (openChecks.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: Text(
                            '${openChecks.length}',
                            style: const TextStyle(
                              fontFamily: 'JetBrains Mono',
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Saved'),
                      if (savedChecks.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B),
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: Text(
                            '${savedChecks.length}',
                            style: const TextStyle(
                              fontFamily: 'JetBrains Mono',
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Tab(text: 'Closed'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCheckList(openChecks, 'No active checks'),
          _buildCheckList(savedChecks, 'No saved checks'),
          _buildCheckList(closedChecks, 'No closed checks yet'),
        ],
      ),
    );
  }

  Widget _buildCheckList(List<Check> checks, String emptyMessage) {
    if (checks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.receipt_long_rounded,
              size: 56,
              color: Color(0xFF434655),
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: const TextStyle(
                fontFamily: 'Hanken Grotesk',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFFC3C6D7),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Checks will appear here as they are created',
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 12,
                color: Color(0xFF8D90A0),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: checks.length,
      itemBuilder: (context, index) {
        final check = checks[index];
        return _CheckCard(
          check: check,
          statusColor: _checkStatusColor(check.status),
          onTap: () {
            if (check.status == CheckStatus.open) {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => OrderSummaryScreen(checkId: check.id),
                ),
              );
            } else if (check.status == CheckStatus.saved) {
              _showRecallDialog(check);
            } else {
              _showClosedCheckDetail(check);
            }
          },
        );
      },
    );
  }

  void _showRecallDialog(Check check) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1D1F27),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Recall ${check.id}?',
            style: const TextStyle(
              fontFamily: 'Hanken Grotesk',
              fontWeight: FontWeight.w700,
              color: Color(0xFFE1E2ED),
            ),
          ),
          content: Text(
            'This will reopen the saved check for Table ${check.tableNumber} (${check.items.length} items, \$${check.subtotal.toStringAsFixed(2)}).',
            style: const TextStyle(
              fontFamily: 'Hanken Grotesk',
              color: Color(0xFFC3C6D7),
            ),
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
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
              ),
              child: const Text('Recall Check'),
            ),
          ],
        );
      },
    );
  }

  void _showClosedCheckDetail(Check check) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1D1F27),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            24, 24, 24,
            MediaQuery.of(ctx).padding.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    check.id,
                    style: const TextStyle(
                      fontFamily: 'Hanken Grotesk',
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFE1E2ED),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(9999),
                      border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.5)),
                    ),
                    child: const Text(
                      'CLOSED',
                      style: TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF22C55E),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _DetailRow('Table', '${check.tableNumber}'),
              _DetailRow('Server', check.serverName),
              _DetailRow('Covers', '${check.covers}'),
              _DetailRow('Duration', check.duration),
              _DetailRow('Payment', check.paymentMethod),
              const Divider(color: Color(0xFF434655), height: 32),
              _DetailRow('Subtotal', '\$${check.subtotal.toStringAsFixed(2)}'),
              _DetailRow('Tax', '\$${check.tax.toStringAsFixed(2)}'),
              _DetailRow('Tip', '\$${check.tip.toStringAsFixed(2)}'),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TOTAL',
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFE1E2ED),
                    ),
                  ),
                  Text(
                    '\$${check.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontFamily: 'Hanken Grotesk',
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF22C55E),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CheckCard extends StatelessWidget {
  const _CheckCard({
    required this.check,
    required this.statusColor,
    required this.onTap,
  });

  final Check check;
  final Color statusColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1D1F27),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF434655).withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            // Status strip
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          // Table badge
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: statusColor.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '${check.tableNumber}',
                                style: TextStyle(
                                  fontFamily: 'Hanken Grotesk',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                check.id,
                                style: const TextStyle(
                                  fontFamily: 'JetBrains Mono',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFE1E2ED),
                                ),
                              ),
                              Text(
                                '${check.covers} covers · ${check.duration}',
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '\$${check.total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontFamily: 'Hanken Grotesk',
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFB4C5FF),
                            ),
                          ),
                          Text(
                            '${check.items.length} items',
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
                  if (check.items.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    // First few items preview
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: check.items.take(3).map((item) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF191B23),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${item.name} ×${item.quantity}',
                            style: const TextStyle(
                              fontFamily: 'JetBrains Mono',
                              fontSize: 10,
                              color: Color(0xFFC3C6D7),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    if (check.items.length > 3)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '+${check.items.length - 3} more items',
                          style: const TextStyle(
                            fontFamily: 'JetBrains Mono',
                            fontSize: 10,
                            color: Color(0xFF8D90A0),
                          ),
                        ),
                      ),
                  ],
                  // Server badge
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.person_outline_rounded, size: 14, color: Color(0xFF8D90A0)),
                      const SizedBox(width: 4),
                      Text(
                        check.serverName,
                        style: const TextStyle(
                          fontFamily: 'Hanken Grotesk',
                          fontSize: 12,
                          color: Color(0xFF8D90A0),
                        ),
                      ),
                      if (check.paymentMethod.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        const Icon(Icons.payment_rounded, size: 14, color: Color(0xFF8D90A0)),
                        const SizedBox(width: 4),
                        Text(
                          check.paymentMethod,
                          style: const TextStyle(
                            fontFamily: 'Hanken Grotesk',
                            fontSize: 12,
                            color: Color(0xFF8D90A0),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
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
            style: const TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFFE1E2ED),
            ),
          ),
        ],
      ),
    );
  }
}
