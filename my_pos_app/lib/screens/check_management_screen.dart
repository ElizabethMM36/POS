import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:my_pos_app/models/pos_models.dart';
import 'package:my_pos_app/providers/pos_provider.dart';
import 'package:my_pos_app/screens/order_summary_screen.dart';

/// An elegant web-inspired Dashboard screen that renders the ticket pipeline
/// like a structural HTML/CSS management platform.
class CheckManagementScreen extends StatefulWidget {
  const CheckManagementScreen({super.key});

  @override
  State<CheckManagementScreen> createState() => _CheckManagementScreenState();
}

class _CheckManagementScreenState extends State<CheckManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Color _checkStatusColor(CheckStatus status) {
    switch (status) {
      case CheckStatus.open:
        return const Color(0xFF22C55E); // success-green
      case CheckStatus.saved:
        return const Color(0xFFF59E0B); // warning-amber
      case CheckStatus.closed:
        return const Color(0xFF3B82F6); // primary-blue
      case CheckStatus.voided:
        return const Color(0xFFEF4444); // destructive-red
    }
  }

  List<Check> _filterChecks(List<Check> checks) {
    if (_searchQuery.isEmpty) return checks;
    final lowercaseQuery = _searchQuery.toLowerCase();
    return checks.where((check) {
      final matchesId = check.id.toLowerCase().contains(lowercaseQuery);
      final matchesTable = check.tableNumber.toString().contains(_searchQuery);
      final matchesServer = check.serverName.toLowerCase().contains(
        lowercaseQuery,
      );
      return matchesId || matchesTable || matchesServer;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<POSProvider>();
    final openChecks = _filterChecks(provider.openChecks);
    final savedChecks = _filterChecks(provider.savedChecks);
    final closedChecks = _filterChecks(provider.closedChecks);

    return Scaffold(
      backgroundColor: const Color(
        0xFF0F172A,
      ), // Tailwinds Slate-900 background
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B), // Slate-800 Navbar header
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            const Icon(
              Icons.dashboard_customize_outlined,
              color: Color(0xFF94A3B8),
              size: 22,
            ),
            const SizedBox(width: 10),
            const Text(
              'Check Pipeline',
              style: TextStyle(
                fontFamily: 'Hanken Grotesk',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFFF8FAFC),
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Container(
            color: const Color(0xFF1E293B),
            child: Column(
              children: [
                // Clean HTML Input-Group style row
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: const Color(0xFF334155),
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val),
                      style: const TextStyle(
                        color: Color(0xFFF1F5F9),
                        fontFamily: 'JetBrains Mono',
                        fontSize: 13,
                      ),
                      decoration: InputDecoration(
                        hintText:
                            'Filter checks by reference ID, table ID, or server name...',
                        hintStyle: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 13,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          size: 16,
                          color: Color(0xFF64748B),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.cancel_rounded,
                                  size: 16,
                                  color: Color(0xFF64748B),
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
                // Tab Navigation bar styled like a fluid web nav-strip
                Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Color(0xFF334155), width: 1),
                    ),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: false,
                    indicatorColor: const Color(0xFF3B82F6), // Accent Blue line
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicatorWeight: 3,
                    labelColor: const Color(0xFF3B82F6),
                    unselectedLabelColor: const Color(0xFF94A3B8),
                    dividerColor: Colors.transparent,
                    labelStyle: const TextStyle(
                      fontFamily: 'Hanken Grotesk',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontFamily: 'Hanken Grotesk',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    tabs: [
                      Tab(text: 'Active Session (${openChecks.length})'),
                      Tab(text: 'Saved / Hold (${savedChecks.length})'),
                      Tab(text: 'Settled Vault (${closedChecks.length})'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDataViewGrid(openChecks, 'No active system tickets found'),
          _buildDataViewGrid(savedChecks, 'No held pipeline checks found'),
          _buildDataViewGrid(closedChecks, 'No cleared historical files found'),
        ],
      ),
    );
  }

  Widget _buildDataViewGrid(List<Check> checks, String emptyStatePrompt) {
    if (checks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.layers_clear_outlined,
              size: 40,
              color: Color(0xFF475569),
            ),
            const SizedBox(height: 12),
            Text(
              emptyStatePrompt,
              style: const TextStyle(
                fontFamily: 'Hanken Grotesk',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );
    }

    final double screenWidth = MediaQuery.of(context).size.width;
    final int crossAxisCount = screenWidth > 768
        ? 3
        : (screenWidth > 480 ? 2 : 1);

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: checks.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        mainAxisExtent: 185,
      ),
      itemBuilder: (context, index) {
        final check = checks[index];
        return _CheckCard(
          check: check,
          statusColor: _checkStatusColor(check.status),
          onModify: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => OrderSummaryScreen(checkId: check.id),
              ),
            );
          },
          onRecall: () => _showRecallDialog(check),
          onViewArchive: () => _showClosedCheckDetail(check),
          onVoid: () => _showVoidCheckDialog(check),
        );
      },
    );
  }

  void _showRecallDialog(Check check) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          title: Text(
            'Pipeline Event: Recall Check ${check.id}?',
            style: const TextStyle(
              fontFamily: 'Hanken Grotesk',
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Color(0xFFF8FAFC),
            ),
          ),
          content: Text(
            'Re-opening this held statement restores operational workflows for Table ${check.tableNumber}.',
            style: const TextStyle(
              fontFamily: 'Hanken Grotesk',
              fontSize: 14,
              color: Color(0xFF94A3B8),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'ABORT',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: const Color(0xFF0F172A),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                context.read<POSProvider>().recallCheck(check.id);
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => OrderSummaryScreen(checkId: check.id),
                  ),
                );
              },
              child: const Text(
                'RESTORE FLOW',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  fontFamily: 'Hanken Grotesk',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showVoidCheckDialog(Check check) {
    final TextEditingController reasonController = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          title: Text(
            'Void Check ${check.id}?',
            style: const TextStyle(
              fontFamily: 'Hanken Grotesk',
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Color(0xFFF8FAFC),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Table ${check.tableNumber} · \$${check.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontFamily: 'Hanken Grotesk',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Reason for void:',
                style: const TextStyle(
                  fontFamily: 'Hanken Grotesk',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFF1F5F9),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: reasonController,
                style: const TextStyle(
                  color: Color(0xFFF1F5F9),
                  fontFamily: 'JetBrains Mono',
                  fontSize: 12,
                ),
                decoration: InputDecoration(
                  hintText:
                      'e.g., Wrong order, customer request, system error...',
                  hintStyle: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(
                      color: Color(0xFF334155),
                      width: 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(
                      color: Color(0xFF334155),
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(
                      color: Color(0xFF3B82F6),
                      width: 1,
                    ),
                  ),
                ),
                maxLines: 3,
                minLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'CANCEL',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              onPressed: () {
                final reason = reasonController.text.trim();
                if (reason.isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Please provide a reason for voiding the check',
                      ),
                      backgroundColor: Color(0xFFEF4444),
                    ),
                  );
                  return;
                }
                Navigator.pop(ctx);
                context.read<POSProvider>().voidCheck(check.id, reason: reason);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Check ${check.id} voided: \$reason'),
                    backgroundColor: const Color(0xFFEF4444),
                  ),
                );
              },
              child: const Text(
                'VOID CHECK',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  fontFamily: 'Hanken Grotesk',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showClosedCheckDetail(Check check) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'System Log Matrix // ID: ${check.id}',
                style: const TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFF8FAFC),
                ),
              ),
              const SizedBox(height: 20),
              _DetailRow(
                'Target Index Location',
                'Table Slot ${check.tableNumber}',
              ),
              _DetailRow('Authenticated Operator', check.serverName),
              _DetailRow(
                'Financial Liquidation Total',
                '\$${check.total.toStringAsFixed(2)}',
              ),
              _DetailRow(
                'Settlement Gateway Protocol',
                check.paymentMethod.isNotEmpty ? check.paymentMethod : 'N/A',
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 40,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF334155)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'DISMISS PROFILE OVERLAY',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontFamily: 'Hanken Grotesk',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
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
}

