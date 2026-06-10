enum UserRole {
  admin,
  server,
  kitchen,
  manager;

  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.server:
        return 'Server';
      case UserRole.kitchen:
        return 'Kitchen';
      case UserRole.manager:
        return 'Manager';
    }
  }
}

enum TableStatus {
  available,
  occupied,
  readyForBill;

  String get displayName {
    switch (this) {
      case TableStatus.available:
        return 'Available';
      case TableStatus.occupied:
        return 'Occupied';
      case TableStatus.readyForBill:
        return 'Ready for Bill';
    }
  }
}

enum MenuCategory {
  appetizers,
  mains,
  desserts,
  beverages,
  sides;

  String get displayName {
    switch (this) {
      case MenuCategory.appetizers:
        return 'Appetizers';
      case MenuCategory.mains:
        return 'Mains';
      case MenuCategory.desserts:
        return 'Desserts';
      case MenuCategory.beverages:
        return 'Beverages';
      case MenuCategory.sides:
        return 'Sides';
    }
  }

  String get icon {
    switch (this) {
      case MenuCategory.appetizers:
        return '🍲';
      case MenuCategory.mains:
        return '🍕';
      case MenuCategory.desserts:
        return '🍰';
      case MenuCategory.beverages:
        return '☕';
      case MenuCategory.sides:
        return '🍟';
    }
  }
}

enum CheckStatus {
  open,
  saved,
  closed,
  voided;

  String get displayName {
    switch (this) {
      case CheckStatus.open:
        return 'Open';
      case CheckStatus.saved:
        return 'Saved';
      case CheckStatus.closed:
        return 'Closed';
      case CheckStatus.voided:
        return 'Voided';
    }
  }
}

enum OrderItemStatus {
  pending,
  fired,
  preparing,
  ready,
  served;

  String get displayName {
    switch (this) {
      case OrderItemStatus.pending:
        return 'Pending';
      case OrderItemStatus.fired:
        return 'Fired';
      case OrderItemStatus.preparing:
        return 'Preparing';
      case OrderItemStatus.ready:
        return 'Ready';
      case OrderItemStatus.served:
        return 'Served';
    }
  }
}

enum DiscountType {
  employeeDiscount,
  deliveroo,
  percent,
  customAmount;

  String get displayName {
    switch (this) {
      case DiscountType.employeeDiscount:
        return 'Employee Discount';
      case DiscountType.deliveroo:
        return 'Deliveroo';
      case DiscountType.percent:
        return 'percent';
      case DiscountType.customAmount:
        return 'Custom Amount';
    }
  }
}

class User {
  const User({required this.name, required this.role, this.pin = '0000'});

  final String name;
  final UserRole role;
  final String pin;
}

class Outlet {
  const Outlet({required this.id, required this.name, required this.location});

  final String id;
  final String name;
  final String location;
}

class MenuItem {
  const MenuItem({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    this.description = '',
    this.modifiers = const [],
    this.isAvailable = true,
  });

  final String id;
  final String name;
  final double price;
  final MenuCategory category;
  final String description;
  final List<String> modifiers;
  final bool isAvailable;
}

class OrderItem {
  final String id;
  final String name;
  int quantity;
  int courseNumber; // Track course timing assignment
  final double price;
  final List<String> modifiers;
  OrderItemStatus status; // Track individual item cooking/serving status
  final String notes;
  int seatNumber;
  int coverNumber;
  List<String> tags; // Track customized fields like allergies or substitutions

  DateTime? orderedAt; // Track when item was sent to kitchen
  DateTime? servedAt;

  OrderItem({
    required this.name,
    required this.quantity,
    required this.courseNumber,
    this.price = 0.0,
    this.modifiers = const [],
    this.status = OrderItemStatus.pending,
    this.notes = '',
    this.seatNumber = 1,
    this.coverNumber = 0,
    this.orderedAt,
    this.servedAt,
    List<String>? tags,
    String? id,
  }) : tags = tags ?? [],
       id =
           id ??
           '${DateTime.now().millisecondsSinceEpoch}_${name}_C${courseNumber}_S$seatNumber';

  double get total => price * quantity;

  /// Calculates individual item processing runtime latency
  Duration? get prepTime {
    if (orderedAt == null || servedAt == null) return null;
    return servedAt!.difference(orderedAt!);
  }

