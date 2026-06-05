import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
// old one do not use
// Assuming these models match your internal setup.
// Local structures have been safely mapped below to prevent compile blocks.
import 'package:my_pos_app/models/pos_models.dart';
import 'package:my_pos_app/providers/pos_provider.dart';
import 'package:my_pos_app/screens/order_summary_screen.dart';

/// Design Token Colors derived explicitly from the Tailwind Configuration
class AppColors {
  static const background = Color(0xFF11131B);
  static const surface = Color(0xFF11131B);
  static const surfaceDim = Color(0xFF11131B);
  static const surfaceContainer = Color(0xFF1D1F27);
  static const surfaceContainerHigh = Color(0xFF282A32);
  static const surfaceContainerHighest = Color(0xFF32343D);
  static const surfaceVariant = Color(0xFF32343D);

  static const primary = Color(0xFFB4C5FF);
  static const onPrimary = Color(0xFF002A78);
  static const primaryContainer = Color(0xFF2563EB);
  static const onPrimaryContainer = Color(0xFFEEEFFF);

  static const onSurface = Color(0xFFE1E2ED);
  static const onSurfaceVariant = Color(0xFFC3C6D7);
  static const outline = Color(0xFF8D90A0);
  static const outlineVariant = Color(0xFF434655);

  static const statusOccupied = Color(0xFFEF4444);
  static const secondaryContainer = Color(0xFF3A4A5F);
  static const onSecondaryContainer = Color(0xFFA9BAD3);
  static const tertiaryContainer = Color(0xFFBC4800);
  static const onTertiaryContainer = Color(0xFFFFEDE6);
}

class OrderEntryScreen extends StatefulWidget {
  const OrderEntryScreen({super.key, required this.tableNumber, this.checkId});

  final int tableNumber;
  final String? checkId;

  @override
  State<OrderEntryScreen> createState() => _OrderEntryScreenState();
}

