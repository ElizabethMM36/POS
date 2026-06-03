import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:my_pos_app/models/pos_models.dart';
import 'package:my_pos_app/providers/pos_provider.dart';
import 'package:my_pos_app/screens/order_entry_screen.dart';

/// Post-fire confirmation screen showing the full check with item statuses,
/// totals breakdown, and action buttons for save/close/add-more workflows.
class OrderSummaryScreen extends StatefulWidget {
  const OrderSummaryScreen({super.key, required this.checkId});

  final String checkId;

  @override
  State<OrderSummaryScreen> createState() => _OrderSummaryScreenState();
}

class _OrderSummaryScreenState extends State<OrderSummaryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeIn = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOut));
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic),
        );
    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  Color _statusColor(OrderItemStatus status) {
    switch (status) {
      case OrderItemStatus.pending:
        return const Color(0xFFC3C6D7);
      case OrderItemStatus.fired:
        return const Color(0xFFF59E0B);
      case OrderItemStatus.preparing:
        return const Color(0xFFFF6B35);
      case OrderItemStatus.ready:
        return const Color(0xFF22C55E);
      case OrderItemStatus.served:
        return const Color(0xFFB4C5FF);
    }
  }

  IconData _statusIcon(OrderItemStatus status) {
    switch (status) {
      case OrderItemStatus.pending:
        return Icons.hourglass_empty_rounded;
      case OrderItemStatus.fired:
        return Icons.local_fire_department_rounded;
      case OrderItemStatus.preparing:
        return Icons.soup_kitchen_rounded;
      case OrderItemStatus.ready:
        return Icons.check_circle_rounded;
      case OrderItemStatus.served:
        return Icons.restaurant_rounded;
    }
  }

  void _showVoidDialog(BuildContext context) {
    final reasonController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1D1F27),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Void Check',
            style: TextStyle(
              fontFamily: 'Hanken Grotesk',
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFFE1E2ED),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Please provide a reason for voiding this check:',
                style: TextStyle(
                  fontFamily: 'Hanken Grotesk',
                  fontSize: 14,
                  color: Color(0xFFC3C6D7),
                ),
              ),
              const SizedBox(height: 16),
              // Quick reason buttons
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    [
                      'Wrong Order',
                      'Guest Cancellation',
                      'Duplicate',
                      'System Error',
                    ].map((reason) {
                      return OutlinedButton(
                        onPressed: () => reasonController.text = reason,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF434655)),
                          foregroundColor: const Color(0xFFC3C6D7),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          reason,
                          style: const TextStyle(
                            fontFamily: 'Hanken Grotesk',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                maxLines: 3,
                style: const TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 13,
                  color: Color(0xFFE1E2ED),
                ),
                decoration: InputDecoration(
                  hintText: 'Enter custom reason...',
                  hintStyle: const TextStyle(
                    color: Color(0xFF434655),
                    fontFamily: 'JetBrains Mono',
                  ),
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF434655)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF434655)),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF191B23),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontFamily: 'Hanken Grotesk',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFC3C6D7),
                ),
              ),
            ),
            FilledButton(
              onPressed: () {
                if (reasonController.text.isNotEmpty) {
                  context.read<POSProvider>().voidCheck(
                    widget.checkId,
                    reason: reasonController.text,
                  );
                  Navigator.of(ctx).pop(); // close dialog
                  Navigator.of(context).pop(); // back to floor
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Check ${widget.checkId} voided: ${reasonController.text}',
                      ),
                      backgroundColor: const Color(0xFFEF4444),
                    ),
                  );
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Void Check',
                style: TextStyle(
                  fontFamily: 'Hanken Grotesk',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showPaymentDialog(BuildContext context, Check check) {
    String selectedMethod = 'Card';
    final tipController = TextEditingController(text: '0');

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1D1F27),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Close Check',
                    style: TextStyle(
                      fontFamily: 'Hanken Grotesk',
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFE1E2ED),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Payment method selector
                  const Text(
                    'PAYMENT METHOD',
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFC3C6D7),
                      letterSpacing: 0.05,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: ['Card', 'Cash', 'Split'].map((method) {
                      final isSelected = selectedMethod == method;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setSheetState(() => selectedMethod = method),
                          child: Container(
                            margin: EdgeInsets.only(
                              right: method != 'Split' ? 8 : 0,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(
                                      0xFF2563EB,
                                    ).withValues(alpha: 0.2)
                                  : const Color(0xFF191B23),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF2563EB)
                                    : const Color(0xFF434655),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  method == 'Card'
                                      ? Icons.credit_card_rounded
                                      : method == 'Cash'
                                      ? Icons.payments_rounded
                                      : Icons.call_split_rounded,
                                  color: isSelected
                                      ? const Color(0xFFB4C5FF)
                                      : const Color(0xFFC3C6D7),
                                  size: 24,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  method,
                                  style: TextStyle(
                                    fontFamily: 'Hanken Grotesk',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? const Color(0xFFB4C5FF)
                                        : const Color(0xFFC3C6D7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  // Tip
                  const Text(
                    'TIP AMOUNT',
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFC3C6D7),
                      letterSpacing: 0.05,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Quick tip buttons
                      ...['15%', '18%', '20%'].map((pct) {
                        final percent = int.parse(pct.replaceAll('%', ''));
                        final tipAmt = (check.subtotal * percent / 100)
                            .toStringAsFixed(2);
                        return Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setSheetState(() {
                                tipController.text = tipAmt;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF191B23),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFF434655),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    pct,
                                    style: const TextStyle(
                                      fontFamily: 'JetBrains Mono',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFB4C5FF),
                                    ),
                                  ),
                                  Text(
                                    '\$$tipAmt',
                                    style: const TextStyle(
                                      fontFamily: 'JetBrains Mono',
                                      fontSize: 10,
                                      color: Color(0xFFC3C6D7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                      // Custom tip input
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: TextField(
                            controller: tipController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[\d.]'),
                              ),
                            ],
                            style: const TextStyle(
                              fontFamily: 'JetBrains Mono',
                              fontSize: 14,
                              color: Color(0xFFE1E2ED),
                            ),
                            decoration: InputDecoration(
                              prefixText: '\$ ',
                              prefixStyle: const TextStyle(
                                fontFamily: 'JetBrains Mono',
                                fontSize: 14,
                                color: Color(0xFFC3C6D7),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFF434655),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFF434655),
                                ),
                              ),
                              filled: true,
                              fillColor: const Color(0xFF191B23),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Total row
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF282A32),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'TOTAL WITH TIP',
                          style: TextStyle(
                            fontFamily: 'JetBrains Mono',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFC3C6D7),
                          ),
                        ),
                        Text(
                          '\$${(check.subtotal + check.tax + (double.tryParse(tipController.text) ?? 0)).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontFamily: 'Hanken Grotesk',
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF22C55E),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      final tip = double.tryParse(tipController.text) ?? 0;
                      context.read<POSProvider>().closeCheck(
                        widget.checkId,
                        paymentMethod: selectedMethod,
                        tip: tip,
                      );
                      Navigator.of(ctx).pop(); // close sheet
                      Navigator.of(context).pop(); // back to floor
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Check ${widget.checkId} closed via $selectedMethod',
                          ),
                          backgroundColor: const Color(0xFF22C55E),
                        ),
                      );
                    },
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      backgroundColor: const Color(0xFF22C55E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'PROCESS PAYMENT',
                      style: TextStyle(
                        fontFamily: 'Hanken Grotesk',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<POSProvider>();
    final check = provider.getCheckById(widget.checkId);

    if (check == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF11131B),
        body: Center(
          child: Text(
            'Check not found',
            style: TextStyle(color: Color(0xFFE1E2ED)),
          ),
        ),
      );
    }

    // Group items by course
    final courseMap = <int, List<OrderItem>>{};
    for (final item in check.items) {
      courseMap.putIfAbsent(item.courseNumber, () => []).add(item);
    }
    final sortedCourses = courseMap.keys.toList()..sort();

    return Scaffold(
      backgroundColor: const Color(0xFF11131B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF11131B),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          color: const Color(0xFFB4C5FF),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Table ${check.tableNumber} · Order Summary',
              style: const TextStyle(
                fontFamily: 'Hanken Grotesk',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFFE1E2ED),
              ),
            ),
            Text(
              '${check.id} · ${check.covers} covers',
              style: const TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 11,
                color: Color(0xFFC3C6D7),
              ),
            ),
          ],
        ),
        actions: [
          // Fire confirmed indicator
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(9999),
              border: Border.all(
                color: const Color(0xFF22C55E).withValues(alpha: 0.5),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: 14,
                  color: Color(0xFF22C55E),
                ),
                SizedBox(width: 4),
                Text(
                  'FIRED',
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF22C55E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeIn,
        child: SlideTransition(
          position: _slideUp,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Status timeline header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF2563EB).withValues(alpha: 0.15),
                        const Color(0xFF191B23),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.receipt_long_rounded,
                          color: Color(0xFFB4C5FF),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Opened ${check.duration} ago',
                              style: const TextStyle(
                                fontFamily: 'Hanken Grotesk',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFE1E2ED),
                              ),
                            ),
                            Text(
                              'Server: ${check.serverName}',
                              style: const TextStyle(
                                fontFamily: 'JetBrains Mono',
                                fontSize: 12,
                                color: Color(0xFFC3C6D7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Items by course
                ...sortedCourses.map((courseNum) {
                  final courseItems = courseMap[courseNum]!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Course header
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF2563EB,
                                ).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'COURSE $courseNum',
                                style: const TextStyle(
                                  fontFamily: 'JetBrains Mono',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFB4C5FF),
                                  letterSpacing: 0.05,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                height: 1,
                                color: const Color(
                                  0xFF434655,
                                ).withValues(alpha: 0.3),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Course items
                      ...courseItems.map(
                        (item) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1D1F27),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(
                                0xFF434655,
                              ).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              // Status indicator
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: _statusColor(
                                    item.status,
                                  ).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  _statusIcon(item.status),
                                  color: _statusColor(item.status),
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: const TextStyle(
                                        fontFamily: 'Hanken Grotesk',
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFFE1E2ED),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${item.status.displayName} · Qty ×${item.quantity}',
                                      style: TextStyle(
                                        fontFamily: 'JetBrains Mono',
                                        fontSize: 11,
                                        color: _statusColor(item.status),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '\$${item.total.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontFamily: 'JetBrains Mono',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFB4C5FF),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  );
                }),

                // Totals breakdown
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF191B23),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF434655).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      _TotalRow(label: 'Subtotal', value: check.subtotal),
                      const SizedBox(height: 8),
                      _TotalRow(label: 'Tax (8.5%)', value: check.tax),
                      if (check.discount > 0) ...[
                        const SizedBox(height: 8),
                        _TotalRow(
                          label: 'Discount',
                          value: -check.discount,
                          valueColor: const Color(0xFF22C55E),
                        ),
                      ],
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(color: Color(0xFF434655)),
                      ),
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
                              letterSpacing: 0.05,
                            ),
                          ),
                          Text(
                            '\$${check.total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontFamily: 'Hanken Grotesk',
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFB4C5FF),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Action buttons row
                Row(
                  children: [
                    // Add More Items
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute<void>(
                              builder: (_) => OrderEntryScreen(
                                tableNumber: check.tableNumber,
                                checkId: widget.checkId,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add More'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          side: const BorderSide(color: Color(0xFF2563EB)),
                          foregroundColor: const Color(0xFFB4C5FF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Save Check
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          provider.saveCheck(widget.checkId);
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Check saved for later recall'),
                              backgroundColor: Color(0xFFF59E0B),
                            ),
                          );
                        },
                        icon: const Icon(Icons.bookmark_add_rounded, size: 18),
                        label: const Text('Save'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          side: const BorderSide(color: Color(0xFFF59E0B)),
                          foregroundColor: const Color(0xFFF59E0B),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Void Check Button
                OutlinedButton.icon(
                  onPressed: () => _showVoidDialog(context),
                  icon: const Icon(Icons.block_rounded, size: 18),
                  label: const Text('Void Check'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    side: const BorderSide(color: Color(0xFFEF4444)),
                    foregroundColor: const Color(0xFFEF4444),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Close Check
                FilledButton.icon(
                  onPressed: () => _showPaymentDialog(context, check),
                  icon: const Icon(Icons.payment_rounded, size: 20),
                  label: const Text(
                    'CLOSE CHECK',
                    style: TextStyle(
                      fontFamily: 'Hanken Grotesk',
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    backgroundColor: const Color(0xFF22C55E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({required this.label, required this.value, this.valueColor});

  final String label;
  final double value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
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
          '${value < 0 ? '-' : ''}\$${value.abs().toStringAsFixed(2)}',
          style: TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor ?? const Color(0xFFE1E2ED),
          ),
        ),
      ],
    );
  }
}
