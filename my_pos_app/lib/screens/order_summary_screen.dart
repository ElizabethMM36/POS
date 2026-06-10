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

  void _showDiscountDialog(BuildContext context, Check check) {
    final provider = context.read<POSProvider>();
    final customAmountController = TextEditingController();
    DiscountType? selectedType;
    // Capture theme colors here so they're accessible inside the builder
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.surfaceContainerHigh,
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
                  Text(
                    'Apply Discount',
                    style: TextStyle(
                      fontFamily: 'Hanken Grotesk',
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ...DiscountType.values.map((type) {
                    final isSelected = selectedType == type;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: () => setSheetState(() => selectedType = type),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? colors.primary.withValues(alpha: 0.15)
                                : colors.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? colors.primary
                                  : colors.outlineVariant,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? colors.primary
                                        : colors.outlineVariant,
                                    width: 2,
                                  ),
                                ),
                                child: isSelected
                                    ? Icon(
                                        Icons.check,
                                        size: 14,
                                        color: colors.primary,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                type.displayName,
                                style: TextStyle(
                                  fontFamily: 'Hanken Grotesk',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: colors.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 20),
                  if (selectedType != null) ...[
                    Text(
                      'Discount Amount',
                      style: TextStyle(
                        fontFamily: 'Hanken Grotesk',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: customAmountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                      ],
                      style: TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 14,
                        color: colors.onSurface,
                      ),
                      decoration: InputDecoration(
                        prefixText: '\$ ',
                        prefixStyle: TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 14,
                          color: colors.onSurfaceVariant,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: colors.outlineVariant),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: colors.outlineVariant),
                        ),
                        filled: true,
                        fillColor: colors.surfaceContainerLowest,
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: () {
                        final amount =
                            double.tryParse(customAmountController.text) ?? 0;
                        if (amount > 0 && selectedType != null) {
                          provider.applyDiscount(
                            widget.checkId,
                            amount: amount,
                            type: selectedType!,
                          );
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${selectedType!.displayName} discount of \$${amount.toStringAsFixed(2)} applied',
                              ),
                              backgroundColor: const Color(0xFF22C55E),
                            ),
                          );
                        }
                      },
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        backgroundColor: colors.primary,
                        foregroundColor: colors.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Apply Discount',
                        style: TextStyle(
                          fontFamily: 'Hanken Grotesk',
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showVoidDialog(BuildContext context) {
    final reasonController = TextEditingController();
    final colors = Theme.of(context).colorScheme;

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: colors.surfaceContainerHigh,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Void Check',
            style: TextStyle(
              fontFamily: 'Hanken Grotesk',
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: colors.onSurface,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Please provide a reason for voiding this check:',
                style: TextStyle(
                  fontFamily: 'Hanken Grotesk',
                  fontSize: 14,
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
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
                          side: BorderSide(color: colors.outlineVariant),
                          foregroundColor: colors.onSurfaceVariant,
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
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 13,
                  color: colors.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: 'Enter custom reason...',
                  hintStyle: TextStyle(
                    color: colors.outlineVariant,
                    fontFamily: 'JetBrains Mono',
                  ),
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: colors.outlineVariant),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: colors.outlineVariant),
                  ),
                  filled: true,
                  fillColor: colors.surfaceContainerLowest,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontFamily: 'Hanken Grotesk',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurfaceVariant,
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
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pop();
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
    final colors = Theme.of(context).colorScheme;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.surfaceContainerHigh,
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
                  Text(
                    'Close Check',
                    style: TextStyle(
                      fontFamily: 'Hanken Grotesk',
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'PAYMENT METHOD',
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurfaceVariant,
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
                                  ? colors.primary.withValues(alpha: 0.15)
                                  : colors.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? colors.primary
                                    : colors.outlineVariant,
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
                                      ? colors.primary
                                      : colors.onSurfaceVariant,
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
                                        ? colors.primary
                                        : colors.onSurfaceVariant,
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
                  Text(
                    'TIP AMOUNT',
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurfaceVariant,
                      letterSpacing: 0.05,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
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
                                color: colors.surfaceContainerLowest,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: colors.outlineVariant,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    pct,
                                    style: TextStyle(
                                      fontFamily: 'JetBrains Mono',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: colors.primary,
                                    ),
                                  ),
                                  Text(
                                    '\$$tipAmt',
                                    style: TextStyle(
                                      fontFamily: 'JetBrains Mono',
                                      fontSize: 10,
                                      color: colors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
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
                            style: TextStyle(
                              fontFamily: 'JetBrains Mono',
                              fontSize: 14,
                              color: colors.onSurface,
                            ),
                            decoration: InputDecoration(
                              prefixText: '\$ ',
                              prefixStyle: TextStyle(
                                fontFamily: 'JetBrains Mono',
                                fontSize: 14,
                                color: colors.onSurfaceVariant,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: colors.outlineVariant,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: colors.outlineVariant,
                                ),
                              ),
                              filled: true,
                              fillColor: colors.surfaceContainerLowest,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'TOTAL WITH TIP',
                          style: TextStyle(
                            fontFamily: 'JetBrains Mono',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colors.onSurfaceVariant,
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
                      Navigator.of(ctx).pop();
                      Navigator.of(context).pop();
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
    // Single theme resolution point — all child widgets reference this
    final colors = Theme.of(context).colorScheme;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;

    if (check == null) {
      return Scaffold(
        backgroundColor: scaffoldBg,
        body: Center(
          child: Text(
            'Check not found',
            style: TextStyle(color: colors.onSurface),
          ),
        ),
      );
    }

    final courseMap = <int, List<OrderItem>>{};
    for (final item in check.items) {
      courseMap.putIfAbsent(item.courseNumber, () => []).add(item);
    }
    final sortedCourses = courseMap.keys.toList()..sort();

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          color: colors.primary,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Table ${check.tableNumber} · Order Summary',
              style: TextStyle(
                fontFamily: 'Hanken Grotesk',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: colors.onSurface,
              ),
            ),
            Text(
              '${check.id.substring(0, 8).toUpperCase()} · ${check.covers} covers',
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 11,
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          Container(
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
              ],
            ),
          ),
          // Dropdown Menu for Administrative Control Workflows
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: colors.primary),
            color: colors.surfaceContainerHigh,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (value) {
              switch (value) {
                case 'discount':
                  _showDiscountDialog(context, check);
                  break;
                case 'remove_discount':
                  context.read<POSProvider>().removeDiscount(widget.checkId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Discount removed'),
                      backgroundColor: Color(0xFFF59E0B),
                    ),
                  );
                  break;
                case 'void':
                  _showVoidDialog(context);
                  break;
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'discount',
                child: Row(
                  children: [
                    const Icon(
                      Icons.local_offer_rounded,
                      color: Color(0xFF8B5CF6),
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Apply Discount',
                      style: TextStyle(
                        color: colors.onSurface,
                        fontFamily: 'Hanken Grotesk',
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'remove_discount',
                enabled: check.discount > 0,
                child: Row(
                  children: [
                    Icon(
                      Icons.close_rounded,
                      color: check.discount > 0
                          ? const Color(0xFFEF4444)
                          : colors.outlineVariant,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Remove Discount',
                      style: TextStyle(
                        color: check.discount > 0
                            ? colors.onSurface
                            : colors.outlineVariant,
                        fontFamily: 'Hanken Grotesk',
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(height: 1),
              const PopupMenuItem<String>(
                value: 'void',
                child: Row(
                  children: [
                    Icon(
                      Icons.block_rounded,
                      color: Color(0xFFEF4444),
                      size: 18,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Void Check',
                      style: TextStyle(
                        color: Color(0xFFEF4444),
                        fontFamily: 'Hanken Grotesk',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
                // Check info header card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colors.primary.withValues(alpha: 0.12),
                        colors.surfaceContainerLow,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.receipt_long_rounded,
                          color: colors.primary,
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
                              style: TextStyle(
                                fontFamily: 'Hanken Grotesk',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: colors.onSurface,
                              ),
                            ),
                            Text(
                              'Server: ${check.serverName}',
                              style: TextStyle(
                                fontFamily: 'JetBrains Mono',
                                fontSize: 12,
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Course sections with order items
                ...sortedCourses.map((courseNum) {
                  final courseItems = courseMap[courseNum]!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                                color: colors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'COURSE $courseNum',
                                style: TextStyle(
                                  fontFamily: 'JetBrains Mono',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: colors.primary,
                                  letterSpacing: 0.05,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                height: 1,
                                color: colors.outlineVariant.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ...courseItems.map(
                        (item) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: colors.surfaceContainer,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: colors.outlineVariant.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
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
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: 'Hanken Grotesk',
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: colors.onSurface,
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
                              const SizedBox(width: 8),
                              Text(
                                '\$${item.total.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontFamily: 'JetBrains Mono',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: colors.onSurface,
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

                // Totals breakdown card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colors.outlineVariant.withValues(alpha: 0.4),
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
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Divider(color: colors.outlineVariant),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'TOTAL',
                            style: TextStyle(
                              fontFamily: 'JetBrains Mono',
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: colors.onSurface,
                              letterSpacing: 0.05,
                            ),
                          ),
                          Text(
                            '\$${check.total.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontFamily: 'Hanken Grotesk',
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: colors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Symmetrical bottom action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          provider.updateTableStatus(
                            check.tableNumber,
                            status: TableStatus.readyForBill,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Check printed and sent to table'),
                              backgroundColor: Color(0xFF22C55E),
                            ),
                          );
                        },
                        icon: const Icon(Icons.print_rounded, size: 18),
                        label: const Text('Print Check'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          side: const BorderSide(color: Color(0xFF22C55E)),
                          foregroundColor: const Color(0xFF22C55E),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          provider.saveCheck(widget.checkId);
                          provider.updateTableStatus(
                            check.tableNumber,
                            status: TableStatus.readyForBill,
                          );
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Check saved and ready for bill'),
                              backgroundColor: Color(0xFFF59E0B),
                            ),
                          );
                        },
                        icon: const Icon(Icons.bookmark_add_rounded, size: 18),
                        label: const Text('Save Check'),
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
                const SizedBox(height: 16),

                // Dominant Close Check / payment trigger button
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
    final colors = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Hanken Grotesk',
            fontSize: 14,
            color: colors.onSurfaceVariant,
          ),
        ),
        Text(
          '${value < 0 ? '-' : ''}\$${value.abs().toStringAsFixed(2)}',
          style: TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor ?? colors.onSurface,
          ),
        ),
      ],
    );
  }
}
