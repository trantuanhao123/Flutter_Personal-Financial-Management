import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:do_an_mobile/models/models.dart';
import 'package:do_an_mobile/widgets/edit_transaction.dart';
import '../services/realm_service.dart';

class TransactionList extends StatefulWidget {
  final RealmService realmService;

  const TransactionList({super.key, required this.realmService});

  @override
  State<TransactionList> createState() => _TransactionListState();
}

class _TransactionListState extends State<TransactionList> with TickerProviderStateMixin {
  int _selectedMonth = DateTime.now().month;
  late TabController _tabController;
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'VNĐ');
  final NumberFormat _amountFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '');
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');
  
  List<GiaoDich> _transactions = [];
  List<DanhMuc> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final transactions = await widget.realmService.loadTransactions(); // Sửa ở đây
      final categories = await widget.realmService.getAllCategories();

      setState(() {
        _transactions = transactions;
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi tải dữ liệu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Map<String, List<GiaoDich>> _groupTransactions(List<GiaoDich> transactions) {
    final Map<String, List<GiaoDich>> grouped = {};
    grouped['Không có danh mục'] = [];

    for (var transaction in transactions) {
      final category = transaction.category;
      if (!grouped.containsKey(category)) {
        grouped[category] = [];
      }
      grouped[category]!.add(transaction);
    }

    grouped.forEach((key, value) {
      value.sort((a, b) => b.date.compareTo(a.date));
    });

    if (grouped['Không có danh mục']!.isEmpty) {
      grouped.remove('Không có danh mục');
    }

    return grouped;
  }

  Future<void> _pinTransaction(GiaoDich transaction) async {
    try {
      await widget.realmService.pinTransaction(transaction);
      
      // Cập nhật trạng thái local
      setState(() {
        final index = _transactions.indexWhere((t) => t.id == transaction.id);
        if (index != -1) {
          _transactions[index].isPinned = !_transactions[index].isPinned;
        }
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              transaction.isPinned ? 'Đã ghim giao dịch' : 'Đã bỏ ghim giao dịch',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi thay đổi trạng thái ghim: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _deleteTransaction(GiaoDich transaction) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: const Text('Bạn có chắc chắn muốn xóa giao dịch này không?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await widget.realmService.deleteTransaction(transaction.id);
                  
                  // Cập nhật danh sách local
                  setState(() {
                    _transactions.removeWhere((t) => t.id == transaction.id);
                  });
                  
                  Navigator.of(context).pop();
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã xóa giao dịch')),
                    );
                  }
                } catch (e) {
                  Navigator.of(context).pop();
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Lỗi khi xóa giao dịch: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Xóa', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _editTransaction(GiaoDich transaction) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditTransactionDialog(
          realmService: widget.realmService,
          transaction: transaction,
          onSave: (updatedTransaction) async {
            await widget.realmService.updateTransaction(updatedTransaction);
          },
        ),
      ),
    );
    
    if (result == true) {
      await _loadData(); // Tải lại dữ liệu sau khi chỉnh sửa
    }
  }

  Widget _buildTransactionList(List<GiaoDich> transactions) {
    final groupedTransactions = _groupTransactions(transactions);

    if (transactions.isEmpty) {
      return const Center(child: Text('Không có giao dịch nào'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: groupedTransactions.length,
      itemBuilder: (context, index) {
        final category = groupedTransactions.keys.elementAt(index);
        final categoryTransactions = groupedTransactions[category]!;

        final totalAmount = categoryTransactions.fold<double>(
          0,
          (sum, t) => sum + (t.type == 'Chi' ? -t.amount : t.amount),
        );

        return ExpansionTile(
          title: Text(
            category,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            'Tổng: ${_currencyFormat.format(totalAmount)}',
            style: TextStyle(
              color: totalAmount >= 0 ? Colors.green : Colors.red,
            ),
          ),
          initiallyExpanded: true,
          children: categoryTransactions.map((transaction) {
            return ListTile(
              title: Text(
                '${transaction.type == 'Chi' ? '-' : '+'}${_amountFormat.format(transaction.amount)}',
              ),
              subtitle: Text(
                _dateFormat.format(transaction.date),
              ),
              leading: IconButton(
                icon: Icon(
                  transaction.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                ),
                onPressed: () => _pinTransaction(transaction),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _editTransaction(transaction),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteTransaction(transaction),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    final today = DateTime.now();

    final todayTransactions = _transactions.where((t) =>
      t.date.year == today.year && t.date.month == today.month && t.date.day == today.day).toList();

    final monthTransactions = _transactions.where((t) =>
      t.date.month == _selectedMonth && t.date.year == today.year).toList();

    return Column(
      children: [
        TabBar(
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).primaryColor,
          tabs: const [
            Tab(text: 'Hôm nay'),
            Tab(text: 'Theo tháng'),
            Tab(text: 'Tất cả'),
          ],
          controller: _tabController,
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildTransactionList(todayTransactions),
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: DropdownButton<int>(
                      value: _selectedMonth,
                      items: List.generate(12, (index) {
                        final month = index + 1;
                        return DropdownMenuItem(
                          value: month,
                          child: Text('Tháng $month'),
                        );
                      }),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedMonth = value;
                          });
                        }
                      },
                    ),
                  ),
                  Expanded(child: _buildTransactionList(monthTransactions)),
                ],
              ),
              _buildTransactionList(_transactions),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton(
            onPressed: _loadData,
            child: const Text('Làm mới'),
          ),
        ),
      ],
    );
  }
}