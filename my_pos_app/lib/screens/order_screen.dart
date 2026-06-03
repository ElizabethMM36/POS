import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:my_pos_app/models/pos_models.dart';
import 'package:my_pos_app/providers/pos_provider.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({
    super.key,
    required this.tableNumber,
  });

  final int tableNumber;

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _coversController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');

  String? _selectedMenuItem;
  int _selectedCourse = 1;
  final List<OrderItem> _draftTicket = [];

  static const List<String> _courseLabels = [
    'Course 1',
    'Course 2',
    'Course 3',
  ];

  @override
  void initState() {
    super.initState();
    final table =
        context.read<POSProvider>().getTableByNumber(widget.tableNumber);
    if (table != null && table.covers > 0) {
      _coversController.text = '${table.covers}';
    }
    _selectedMenuItem = POSProvider.menuItems.first;
  }

  @override
  void dispose() {
    _coversController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  int? _parsePositiveInt(String? value, {required String fieldLabel}) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final parsed = int.tryParse(value.trim());
    if (parsed == null || parsed < 1) {
      return null;
    }
    return parsed;
  }

  void _addToTicket() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final quantity = _parsePositiveInt(
      _quantityController.text,
      fieldLabel: 'Quantity',
    );
    if (quantity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Quantity must be a whole number of 1 or more.'),
        ),
      );
      return;
    }

    final menuItem = _selectedMenuItem;
    if (menuItem == null || menuItem.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a menu item.')),
      );
      return;
    }

    setState(() {
      _draftTicket.add(
        OrderItem(
          name: menuItem,
          quantity: quantity,
          courseNumber: _selectedCourse,
        ),
      );
    });

    _quantityController.text = '1';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added $menuItem to draft ticket.')),
    );
  }

  void _removeDraftItem(int index) {
    setState(() => _draftTicket.removeAt(index));
  }

  void _dispatchToKitchen() {
    final covers = _parsePositiveInt(
      _coversController.text,
      fieldLabel: 'Covers',
    );
    if (covers == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Covers must be a whole number of 1 or more.'),
        ),
      );
      return;
    }

    if (_draftTicket.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Add at least one item to the ticket before dispatching.',
          ),
        ),
      );
      return;
    }

    final provider = context.read<POSProvider>();
    provider.updateTableMetadata(
      widget.tableNumber,
      status: TableStatus.occupied,
      covers: covers,
      orders: List<OrderItem>.from(_draftTicket),
      replaceOrders: true,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Runner ticket dispatched for Table ${widget.tableNumber}.',
        ),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<POSProvider>();
    final outletName = provider.selectedOutlet?.name ?? 'Outlet';

    return Scaffold(
      appBar: AppBar(
        title: Text('Table ${widget.tableNumber} — $outletName'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _coversController,
                      decoration: const InputDecoration(
                        labelText: 'Covers (Pax)',
                        hintText: 'Number of guests',
                        prefixIcon: Icon(Icons.people_outline),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        final parsed = _parsePositiveInt(value, fieldLabel: 'Covers');
                        if (parsed == null) {
                          return 'Enter a valid guest count (1+)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedMenuItem,
                      decoration: const InputDecoration(
                        labelText: 'Menu item',
                        prefixIcon: Icon(Icons.menu_book_outlined),
                        border: OutlineInputBorder(),
                      ),
                      isExpanded: true,
                      items: POSProvider.menuItems
                          .map(
                            (item) => DropdownMenuItem<String>(
                              value: item,
                              child: Text(item, overflow: TextOverflow.ellipsis),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() => _selectedMenuItem = value);
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Select a menu item';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: _selectedCourse,
                      decoration: const InputDecoration(
                        labelText: 'Course number',
                        prefixIcon: Icon(Icons.layers_outlined),
                        border: OutlineInputBorder(),
                      ),
                      items: List<DropdownMenuItem<int>>.generate(
                        3,
                        (i) => DropdownMenuItem<int>(
                          value: i + 1,
                          child: Text(_courseLabels[i]),
                        ),
                      ),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedCourse = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(
                        labelText: 'Quantity',
                        prefixIcon: Icon(Icons.numbers),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        final parsed =
                            _parsePositiveInt(value, fieldLabel: 'Quantity');
                        if (parsed == null) {
                          return 'Enter a valid quantity (1+)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: _addToTicket,
                      icon: const Icon(Icons.add_shopping_cart),
                      label: const Text('Add to Ticket'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Draft ticket',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_draftTicket.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'No items yet. Add menu items above.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _draftTicket.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = _draftTicket[index];
                          return Card(
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              minVerticalPadding: 12,
                              title: Text(
                                item.name,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: Text(
                                'Qty ${item.quantity} · ${_courseLabels[item.courseNumber - 1]}',
                                style: theme.textTheme.labelMedium,
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline),
                                tooltip: 'Remove item',
                                onPressed: () => _removeDraftItem(index),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: FilledButton(
                onPressed: _dispatchToKitchen,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  backgroundColor: theme.colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'DISPATCH RUNNER TICKET TO KITCHEN',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
