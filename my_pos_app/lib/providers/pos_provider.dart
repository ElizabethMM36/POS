import 'package:flutter/foundation.dart';

import 'package:my_pos_app/models/pos_models.dart';

/// Central application state for authentication, outlet selection, tables,
/// menu, checks, and staff management.
class POSProvider extends ChangeNotifier {
  User? _currentUser;
  Outlet? _selectedOutlet;
  int _currentNavIndex = 0;

  User? get currentUser => _currentUser;
  Outlet? get selectedOutlet => _selectedOutlet;
  int get currentNavIndex => _currentNavIndex;

  void setNavIndex(int index) {
    _currentNavIndex = index;
    notifyListeners();
  }

  // ── Outlets ──────────────────────────────────────────────────────

  final List<Outlet> mockOutlets = const [
    Outlet(
      id: 'outlet-1',
      name: 'Main Dining Floor',
      location: 'Ground Level — 48 seats',
    ),
    Outlet(
      id: 'outlet-2',
      name: 'Terrace & Rooftop Bar',
      location: 'Level 2 — Outdoor seating',
    ),
    Outlet(
      id: 'outlet-3',
      name: 'Private Dining Room',
      location: 'East Wing — Reservations only',
    ),
    Outlet(
      id: 'outlet-4',
      name: 'Quick Service Counter',
      location: 'Lobby — Walk-in & takeaway',
    ),
  ];

  // ── Menu Items ──────────────────────────────────────────────────

  static const List<String> menuItems = [
    'Grilled Atlantic Salmon',
    'Wagyu Beef Burger',
    'Truffle Mushroom Risotto',
    'Caesar Salad',
    'Lobster Bisque',
    'Margherita Pizza',
    'Chicken Parmigiana',
    'Vegetable Pad Thai',
    'Chocolate Lava Cake',
    'Espresso Martini',
    'House Red Wine (Glass)',
    'Sparkling Water',
  ];

