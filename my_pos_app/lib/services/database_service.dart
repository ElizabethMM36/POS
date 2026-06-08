import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:my_pos_app/models/pos_models.dart'; // Make sure this path matches your project structure

class DatabaseService {
  // 1. Private constructor for Singleton pattern
  DatabaseService._privateConstructor();
  static final DatabaseService instance = DatabaseService._privateConstructor();

  // 2. Cached database reference
  static Database? _database;

  // 3. Getter that ensures only one database connection is opened across the app
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // 4. Database initialization and schema creation
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'pos_restaurant.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Create staff members table
        await db.execute('''
          CREATE TABLE staff_members (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            role TEXT NOT NULL,
            pin TEXT NOT NULL,
            is_active INTEGER DEFAULT 1
          )
        ''');

        // Create restaurant tables tracking layout
        await db.execute('''
          CREATE TABLE restaurant_tables (
            number INTEGER PRIMARY KEY,
            status TEXT NOT NULL DEFAULT 'available',
            covers INTEGER DEFAULT 0,
            active_check_id TEXT
          )
        ''');

        // Create transactional checks/bills table
        await db.execute('''
          CREATE TABLE checks (
            id TEXT PRIMARY KEY,
            table_number INTEGER NOT NULL,
            server_name TEXT NOT NULL,
            status TEXT NOT NULL DEFAULT 'open',
            opened_at TEXT NOT NULL,
            closed_at TEXT,
            covers INTEGER NOT NULL,
            subtotal REAL DEFAULT 0.0,
            tax REAL DEFAULT 0.0,
            tip REAL DEFAULT 0.0,
            payment_method TEXT,
            void_reason TEXT,
            discount REAL DEFAULT 0.0
          )
        ''');

        // Create itemized orders table
        await db.execute('''
          CREATE TABLE order_items (
            id TEXT PRIMARY KEY,
            check_id TEXT NOT NULL,
            name TEXT NOT NULL,
            quantity INTEGER NOT NULL,
            price REAL NOT NULL,
            course_number INTEGER NOT NULL DEFAULT 1,
            seat_number INTEGER NOT NULL DEFAULT 1,
            status TEXT NOT NULL DEFAULT 'pending',
            tags TEXT
          )
        ''');

        // Seed default staff pins from pos_provider mock context
        await db.insert('staff_members', {
          'id': 's3',
          'name': 'Emily Davis',
          'role': 'server',
          'pin': '9012',
        });
        await db.insert('staff_members', {
          'id': 's4',
          'name': 'James Wilson',
          'role': 'server',
          'pin': '3456',
        });

        // Seed the 16 tables from pos_provider mock
        for (int i = 1; i <= 16; i++) {
          await db.insert('restaurant_tables', {
            'number': i,
            'status': 'available',
            'covers': 0,
          });
        }
      },
    );
  }

  // ── TRANSACTION WORKFLOW METHODS ──────────────────────────────────────

  Future<bool> databaseAuthenticateUser(String pin) async {
    // Fetch the active database reference
    final Database db = await database;

    final List<Map<String, dynamic>> maps = await db.query(
      'staff_members',
      where: 'pin = ? AND is_active = 1',
      whereArgs: [pin],
    );
    if (maps.isNotEmpty) {
      return true;
    }
    return false;
  }

  Future<void> dbDispatchOrderTicket({
    required int tableNumber,
    required int covers,
    required List<OrderItem> items,
    required String currentServerName,
  }) async {
    final Database db = await database;

    await db.transaction((txn) async {
      // 1. Check if the table already has an active check
      final List<Map<String, dynamic>> tableCheck = await txn.query(
        'restaurant_tables',
        columns: ['active_check_id'],
        where: 'number = ?',
        whereArgs: [tableNumber],
      );

      String? checkId = tableCheck.first['active_check_id'];

      if (checkId == null) {
        // Create a fresh new check entry matching pos_provider.dart structure
        checkId = 'CHK-${DateTime.now().millisecondsSinceEpoch}';
        await txn.insert('checks', {
          'id': checkId,
          'table_number': tableNumber,
          'server_name': currentServerName,
          'status': 'open',
          'opened_at': DateTime.now().toIso8601String(),
          'covers': covers,
        });

        // Update table metadata
        await txn.update(
          'restaurant_tables',
          {'status': 'occupied', 'covers': covers, 'active_check_id': checkId},
          where: 'number = ?',
          whereArgs: [tableNumber],
        );
      }

      // 2. Insert or merge order line items
      for (var item in items) {
        await txn.insert('order_items', {
          'id': 'ITEM-${DateTime.now().microsecondsSinceEpoch}',
          'check_id': checkId,
          'name': item.name,
          'quantity': item.quantity,
          'price': item.price,
          'course_number': item.courseNumber,
          'seat_number': item.seatNumber,
          'status': 'pending', // Fresh items are logged as pending
          'tags': item.tags.join(','),
        });
      }

      // 3. Recalculate financial records totals instantly
      final List<Map<String, dynamic>> itemTotals = await txn.rawQuery(
        'SELECT SUM(price * quantity) as subtotal FROM order_items WHERE check_id = ?',
        [checkId],
      );
      double subtotal = itemTotals.first['subtotal'] ?? 0.0;
      double tax = subtotal * 0.085; // Standard 8.5% operational tax rules

      await txn.update(
        'checks',
        {'subtotal': subtotal, 'tax': tax},
        where: 'id = ?',
        whereArgs: [checkId],
      );
    });
  }

  Future<void> dbFireCheckItems(String checkId) async {
    final Database db = await database;

    await db.update(
      'order_items',
      {'status': 'fired'},
      where: 'check_id = ? AND status = ?',
      whereArgs: [checkId, 'pending'],
    );
  }

  Future<void> dbCloseCheck({
    required String checkId,
    required int tableNumber,
    required String paymentMethod,
    required double tip,
  }) async {
    final Database db = await database;

    await db.transaction((txn) async {
      // 1. Close check record entries
      await txn.update(
        'checks',
        {
          'status': 'closed',
          'closed_at': DateTime.now().toIso8601String(),
          'payment_method': paymentMethod,
          'tip': tip,
        },
        where: 'id = ?',
        whereArgs: [checkId],
      );

      // 2. Free up physical layout tables cleanly matching clear values
      await txn.update(
        'restaurant_tables',
        {'status': 'available', 'covers': 0, 'active_check_id': null},
        where: 'number = ?',
        whereArgs: [tableNumber],
      );
    });
  }
}
