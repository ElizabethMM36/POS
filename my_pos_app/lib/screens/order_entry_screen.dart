import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:my_pos_app/models/pos_models.dart';
import 'package:my_pos_app/providers/pos_provider.dart';
import 'package:my_pos_app/screens/order_summary_screen.dart';

/// High-velocity order entry screen with category tabs, visual menu grid,
/// and a live ticket sidebar that collapses on mobile into a bottom sheet.
class OrderEntryScreen extends StatefulWidget {
  const OrderEntryScreen({
    super.key,
    required this.tableNumber,
    this.checkId,
  });

  final int tableNumber;
  final String? checkId;

  @override
  State<OrderEntryScreen> createState() => _OrderEntryScreenState();
}

class _OrderEntryScreenState extends State<OrderEntryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late String _activeCheckId;
  int _selectedCourse = 1;
  final List<OrderItem> _pendingItems = [];

  static const _categories = MenuCategory.values;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);

    final provider = context.read<POSProvider>();
    if (widget.checkId != null) {
      _activeCheckId = widget.checkId!;
    } else {
      // Create a new check or get the existing one
      final existingCheck = provider.getCheckForTable(widget.tableNumber);
      if (existingCheck != null) {
        _activeCheckId = existingCheck.id;
      } else {
        _activeCheckId = provider.createCheck(
          tableNumber: widget.tableNumber,
          covers: provider.getTableByNumber(widget.tableNumber)?.covers ?? 1,
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _addItem(MenuItem menuItem) {
    HapticFeedback.lightImpact();
    setState(() {
      // Check if item already in pending list for same course
      final existingIdx = _pendingItems.indexWhere(
        (i) => i.name == menuItem.name && i.courseNumber == _selectedCourse,
      );
      if (existingIdx >= 0) {
        _pendingItems[existingIdx].quantity++;
      } else {
        _pendingItems.add(OrderItem(
          name: menuItem.name,
          quantity: 1,
          courseNumber: _selectedCourse,
          price: menuItem.price,
        ));
      }
    });
  }

  void _removeItem(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_pendingItems[index].quantity > 1) {
        _pendingItems[index].quantity--;
      } else {
        _pendingItems.removeAt(index);
      }
    });
  }

  void _fireToKitchen() {
    if (_pendingItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add items before firing to kitchen'),
          backgroundColor: Color(0xFF282A32),
        ),
      );
      return;
    }

    final provider = context.read<POSProvider>();
    for (final item in _pendingItems) {
      provider.addItemToCheck(_activeCheckId, item);
    }
    provider.fireCheckItems(_activeCheckId);

    HapticFeedback.heavyImpact();

    // Navigate to order summary
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => OrderSummaryScreen(checkId: _activeCheckId),
      ),
    );
  }

  void _showTicketSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1D1F27),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, controller) => _buildTicketContent(controller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<POSProvider>();
    final check = provider.getCheckById(_activeCheckId);
    final table = provider.getTableByNumber(widget.tableNumber);
    final pendingTotal = _pendingItems.fold<double>(0, (s, i) => s + i.total);

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
              'Table ${widget.tableNumber}',
              style: const TextStyle(
                fontFamily: 'Hanken Grotesk',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFFE1E2ED),
              ),
            ),
            if (check != null)
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
        actions: [
          // Course selector
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF282A32),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF434655)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _selectedCourse,
                isDense: true,
                dropdownColor: const Color(0xFF282A32),
                style: const TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFB4C5FF),
                ),
                items: List.generate(
                  3,
                  (i) => DropdownMenuItem(
                    value: i + 1,
                    child: Text('C${i + 1}'),
                  ),
                ),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCourse = val);
                },
              ),
            ),
          ),
          // Ticket count badge
          IconButton(
            onPressed: _showTicketSheet,
            icon: Badge(
              label: Text(
                '${_pendingItems.length}',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              ),
              isLabelVisible: _pendingItems.isNotEmpty,
              backgroundColor: const Color(0xFFEF4444),
              child: const Icon(Icons.receipt_rounded),
            ),
            color: const Color(0xFFB4C5FF),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(49),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFF434655), width: 0.5),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
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
              padding: const EdgeInsets.symmetric(horizontal: 8),
              tabs: _categories.map((cat) {
                return Tab(
                  child: Row(
                    children: [
                      Text(cat.icon),
                      const SizedBox(width: 6),
                      Text(cat.displayName),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _categories.map((cat) {
                final items = POSProvider.fullMenu
                    .where((m) => m.category == cat && m.isAvailable)
                    .toList();
                return _buildMenuGrid(items);
              }).toList(),
            ),
          ),
          // Sticky bottom fire button
          if (_pendingItems.isNotEmpty)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: const BoxDecoration(
                color: Color(0xFF191B23),
                border: Border(
                  top: BorderSide(color: Color(0xFF434655), width: 0.5),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    // Ticket summary
                    Expanded(
                      child: GestureDetector(
                        onTap: _showTicketSheet,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_pendingItems.length} ${_pendingItems.length == 1 ? 'item' : 'items'} · \$${pendingTotal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontFamily: 'Hanken Grotesk',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFE1E2ED),
                              ),
                            ),
                            const Text(
                              'Tap to review ticket',
                              style: TextStyle(
                                fontFamily: 'JetBrains Mono',
                                fontSize: 11,
                                color: Color(0xFFC3C6D7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Fire button
                    FilledButton.icon(
                      onPressed: _fireToKitchen,
                      icon: const Icon(Icons.local_fire_department_rounded, size: 20),
                      label: const Text(
                        'FIRE',
                        style: TextStyle(
                          fontFamily: 'Hanken Grotesk',
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMenuGrid(List<MenuItem> items) {
    if (items.isEmpty) {
      return const Center(
        child: Text(
          'No items in this category',
          style: TextStyle(
            fontFamily: 'Hanken Grotesk',
            fontSize: 16,
            color: Color(0xFFC3C6D7),
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.35,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        // Check how many of this item are in pending
        final pendingQty = _pendingItems
            .where((p) => p.name == item.name)
            .fold<int>(0, (s, p) => s + p.quantity);

        return _MenuItemCard(
          item: item,
          pendingQty: pendingQty,
          onTap: () => _addItem(item),
        );
      },
    );
  }

  Widget _buildTicketContent(ScrollController? controller) {
    final pendingTotal = _pendingItems.fold<double>(0, (s, i) => s + i.total);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF434655),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Draft Ticket',
                style: TextStyle(
                  fontFamily: 'Hanken Grotesk',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFE1E2ED),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(9999),
                  border: Border.all(color: const Color(0xFF2563EB)),
                ),
                child: Text(
                  'Course $_selectedCourse',
                  style: const TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFB4C5FF),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Items list
          Expanded(
            child: _pendingItems.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.restaurant_menu_rounded, size: 48, color: Color(0xFF434655)),
                        SizedBox(height: 12),
                        Text(
                          'No items yet',
                          style: TextStyle(
                            fontFamily: 'Hanken Grotesk',
                            fontSize: 16,
                            color: Color(0xFFC3C6D7),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Tap menu items to add them',
                          style: TextStyle(
                            fontFamily: 'JetBrains Mono',
                            fontSize: 12,
                            color: Color(0xFF8D90A0),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    controller: controller,
                    itemCount: _pendingItems.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final item = _pendingItems[index];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF191B23),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF434655).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Quantity badge
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  '${item.quantity}',
                                  style: const TextStyle(
                                    fontFamily: 'JetBrains Mono',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFB4C5FF),
                                  ),
                                ),
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
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFE1E2ED),
                                    ),
                                  ),
                                  Text(
                                    'C${item.courseNumber} · \$${item.total.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontFamily: 'JetBrains Mono',
                                      fontSize: 11,
                                      color: Color(0xFFC3C6D7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                _removeItem(index);
                                if (_pendingItems.isEmpty) Navigator.pop(context);
                              },
                              icon: const Icon(Icons.remove_circle_outline_rounded),
                              color: const Color(0xFFFFB4AB),
                              iconSize: 22,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 12),
          // Total + Fire
          if (_pendingItems.isNotEmpty) ...[
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
                    'Pending Total',
                    style: TextStyle(
                      fontFamily: 'Hanken Grotesk',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFC3C6D7),
                    ),
                  ),
                  Text(
                    '\$${pendingTotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontFamily: 'Hanken Grotesk',
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFB4C5FF),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(context); // close sheet
                _fireToKitchen();
              },
              icon: const Icon(Icons.local_fire_department_rounded),
              label: const Text(
                'FIRE TO KITCHEN',
                style: TextStyle(
                  fontFamily: 'Hanken Grotesk',
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _MenuItemCard extends StatefulWidget {
  const _MenuItemCard({
    required this.item,
    required this.pendingQty,
    required this.onTap,
  });

  final MenuItem item;
  final int pendingQty;
  final VoidCallback onTap;

  @override
  State<_MenuItemCard> createState() => _MenuItemCardState();
}

class _MenuItemCardState extends State<_MenuItemCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) {
        _scaleController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _scaleController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1D1F27),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.pendingQty > 0
                  ? const Color(0xFF2563EB)
                  : const Color(0xFF434655).withValues(alpha: 0.4),
              width: widget.pendingQty > 0 ? 2 : 1,
            ),
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Hanken Grotesk',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFE1E2ED),
                        height: 1.2,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '\$${widget.item.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontFamily: 'JetBrains Mono',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFB4C5FF),
                          ),
                        ),
                        Icon(
                          Icons.add_circle_rounded,
                          color: widget.pendingQty > 0
                              ? const Color(0xFF2563EB)
                              : const Color(0xFF434655),
                          size: 24,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Pending quantity badge
              if (widget.pendingQty > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB),
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Center(
                      child: Text(
                        '${widget.pendingQty}',
                        style: const TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