  static final List<MenuItem> fullMenu = [
    // Appetizers
    const MenuItem(
      id: 'a1',
      name: 'Lobster Bisque',
      price: 18.00,
      category: MenuCategory.appetizers,
      description: 'Creamy lobster soup with cognac drizzle',
    ),
    const MenuItem(
      id: 'a2',
      name: 'Caesar Salad',
      price: 14.00,
      category: MenuCategory.appetizers,
      description: 'Crisp romaine, parmesan, house-made croutons',
    ),
    const MenuItem(
      id: 'a3',
      name: 'Tuna Tartare',
      price: 22.00,
      category: MenuCategory.appetizers,
      description: 'Yellowfin tuna, avocado, sesame-soy dressing',
    ),
    const MenuItem(
      id: 'a4',
      name: 'Bruschetta Trio',
      price: 12.00,
      category: MenuCategory.appetizers,
      description: 'Tomato basil, mushroom, olive tapenade',
    ),
    // Mains
    const MenuItem(
      id: 'm1',
      name: 'Grilled Atlantic Salmon',
      price: 38.00,
      category: MenuCategory.mains,
      description: 'Herb-crusted, lemon beurre blanc',
    ),
    const MenuItem(
      id: 'm2',
      name: 'Wagyu Beef Burger',
      price: 32.00,
      category: MenuCategory.mains,
      description: 'A5 wagyu patty, truffle aioli, brioche',
    ),
    const MenuItem(
      id: 'm3',
      name: 'Truffle Mushroom Risotto',
      price: 28.00,
      category: MenuCategory.mains,
      description: 'Arborio rice, wild mushrooms, shaved truffle',
    ),
    const MenuItem(
      id: 'm4',
      name: 'Chicken Parmigiana',
      price: 26.00,
      category: MenuCategory.mains,
      description: 'Crumbed chicken, napoli, mozzarella',
    ),
    const MenuItem(
      id: 'm5',
      name: 'Margherita Pizza',
      price: 20.00,
      category: MenuCategory.mains,
      description: 'San Marzano, fresh mozzarella, basil',
    ),
    const MenuItem(
      id: 'm6',
      name: 'Vegetable Pad Thai',
      price: 22.00,
      category: MenuCategory.mains,
      description: 'Rice noodles, tofu, tamarind sauce',
    ),
    // Desserts
    const MenuItem(
      id: 'd1',
      name: 'Chocolate Lava Cake',
      price: 16.00,
      category: MenuCategory.desserts,
      description: 'Warm molten center, vanilla gelato',
    ),
    const MenuItem(
      id: 'd2',
      name: 'Crème Brûlée',
      price: 14.00,
      category: MenuCategory.desserts,
      description: 'Classic vanilla, caramelized sugar',
    ),
    const MenuItem(
      id: 'd3',
      name: 'Tiramisu',
      price: 15.00,
      category: MenuCategory.desserts,
      description: 'Espresso-soaked ladyfingers, mascarpone',
    ),
    // Beverages
    const MenuItem(
      id: 'b1',
      name: 'Espresso Martini',
      price: 18.00,
      category: MenuCategory.beverages,
      description: 'Vodka, Kahlúa, fresh espresso',
    ),
    const MenuItem(
      id: 'b2',
      name: 'House Red Wine (Glass)',
      price: 14.00,
      category: MenuCategory.beverages,
      description: 'Cabernet Sauvignon, Napa Valley',
    ),
    const MenuItem(
      id: 'b3',
      name: 'Sparkling Water',
      price: 6.00,
      category: MenuCategory.beverages,
      description: 'San Pellegrino 750ml',
    ),
    const MenuItem(
      id: 'b4',
      name: 'Craft Lager',
      price: 10.00,
      category: MenuCategory.beverages,
      description: 'Local microbrewery, 330ml',
    ),
    // Sides
    const MenuItem(
      id: 's1',
      name: 'Truffle Fries',
      price: 12.00,
      category: MenuCategory.sides,
      description: 'Hand-cut, parmesan, truffle oil',
    ),
    const MenuItem(
      id: 's2',
      name: 'Grilled Asparagus',
      price: 10.00,
      category: MenuCategory.sides,
      description: 'Hollandaise, toasted almonds',
    ),
    const MenuItem(
      id: 's3',
      name: 'Garlic Bread',
      price: 8.00,
      category: MenuCategory.sides,
      description: 'Herb butter, mozzarella',
    ),
  ];

  List<MenuItem> getMenuByCategory(MenuCategory category) {
    return fullMenu
        .where((item) => item.category == category && item.isAvailable)
        .toList();
  }

  // ── Tables ──────────────────────────────────────────────────────

  final List<RestaurantTable> _tables = [
    RestaurantTable(number: 1, status: TableStatus.available),
    RestaurantTable(number: 2, status: TableStatus.available),
    RestaurantTable(number: 3, status: TableStatus.available),
    RestaurantTable(
      number: 4,
      status: TableStatus.billing,
      covers: 2,
      duration: '42m',
      billAmount: 84.50,
      orders: [
        OrderItem(
          name: 'Wagyu Beef Burger',
          quantity: 2,
          courseNumber: 2,
          price: 32.00,
          status: OrderItemStatus.served,
        ),
        OrderItem(
          name: 'Espresso Martini',
          quantity: 2,
          courseNumber: 3,
          price: 18.00,
          status: OrderItemStatus.served,
        ),
      ],
    ),
    RestaurantTable(
      number: 5,
      status: TableStatus.occupied,
      covers: 8,
      duration: '15m',
      billAmount: 45.00,
      orders: [
        OrderItem(
          name: 'Margherita Pizza',
          quantity: 2,
          courseNumber: 1,
          price: 20.00,
          status: OrderItemStatus.preparing,
        ),
      ],
    ),
    RestaurantTable(number: 6, status: TableStatus.available),
    RestaurantTable(
      number: 7,
      status: TableStatus.billing,
      covers: 4,
      duration: '1h 12m',
      billAmount: 126.00,
      orders: [
        OrderItem(
          name: 'Grilled Atlantic Salmon',
          quantity: 3,
          courseNumber: 2,
          price: 38.00,
          status: OrderItemStatus.served,
        ),
      ],
    ),
    RestaurantTable(number: 8, status: TableStatus.available),
    RestaurantTable(number: 9, status: TableStatus.available),
    RestaurantTable(number: 10, status: TableStatus.available),
    RestaurantTable(number: 11, status: TableStatus.available),
    RestaurantTable(
      number: 12,
      status: TableStatus.reserved,
      covers: 6,
      reservationTime: 'At 19:30',
    ),
    RestaurantTable(number: 13, status: TableStatus.available),
    RestaurantTable(number: 14, status: TableStatus.available),
    RestaurantTable(
      number: 15,
      status: TableStatus.reserved,
      covers: 2,
      reservationTime: 'At 20:00',
    ),
    RestaurantTable(number: 16, status: TableStatus.available),
  ];

