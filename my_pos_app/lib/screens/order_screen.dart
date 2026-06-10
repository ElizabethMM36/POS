import 'package:flutter/foundation.dart'; // Required for listEquals
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_pos_app/models/pos_models.dart';
import 'package:my_pos_app/providers/pos_provider.dart';
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
  int _coversCount = 1;
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

                        // FIX: Wrapped tags inside Wrap widget to cleanly scale to mobile lines
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
        final newQty = _draftTicket[existingIndex].quantity + delta;
        if (newQty <= 0) {
          _draftTicket.removeAt(existingIndex);
        } else {
          _draftTicket[existingIndex].quantity = newQty;
        }
      } else if (delta > 0) {
        _draftTicket.add(
          OrderItem(
            name: itemName,
            quantity: delta,
            courseNumber: targetCourse,
            seatNumber: targetSeat,
            price: price,
            status: OrderItemStatus.pending,
            tags: targetTags,
          ),
        );
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
                                      const SizedBox(width: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: cs.primaryContainer,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          'x${item.quantity}',
                                          style: TextStyle(
                                            fontFamily: 'JetBrains Mono',
                                            color: cs.onPrimaryContainer,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
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
                                            builder: (_) => OrderSummaryScreen(
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
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
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
    final provider = context.watch<POSProvider>();

    final filteredMenu = provider.fullMenu.where((item) {
      final matchesCategory =
          _selectedCategory == null || item.category == _selectedCategory;
      final matchesSearch = item.name.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      return matchesCategory && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
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
      // Floating "View Order" button
      floatingActionButton: _draftTicket.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showOrderTicketSheet(context),
              icon: const Icon(Icons.receipt_long_rounded),
              label: Text(
                'View Order  •  \$${_subtotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontFamily: 'Hanken Grotesk',
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 236, 239, 239),
                  fontSize: 14,
                ),
              ),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: Column(
        children: [
          // ── Controls Bar: Covers / Course / Seat ──────────────────────
          Container(
            color: cs.surfaceContainer,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                // COVERS
                _buildControlChip(
                  context: context,
                  label: 'COVERS',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildSmallIconButton(
                        icon: Icons.remove,
                        onPressed: _coversCount > 1
                            ? () => setState(() {
                                _coversCount--;
                                if (_selectedSeat > _coversCount) {
                                  _selectedSeat = _coversCount;
                                }
                              })
                            : null,
                        cs: cs,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$_coversCount',
                        style: TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(width: 6),
                      _buildSmallIconButton(
                        icon: Icons.add,
                        onPressed: () => setState(() => _coversCount++),
                        cs: cs,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // COURSE
                _buildControlChip(
                  context: context,
                  label: 'COURSE',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [1, 2, 3].map((c) {
                      final isSelected = _selectedCourse == c;
                      return Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedCourse = c),
                          child: Container(
                            width: 30,
                            height: 28,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? cs.primary
                                  : cs.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isSelected
                                    ? cs.primary
                                    : cs.outlineVariant,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'C$c',
                                style: TextStyle(
                                  fontFamily: 'JetBrains Mono',
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? cs.onTertiaryContainer
                                      : cs.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(width: 10),
                // SEAT
                _buildControlChip(
                  context: context,
                  label: 'SEAT',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildSmallIconButton(
                        icon: Icons.chevron_left,
                        onPressed: _selectedSeat > 1
                            ? () => setState(() => _selectedSeat--)
                            : null,
                        cs: cs,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$_selectedSeat',
                        style: TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: cs.onTertiaryContainer,
                        ),
                      ),
                      const SizedBox(width: 6),
                      _buildSmallIconButton(
                        icon: Icons.chevron_right,
                        onPressed: _selectedSeat < _coversCount
                            ? () => setState(() => _selectedSeat++)
                            : null,
                        cs: cs,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Menu Area ─────────────────────────────────────────────────
          Expanded(
            child: Container(
              color: cs.surfaceContainerLow,
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search bar
                  TextField(
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Search menu items...',
                      prefixIcon: const Icon(Icons.search),
                      fillColor: cs.surfaceContainer,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
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
                        ),
                        ...MenuCategory.values.map(
                          (cat) => _buildTabButton(
                            label: cat.displayName,
                            category: cat,
                            context: context,
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
                            padding: const EdgeInsets.only(bottom: 90),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 1.5,
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
                                        i.courseNumber == _selectedCourse &&
                                        i.seatNumber == _selectedSeat,
                                  )
                                  .fold<int>(0, (prev, i) => prev + i.quantity);

                              return InkWell(
                                onTap: () => _updateItemQuantity(
                                  menuItem.name,
                                  menuItem.price,
                                  1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: cs.surfaceContainerHigh,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: activeSeatQty > 0
                                          ? cs.onTertiaryContainer
                                          : cs.outlineVariant,
                                      width: activeSeatQty > 0 ? 2 : 1,
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          menuItem.name,
                                          style: TextStyle(
                                            fontFamily: 'Hanken Grotesk',
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: cs.onSurface,
                                            height: 1.2,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '\$${menuItem.price.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              fontFamily: 'JetBrains Mono',
                                              color: cs.onTertiaryContainer,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
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
                                                color: cs.primaryContainer,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                'x$activeSeatQty',
                                                style: TextStyle(
                                                  fontFamily: 'JetBrains Mono',
                                                  color: cs.onPrimaryContainer,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
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
    );
  }

  /// Compact icon button used inside the controls bar
  Widget _buildSmallIconButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required ColorScheme cs,
  }) {
    return SizedBox(
      width: 28,
      height: 28,
      child: Material(
        color: onPressed == null
            ? cs.surfaceContainerHighest.withValues(alpha: 0.4)
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

  /// Labeled chip container used for the controls bar
  Widget _buildControlChip({
    required BuildContext context,
    required String label,
    required Widget child,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 9,
                color: cs.outline,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 6),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required String label,
    required MenuCategory? category,
    required BuildContext context,
  }) {
    final cs = Theme.of(context).colorScheme;
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: InkWell(
        onTap: () => setState(() => _selectedCategory = category),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? cs.primary : cs.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? Colors.transparent : cs.outlineVariant,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? cs.onPrimary : cs.onSurfaceVariant,
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