class _OrderEntryScreenState extends State<OrderEntryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late String _activeCheckId;

  // State management values matched to the HTML specification
  int _coversCount = 4;
  int _currentCourseIndex = 2; // "Mains"
  final List<String> _courses = [
    'Drinks',
    'Appetizers',
    'Mains',
    'Dessert',
    'Final Bill',
  ];

  // Categorization definitions matching HTML Tab UI
  final List<String> _categories = [
    'Mains',
    'Appetizers',
    'Drinks',
    'Sides',
    'Specials',
  ];

  // Tracked item structure mapped from the original interactive template
  final List<OrderItem> _pendingItems = [
    OrderItem(
      name: 'Pan-Seared Scallops',
      quantity: 2,
      price: 28.50,
      courseNumber: 1,
    ),
    OrderItem(
      name: 'Harvest Grain Bowl',
      quantity: 1,
      price: 19.00,
      courseNumber: 1,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);

    // Setting up baseline context checking safely
    final provider = context.read<POSProvider>();
    if (widget.checkId != null) {
      _activeCheckId = widget.checkId!;
    } else {
      final existingCheck = provider.getCheckForTable(widget.tableNumber);
      if (existingCheck != null) {
        _activeCheckId = existingCheck.id;
      } else {
        _activeCheckId = provider.createCheck(
          tableNumber: widget.tableNumber,
          covers: _coversCount,
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Adjust routine mirrors the dynamic logic from the Javascript functions
  void _adjustCovers(int delta) {
    HapticFeedback.lightImpact();
    setState(() {
      _coversCount = (_coversCount + delta).clamp(1, 20);
    });
  }

  void _adjustCourse(int delta) {
    HapticFeedback.lightImpact();
    setState(() {
      _currentCourseIndex =
          (_currentCourseIndex + delta + _courses.length) % _courses.length;
    });
  }

  void _updateItemCount(String itemName, double price, int delta) {
    HapticFeedback.lightImpact();
    setState(() {
      final idx = _pendingItems.indexWhere((item) => item.name == itemName);
      if (idx >= 0) {
        final currentQty = _pendingItems[idx].quantity;
        if (currentQty + delta > 0) {
          _pendingItems[idx].quantity += delta;
        } else {
          _pendingItems.removeAt(idx);
        }
      } else if (delta > 0) {
        _pendingItems.add(
          OrderItem(
            name: itemName,
            quantity: 1,
            price: price,
            courseNumber: _currentCourseIndex,
          ),
        );
      }
    });
  }

  int _getItemCount(String itemName) {
    final idx = _pendingItems.indexWhere((item) => item.name == itemName);
    return idx >= 0 ? _pendingItems[idx].quantity : 0;
  }

  double _calculateTotal() {
    return _pendingItems.fold(
      0.0,
      (sum, item) => sum + (item.price * item.quantity),
    );
  }

  int _calculateTotalItemsCount() {
    return _pendingItems.fold(0, (sum, item) => sum + item.quantity);
  }

  void _fireToKitchen() {
    if (_pendingItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add items before firing to kitchen'),
          backgroundColor: AppColors.surfaceContainerHigh,
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

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => OrderSummaryScreen(checkId: _activeCheckId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 24.0,
                ),
                children: [
                  _buildBentoSelectors(),
                  const SizedBox(height: 24.0),
                  _buildStickySearchAndTabs(),
                  const SizedBox(height: 16.0),
                  _buildMenuGrid(),
                ],
              ),
            ),
            _buildBottomActionBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 48.0,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: const BoxDecoration(
        color: AppColors.surfaceDim,
        border: Border(
          bottom: BorderSide(color: AppColors.outlineVariant, width: 1.0),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(
                    Icons.arrow_back,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 16.0),
              Text(
                'Table ${widget.tableNumber}',
                style: const TextStyle(
                  fontFamily: 'Hanken Grotesk',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: AppColors.statusOccupied,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 16.0),
              const Text(
                '00:24:12',
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBentoSelectors() {
    final String nextCourse =
        _courses[(_currentCourseIndex + 1) % _courses.length];

    return Row(
      children: [
        // Covers Selector
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: AppColors.outlineVariant, width: 1.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'COVERS',
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildIconButton(
                      Icons.remove,
                      AppColors.surfaceVariant,
                      () => _adjustCovers(-1),
                    ),
                    Text(
                      '$_coversCount',
                      style: const TextStyle(
                        fontFamily: 'Hanken Grotesk',
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    _buildIconButton(
                      Icons.add,
                      AppColors.primaryContainer,
                      () => _adjustCovers(1),
                      iconColor: AppColors.onPrimaryContainer,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16.0),
        // Course Selector
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: AppColors.outlineVariant, width: 1.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'COURSE',
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildIconButton(
                      Icons.chevron_left,
                      AppColors.surfaceVariant,
                      () => _adjustCourse(-1),
                    ),
                    Column(
                      children: [
                        Text(
                          _courses[_currentCourseIndex],
                          style: const TextStyle(
                            fontFamily: 'Hanken Grotesk',
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          'Next: $nextCourse',
                          style: const TextStyle(
                            fontFamily: 'JetBrains Mono',
                            fontSize: 10,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    _buildIconButton(
                      Icons.chevron_right,
                      AppColors.surfaceVariant,
                      () => _adjustCourse(1),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIconButton(
    IconData icon,
    Color bg,
    VoidCallback onTap, {
    Color iconColor = AppColors.onSurface,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
    );
  }

  Widget _buildStickySearchAndTabs() {
    return Column(
      children: [
        TextField(
          style: const TextStyle(
            color: AppColors.onSurface,
            fontFamily: 'Hanken Grotesk',
          ),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search, color: AppColors.outline),
            hintText: 'Search menu items...',
            hintStyle: const TextStyle(
              color: AppColors.outline,
              fontFamily: 'Hanken Grotesk',
            ),
            fillColor: AppColors.surfaceContainerHighest,
            filled: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 16.0),
        SizedBox(
          height: 38,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            dividerColor: Colors.transparent,
            indicator: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(9999),
            ),
            labelColor: AppColors.onPrimary,
            unselectedLabelColor: AppColors.onSurfaceVariant,
            labelStyle: const TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            tabs: _categories.map((cat) => Tab(text: cat)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuGrid() {
    // Statically mapped items grid matching the HTML layout view specifications
    final menuItems = [
      _MenuData(
        name: 'Ribeye Steak 400g',
        price: 42.00,
        desc: 'Grass-fed, aged 28 days',
        imageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuBv8mX6cH6bKH_7Dz1N5_GiCmJV1v7aeNenXqKknS624hvXtqXQV93Cj_-UqJ28WDwCtwmE-dyOmVLKvy2RgKpZeH0TeuHd2B6vUFR-GTLDw18effr4V9Yuo8z0LqZ6j9cehJolqjrb4P7etYo8MNzAwfZ_cXwJpM_QkIEXauexk_a6gGXWbaq-U-P4qXVpoCXOa1gHMucJcQk3KuaevN7hBAtOeppRzW7BrIiVa4-AgD-APXKJ98DQqA30HybVOkI9y23h6eyCVPo',
        tags: [
          const _TagData(
            'GF',
            AppColors.secondaryContainer,
            AppColors.onSecondaryContainer,
          ),
          const _TagData(
            'Chef Pick',
            AppColors.tertiaryContainer,
            AppColors.onTertiaryContainer,
          ),
        ],
      ),
      _MenuData(
        name: 'Pan-Seared Scallops',
        price: 28.50,
        desc: 'Pea puree, lemon foam',
        imageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuDhy9QpoguRzGqHA-UNzOX2oUBnV4c5wYr6ExQLSikZQuEuuOlUdzACSVNyg8cymuIodEWpAIL25RuaaEMhFzy-e7m9Iuh36Z2_5YEPzI63L_2L-4RSRzrAZhCA4QSMBeeaT4PkwwCI3MCd-Q_CN2J5Al2tf7yW_HfkaD5rI21KUMsI6r8zHTAl9A6ITfiAHOY7v_5I337d9BPKLyWKwcZPi10n12FyOqe6NMf5Qd9kvFqYuM4RXd74kXnTE2Z71czBUQEwIxsizag',
        tags: [
          const _TagData(
            'Seafood',
            AppColors.secondaryContainer,
            AppColors.onSecondaryContainer,
          ),
        ],
      ),
      _MenuData(
        name: 'Harvest Grain Bowl',
        price: 19.00,
        desc: 'Quinoa, tahini dressing',
        imageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuCM3AK50LJocmzdugVgffwnZFARruyFJIzxK-cV1yvu357BfCPXdzkX0D7_7J-gVIJob4fms2ukoxyAFngwBUmSowUAFEXYWhsPyRGKZW__trbUVjQYkrK4KQbk6XEwEcAidfVC0Bg6H2YbIL2ACRsRmt6fMk9HyJg_f_rRSNZE6_C1XCa3vtSDBpLgJEzI6bWWJyYef2TjmJE3hLgzEKzBE4EGVVCFWXCg1lRDB1Ubfk-XkzBTzBdzQLjzTvSWWcTrelfwCE3wzgA',
        tags: [
          const _TagData(
            'Veg',
            AppColors.secondaryContainer,
            AppColors.onSecondaryContainer,
          ),
        ],
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: menuItems.length,
      itemBuilder: (context, idx) {
        final item = menuItems[idx];
        final qty = _getItemCount(item.name);
        final bool isSelected = qty > 0;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.outlineVariant,
              width: 1.5,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Image.network(
                    item.imageUrl,
                    height: 96,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(
                      height: 96,
                      color: AppColors.surfaceContainerHigh,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Text(
                        '\$${item.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Hanken Grotesk',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    Text(
                      item.desc,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Hanken Grotesk',
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Row(
                      children: item.tags
                          .map(
                            (t) => Container(
                              margin: const EdgeInsets.only(right: 4.0),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: t.bg,
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                              child: Text(
                                t.label,
                                style: TextStyle(
                                  fontFamily: 'JetBrains Mono',
                                  fontSize: 10,
                                  color: t.text,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 12.0),
                    Container(
                      padding: const EdgeInsets.all(2.0),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(color: AppColors.outlineVariant),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () =>
                                _updateItemCount(item.name, item.price, -1),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              child: Icon(
                                Icons.remove,
                                color: AppColors.onSurfaceVariant,
                                size: 16,
                              ),
                            ),
                          ),
                          Text(
                            '$qty',
                            style: const TextStyle(
                              fontFamily: 'JetBrains Mono',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurface,
                            ),
                          ),
                          GestureDetector(
                            onTap: () =>
                                _updateItemCount(item.name, item.price, 1),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              child: Icon(
                                Icons.add,
                                color: AppColors.primary,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomActionBar() {
    final totalItems = _calculateTotalItemsCount();
    final totalPrice = _calculateTotal();

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainer,
        border: Border(
          top: BorderSide(color: AppColors.outlineVariant, width: 1.0),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$totalItems Items Added',
                style: const TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              Text(
                '\$${totalPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontFamily: 'Hanken Grotesk',
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          Row(
            children: [
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.surfaceVariant,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                child: const Text(
                  'Review',
                  style: TextStyle(
                    fontFamily: 'Hanken Grotesk',
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8.0),
              ElevatedButton.icon(
                onPressed: _fireToKitchen,
                icon: const Icon(Icons.send, size: 16),
                label: const Text('Send Order'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 12.0,
                  ),
                  textStyle: const TextStyle(
                    fontFamily: 'Hanken Grotesk',
                    fontWeight: FontWeight.w700,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Helper structures mapping item fields efficiently
class _MenuData {
  final String name;
  final double price;
  final String desc;
  final String imageUrl;
  final List<_TagData> tags;
  const _MenuData({
    required this.name,
    required this.price,
    required this.desc,
    required this.imageUrl,
    required this.tags,
  });
}

class _TagData {
  final String label;
  final Color bg;
  final Color text;
  const _TagData(this.label, this.bg, this.text);
}
