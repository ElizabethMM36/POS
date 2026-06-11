import 'dart:ui';
import 'package:flutter/foundation.dart'; // Required for listEquals
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_pos_app/models/pos_models.dart';
import 'package:my_pos_app/providers/pos_provider.dart';
import 'package:my_pos_app/widgets/pos_background.dart';
import 'order_summary_screen.dart';

/// Categorization tags for shared service broadcasts
enum NotificationTag { kitchenAlert, promotion, serverNote }

extension NotificationTagExtension on NotificationTag {
  String get displayName {
    switch (this) {
      case NotificationTag.kitchenAlert:
        return 'Kitchen Alert';
      case NotificationTag.promotion:
        return 'Promotions';
      case NotificationTag.serverNote:
        return 'Server Note';
    }
  }
}

/// Data model representing shared runtime broadcast announcements or reminders.
class ServerNotification {
  final String id;
  final String text;
  final NotificationTag tag;
  final DateTime timestamp;

  ServerNotification({
    required this.id,
    required this.text,
    required this.tag,
    required this.timestamp,
  });
}

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key, required this.tableNumber});

  final int tableNumber;

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final List<OrderItem> _draftTicket = [];
  int _coversCount = 2; // Default to 2, avoids defaulting strictly to 1
  int _selectedCourse = 1;
  int _selectedSeat = 1;
  String _searchQuery = '';
  MenuCategory? _selectedCategory;

  // Track live active floor reminders or promotions with structured tags
  final List<ServerNotification> _notifications = [
    ServerNotification(
      id: '1',
      text: 'Soup of the Day: Creamy Roasted Tomato Basil',
      tag: NotificationTag.serverNote,
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    ServerNotification(
      id: '2',
      text: '86 Filet Mignon for the rest of the shift.',
      tag: NotificationTag.kitchenAlert,
      timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
    ),
    ServerNotification(
      id: '3',
      text: 'Promo Alert: 15% off all Desserts when paired with an Appetizer',
      tag: NotificationTag.promotion,
      timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
    ),
  ];

  @override
  void initState() {
    super.initState();
    final table = context.read<POSProvider>().getTableByNumber(
      widget.tableNumber,
    );
    if (table != null && table.covers > 0) {
      _coversCount = table.covers;
    }
  }

  /// Converts standard DateTime instances safely into clean localized formats
  String _formatTimestamp(DateTime dt) {
    final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final amPm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $amPm';
  }

  /// Displays the interactive Server Reminders Board directly in the middle of the screen
  void _showNotificationBoard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final mediaQuery = MediaQuery.of(context);
    final noteController = TextEditingController();
    NotificationTag selectedCreationTag = NotificationTag.serverNote;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              backgroundColor: cs.surfaceContainerHigh,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              // Use standard adaptive inset paddings to prevent emulator clipping
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 24,
              ),
              child: AnimatedPadding(
                padding: mediaQuery.viewInsets,
                duration: const Duration(milliseconds: 100),
                curve: Curves.decelerate,
                child: Container(
                  // Set a clear maximum width for desktop but allow complete shrinking on mobile
                  constraints: const BoxConstraints(maxWidth: 500),
                  padding: const EdgeInsets.all(20),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.campaign_rounded,
                                    color: cs.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Broadcasts & Specials',
                                      style: TextStyle(
                                        fontFamily: 'Hanken Grotesk',
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: cs.onSurface,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Active updates visible across terminal nodes',
                          style: TextStyle(
                            fontFamily: 'Hanken Grotesk',
                            color: cs.outline,
                            fontSize: 12,
                          ),
                        ),
                        const Divider(height: 24),

                        // Active entries log area
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            // Dynamically downscale max height if screen space is compromised
                            maxHeight: mediaQuery.viewInsets.bottom > 0
                                ? 120
                                : 220,
                          ),
                          child: _notifications.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 24.0,
                                  ),
                                  child: Center(
                                    child: Text(
                                      'No active broadcast tags configured.',
                                      style: TextStyle(
                                        color: cs.outline,
                                        fontFamily: 'Hanken Grotesk',
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  shrinkWrap: true,
                                  itemCount: _notifications.length,
                                  separatorBuilder: (_, __) =>
                                      const Divider(height: 1),
                                  itemBuilder: (context, idx) {
                                    final broadcast = _notifications[idx];

                                    Color tagBgColor = cs.secondaryContainer;
                                    Color tagTextColor =
                                        cs.onSecondaryContainer;
                                    if (broadcast.tag ==
                                        NotificationTag.kitchenAlert) {
                                      tagBgColor = cs.errorContainer;
                                      tagTextColor = cs.onErrorContainer;
                                    } else if (broadcast.tag ==
                                        NotificationTag.promotion) {
                                      tagBgColor = cs.primaryContainer;
                                      tagTextColor = cs.onPrimaryContainer;
                                    }

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8.0,
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 6,
                                                            vertical: 2,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: tagBgColor,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              4,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        broadcast
                                                            .tag
                                                            .displayName
                                                            .toUpperCase(),
                                                        style: TextStyle(
                                                          fontFamily:
                                                              'JetBrains Mono',
                                                          fontSize: 9,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: tagTextColor,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      _formatTimestamp(
                                                        broadcast.timestamp,
                                                      ),
                                                      style: TextStyle(
                                                        fontFamily:
                                                            'JetBrains Mono',
                                                        fontSize: 10,
                                                        color: cs.outline,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  broadcast.text,
                                                  style: const TextStyle(
                                                    fontFamily:
                                                        'Hanken Grotesk',
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              Icons.delete_outline_rounded,
                                              color: cs.error,
                                              size: 18,
                                            ),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            onPressed: () {
                                              setState(() {
                                                _notifications.removeWhere(
                                                  (n) => n.id == broadcast.id,
                                                );
                                              });
                                              setModalState(() {});
                                            },
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                        ),
                        const Divider(height: 24),

                        Text(
                          'BROADCAST A NEW REMINDER',
                          style: TextStyle(
                            fontFamily: 'JetBrains Mono',
                            fontSize: 11,
                            color: cs.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),

                        Wrap(
                          spacing: 6.0,
                          runSpacing: 6.0,
                          children: NotificationTag.values.map((tag) {
                            final isSelected = selectedCreationTag == tag;
                            return ChoiceChip(
                              label: Text(tag.displayName),
                              selected: isSelected,
                              onSelected: (val) {
                                if (val) {
                                  setModalState(
                                    () => selectedCreationTag = tag,
                                  );
                                }
                              },
                              labelStyle: TextStyle(
                                fontFamily: 'Hanken Grotesk',
                                fontSize: 11,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: noteController,
                                decoration: InputDecoration(
                                  hintText:
                                      'e.g., Soup of the day is Clam Chowder...',
                                  fillColor: cs.surfaceContainerLow,
                                  filled: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  hintStyle: TextStyle(
                                    color: cs.outline,
                                    fontSize: 13,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                style: const TextStyle(
                                  fontFamily: 'Hanken Grotesk',
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filled(
                              onPressed: () {
                                if (noteController.text.trim().isEmpty) return;
                                final newNote = ServerNotification(
                                  id: DateTime.now().millisecondsSinceEpoch
                                      .toString(),
                                  text: noteController.text.trim(),
                                  tag: selectedCreationTag,
                                  timestamp: DateTime.now(),
                                );
                                setState(() {
                                  _notifications.insert(0, newNote);
                                });
                                noteController.clear();
                                setModalState(() {});
                              },
                              style: IconButton.styleFrom(
                                backgroundColor: cs.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              icon: const Icon(Icons.playlist_add_rounded),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Updates quantity or instantiates new OrderItems.
  void _updateItemQuantity(
    String itemName,
    double price,
    int delta, {
    int? course,
    int? seat,
    List<String>? tags,
    int? absoluteQuantity,
  }) {
    setState(() {
      final targetCourse = course ?? _selectedCourse;
      final targetSeat = seat ?? _selectedSeat;
      final targetTags = tags ?? <String>[];

      final existingIndex = _draftTicket.indexWhere(
        (item) =>
            item.name == itemName &&
            item.courseNumber == targetCourse &&
            item.seatNumber == targetSeat &&
            listEquals(item.tags, targetTags),
      );

      if (existingIndex >= 0) {
        final newQty =
            absoluteQuantity ?? (_draftTicket[existingIndex].quantity + delta);
        if (newQty <= 0) {
          _draftTicket.removeAt(existingIndex);
        } else {
          _draftTicket[existingIndex].quantity = newQty;
        }
      } else {
        final initialQty = absoluteQuantity ?? delta;
        if (initialQty > 0) {
          _draftTicket.add(
            OrderItem(
              name: itemName,
              quantity: initialQty,
              courseNumber: targetCourse,
              seatNumber: targetSeat,
              price: price,
              status: OrderItemStatus.pending,
              tags: targetTags,
            ),
          );
        }
      }
    });
  }

  /// Displays an option menu/dialog to modify tags, allergies, and substitutions
  void _showItemCustomizationSheet(OrderItem item) {
    final cs = Theme.of(context).colorScheme;
    final textController = TextEditingController(
      text: item.tags.firstWhere((t) => !t.startsWith('⚠️ '), orElse: () => ''),
    );

    List<String> activeAllergies = item.tags
        .where((t) => t.startsWith('⚠️ '))
        .map((t) => t.replaceFirst('⚠️ ', ''))
        .toList();

    final commonAllergies = [
      'Nut Allergy',
      'Gluten Free',
      'Dairy Free',
      'No Garlic',
      'Shellfish Allergy',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Customize: ${item.name}',
                    style: const TextStyle(
                      fontFamily: 'Hanken Grotesk',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Course ${item.courseNumber} — Seat ${item.seatNumber}',
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      color: cs.outline,
                      fontSize: 12,
                    ),
                  ),
                  const Divider(height: 24),

                  Text(
                    'CRITICAL ALLERGY & DIETARY TAGS',
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 11,
                      color: cs.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: commonAllergies.map((allergy) {
                      final isSelected = activeAllergies.contains(allergy);
                      return FilterChip(
                        label: Text(allergy),
                        selected: isSelected,
                        selectedColor: cs.errorContainer,
                        checkmarkColor: cs.onErrorContainer,
                        labelStyle: TextStyle(
                          fontFamily: 'Hanken Grotesk',
                          fontSize: 12,
                          color: isSelected
                              ? cs.onErrorContainer
                              : cs.onSurface,
                        ),
                        onSelected: (bool selected) {
                          setModalState(() {
                            if (selected) {
                              activeAllergies.add(allergy);
                            } else {
                              activeAllergies.remove(allergy);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'PREPARATION SUBSTITUTIONS & NOTES',
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 11,
                      color: cs.outline,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: textController,
                    decoration: InputDecoration(
                      hintText:
                          'e.g., Sub fries for side salad, sauce on side...',
                      fillColor: cs.surfaceContainerLow,
                      hintStyle: TextStyle(color: cs.outline, fontSize: 13),
                    ),
                    style: const TextStyle(
                      fontFamily: 'Hanken Grotesk',
                      fontSize: 14,
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: TextStyle(color: cs.outline),
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: () {
                          setState(() {
                            final finalTags = activeAllergies
                                .map((a) => '⚠️ $a')
                                .toList();
                            if (textController.text.trim().isNotEmpty) {
                              finalTags.add(textController.text.trim());
                            }
                            item.tags = finalTags;
                          });
                          Navigator.pop(context);
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: cs.primary,
                        ),
                        child: const Text(
                          'Apply Changes',
                          style: TextStyle(fontFamily: 'Hanken Grotesk'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  double get _subtotal =>
      _draftTicket.fold(0.0, (sum, item) => sum + item.total);

  /// Shows the full order ticket as a bottom sheet
  void _showOrderTicketSheet(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Vibrant Active Gradient
    const primaryActiveGradient = LinearGradient(
      colors: [Color(0xFFFF6F43), Color(0xFFE64A19)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.75,
              minChildSize: 0.4,
              maxChildSize: 0.95,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    // Handle bar
                    Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 8),
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: cs.outlineVariant,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Order Ticket',
                            style: TextStyle(
                              fontFamily: 'Hanken Grotesk',
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: cs.onSurface,
                            ),
                          ),
                          Text(
                            '${_draftTicket.length} item${_draftTicket.length == 1 ? '' : 's'}',
                            style: TextStyle(
                              fontFamily: 'JetBrains Mono',
                              fontSize: 12,
                              color: cs.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Divider(color: cs.outlineVariant),
                    ),
                    // Items list
                    Expanded(
                      child: _draftTicket.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.receipt_long_outlined,
                                    size: 48,
                                    color: cs.outlineVariant,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No items added yet',
                                    style: TextStyle(
                                      fontFamily: 'Hanken Grotesk',
                                      color: cs.outline,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Tap menu items to add them here',
                                    style: TextStyle(
                                      fontFamily: 'Hanken Grotesk',
                                      color: cs.outlineVariant,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              controller: scrollController,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              itemCount: _draftTicket.length,
                              separatorBuilder: (_, __) =>
                                  Divider(height: 1, color: cs.outlineVariant),
                              itemBuilder: (context, idx) {
                                final item = _draftTicket[idx];

                                // Generate local controller instance tied directly to loop iteration metrics
                                final qtyController = TextEditingController(
                                  text: '${item.quantity}',
                                );

                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 4,
                                  ),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _showItemCustomizationSheet(item);
                                  },
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.name,
                                          style: const TextStyle(
                                            fontFamily: 'Hanken Grotesk',
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      Icon(
                                        Icons.edit_note_rounded,
                                        size: 18,
                                        color: cs.primary,
                                      ),
                                      const SizedBox(width: 8),

                                      // Sleek Inline Direct-Edit Text Field Container
                                      Container(
                                        width: 44,
                                        height: 28,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: cs.primaryContainer.withAlpha(
                                            140,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: TextFormField(
                                          controller: qtyController,
                                          keyboardType: TextInputType.number,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontFamily: 'JetBrains Mono',
                                            color: cs.onPrimaryContainer,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                          decoration: const InputDecoration(
                                            isDense: true,
                                            contentPadding: EdgeInsets.zero,
                                            border: InputBorder.none,
                                            prefixText: 'x',
                                            prefixStyle: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.normal,
                                            ),
                                          ),
                                          onTap: () {
                                            // Auto-select text on tap for immediate overwriting
                                            qtyController.selection =
                                                TextSelection(
                                                  baseOffset: 0,
                                                  extentOffset:
                                                      qtyController.text.length,
                                                );
                                          },
                                          onChanged: (val) {
                                            final parsed = int.tryParse(
                                              val.trim(),
                                            );
                                            if (parsed != null) {
                                              _updateItemQuantity(
                                                item.name,
                                                item.price,
                                                0,
                                                course: item.courseNumber,
                                                seat: item.seatNumber,
                                                tags: item.tags,
                                                absoluteQuantity: parsed,
                                              );
                                              // Keeps sheet calculation references updated in real time
                                              setSheetState(() {});
                                            }
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 2),
                                      Text(
                                        'Course ${item.courseNumber} — Seat ${item.seatNumber}',
                                        style: TextStyle(
                                          fontFamily: 'JetBrains Mono',
                                          fontSize: 11,
                                          color: cs.outline,
                                        ),
                                      ),
                                      if (item.tags.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Wrap(
                                          spacing: 4,
                                          runSpacing: 4,
                                          children: item.tags.map((tag) {
                                            final isAllergy = tag.startsWith(
                                              '⚠️ ',
                                            );
                                            return Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: isAllergy
                                                    ? cs.errorContainer
                                                          .withValues(
                                                            alpha: 0.5,
                                                          )
                                                    : cs.secondaryContainer
                                                          .withValues(
                                                            alpha: 0.5,
                                                          ),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                tag,
                                                style: TextStyle(
                                                  fontFamily: 'Hanken Grotesk',
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: isAllergy
                                                      ? cs.error
                                                      : cs.onSecondaryContainer,
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ],
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '\$${item.total.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontFamily: 'JetBrains Mono',
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      IconButton(
                                        icon: Icon(
                                          Icons.remove_circle_outline,
                                          color: cs.error,
                                          size: 18,
                                        ),
                                        onPressed: () {
                                          _updateItemQuantity(
                                            item.name,
                                            item.price,
                                            -1,
                                            course: item.courseNumber,
                                            seat: item.seatNumber,
                                            tags: item.tags,
                                          );
                                          setSheetState(() {});
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                    // Footer: Subtotal + Send Order
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHigh,
                        border: Border(
                          top: BorderSide(color: cs.outlineVariant),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Subtotal',
                                style: TextStyle(
                                  fontFamily: 'Hanken Grotesk',
                                  color: cs.outline,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '\$${_subtotal.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontFamily: 'JetBrains Mono',
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: cs.onSurface,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: _draftTicket.isEmpty
                                    ? null
                                    : primaryActiveGradient,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: FilledButton.icon(
                                onPressed: _draftTicket.isEmpty
                                    ? null
                                    : () {
                                        Navigator.pop(context);
                                        final p = context.read<POSProvider>();
                                        p.dispatchOrderTicket(
                                          tableNumber: widget.tableNumber,
                                          covers: _coversCount,
                                          items: _draftTicket,
                                        );
                                        final activeCheck = p.getCheckForTable(
                                          widget.tableNumber,
                                        );
                                        if (activeCheck != null) {
                                          Navigator.of(context).pushReplacement(
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  OrderSummaryScreen(
                                                    checkId: activeCheck.id,
                                                  ),
                                            ),
                                          );
                                        }
                                      },
                                icon: const Icon(Icons.send_rounded),
                                label: const Text(
                                  'Send Order',
                                  style: TextStyle(
                                    fontFamily: 'Hanken Grotesk',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<POSProvider>();

    // Premium multi-toned active linear gradient state
    const primaryActiveGradient = LinearGradient(
      colors: [Color(0xFFFF6F43), Color(0xFFE64A19)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    final filteredMenu = provider.fullMenu.where((item) {
      final matchesCategory =
          _selectedCategory == null || item.category == _selectedCategory;
      final matchesSearch = item.name.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      return matchesCategory && matchesSearch;
    }).toList();

    // 1. Wrap the entire Scaffold inside POSBackground so it extends behind the App Bar
    return POSBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          // 2. Clear out the surfaceTintColor layer to fix scrolling glitch artifacts
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Table ${widget.tableNumber} — New Order',
            style: const TextStyle(
              fontFamily: 'Hanken Grotesk',
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    _notifications.isNotEmpty
                        ? Icons.notifications_active_rounded
                        : Icons.notifications_none_rounded,
                    color: _notifications.isNotEmpty
                        ? cs.onTertiaryContainer
                        : cs.onSurfaceVariant,
                  ),
                  onPressed: () => _showNotificationBoard(context),
                ),
                if (_notifications.isNotEmpty)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: cs.error,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 14,
                        minHeight: 14,
                      ),
                      child: Text(
                        '${_notifications.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontFamily: 'JetBrains Mono',
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
          ],
        ),
        // 3. Keep standard Stack body directly without duplicate POSBackground wrappers
        body: Stack(
          children: [
            Column(
              children: [
                // ── UNIFIED CONTROLS PANEL ──
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 8,
                  ),
                  decoration: BoxDecoration(
                    // Glass panel — white 72%, soft border, floating shadow
                    color: isDark
                        ? cs.surfaceContainer
                        : Colors.white.withOpacity(0.72),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? cs.outlineVariant
                          : Colors.white.withOpacity(0.60),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.15 : 0.06),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStandardSelector(
                        context: context,
                        label: 'COVERS',
                        value: '$_coversCount',
                        onDecrement: _coversCount > 1
                            ? () => setState(() {
                                _coversCount--;
                                if (_selectedSeat > _coversCount) {
                                  _selectedSeat = _coversCount;
                                }
                              })
                            : null,
                        onIncrement: () => setState(() => _coversCount++),
                      ),
                      Container(width: 1, height: 32, color: cs.outlineVariant),
                      _buildStandardSelector(
                        context: context,
                        label: 'COURSE',
                        value: 'C$_selectedCourse',
                        onDecrement: _selectedCourse > 1
                            ? () => setState(() => _selectedCourse--)
                            : null,
                        onIncrement: () => setState(() => _selectedCourse++),
                      ),
                      Container(width: 1, height: 32, color: cs.outlineVariant),
                      _buildStandardSelector(
                        context: context,
                        label: 'SEAT',
                        value: 'S$_selectedSeat',
                        onDecrement: _selectedSeat > 1
                            ? () => setState(() => _selectedSeat--)
                            : null,
                        onIncrement: _selectedSeat < _coversCount
                            ? () => setState(() => _selectedSeat++)
                            : null,
                      ),
                    ],
                  ),
                ),

                // ── Menu Area ─────────────────────────────────────────────────
                Expanded(
                  child: Container(
                    // Transparent — gradient shows through from POSBackground
                    color: Colors.transparent,
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Search bar — glass-tinted
                        TextField(
                          onChanged: (value) =>
                              setState(() => _searchQuery = value),
                          decoration: InputDecoration(
                            hintText: 'Search menu items...',
                            prefixIcon: const Icon(Icons.search),
                            fillColor: isDark
                                ? cs.surfaceContainer
                                : Colors.white.withOpacity(0.72),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 10,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Category tabs
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildTabButton(
                                label: 'All Items',
                                category: null,
                                context: context,
                                primaryActiveGradient: primaryActiveGradient,
                              ),
                              ...MenuCategory.values.map(
                                (cat) => _buildTabButton(
                                  label: cat.displayName,
                                  category: cat,
                                  context: context,
                                  primaryActiveGradient: primaryActiveGradient,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        // ── Menu Grid ──────────────────────────────────────────
                        Expanded(
                          child: filteredMenu.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No items found matching your selection.',
                                  ),
                                )
                              : GridView.builder(
                                  padding: const EdgeInsets.only(bottom: 120),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        childAspectRatio: 1.25,
                                        crossAxisSpacing: 12,
                                        mainAxisSpacing: 12,
                                      ),
                                  itemCount: filteredMenu.length,
                                  itemBuilder: (context, index) {
                                    final menuItem = filteredMenu[index];

                                    final activeSeatQty = _draftTicket
                                        .where(
                                          (i) =>
                                              i.name == menuItem.name &&
                                              i.courseNumber ==
                                                  _selectedCourse &&
                                              i.seatNumber == _selectedSeat,
                                        )
                                        .fold<int>(
                                          0,
                                          (prev, i) => prev + i.quantity,
                                        );

                                    final isActive = activeSeatQty > 0;
                                    return Container(
                                      decoration: BoxDecoration(
                                        // Glass card — white 72% or active-tinted
                                        color: isDark
                                            ? (isActive
                                                  ? cs.primaryContainer
                                                        .withOpacity(0.25)
                                                  : cs.surfaceContainerHigh)
                                            : (isActive
                                                  ? const Color(
                                                      0xFFFF6F43,
                                                    ).withOpacity(0.10)
                                                  : Colors.white.withOpacity(
                                                      0.72,
                                                    )),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isActive
                                              ? (isDark
                                                    ? cs.primary.withOpacity(
                                                        0.6,
                                                      )
                                                    : const Color(
                                                        0xFFFF6F43,
                                                      ).withOpacity(0.55))
                                              : (isDark
                                                    ? cs.outlineVariant
                                                    : Colors.white.withOpacity(
                                                        0.60,
                                                      )),
                                          width: isActive ? 1.5 : 1.0,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: isActive
                                                ? const Color(
                                                    0xFFFF6F43,
                                                  ).withOpacity(
                                                    isDark ? 0.15 : 0.08,
                                                  )
                                                : Colors.black.withOpacity(
                                                    isDark ? 0.15 : 0.05,
                                                  ),
                                            blurRadius: 16,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: InkWell(
                                        onTap: () => _updateItemQuantity(
                                          menuItem.name,
                                          menuItem.price,
                                          1,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        child: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  menuItem.name,
                                                  style: TextStyle(
                                                    fontFamily:
                                                        'Hanken Grotesk',
                                                    fontWeight: FontWeight.bold,
                                                    fontSize:
                                                        13, // Refined typography size to fit
                                                    color: cs.onSurface,
                                                    height: 1.2,
                                                  ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    '\$${menuItem.price.toStringAsFixed(2)}',
                                                    style: TextStyle(
                                                      fontFamily:
                                                          'JetBrains Mono',
                                                      color: cs
                                                          .onSurface, // High contrast
                                                      fontSize: 14,
                                                      fontWeight: FontWeight
                                                          .w900, // Bold price point for readability
                                                    ),
                                                  ),
                                                  if (activeSeatQty > 0)
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 3,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            cs.primaryContainer,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        'x$activeSeatQty',
                                                        style: TextStyle(
                                                          fontFamily:
                                                              'JetBrains Mono',
                                                          color: cs
                                                              .onPrimaryContainer,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
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
                  ),
                ),
              ],
            ),

            // ── FLOATING GLASSMORPHIC ACTION LAYER OVERLAY ──
            if (_draftTicket.isNotEmpty)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.only(
                        left: 20,
                        right: 20,
                        top: 16,
                        bottom: 32,
                      ),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerLowest.withOpacity(0.6),
                        border: Border(
                          top: BorderSide(
                            color: cs.outlineVariant.withOpacity(0.5),
                          ),
                        ),
                      ),
                      child: InkWell(
                        onTap: () => _showOrderTicketSheet(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient: primaryActiveGradient,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFE64A19).withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'View Order  •  \$${_subtotal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontFamily: 'Hanken Grotesk',
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Compact icon button used inside the controls bar
  Widget _buildSmallIconButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required ColorScheme cs,
  }) {
    return SizedBox(
      width: 26,
      height: 26,
      child: Material(
        color: onPressed == null
            ? cs.surfaceContainerHighest.withOpacity(0.4)
            : cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(6),
          child: Icon(
            icon,
            size: 16,
            color: onPressed == null ? cs.outlineVariant : cs.onSurface,
          ),
        ),
      ),
    );
  }

  /// Standardized consistent control layout for parameter settings
  Widget _buildStandardSelector({
    required BuildContext context,
    required String label,
    required String value,
    required VoidCallback? onDecrement,
    required VoidCallback? onIncrement,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 10,
            color: cs.outline,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSmallIconButton(
              icon: Icons.remove,
              onPressed: onDecrement,
              cs: cs,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Text(
                value,
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
            ),
            _buildSmallIconButton(
              icon: Icons.add,
              onPressed: onIncrement,
              cs: cs,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTabButton({
    required String label,
    required MenuCategory? category,
    required BuildContext context,
    required LinearGradient primaryActiveGradient,
  }) {
    final cs = Theme.of(context).colorScheme;
    final isSelected = _selectedCategory == category;
    final isDarkBtn = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: InkWell(
        onTap: () => setState(() => _selectedCategory = category),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            gradient: isSelected ? primaryActiveGradient : null,
            color: isSelected
                ? null
                : (isDarkBtn
                      ? cs.surfaceContainerHigh
                      : Colors.white.withOpacity(0.72)),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? Colors.transparent
                  : (isDarkBtn
                        ? cs.outlineVariant
                        : Colors.white.withOpacity(0.60)),
            ),
            boxShadow: isSelected
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDarkBtn ? 0.12 : 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : cs.onSurfaceVariant,
                fontFamily: 'JetBrains Mono',
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