/// A highly-structured data component resembling a dashboard container
/// block with clear borders and explicit flex layouts.
class _CheckCard extends StatelessWidget {
  final Check check;
  final Color statusColor;
  final VoidCallback onModify;
  final VoidCallback onRecall;
  final VoidCallback onViewArchive;
  final VoidCallback onVoid;

  const _CheckCard({
    required this.check,
    required this.statusColor,
    required this.onModify,
    required this.onRecall,
    required this.onViewArchive,
    required this.onVoid,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), // CSS Card BG
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF334155), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Flat HTML Card Header Component
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge Container element mapping Status
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'T${check.tableNumber}',
                        style: TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: statusColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          check.id,
                          style: const TextStyle(
                            fontFamily: 'JetBrains Mono',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFF1F5F9),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${check.covers} Pax · ${check.duration}',
                          style: const TextStyle(
                            fontFamily: 'Hanken Grotesk',
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Financial Flex Row Alignments
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${check.total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFF1F5F9),
                      ),
                    ),
                    Text(
                      '${check.items.length} units',
                      style: const TextStyle(
                        fontFamily: 'Hanken Grotesk',
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Inner Row Content block parsing ordered items
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: check.items.isEmpty
                  ? const Text(
                      'Session buffer clear.',
                      style: TextStyle(
                        color: Color(0xFF475569),
                        fontSize: 11,
                        fontFamily: 'JetBrains Mono',
                      ),
                    )
                  : Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: check.items.take(3).map((item) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(
                              color: const Color(0xFF334155),
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            '${item.name} (x${item.quantity})',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'JetBrains Mono',
                              fontSize: 10,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
            ),
          ),

          // Precise Divider Break lines mimicking border-t rule
          const Divider(color: Color(0xFF334155), height: 1, thickness: 1),

          // HTML-Footer status row grouping operation handlers
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: const Color(0xFF131D31), // Darker structural footer
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.account_circle_outlined,
                      size: 14,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      check.serverName,
                      style: const TextStyle(
                        fontFamily: 'Hanken Grotesk',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (check.status == CheckStatus.open)
                      Row(
                        children: [
                          _buildHtmlActionButton(
                            label: 'Manage Order',
                            backgroundColor: const Color(
                              0xFF2563EB,
                            ), // Tailwind Blue-600
                            textColor: Colors.white,
                            onPressed: onModify,
                          ),
                          const SizedBox(width: 6),
                          _buildHtmlActionButton(
                            label: 'Void Check',
                            backgroundColor: const Color(
                              0xFFEF4444,
                            ), // Tailwind Red-600
                            textColor: Colors.white,
                            onPressed: onVoid,
                          ),
                        ],
                      )
                    else if (check.status == CheckStatus.saved)
                      _buildHtmlActionButton(
                        label: 'Recall Ticket',
                        backgroundColor: const Color(
                          0xFFD97706,
                        ), // Tailwind Amber-600
                        textColor: Colors.white,
                        onPressed: onRecall,
                      )
                    else
                      _buildHtmlActionButton(
                        label: 'Review Vault',
                        backgroundColor: const Color(
                          0xFF475569,
                        ), // Tailwind Slate-600
                        textColor: const Color(0xFFF1F5F9),
                        onPressed: onViewArchive,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHtmlActionButton({
    required String label,
    required Color backgroundColor,
    required Color textColor,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 26,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: 0,

          padding: const EdgeInsets.symmetric(horizontal: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Hanken Grotesk',
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Hanken Grotesk',
              fontSize: 13,
              color: Color(0xFF94A3B8),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFFF1F5F9),
            ),
          ),
        ],
      ),
    );
  }
}