  List<RestaurantTable> get tables => List.unmodifiable(_tables);

  // ── Checks ──────────────────────────────────────────────────────

  final List<Check> _checks = [];

  List<Check> get checks => List.unmodifiable(_checks);

  List<Check> get openChecks =>
      _checks.where((c) => c.status == CheckStatus.open).toList();
  List<Check> get savedChecks =>
      _checks.where((c) => c.status == CheckStatus.saved).toList();
  List<Check> get closedChecks =>
      _checks.where((c) => c.status == CheckStatus.closed).toList();

  Check? getCheckById(String id) {
    try {
      return _checks.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  Check? getCheckForTable(int tableNumber) {
    try {
      return _checks.firstWhere(
        (c) => c.tableNumber == tableNumber && c.status == CheckStatus.open,
      );
    } catch (_) {
      return null;
    }
  }

  String createCheck({required int tableNumber, required int covers}) {
    final id = 'CHK-${DateTime.now().millisecondsSinceEpoch}';
    final check = Check(
      id: id,
      tableNumber: tableNumber,
      serverName: _currentUser?.name ?? 'Unknown',
      openedAt: DateTime.now(),
      covers: covers,
    );
    _checks.add(check);

    // Update table status
    final index = _tables.indexWhere((t) => t.number == tableNumber);
    if (index != -1) {
      _tables[index].status = TableStatus.occupied;
      _tables[index].covers = covers;
      _tables[index].activeCheckId = id;
    }
    notifyListeners();
    return id;
  }

  void addItemToCheck(String checkId, OrderItem item) {
    final check = getCheckById(checkId);
    if (check == null) return;

    check.items.add(item);
    check.subtotal = check.items.fold(0, (sum, i) => sum + i.total);
    check.tax = check.subtotal * 0.085; // 8.5% tax

    // Update table bill amount
    final tableIdx = _tables.indexWhere((t) => t.number == check.tableNumber);
    if (tableIdx != -1) {
      _tables[tableIdx].billAmount = check.subtotal;
      _tables[tableIdx].orders.add(item);
    }
    notifyListeners();
  }

  void removeItemFromCheck(String checkId, String itemId) {
    final check = getCheckById(checkId);
    if (check == null) return;

    check.items.removeWhere((i) => i.id == itemId);
    check.subtotal = check.items.fold(0, (sum, i) => sum + i.total);
    check.tax = check.subtotal * 0.085;
    notifyListeners();
  }

  void fireCheckItems(String checkId) {
    final check = getCheckById(checkId);
    if (check == null) return;

    for (var item in check.items) {
      if (item.status == OrderItemStatus.pending) {
        item.status = OrderItemStatus.fired;
      }
    }
    notifyListeners();
  }

  void saveCheck(String checkId) {
    final check = getCheckById(checkId);
    if (check == null) return;

    check.status = CheckStatus.saved;

    final tableIdx = _tables.indexWhere((t) => t.number == check.tableNumber);
    if (tableIdx != -1) {
      _tables[tableIdx].status = TableStatus.occupied;
    }
    notifyListeners();
  }

  void recallCheck(String checkId) {
    final check = getCheckById(checkId);
    if (check == null) return;

    check.status = CheckStatus.open;
    notifyListeners();
  }

  void closeCheck(
    String checkId, {
    String paymentMethod = 'Card',
    double tip = 0.0,
  }) {
    final check = getCheckById(checkId);
    if (check == null) return;

    check.status = CheckStatus.closed;
    check.closedAt = DateTime.now();
    check.paymentMethod = paymentMethod;
    check.tip = tip;

    // Free the table
    final tableIdx = _tables.indexWhere((t) => t.number == check.tableNumber);
    if (tableIdx != -1) {
      _tables[tableIdx].status = TableStatus.available;
      _tables[tableIdx].covers = 0;
      _tables[tableIdx].billAmount = 0;
      _tables[tableIdx].duration = '';
      _tables[tableIdx].orders.clear();
      _tables[tableIdx].activeCheckId = null;
    }
    notifyListeners();
  }

  void voidCheck(String checkId, {String reason = ''}) {
    final check = getCheckById(checkId);
    if (check == null) return;

    check.status = CheckStatus.voided;
    check.closedAt = DateTime.now();
    check.voidReason = reason;

    final tableIdx = _tables.indexWhere((t) => t.number == check.tableNumber);
    if (tableIdx != -1) {
      _tables[tableIdx].status = TableStatus.available;
      _tables[tableIdx].covers = 0;
      _tables[tableIdx].billAmount = 0;
      _tables[tableIdx].duration = '';
      _tables[tableIdx].orders.clear();
      _tables[tableIdx].activeCheckId = null;
    }
    notifyListeners();
  }

  // ── Staff Management (RBAC) ─────────────────────────────────────

  final List<StaffMember> _staff = [
    StaffMember(
      id: 's1',
      name: 'Sarah Johnson',
      role: UserRole.admin,
      pin: '1234',
      permissions: ['all'],
    ),
    StaffMember(
      id: 's2',
      name: 'Mike Chen',
      role: UserRole.manager,
      pin: '5678',
      permissions: [
        'void_check',
        'apply_discount',
        'view_reports',
        'manage_menu',
      ],
    ),
    StaffMember(
      id: 's3',
      name: 'Emily Davis',
      role: UserRole.server,
      pin: '9012',
      permissions: ['create_check', 'add_items', 'save_check'],
    ),
    StaffMember(
      id: 's4',
      name: 'James Wilson',
      role: UserRole.server,
      pin: '3456',
      permissions: ['create_check', 'add_items', 'save_check'],
    ),
    StaffMember(
      id: 's5',
      name: 'Alex Rodriguez',
      role: UserRole.kitchen,
      pin: '7890',
      permissions: ['view_orders', 'update_status'],
    ),
    StaffMember(
      id: 's6',
      name: 'Lisa Park',
      role: UserRole.server,
      pin: '2468',
      isActive: false,
      permissions: ['create_check', 'add_items'],
    ),
  ];

  List<StaffMember> get staff => List.unmodifiable(_staff);
  List<StaffMember> get activeStaff => _staff.where((s) => s.isActive).toList();

  static const List<Permission> allPermissions = [
    Permission(
      id: 'create_check',
      name: 'Create Check',
      description: 'Open new checks on tables',
      category: 'Orders',
    ),
    Permission(
      id: 'add_items',
      name: 'Add Items',
      description: 'Add items to open checks',
      category: 'Orders',
    ),
    Permission(
      id: 'save_check',
      name: 'Save Check',
      description: 'Save checks for later recall',
      category: 'Orders',
    ),
    Permission(
      id: 'void_check',
      name: 'Void Check',
      description: 'Void entire checks',
      category: 'Admin',
    ),
    Permission(
      id: 'void_item',
      name: 'Void Item',
      description: 'Remove individual items from checks',
      category: 'Admin',
    ),
    Permission(
      id: 'apply_discount',
      name: 'Apply Discount',
      description: 'Apply discounts to checks',
      category: 'Admin',
    ),
    Permission(
      id: 'view_reports',
      name: 'View Reports',
      description: 'Access sales and analytics reports',
      category: 'Reports',
    ),
    Permission(
      id: 'manage_menu',
      name: 'Manage Menu',
      description: 'Edit menu items and pricing',
      category: 'Menu',
    ),
    Permission(
      id: 'manage_staff',
      name: 'Manage Staff',
      description: 'Add/edit/deactivate staff members',
      category: 'Admin',
    ),
    Permission(
      id: 'view_orders',
      name: 'View Orders',
      description: 'View incoming kitchen orders',
      category: 'Kitchen',
    ),
    Permission(
      id: 'update_status',
      name: 'Update Status',
      description: 'Update order preparation status',
      category: 'Kitchen',
    ),
  ];

  void addStaffMember(StaffMember member) {
    _staff.add(member);
    notifyListeners();
  }

  void updateStaffMember(
    String id, {
    String? name,
    UserRole? role,
    String? pin,
    bool? isActive,
    List<String>? permissions,
  }) {
    final index = _staff.indexWhere((s) => s.id == id);
    if (index == -1) return;

    if (name != null) _staff[index].name = name;
    if (role != null) _staff[index].role = role;
    if (pin != null) _staff[index].pin = pin;
    if (isActive != null) _staff[index].isActive = isActive;
    if (permissions != null) _staff[index].permissions = permissions;
    notifyListeners();
  }

  void toggleStaffActive(String id) {
    final index = _staff.indexWhere((s) => s.id == id);
    if (index == -1) return;
    _staff[index].isActive = !_staff[index].isActive;
    notifyListeners();
  }

  bool hasPermission(String permissionId) {
    if (_currentUser == null) return false;
    if (_currentUser!.role == UserRole.admin) return true;

    final staffMember = _staff
        .where((s) => s.name == _currentUser!.name)
        .toList();
    if (staffMember.isEmpty) return false;
    return staffMember.first.permissions.contains(permissionId) ||
        staffMember.first.permissions.contains('all');
  }

  // ── Auth ─────────────────────────────────────────────────────────

  bool get isAuthenticated => _currentUser != null;

  /// Validates staff credentials and establishes the session.
  bool authenticateUser({
    required String staffIdOrName,
    required UserRole role,
  }) {
    final trimmed = staffIdOrName.trim();
    if (trimmed.isEmpty) {
      return false;
    }
    _currentUser = User(name: trimmed, role: role);
    _initializeMockChecks();
    notifyListeners();
    return true;
  }

  /// Persists the active service area for this session.
  void selectOutlet(Outlet outlet) {
    _selectedOutlet = outlet;
    notifyListeners();
  }

  RestaurantTable? getTableByNumber(int tableNumber) {
    try {
      return _tables.firstWhere((t) => t.number == tableNumber);
    } catch (_) {
      return null;
    }
  }

  /// Updates table status, covers, and/or order list for a given table.
  void updateTableMetadata(
    int tableNumber, {
    TableStatus? status,
    int? covers,
    List<OrderItem>? orders,
    bool replaceOrders = false,
  }) {
    final index = _tables.indexWhere((t) => t.number == tableNumber);
    if (index == -1) return;

    final table = _tables[index];
    if (status != null) {
      table.status = status;
    }
    if (covers != null) {
      table.covers = covers;
    }
    if (orders != null) {
      if (replaceOrders) {
        table.orders
          ..clear()
          ..addAll(orders);
      } else {
        table.orders.addAll(orders);
      }
    }
    notifyListeners();
  }

  void _initializeMockChecks() {
    if (_checks.isNotEmpty) return;

    // Create mock checks for occupied/billing tables
    final check4 = Check(
      id: 'CHK-1001',
      tableNumber: 4,
      serverName: _currentUser?.name ?? 'Staff',
      openedAt: DateTime.now().subtract(const Duration(minutes: 42)),
      status: CheckStatus.open,
      covers: 2,
      items: [
        OrderItem(
          name: 'Wagyu Beef Burger',
          quantity: 2,
          courseNumber: 2,
          price: 32.00,
          status: OrderItemStatus.served,
        ),
        OrderItem(
          name: 'Espresso Martini',
          quantity: 2,
          courseNumber: 3,
          price: 18.00,
          status: OrderItemStatus.served,
        ),
      ],
      subtotal: 100.00,
      tax: 8.50,
    );
    _checks.add(check4);
    _tables[3].activeCheckId = 'CHK-1001';

    final check5 = Check(
      id: 'CHK-1002',
      tableNumber: 5,
      serverName: _currentUser?.name ?? 'Staff',
      openedAt: DateTime.now().subtract(const Duration(minutes: 15)),
      status: CheckStatus.open,
      covers: 8,
      items: [
        OrderItem(
          name: 'Margherita Pizza',
          quantity: 2,
          courseNumber: 1,
          price: 20.00,
          status: OrderItemStatus.preparing,
        ),
      ],
      subtotal: 40.00,
      tax: 3.40,
    );
    _checks.add(check5);
    _tables[4].activeCheckId = 'CHK-1002';

    final check7 = Check(
      id: 'CHK-1003',
      tableNumber: 7,
      serverName: _currentUser?.name ?? 'Staff',
      openedAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 12)),
      status: CheckStatus.open,
      covers: 4,
      items: [
        OrderItem(
          name: 'Grilled Atlantic Salmon',
          quantity: 3,
          courseNumber: 2,
          price: 38.00,
          status: OrderItemStatus.served,
        ),
      ],
      subtotal: 114.00,
      tax: 9.69,
    );
    _checks.add(check7);
    _tables[6].activeCheckId = 'CHK-1003';

    // Add some saved checks
    final savedCheck1 = Check(
      id: 'CHK-0998',
      tableNumber: 3,
      serverName: 'Emily Davis',
      openedAt: DateTime.now().subtract(const Duration(hours: 2)),
      status: CheckStatus.saved,
      covers: 2,
      items: [
        OrderItem(
          name: 'Caesar Salad',
          quantity: 2,
          courseNumber: 1,
          price: 14.00,
          status: OrderItemStatus.served,
        ),
        OrderItem(
          name: 'Truffle Mushroom Risotto',
          quantity: 1,
          courseNumber: 2,
          price: 28.00,
          status: OrderItemStatus.served,
        ),
      ],
      subtotal: 56.00,
      tax: 4.76,
    );
    _checks.add(savedCheck1);

    // Add some closed checks
    final closedCheck1 = Check(
      id: 'CHK-0995',
      tableNumber: 9,
      serverName: 'James Wilson',
      openedAt: DateTime.now().subtract(const Duration(hours: 3, minutes: 30)),
      closedAt: DateTime.now().subtract(const Duration(hours: 2, minutes: 15)),
      status: CheckStatus.closed,
      covers: 4,
      items: [
        OrderItem(
          name: 'Lobster Bisque',
          quantity: 2,
          courseNumber: 1,
          price: 18.00,
          status: OrderItemStatus.served,
        ),
        OrderItem(
          name: 'Wagyu Beef Burger',
          quantity: 2,
          courseNumber: 2,
          price: 32.00,
          status: OrderItemStatus.served,
        ),
        OrderItem(
          name: 'Chocolate Lava Cake',
          quantity: 2,
          courseNumber: 3,
          price: 16.00,
          status: OrderItemStatus.served,
        ),
      ],
      subtotal: 132.00,
      tax: 11.22,
      tip: 19.80,
      paymentMethod: 'Visa •••• 4242',
    );
    _checks.add(closedCheck1);

    final closedCheck2 = Check(
      id: 'CHK-0992',
      tableNumber: 11,
      serverName: 'Mike Chen',
      openedAt: DateTime.now().subtract(const Duration(hours: 4)),
      closedAt: DateTime.now().subtract(const Duration(hours: 3)),
      status: CheckStatus.closed,
      covers: 6,
      items: [
        OrderItem(
          name: 'Tuna Tartare',
          quantity: 3,
          courseNumber: 1,
          price: 22.00,
          status: OrderItemStatus.served,
        ),
        OrderItem(
          name: 'Grilled Atlantic Salmon',
          quantity: 4,
          courseNumber: 2,
          price: 38.00,
          status: OrderItemStatus.served,
        ),
        OrderItem(
          name: 'House Red Wine (Glass)',
          quantity: 6,
          courseNumber: 2,
          price: 14.00,
          status: OrderItemStatus.served,
        ),
      ],
      subtotal: 302.00,
      tax: 25.67,
      tip: 54.36,
      paymentMethod: 'Amex •••• 1001',
    );
    _checks.add(closedCheck2);
  }

