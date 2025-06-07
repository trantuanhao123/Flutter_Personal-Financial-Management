import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:do_an_mobile/models/models.dart';
import 'package:uuid/uuid.dart' as uuid; // Thêm prefix để tránh xung đột
import '../services/realm_service.dart';
import '../neon_styles.dart';

class BudgetScreen extends StatefulWidget {
  final RealmService realmService;

  const BudgetScreen({super.key, required this.realmService});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _categoryNameController = TextEditingController();
  final TextEditingController _budgetLimitController = TextEditingController();
  String _categoryType = 'Chi'; // Mặc định là 'Chi'
  String? _selectedFilter; // Thêm bộ lọc
  final currencyFormat =
  NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);

  late Future<List<DanhMuc>> _categoriesFuture;
  late Future<List<GiaoDich>> _transactionsFuture;
  late AnimationController _animationController;
  final _uuid = uuid.Uuid();

  @override
  void initState() {
    super.initState();
    _refreshData();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _categoryNameController.dispose();
    _budgetLimitController.dispose();
    super.dispose();
  }

  void _refreshData() {
    _categoriesFuture = widget.realmService.loadCategories();
    _transactionsFuture = widget.realmService.loadTransactions();
  }

  void _addCategory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
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
              children: <Widget>[
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Thêm danh mục mới',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(Icons.drag_handle),
                  ],
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _categoryNameController,
                  decoration: InputDecoration(
                    hintText: 'Tên danh mục',
                    filled: true,
                    fillColor: Colors.grey[850],
                    labelStyle: TextStyle(color: Colors.white),
                    hintStyle: TextStyle(color: Colors.white54),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.category),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Loại danh mục',
                    filled: true,
                    fillColor: Colors.grey[850],
                    labelStyle: TextStyle(color: Colors.white),
                    hintStyle: TextStyle(color: Colors.white54),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.type_specimen),
                  ),
                  value: _categoryType,
                  items: <String>['Thu', 'Chi'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _categoryType = newValue!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _budgetLimitController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    hintText: 'Giới hạn chi tiêu (VNĐ)',
                    filled: true,
                    fillColor: Colors.grey[850],
                    labelStyle: TextStyle(color: Colors.white),
                    hintStyle: TextStyle(color: Colors.white54),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.monetization_on),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[200],
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          _clearInputFields();
                        },
                        child: const Text('Hủy'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFa259ff),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          if (_categoryNameController.text.isNotEmpty) {
                            double? limit;
                            if (_categoryType == 'Chi' &&
                                _budgetLimitController.text.isNotEmpty) {
                              limit = double.tryParse(
                                  _budgetLimitController.text.trim());
                            }
                            // Nếu là Thu thì limit luôn là null
                            if (_categoryType == 'Thu') limit = null;
                            final newCategory = DanhMuc(
                              _uuid.v4(),
                              _categoryNameController.text.trim(),
                              _categoryType,
                              icon: "more_horiz",
                              color: "#9E9E9E",
                              limit: limit,
                            );
                            await widget.realmService.addCategory(newCategory);
                            setState(() { _refreshData(); });
                            Navigator.of(context).pop();
                            _clearInputFields();
                          }
                        },
                        child: const Text('Thêm'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  void _clearInputFields() {
    _categoryNameController.clear();
    _budgetLimitController.clear();
    _categoryType = 'Chi';
  }

  void _deleteCategory(DanhMuc category) async {
    try {
      final categoryId = category.id; // Sử dụng id thay vì name

      // Kiểm tra giao dịch liên quan
      final transactions = await widget.realmService.loadTransactions();
      final relatedTransactions = transactions
          .where((t) => t.category == categoryId)
          .toList();

      if (relatedTransactions.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Không thể xóa danh mục ${category.name} vì có giao dịch đang sử dụng.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Xóa danh mục thông qua RealmService
      await widget.realmService.deleteCategory(categoryId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã xóa danh mục ${category.name}'),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {
        _refreshData();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi xóa danh mục: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDeleteConfirmation(DanhMuc category) {
    final categoryName = category.name;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Xác nhận xóa'),
          content: Text('Bạn có chắc chắn muốn xóa danh mục "$categoryName"?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Hủy'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Xóa', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteCategory(category);
              },
            ),
          ],
        );
      },
    );
  }

  void _showEditCategoryDialog(DanhMuc category) {
    final TextEditingController nameController = TextEditingController(text: category.name);
    final TextEditingController limitController = TextEditingController(text: category.limit?.toString() ?? '');
    String type = category.type;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Sửa ngân sách'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Tên ngân sách'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: type,
                  items: ['Thu', 'Chi'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (val) => type = val!,
                  decoration: const InputDecoration(labelText: 'Loại'),
                ),
                TextField(
                  controller: limitController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Giới hạn (VNĐ)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () async {
                final newName = nameController.text.trim();
                final newType = type;
                final newLimit = newType == 'Chi' ? double.tryParse(limitController.text.trim()) : null;
                if (newName.isNotEmpty) {
                  final updated = DanhMuc(
                    category.id,
                    newName,
                    newType,
                    icon: category.icon,
                    color: category.color,
                    limit: newLimit,
                  );
                  await widget.realmService.updateCategory(updated);
                  setState(() { _refreshData(); });
                  Navigator.pop(context);
                }
              },
              child: const Text('Lưu'),
            ),
            TextButton(
              onPressed: () async {
                await widget.realmService.deleteCategory(category.name);
                setState(() { _refreshData(); });
                Navigator.pop(context);
              },
              child: const Text('Xóa', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: NeonStyles.neonGalaxyBackground(),
            height: 250,
            width: double.infinity,
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(theme),
                Expanded(
                  child: Container(
                    decoration: NeonStyles.neonContentBackground(),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                      child: Column(
                        children: [
                          _buildFilterBar(theme),
                          Expanded(
                            child: FutureBuilder<List<DanhMuc>>(
                              future: _categoriesFuture,
                              builder: (context, categoriesSnapshot) {
                                if (categoriesSnapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                      child: CircularProgressIndicator());
                                }

                                if (categoriesSnapshot.hasError) {
                                  return Center(
                                      child: Text(
                                          'Lỗi: ${categoriesSnapshot.error}'));
                                }

                                final allCategories = categoriesSnapshot.data!;
                                final filteredCategories = _selectedFilter != null
                                    ? allCategories
                                    .where((c) => c.type == _selectedFilter)
                                    .toList()
                                    : allCategories;

                                return FutureBuilder<List<GiaoDich>>(
                                  future: _transactionsFuture,
                                  builder: (context, transactionsSnapshot) {
                                    if (transactionsSnapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Center(
                                          child: CircularProgressIndicator());
                                    }

                                    if (transactionsSnapshot.hasError) {
                                      return Center(
                                          child: Text(
                                              'Lỗi: ${transactionsSnapshot.error}'));
                                    }

                                    final allTransactions =
                                    transactionsSnapshot.data!;

                                    // Nếu không có danh mục nào, hiển thị thông báo
                                    if (filteredCategories.isEmpty) {
                                      return Center(
                                        child: Column(
                                          mainAxisAlignment:
                                          MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.category_outlined,
                                                size: 72,
                                                color: Colors.grey[400]),
                                            const SizedBox(height: 16),
                                            const Text(
                                              'Chưa có danh mục nào',
                                              style: TextStyle(
                                                fontSize: 18,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            const SizedBox(height: 24),
                                            ElevatedButton.icon(
                                              onPressed: () =>
                                                  _addCategory(context),
                                              icon: const Icon(Icons.add),
                                              label:
                                              const Text('Thêm danh mục mới'),
                                              style: ElevatedButton.styleFrom(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 24, vertical: 12),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                  BorderRadius.circular(30),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }

                                    return AnimatedBuilder(
                                      animation: _animationController,
                                      builder: (context, child) {
                                        return ListView.builder(
                                          padding: const EdgeInsets.all(16),
                                          itemCount: filteredCategories.length,
                                          itemBuilder: (context, index) {
                                            final category =
                                            filteredCategories[index];
                                            final categoryTransactions = allTransactions
                                                .where((t) =>
                                            t.category == category.id &&
                                                t.type == category.type)
                                                .toList();

                                            double totalSpent = 0;
                                            if (categoryTransactions.isNotEmpty) {
                                              totalSpent = categoryTransactions
                                                  .map((t) => t.amount)
                                                  .reduce((a, b) => a + b);
                                            }

                                            // Tính phần trăm ngân sách đã chi
                                            double percentage = 0;
                                            if (category.type == 'Chi' &&
                                                category.limit != null &&
                                                category.limit! > 0) {
                                              percentage =
                                                  (totalSpent / category.limit!) *
                                                      100;
                                              // Giới hạn ở 100%
                                              percentage =
                                              percentage > 100 ? 100 : percentage;
                                            }

                                            // Màu sắc dựa trên mức độ chi tiêu
                                            Color progressColor = Colors.green;
                                            if (percentage > 90) {
                                              progressColor = Colors.red;
                                            } else if (percentage > 70) {
                                              progressColor = Colors.orange;
                                            } else if (percentage > 50) {
                                              progressColor = Colors.amber;
                                            }

                                            // Animation
                                            final Animation<double> animation =
                                            CurvedAnimation(
                                              parent: _animationController,
                                              curve: Interval(
                                                0.1 * index,
                                                0.1 * index + 0.6,
                                                curve: Curves.easeOut,
                                              ),
                                            );

                                            return AnimatedBuilder(
                                              animation: animation,
                                              builder: (context, child) {
                                                return Transform.translate(
                                                  offset: Offset(
                                                      0, 50 * (1 - animation.value)),
                                                  child: Opacity(
                                                    opacity: animation.value,
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        gradient: LinearGradient(
                                                          colors: [
                                                            Color(0xFF232526), // xanh tím than
                                                            Color(0xFF1a2980), // tím đậm
                                                            Color(0xFFa259ff), // tím neon
                                                          ],
                                                          begin: Alignment.topLeft,
                                                          end: Alignment.bottomRight,
                                                        ),
                                                        borderRadius: BorderRadius.circular(18),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Color(0xFFa259ff).withOpacity(0.4), // shadow tím neon
                                                            blurRadius: 32,
                                                            spreadRadius: 2,
                                                            offset: Offset(0, 0),
                                                          ),
                                                        ],
                                                        border: Border.all(
                                                          color: Color(0xFFa259ff), // viền tím neon
                                                          width: 2,
                                                        ),
                                                      ),
                                                      margin: const EdgeInsets.only(
                                                          bottom: 16),
                                                      child: InkWell(
                                                        borderRadius:
                                                        BorderRadius.circular(16),
                                                        onTap: () => _showEditCategoryDialog(category),
                                                        child: Padding(
                                                          padding:
                                                          const EdgeInsets.all(16),
                                                          child: Column(
                                                            crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                            children: [
                                                              Row(
                                                                mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .spaceBetween,
                                                                children: [
                                                                  Row(
                                                                    children: [
                                                                      Container(
                                                                        padding:
                                                                        const EdgeInsets.all(
                                                                            8),
                                                                        decoration:
                                                                        BoxDecoration(
                                                                          color: category
                                                                              .type ==
                                                                              'Chi'
                                                                              ? Colors.red
                                                                              .withOpacity(0.1)
                                                                              : Colors.green
                                                                              .withOpacity(0.1),
                                                                          borderRadius:
                                                                          BorderRadius.circular(8),
                                                                        ),
                                                                        child: Icon(
                                                                          category.type ==
                                                                              'Chi'
                                                                              ? Icons.remove
                                                                              : Icons.add,
                                                                          color: category.type ==
                                                                              'Chi'
                                                                              ? Colors.red
                                                                              : Colors.green,
                                                                        ),
                                                                      ),
                                                                      const SizedBox(
                                                                          width: 12),
                                                                      Text(
                                                                        category.name,
                                                                        style: const TextStyle(
                                                                          fontSize: 18,
                                                                          fontWeight:
                                                                          FontWeight.bold,
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                  Container(
                                                                    padding:
                                                                    const EdgeInsets.symmetric(
                                                                        horizontal: 8,
                                                                        vertical: 4),
                                                                    decoration:
                                                                    BoxDecoration(
                                                                      color: category.type ==
                                                                          'Chi'
                                                                          ? Colors.red
                                                                          .withOpacity(0.1)
                                                                          : Colors.green
                                                                          .withOpacity(0.1),
                                                                      borderRadius:
                                                                      BorderRadius.circular(12),
                                                                    ),
                                                                    child: Text(
                                                                      category.type,
                                                                      style: TextStyle(
                                                                        color: category.type ==
                                                                            'Chi'
                                                                            ? Colors.red
                                                                            : Colors.green,
                                                                        fontWeight:
                                                                        FontWeight.bold,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                              const SizedBox(
                                                                  height: 16),
                                                              if (category.type ==
                                                                  'Chi' &&
                                                                  category.limit != null)
                                                                Column(
                                                                  crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                                  children: [
                                                                    Row(
                                                                      mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .spaceBetween,
                                                                      children: [
                                                                        Text(
                                                                          currencyFormat
                                                                              .format(totalSpent),
                                                                          style: TextStyle(
                                                                            fontSize: 16,
                                                                            fontWeight:
                                                                            FontWeight.bold,
                                                                            color: percentage > 90
                                                                                ? Colors.red
                                                                                : Colors.grey[800],
                                                                          ),
                                                                        ),
                                                                        Text(
                                                                          '${percentage.toStringAsFixed(0)}%',
                                                                          style: TextStyle(
                                                                            fontWeight:
                                                                            FontWeight.bold,
                                                                            color:
                                                                            progressColor,
                                                                          ),
                                                                        ),
                                                                        Text(
                                                                          currencyFormat
                                                                              .format(category.limit),
                                                                          style: TextStyle(
                                                                            fontWeight:
                                                                            FontWeight.bold,
                                                                            color:
                                                                            Colors.grey[600],
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                    const SizedBox(
                                                                        height: 8),
                                                                    ClipRRect(
                                                                      borderRadius:
                                                                      BorderRadius.circular(8),
                                                                      child:
                                                                      LinearProgressIndicator(
                                                                        value:
                                                                        percentage / 100,
                                                                        minHeight: 8,
                                                                        backgroundColor:
                                                                        Colors.grey[200],
                                                                        valueColor:
                                                                        AlwaysStoppedAnimation<Color>(progressColor),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                )
                                                              else
                                                                Text(
                                                                  currencyFormat
                                                                      .format(totalSpent),
                                                                  style: TextStyle(
                                                                    fontSize: 18,
                                                                    fontWeight:
                                                                    FontWeight.bold,
                                                                    color: category
                                                                        .type ==
                                                                        'Chi'
                                                                        ? Colors.red
                                                                        : Colors.green,
                                                                  ),
                                                                ),
                                                              const SizedBox(
                                                                  height: 8),
                                                              Text(
                                                                '${categoryTransactions.length} giao dịch',
                                                                style: TextStyle(
                                                                  color: Colors.grey[600],
                                                                  fontSize: 14,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            );
                                          },
                                        );
                                      },
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: theme.primaryColor,
        onPressed: () => _addCategory(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quản lý ngân sách',
                style: NeonStyles.neonWhite(fontSize: 24),
              ),
              IconButton(
                icon: const Icon(Icons.search, color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Tổng đã chi tháng 2',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                currencyFormat.format(0),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Icon(Icons.visibility, color: Colors.white),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildFilterBar(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          _filterButton(theme, null, 'Tất cả'),
          _filterButton(theme, 'Thu', 'Thu'),
          _filterButton(theme, 'Chi', 'Chi'),
        ],
      ),
    );
  }

  Widget _filterButton(ThemeData theme, String? filter, String label) {
    final isSelected = _selectedFilter == filter;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          setState(() {
            _selectedFilter = filter;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color:
            isSelected ? theme.primaryColor.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? theme.primaryColor : Colors.grey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}