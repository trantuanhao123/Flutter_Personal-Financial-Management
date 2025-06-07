import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../services/realm_service.dart';
import '../models/models.dart';
import '../neon_styles.dart';
import '../widgets/neon_transaction_card.dart';

class TransactionScreen extends StatefulWidget {
  final RealmService realmService;

  const TransactionScreen({super.key, required this.realmService});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> with SingleTickerProviderStateMixin {
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
  late TabController _tabController;
  bool _showExpense = true;

  // Dữ liệu theo tháng
  final List<double> _monthlyExpense = List.filled(12, 0);
  final List<double> _monthlyIncome = List.filled(12, 0);

  // Dữ liệu chi tiêu theo danh mục
  final Map<String, Map<String, dynamic>> _expenseCategories = {
    'Ăn uống': {'icon': Icons.restaurant, 'color': Colors.orange, 'transactions': []},
    'Di chuyển': {'icon': Icons.directions_car, 'color': Colors.blue, 'transactions': []},
    'Mua sắm': {'icon': Icons.shopping_bag, 'color': Colors.pink, 'transactions': []},
    'Giải trí': {'icon': Icons.sports_esports, 'color': Colors.purple, 'transactions': []},
    'Hóa đơn': {'icon': Icons.receipt_long, 'color': Colors.red, 'transactions': []},
    'Khác': {'icon': Icons.more_horiz, 'color': Colors.grey, 'transactions': []},
  };

  // Dữ liệu thu nhập theo danh mục
  final Map<String, Map<String, dynamic>> _incomeCategories = {
    'Lương': {'icon': Icons.account_balance_wallet, 'color': Colors.green, 'transactions': []},
    'Thưởng': {'icon': Icons.card_giftcard, 'color': Colors.amber, 'transactions': []},
    'Đầu tư': {'icon': Icons.trending_up, 'color': Colors.blue, 'transactions': []},
    'Bán hàng': {'icon': Icons.store, 'color': Colors.orange, 'transactions': []},
    'Khác': {'icon': Icons.more_horiz, 'color': Colors.grey, 'transactions': []},
  };

  // Dữ liệu giao dịch
  final List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;

  List<DanhMuc> _categories = [];
  Future<void> _loadCategories() async {
    _categories = await widget.realmService.getAllCategories();
    setState(() {});
  }

  // Thêm biến để theo dõi trạng thái xem tất cả
  bool _viewAll = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _showExpense = _tabController.index == 0;
      });
    });

    // Khởi tạo và tải dữ liệu
    _initData();
  }

  // Hàm khởi tạo và tải dữ liệu từ Realm
  Future<void> _initData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (!widget.realmService.isInitialized) {
        await widget.realmService.clear(); // Xóa dữ liệu cũ
        await widget.realmService.initialize(); // Khởi tạo lại với danh mục mặc định
      }

      final transactions = await widget.realmService.loadTransactions();
      final categories = await widget.realmService.getAllCategories();

      _transactions.clear();
      _monthlyExpense.fillRange(0, 12, 0);
      _monthlyIncome.fillRange(0, 12, 0);

      for (final transaction in transactions) {
        // Tìm tên danh mục từ ID
        final category = categories.firstWhere(
          (c) => c.id == transaction.category,
          orElse: () {
            final defaultCategory = DanhMuc('unknown', 'Không xác định', transaction.type);
            defaultCategory.icon = 'help_outline';
            defaultCategory.color = '#9E9E9E';
            return defaultCategory;
          },
        );

        final isExpense = transaction.type == 'Chi';
        final month = transaction.date.month - 1;

        _transactions.add({
          'id': transaction.id,
          'category': category.name,
          'amount': transaction.amount,
          'date': transaction.date,
          'type': transaction.type,
          'note': transaction.note,
          'isPinned': transaction.isPinned,
        });

        if (isExpense) {
          _monthlyExpense[month] += transaction.amount;
        } else {
          _monthlyIncome[month] += transaction.amount;
        }
      }

      _transactions.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
    } catch (e) {
      print('Lỗi khi tải dữ liệu: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _addTransaction(String category, double amount, DateTime date, {bool isExpense = true}) async {
    try {
      // 1. Kiểm tra RealmService đã được khởi tạo
      if (!widget.realmService.isInitialized) {
        await widget.realmService.initialize();
      }

      // 2. Tìm ID của danh mục từ tên
      final categories = await widget.realmService.getAllCategories();
      final selectedCategory = categories.firstWhere(
        (c) => c.name == category && c.type == (isExpense ? 'Chi' : 'Thu'),
        orElse: () {
          final category = DanhMuc(
            'unknown',
            'Không xác định',
            isExpense ? 'Chi' : 'Thu',
            icon: 'help_outline',
            color: '#9E9E9E',
          );
          return category;
        },
      );

      // 3. Nếu là khoản chi, kiểm tra giới hạn chi tiêu
      if (isExpense) {
        final spendingCheck = await widget.realmService.checkSpendingLimit(
          category,
          date.year,
          date.month,
        );

        if (spendingCheck['isOverLimit'] ||
            (spendingCheck['currentSpending'] + amount) > spendingCheck['limit']) {
          // Hiển thị cảnh báo
          if (mounted) {
            final result = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: Color(0xFF262626),
                title: Text(
                  'Cảnh báo vượt giới hạn',
                  style: TextStyle(color: Colors.orange),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Khoản chi này sẽ vượt quá giới hạn của danh mục "$category"',
                      style: TextStyle(color: Colors.white),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Chi tiêu hiện tại: ${currencyFormat.format(spendingCheck['currentSpending'])}',
                      style: TextStyle(color: Colors.white70),
                    ),
                    Text(
                      'Giới hạn: ${currencyFormat.format(spendingCheck['limit'])}',
                      style: TextStyle(color: Colors.white70),
                    ),
                    Text(
                      'Sau khi thêm: ${currencyFormat.format(spendingCheck['currentSpending'] + amount)}',
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text('Hủy'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(
                      'Vẫn thêm',
                      style: TextStyle(color: Colors.orange),
                    ),
                  ),
                ],
              ),
            );

            if (result != true) {
              return;
            }
          }
        }
      }

      // 4. Tạo ID mới cho giao dịch
      final transactionId = Uuid().v4();

      // 5. Tạo đối tượng GiaoDich theo đúng constructor từ model
      final transaction = GiaoDich(
        transactionId,       // id (bắt buộc)
        amount,              // amount (bắt buộc)
        selectedCategory.id, // category ID (bắt buộc)
        date,                // date (bắt buộc)
        isExpense ? 'Chi' : 'Thu', // type (bắt buộc)
        false,               // isPinned (bắt buộc, mặc định false)
        note: null,          // note (tùy chọn)
      );

      // 6. Thêm vào Realm
      await widget.realmService.addTransaction(transaction);

      // 7. Cập nhật UI
      setState(() {
        final month = date.month - 1;

        if (isExpense) {
          _monthlyExpense[month] = (_monthlyExpense[month] ?? 0) + amount;
        } else {
          _monthlyIncome[month] = (_monthlyIncome[month] ?? 0) + amount;
        }

        _transactions.add({
          'id': transaction.id,
          'category': category, // Sử dụng tên danh mục
          'amount': amount,
          'date': date,
          'type': isExpense ? 'Chi' : 'Thu',
          'note': null,
          'isPinned': false,
        });

        _transactions.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
      });

      // 8. Hiển thị thông báo
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã thêm ${isExpense ? "khoản chi" : "khoản thu"} mới'),
            backgroundColor: isExpense ? Colors.red : Colors.green,
          ),
        );
      }
    } catch (e) {
      if (e.toString() != 'Exception: Không tìm thấy danh mục') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi thêm giao dịch: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddTransactionDialog() async {
    await _loadCategories();

    // Lọc danh mục theo loại giao dịch (Thu/Chi)
    final filteredCategories = _categories.where((c) => c.type == (_showExpense ? 'Chi' : 'Thu')).toList();

    // Kiểm tra nếu không có danh mục nào
    if (filteredCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Chưa có danh mục ${_showExpense ? "chi" : "thu"} nào. Vui lòng thêm danh mục trước.'),
          backgroundColor: Colors.orange,
          action: SnackBarAction(
            label: 'Đóng',
            onPressed: () {},
          ),
        ),
      );
      return;
    }

    String selectedCategoryId = filteredCategories.first.id;
    DateTime selectedDate = DateTime.now();
    final amountController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF232526), Color(0xFF181A20)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 24,
                  offset: Offset(0, -8),
                ),
              ],
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 16,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _showExpense ? 'Thêm khoản chi' : 'Thêm khoản thu',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Hiển thị danh mục dạng grid
                  const Text(
                    'Chọn danh mục',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Grid các danh mục
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      childAspectRatio: 1,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: filteredCategories.length,
                    itemBuilder: (context, index) {
                      final category = filteredCategories[index];
                      final isSelected = category.id == selectedCategoryId;

                      // Convert hex color to Color
                      Color categoryColor;
                      try {
                        categoryColor = _getCategoryColor(category.name, _showExpense);
                      } catch (e) {
                        categoryColor = Colors.grey;
                      }

                      return InkWell(
                        onTap: () {
                          setSheetState(() {
                            selectedCategoryId = category.id;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? categoryColor.withOpacity(0.18)
                                : Colors.grey[900],
                            borderRadius: BorderRadius.circular(12),
                            border: isSelected
                                ? Border.all(
                                    color: categoryColor,
                                    width: 2,
                                  )
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _getCategoryIcon(category.name, _showExpense),
                                color: categoryColor,
                                size: 28,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                category.name,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Nhập số tiền
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Số tiền (VNĐ)',
                      filled: true,
                      fillColor: Colors.grey[850],
                      labelStyle: TextStyle(color: Colors.white),
                      hintStyle: TextStyle(color: Colors.white54),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white24),
                      ),
                      prefixIcon: const Icon(Icons.monetization_on, color: Colors.white70),
                    ),
                    style: TextStyle(color: Colors.white),
                  ),

                  const SizedBox(height: 16),

                  // Chọn ngày
                  InkWell(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2025),
                      );
                      if (picked != null && picked != selectedDate) {
                        setSheetState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[850],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Colors.white),
                          const SizedBox(width: 10),
                          Text(
                            DateFormat('dd/MM/yyyy').format(selectedDate),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _showExpense ? Colors.red : Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        if (amountController.text.isNotEmpty) {
                          final amount = double.tryParse(amountController.text) ?? 0;
                          if (amount > 0) {
                            // Tìm category name từ ID để hiển thị
                            final selectedCategory = filteredCategories.firstWhere(
                              (c) => c.id == selectedCategoryId,
                              orElse: () => throw Exception('Không tìm thấy danh mục'),
                            );
                            _addTransaction(
                              selectedCategory.name,
                              amount,
                              selectedDate,
                              isExpense: _showExpense,
                            );
                            Navigator.pop(context);
                          }
                        }
                      },
                      child: Text(_showExpense ? 'Thêm khoản chi' : 'Thêm khoản thu'),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _getCategoryIcon(String categoryName, bool isExpense) {
    try {
      final category = _categories.firstWhere(
        (c) => c.name == categoryName && c.type == (isExpense ? 'Chi' : 'Thu'),
        orElse: () {
          final defaultCategory = DanhMuc('unknown', 'Không xác định', isExpense ? 'Chi' : 'Thu');
          defaultCategory.icon = 'help_outline';
          return defaultCategory;
        },
      );

      // Map string icon name to IconData
      final Map<String, IconData> iconMap = {
        'restaurant': Icons.restaurant,
        'directions_car': Icons.directions_car,
        'shopping_bag': Icons.shopping_bag,
        'sports_esports': Icons.sports_esports,
        'receipt_long': Icons.receipt_long,
        'more_horiz': Icons.more_horiz,
        'account_balance_wallet': Icons.account_balance_wallet,
        'card_giftcard': Icons.card_giftcard,
        'trending_up': Icons.trending_up,
        'store': Icons.store,
        'help_outline': Icons.help_outline,
      };

      return iconMap[category.icon ?? 'help_outline'] ?? Icons.help_outline;
    } catch (e) {
      print('Lỗi lấy icon: $e');
      return Icons.help_outline;
    }
  }

  Color _getCategoryColor(String categoryName, bool isExpense) {
    try {
      final category = _categories.firstWhere(
        (c) => c.name == categoryName && c.type == (isExpense ? 'Chi' : 'Thu'),
        orElse: () {
          final defaultCategory = DanhMuc('unknown', 'Không xác định', isExpense ? 'Chi' : 'Thu');
          defaultCategory.icon = 'help_outline';
          defaultCategory.color = '#9E9E9E';
          return defaultCategory;
        },
      );

      if (category.color == null || category.color!.isEmpty) {
        return Colors.grey;
      }

      // Kiểm tra xem có phải mã màu hex không
      if (category.color!.startsWith('#')) {
        // Chuyển đổi mã hex thành Color
        try {
          final hex = category.color!.replaceAll('#', '');
          return Color(int.parse('FF$hex', radix: 16));
        } catch (e) {
          print('Lỗi chuyển đổi mã màu hex: $e');
          return Colors.grey;
        }
      }

      // Nếu không phải mã hex, xử lý như tên màu
      final Map<String, Color> colorMap = {
        'orange': Colors.orange,
        'blue': Colors.blue,
        'pink': Colors.pink,
        'purple': Colors.purple,
        'red': Colors.red,
        'grey': Colors.grey,
        'green': Colors.green,
        'amber': Colors.amber,
      };

      return colorMap[category.color!.toLowerCase()] ?? Colors.grey;
    } catch (e) {
      print('Lỗi lấy màu danh mục: $e');
      return Colors.grey;
    }
  }

  double _getTotalExpense() {
    return _monthlyExpense.reduce((a, b) => a + b);
  }

  double _getTotalIncome() {
    return _monthlyIncome.reduce((a, b) => a + b);
  }

  // Hàm chuyển đổi chế độ xem
  void _toggleViewAll() {
    setState(() {
      _viewAll = !_viewAll;
    });
  }

  String _formatCompactCurrency(double amount) {
    if (amount >= 1000000000) {
      return '${(amount / 1000000000).toStringAsFixed(1)}tỷ ₫';
    } else if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}tr ₫';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}k ₫';
    } else {
      return '${amount.toStringAsFixed(0)} ₫';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return WillPopScope(
      onWillPop: () async {
        // Refresh data trước khi quay lại
        Navigator.pop(context);
        return false;
      },
      child: Scaffold(
        body: Stack(
          children: [
            // Background gradient
            Container(
              height: 250,
              width: double.infinity,
              decoration: NeonStyles.neonGalaxyBackground(),
            ),

            SafeArea(
              child: Column(
                children: [
                  // Header với nút back
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Text(
                          'Quản lý giao dịch',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  _buildTabBar(theme),

                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF232526),
                            Color(0xFF1a2980),
                            Color(0xFFa259ff),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                        child: _isLoading
                            ? _buildLoadingView()
                            : RefreshIndicator(
                                onRefresh: _initData,
                                child: TabBarView(
                                  controller: _tabController,
                                  children: [
                                    _buildTransactionsTab(theme, true),
                                    _buildTransactionsTab(theme, false),
                                  ],
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: AnimatedSlide(
          duration: const Duration(milliseconds: 300),
          offset: const Offset(0, 0),
          child: FloatingActionButton(
            backgroundColor: _showExpense ? Colors.red : Colors.green,
            onPressed: _showAddTransactionDialog,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(25),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: NeonStyles.neonGalaxyGradient(),
          borderRadius: BorderRadius.circular(25),
        ),
        labelColor: NeonStyles.neonCyan,
        unselectedLabelColor: Colors.white,
        tabs: const [
          Tab(text: 'Khoản chi'),
          Tab(text: 'Khoản thu'),
        ],
      ),
    );
  }

  Widget _buildTransactionsTab(ThemeData theme, bool isExpense) {
    // Lọc giao dịch theo loại (thu hoặc chi)
    final filteredTransactions = _transactions
        .where((transaction) => transaction['type'] == (isExpense ? 'Chi' : 'Thu'))
        .toList();

    // Nếu không ở chế độ xem tất cả, chỉ hiển thị 5 giao dịch gần nhất
    final displayedTransactions = _viewAll
        ? filteredTransactions
        : filteredTransactions.take(5).toList();

    return Column(
      children: [
        // Hiển thị danh sách tháng và chi tiêu tương ứng
        Container(
          height: 100,
          margin: const EdgeInsets.only(top: 16),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 12,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemBuilder: (context, index) {
              final monthData = isExpense ? _monthlyExpense[index] : _monthlyIncome[index];
              final bool isCurrentMonth = index == DateTime.now().month - 1;

              return TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: 1),
                duration: Duration(milliseconds: 400 + (index * 50)),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: 0.8 + (0.2 * value),
                    child: Opacity(
                      opacity: value,
                      child: Container(
                        width: 80,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          borderRadius: BorderRadius.circular(12),
                          border: isCurrentMonth
                              ? Border.all(color: Colors.white, width: 2)
                              : Border.all(color: Colors.white24, width: 1),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'T${index + 1}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isCurrentMonth ? Colors.white : Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              monthData > 0
                                  ? currencyFormat.format(monthData)
                                  : '0 ₫',
                              style: TextStyle(
                                color: isExpense ? Colors.red : Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),

        // Tiêu đề danh sách giao dịch
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    height: 24,
                    width: 4,
                    decoration: BoxDecoration(
                      color: isExpense ? Colors.red : Colors.green,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isExpense ? 'Khoản chi gần đây' : 'Khoản thu gần đây',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: _toggleViewAll,
                icon: Icon(
                  _viewAll ? Icons.visibility_off : Icons.visibility,
                  size: 18,
                  color: theme.primaryColor,
                ),
                label: Text(_viewAll ? 'Thu gọn' : 'Xem tất cả'),
                style: TextButton.styleFrom(
                  foregroundColor: theme.primaryColor,
                ),
              ),
            ],
          ),
        ),

        // Danh sách giao dịch
        Expanded(
          child: displayedTransactions.isEmpty
              ? _buildEmptyState(isExpense)
              : _buildTransactionList(displayedTransactions, theme),
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool isExpense) {
    final Color primaryColor = isExpense ? Colors.red : Colors.green;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 800),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Icon(
                  isExpense ? Icons.money_off : Icons.attach_money,
                  size: 80,
                  color: Colors.grey[300],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            isExpense ? 'Chưa có khoản chi nào được ghi nhận' : 'Chưa có khoản thu nào được ghi nhận',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddTransactionDialog,
            icon: const Icon(Icons.add),
            label: Text('Thêm ${isExpense ? 'khoản chi' : 'khoản thu'}'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList(List<Map<String, dynamic>> transactions, ThemeData theme) {
    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có giao dịch nào',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];

        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: 1),
          duration: Duration(milliseconds: 400 + (index * 50)),
          curve: Curves.easeOutQuart,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 30 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: child,
              ),
            );
          },
          child: NeonTransactionCard(
            transaction: {
              ...transaction,
              'amount_formatted': _formatCompactCurrency(transaction['amount']),
            },
            currencyFormat: currencyFormat,
            onEdit: () => _showEditTransactionDialog(transaction),
            onPin: () => widget.realmService.toggleTransactionPin(transaction['id']),
            isPinned: transaction['isPinned'] ?? false,
          ),
        );
      },
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Đang tải dữ liệu...'),
        ],
      ),
    );
  }

  // Hàm chỉnh sửa giao dịch
  Future<void> _editTransaction(String transactionId, {
    String? newCategory,  // This is now category ID
    double? newAmount,
    DateTime? newDate,
    String? newType,
    String? newNote,
  }) async {
    try {
      await widget.realmService.updateTransaction(
        transactionId,
        newCategory: newCategory,  // Pass category ID directly
        newAmount: newAmount,
        newDate: newDate,
        newType: newType,
        newNote: newNote,
      );

      // Cập nhật UI ngay lập tức
      setState(() {
        final index = _transactions.indexWhere((t) => t['id'] == transactionId);
        if (index != -1) {
          final oldTransaction = _transactions[index];
          final oldAmount = oldTransaction['amount'] as double;
          final oldType = oldTransaction['type'] as String;
          final oldMonth = (oldTransaction['date'] as DateTime).month - 1;

          // Cập nhật tổng thu/chi tháng cũ
          if (oldType == 'Chi') {
            _monthlyExpense[oldMonth] -= oldAmount;
          } else {
            _monthlyIncome[oldMonth] -= oldAmount;
          }

          // Tìm tên danh mục từ ID
          final categoryName = _categories.firstWhere(
            (c) => c.id == newCategory,
            orElse: () {
              final category = DanhMuc(
                'unknown',
                'Không xác định',
                newType ?? oldType,
                icon: 'help_outline',
                color: '#9E9E9E',
              );
              return category;
            },
          ).name;

          // Cập nhật giao dịch
          _transactions[index] = {
            ..._transactions[index],
            if (newCategory != null) 'category': categoryName,  // Use category name for display
            if (newAmount != null) 'amount': newAmount,
            if (newDate != null) 'date': newDate,
            if (newType != null) 'type': newType,
            if (newNote != null) 'note': newNote,
          };

          // Cập nhật tổng thu/chi tháng mới
          final updatedTransaction = _transactions[index];
          final newMonth = (updatedTransaction['date'] as DateTime).month - 1;
          final amount = updatedTransaction['amount'] as double;
          final type = updatedTransaction['type'] as String;

          if (type == 'Chi') {
            _monthlyExpense[newMonth] += amount;
          } else {
            _monthlyIncome[newMonth] += amount;
          }
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã cập nhật giao dịch thành công'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi cập nhật giao dịch: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Hàm xóa giao dịch
  Future<void> _deleteTransaction(String transactionId) async {
    try {
      // Lưu thông tin giao dịch trước khi xóa để cập nhật UI
      final transaction = _transactions.firstWhere((t) => t['id'] == transactionId);
      final amount = transaction['amount'] as double;
      final type = transaction['type'] as String;
      final month = (transaction['date'] as DateTime).month - 1;

      await widget.realmService.deleteTransaction(transactionId);

      // Cập nhật UI ngay lập tức
      setState(() {
        _transactions.removeWhere((t) => t['id'] == transactionId);

        // Cập nhật tổng thu/chi tháng
        if (type == 'Chi') {
          _monthlyExpense[month] -= amount;
        } else {
          _monthlyIncome[month] -= amount;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã xóa giao dịch thành công'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi xóa giao dịch: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Hàm hiển thị dialog chỉnh sửa giao dịch
  void _showEditTransactionDialog(Map<String, dynamic> transaction) async {
    await _loadCategories();

    // Lọc danh mục theo loại giao dịch hiện tại
    final filteredCategories = _categories.where((c) => c.type == transaction['type']).toList();

    // Tìm ID của danh mục từ tên
    String selectedCategoryId = filteredCategories
        .firstWhere((c) => c.name == transaction['category'],
                  orElse: () => filteredCategories.first)
        .id;

    DateTime selectedDate = transaction['date'];
    final amountController = TextEditingController(
      text: transaction['amount'].toString(),
    );
    final noteController = TextEditingController(
      text: transaction['note'] ?? '',
    );
    String selectedType = transaction['type'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF232526), Color(0xFF181A20)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 24,
                  offset: Offset(0, -8),
                ),
              ],
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 16,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Chỉnh sửa giao dịch',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Chọn loại giao dịch
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: selectedType == 'Chi'
                                ? Colors.red.withOpacity(0.2)
                                : Colors.grey[850],
                            borderRadius: BorderRadius.circular(12),
                            border: selectedType == 'Chi'
                                ? Border.all(color: Colors.red.withOpacity(0.5))
                                : null,
                          ),
                          child: InkWell(
                            onTap: () {
                              setSheetState(() {
                                selectedType = 'Chi';
                                final newFilteredCategories = _categories.where((c) => c.type == 'Chi').toList();
                                if (newFilteredCategories.isNotEmpty) {
                                  selectedCategoryId = newFilteredCategories.first.id;
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                'Chi tiêu',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: selectedType == 'Chi' ? Colors.red : Colors.white70,
                                  fontWeight: selectedType == 'Chi' ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: selectedType == 'Thu'
                                ? Colors.green.withOpacity(0.2)
                                : Colors.grey[850],
                            borderRadius: BorderRadius.circular(12),
                            border: selectedType == 'Thu'
                                ? Border.all(color: Colors.green.withOpacity(0.5))
                                : null,
                          ),
                          child: InkWell(
                            onTap: () {
                              setSheetState(() {
                                selectedType = 'Thu';
                                final newFilteredCategories = _categories.where((c) => c.type == 'Thu').toList();
                                if (newFilteredCategories.isNotEmpty) {
                                  selectedCategoryId = newFilteredCategories.first.id;
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                'Thu nhập',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: selectedType == 'Thu' ? Colors.green : Colors.white70,
                                  fontWeight: selectedType == 'Thu' ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Chọn danh mục
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[850],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: selectedCategoryId,
                      items: _categories
                          .where((c) => c.type == selectedType)
                          .map((category) {
                        return DropdownMenuItem(
                          value: category.id,
                          child: Row(
                            children: [
                              Icon(
                                _getCategoryIcon(category.name, selectedType == 'Chi'),
                                color: _getCategoryColor(category.name, selectedType == 'Chi'),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                category.name,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setSheetState(() => selectedCategoryId = value);
                        }
                      },
                      decoration: const InputDecoration(
                        labelText: 'Danh mục',
                        labelStyle: TextStyle(color: Colors.white70),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                          borderSide: BorderSide(color: Colors.transparent),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                          borderSide: BorderSide(color: Colors.white24),
                        ),
                      ),
                      dropdownColor: Color(0xFF262626),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Nhập số tiền
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[850],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Số tiền',
                        labelStyle: TextStyle(color: Colors.white70),
                        prefixIcon: Icon(Icons.monetization_on, color: Colors.white70),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                          borderSide: BorderSide(color: Colors.transparent),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                          borderSide: BorderSide(color: Colors.white24),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Chọn ngày
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[850],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setSheetState(() => selectedDate = picked);
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, color: Colors.white70),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat('dd/MM/yyyy').format(selectedDate),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Ghi chú
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[850],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: noteController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Ghi chú',
                        labelStyle: TextStyle(color: Colors.white70),
                        prefixIcon: Icon(Icons.note, color: Colors.white70),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                          borderSide: BorderSide(color: Colors.transparent),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                          borderSide: BorderSide(color: Colors.white24),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Nút hành động
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.withOpacity(0.2),
                            foregroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.red.withOpacity(0.5)),
                            ),
                          ),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: Color(0xFF262626),
                                title: const Text(
                                  'Xác nhận xóa',
                                  style: TextStyle(color: Colors.white),
                                ),
                                content: const Text(
                                  'Bạn có chắc chắn muốn xóa giao dịch này?',
                                  style: TextStyle(color: Colors.white70),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Hủy'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context); // Đóng dialog xác nhận
                                      Navigator.pop(context); // Đóng form chỉnh sửa
                                      _deleteTransaction(transaction['id']);
                                    },
                                    child: const Text(
                                      'Xóa',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: const Text('Xóa'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: selectedType == 'Chi'
                                ? Colors.red.withOpacity(0.2)
                                : Colors.green.withOpacity(0.2),
                            foregroundColor: selectedType == 'Chi'
                                ? Colors.red
                                : Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: selectedType == 'Chi'
                                    ? Colors.red.withOpacity(0.5)
                                    : Colors.green.withOpacity(0.5),
                              ),
                            ),
                          ),
                          onPressed: () {
                            final newAmount = double.tryParse(amountController.text);
                            if (newAmount != null && newAmount > 0) {
                              _editTransaction(
                                transaction['id'],
                                newCategory: selectedCategoryId,
                                newAmount: newAmount,
                                newDate: selectedDate,
                                newType: selectedType,
                                newNote: noteController.text,
                              );
                              Navigator.pop(context);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Vui lòng nhập số tiền hợp lệ'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            }
                          },
                          child: const Text('Lưu'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}