  OrderItem copyWith({
    String? name,
    int? quantity,
    int? courseNumber,
    double? price,
    List<String>? modifiers,
    OrderItemStatus? status,
    String? notes,
    int? seatNumber,
    int? coverNumber,
    List<String>? tags,
    String? id,
    DateTime? orderedAt,
    DateTime? servedAt,
  }) {
    return OrderItem(
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      courseNumber: courseNumber ?? this.courseNumber,
      price: price ?? this.price,
      modifiers: modifiers ?? List<String>.from(this.modifiers),
      status: status ?? this.status,
      notes: notes ?? this.notes,
      seatNumber: seatNumber ?? this.seatNumber,
      coverNumber: coverNumber ?? this.coverNumber,
      tags: tags ?? List<String>.from(this.tags),
      id: id ?? this.id,
      orderedAt: orderedAt ?? this.orderedAt,
      servedAt: servedAt ?? this.servedAt,
    );
  }
}

class Check {
  Check({
    required this.id,
    required this.tableNumber,
    required this.serverName,
    required this.openedAt,
    this.closedAt,
    this.status = CheckStatus.open,
    this.covers = 1,
    List<OrderItem>? items,
    this.subtotal = 0.0,
    this.tax = 0.0,
    this.tip = 0.0,
    this.discount = 0.0,
    this.discountType,
    this.percent = 0,
    this.paymentMethod = '',
    this.voidReason = '',
  }) : items = items ?? [];

  final String id;
  final int tableNumber;
  final String serverName;
  final DateTime openedAt;
  DateTime? closedAt;
  CheckStatus status;
  int covers;
  final List<OrderItem> items;
  double subtotal;
  double tax;
  double tip;
  double discount;

  DiscountType? discountType;
  double percent;
  String paymentMethod;
  String voidReason;
  get total => subtotal + tax + tip - discount;
  double get discountCalculated {
    // Use ?? 0.0 to handle potential nulls if subtotal isn't initialized yet
    final currentSubtotal = subtotal ?? 0.0;

    if (discountType == DiscountType.percent) {
      return currentSubtotal * (discount / 100);
    } else {
      return discount;
    }
  }

  String get duration {
    final end = closedAt ?? DateTime.now();
    final diff = end.difference(openedAt);
    if (diff.inHours > 0) {
      return '${diff.inHours}h ${diff.inMinutes.remainder(60)}m';
    }
    return '${diff.inMinutes}m';
  }
}

class RestaurantTable {
  RestaurantTable({
    required this.number,

    this.status = TableStatus.available,
    this.covers = 0,
    this.duration = '',
    this.billAmount = 0.0,
    this.reservationTime = '',
    this.seatedAt,
    this.activeCheckId,
    List<OrderItem>? orders,
  }) : orders = List<OrderItem>.from(orders ?? const []);

  final int number;
  TableStatus status;
  int covers;
  String duration;
  double billAmount;
  String reservationTime;
  DateTime? seatedAt;
  String? activeCheckId;
  final List<OrderItem> orders;
  Duration get currentOccupancyDuration {
    if (seatedAt == null) return Duration.zero;
    return DateTime.now().difference(seatedAt!);
  }

  RestaurantTable copyWith({
    TableStatus? status,
    int? covers,
    String? duration,
    double? billAmount,
    String? reservationTime,
    String? activeCheckId,
    List<OrderItem>? orders,
    DateTime? seatedAt,
  }) {
    return RestaurantTable(
      number: number,
      status: status ?? this.status,
      covers: covers ?? this.covers,
      duration: duration ?? this.duration,
      billAmount: billAmount ?? this.billAmount,
      reservationTime: reservationTime ?? this.reservationTime,
      activeCheckId: activeCheckId ?? this.activeCheckId,
      seatedAt: seatedAt ?? this.seatedAt,
      orders: orders ?? List<OrderItem>.from(this.orders),
    );
  }
}

class StaffMember {
  StaffMember({
    required this.id,
    required this.name,
    required this.role,
    required this.pin,
    this.isActive = true,
    this.permissions = const [],
  });

  final String id;
  String name;
  UserRole role;
  String pin;
  bool isActive;
  List<String> permissions;
}

class Permission {
  const Permission({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
  });

  final String id;
  final String name;
  final String description;
  final String category;
}