  /// Clears session state and resets all tables to defaults.
  void clearSession() {
    _currentUser = null;
    _selectedOutlet = null;
    _currentNavIndex = 0;
    _checks.clear();
    _tables[0] = RestaurantTable(number: 1, status: TableStatus.available);
    _tables[1] = RestaurantTable(number: 2, status: TableStatus.available);
    _tables[2] = RestaurantTable(number: 3, status: TableStatus.available);
    _tables[3] = RestaurantTable(
      number: 4,
      status: TableStatus.billing,
      covers: 2,
      duration: '42m',
      billAmount: 84.50,
      orders: [
        OrderItem(
          name: 'Wagyu Beef Burger',
          quantity: 2,
          courseNumber: 2,
          price: 32.00,
        ),
        OrderItem(
          name: 'Espresso Martini',
          quantity: 2,
          courseNumber: 3,
          price: 18.00,
        ),
      ],
    );
    _tables[4] = RestaurantTable(
      number: 5,
      status: TableStatus.occupied,
      covers: 8,
      duration: '15m',
      billAmount: 45.00,
      orders: [
        OrderItem(
          name: 'Margherita Pizza',
          quantity: 2,
          courseNumber: 1,
          price: 20.00,
        ),
      ],
    );
    _tables[5] = RestaurantTable(number: 6, status: TableStatus.available);
    _tables[6] = RestaurantTable(
      number: 7,
      status: TableStatus.billing,
      covers: 4,
      duration: '1h 12m',
      billAmount: 126.00,
      orders: [
        OrderItem(
          name: 'Grilled Atlantic Salmon',
          quantity: 3,
          courseNumber: 2,
          price: 38.00,
        ),
      ],
    );
    _tables[7] = RestaurantTable(number: 8, status: TableStatus.available);
    _tables[8] = RestaurantTable(number: 9, status: TableStatus.available);
    _tables[9] = RestaurantTable(number: 10, status: TableStatus.available);
    _tables[10] = RestaurantTable(number: 11, status: TableStatus.available);
    _tables[11] = RestaurantTable(
      number: 12,
      status: TableStatus.reserved,
      covers: 6,
      reservationTime: 'At 19:30',
    );
    _tables[12] = RestaurantTable(number: 13, status: TableStatus.available);
    _tables[13] = RestaurantTable(number: 14, status: TableStatus.available);
    _tables[14] = RestaurantTable(
      number: 15,
      status: TableStatus.reserved,
      covers: 2,
      reservationTime: 'At 20:00',
    );
    _tables[15] = RestaurantTable(number: 16, status: TableStatus.available);
    notifyListeners();
  }
}
