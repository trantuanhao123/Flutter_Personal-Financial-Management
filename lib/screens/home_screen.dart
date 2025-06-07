import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/realm_service.dart';
import '../models/models.dart';
import 'package:intl/intl.dart';
import '../neon_styles.dart';
import 'transaction_screen.dart';

class HomeScreen extends StatefulWidget {
  final RealmService realmService;

  const HomeScreen({super.key, required this.realmService});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late Future<List<Map<String, dynamic>>> _transactionsFuture;
  late Future<Map<String, double>> _monthlySummaryFuture;
  late AnimationController _animationController;
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
  
  int _tappedIndex = -1;
  
  @override
  void initState() {
    super.initState();
    _refreshData();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  void _refreshData() {
    final now = DateTime.now();
    _transactionsFuture = widget.realmService.getAllTransactions();
    _monthlySummaryFuture = widget.realmService.getMonthlySummary(now.year, now.month);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final theme = Theme.of(context);
    
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _refreshData();
          });
        },
        child: Stack(
          children: [
            // Gradient background
            Container(
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF181A20), Color(0xFF232526)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            
            // Content
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Bar
                  _buildAppBar(),
                  
                  // Tóm tắt tài chính
                  _buildFinancialSummary(),
                  
                  // Main Content
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: NeonStyles.neonGalaxyGradient(),
                        ),
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Biểu đồ thu chi
                              _buildExpenseIncomeChart(now),
                              
                              const SizedBox(height: 24),
                              
                              // Giao dịch gần đây
                              _buildRecentTransactions(),
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
      ),
    );
  }
  
  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Tổng quan tài chính',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: NeonStyles.neonGalaxyGradient(),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: NeonStyles.neonCyan.withOpacity(0.5),
                  blurRadius: 16,
                  offset: Offset(0, 0),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () {
                setState(() {
                  _refreshData();
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã cập nhật dữ liệu')),
                );
              },
              tooltip: 'Làm mới dữ liệu',
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFinancialSummary() {
    final balanceAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    
    return FutureBuilder<Map<String, double>>(
      future: _monthlySummaryFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Lỗi: ${snapshot.error}',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          );
        }
        
        final data = snapshot.data!;
        final totalIncome = data['income'] ?? 0.0;
        final totalExpense = data['expense'] ?? 0.0;
        final balance = totalIncome - totalExpense;
        
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: AnimatedBuilder(
            animation: balanceAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: balanceAnimation.value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - balanceAnimation.value)),
                  child: child,
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Số dư hiện tại',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currencyFormat.format(balance),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      balance >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                      color: balance >= 0 ? Colors.green : Colors.red,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _buildBalanceCard(
                        'Thu', 
                        totalIncome, 
                        Colors.green,
                        Icons.arrow_upward,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildBalanceCard(
                        'Chi', 
                        totalExpense, 
                        Colors.red,
                        Icons.arrow_downward,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }
    );
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
  
  Widget _buildBalanceCard(String title, double amount, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: NeonStyles.neonGalaxyGradient(),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: NeonStyles.neonCyan.withOpacity(0.5),
            blurRadius: 32,
            spreadRadius: 4,
            offset: Offset(0, 0),
          ),
        ],
        border: Border.all(
          color: NeonStyles.neonCyan,
          width: 3,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: NeonStyles.neonCyan.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: NeonStyles.neonCyan, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: NeonStyles.neonWhite(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _formatCompactCurrency(amount),
            style: NeonStyles.neonWhite(fontSize: 16),
          ),
        ],
      ),
    );
  }
  
  Widget _buildExpenseIncomeChart(DateTime now) {
    final chartAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
      ),
    );
    
    return AnimatedBuilder(
      animation: chartAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: chartAnimation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - chartAnimation.value)),
            child: child,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: NeonStyles.neonGalaxyGradient(),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: NeonStyles.neonCyan.withOpacity(0.4),
              blurRadius: 32,
              offset: Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: NeonStyles.neonCyan,
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Biểu đồ thu chi tháng ${now.month}/${now.year}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 250,
                child: FutureBuilder<Map<String, double>>(
                  future: _monthlySummaryFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    if (snapshot.hasError) {
                      return Center(child: Text('Lỗi: ${snapshot.error}'));
                    }
                    
                    final data = snapshot.data!;
                    final totalIncome = data['income'] ?? 0.0;
                    final totalExpense = data['expense'] ?? 0.0;
                    
                    return BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: (totalIncome > totalExpense ? totalIncome : totalExpense) * 1.2,
                        barGroups: [
                          BarChartGroupData(
                            x: 0,
                            barRods: [
                              BarChartRodData(
                                toY: totalIncome,
                                color: Colors.greenAccent,
                                width: 30,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(6),
                                  topRight: Radius.circular(6),
                                ),
                              ),
                            ],
                          ),
                          BarChartGroupData(
                            x: 1,
                            barRods: [
                              BarChartRodData(
                                toY: totalExpense,
                                color: Colors.redAccent,
                                width: 30,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(6),
                                  topRight: Radius.circular(6),
                                ),
                              ),
                            ],
                          ),
                        ],
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  '${(value / 1000000).toStringAsFixed(1)}M',
                                  style: const TextStyle(fontSize: 12, color: Colors.white),
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                switch (value.toInt()) {
                                  case 0:
                                    return const Padding(
                                      padding: EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        'Thu',
                                        style: TextStyle(
                                          color: Colors.greenAccent,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    );
                                  case 1:
                                    return const Padding(
                                      padding: EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        'Chi',
                                        style: TextStyle(
                                          color: Colors.redAccent,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    );
                                  default:
                                    return const Text('');
                                }
                              },
                            ),
                          ),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: false),
                        gridData: const FlGridData(show: false),
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              String formattedValue = currencyFormat.format(rod.toY);
                              String text = groupIndex == 0 ? 'Thu nhập: ' : 'Chi tiêu: ';
                              return BarTooltipItem(
                                text + formattedValue,
                                const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  }
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildRecentTransactions() {
    final transactionsAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );
    
    return AnimatedBuilder(
      animation: transactionsAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: transactionsAnimation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - transactionsAnimation.value)),
            child: child,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: NeonStyles.neonGalaxyGradient(),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: NeonStyles.neonPurple.withOpacity(0.4),
              blurRadius: 24,
              offset: Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: NeonStyles.neonPurple,
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Giao dịch gần đây',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: NeonStyles.neonPurple,
                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                      shadowColor: NeonStyles.neonPurple.withOpacity(0.5),
                      elevation: 2,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TransactionScreen(
                            realmService: widget.realmService,
                          ),
                          maintainState: true,
                          fullscreenDialog: false,
                        ),
                      ).then((_) {
                        _refreshData();
                      });
                    },
                    child: const Text('Xem tất cả'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 300,
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _transactionsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    if (snapshot.hasError) {
                      return Center(child: Text('Lỗi: ${snapshot.error}'));
                    }
                    
                    final transactions = snapshot.data!;
                    
                    if (transactions.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Chưa có giao dịch nào',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    return ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: transactions.length,
                      itemBuilder: (context, index) {
                        final transaction = transactions[index];
                        final isIncome = transaction['type'] == 'Thu';
                        Color color;
                        try {
                          if (transaction['color'].startsWith('#')) {
                            // Xử lý mã màu hex
                            final hex = transaction['color'].replaceAll('#', '');
                            color = Color(int.parse('FF$hex', radix: 16));
                          } else {
                            // Xử lý tên màu
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
                            color = colorMap[transaction['color'].toLowerCase()] ?? Colors.grey;
                          }
                        } catch (e) {
                          print('Lỗi chuyển đổi màu: $e');
                          color = Colors.grey;
                        }
                        
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withOpacity(0.3),
                                color.withOpacity(0.1),
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                left: 8,
                                top: 0,
                                bottom: 0,
                                child: Center(
                                  child: Icon(
                                    _getIconData(transaction['icon']),
                                    color: color,
                                    size: 24,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(48, 8, 16, 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          transaction['category'],
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          '${isIncome ? "+" : "-"}${_formatCompactCurrency(transaction['amount'])}',
                                          style: TextStyle(
                                            color: color,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      DateFormat('dd/MM/yyyy HH:mm').format(transaction['date']),
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 12,
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
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
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
    
    return iconMap[iconName] ?? Icons.help_outline;
  }

  IconData _getCategoryIcon(String category, bool isExpense) {
    final Map<String, IconData> expenseIcons = {
      'Ăn uống': Icons.restaurant,
      'Di chuyển': Icons.directions_car,
      'Mua sắm': Icons.shopping_bag,
      'Giải trí': Icons.movie,
      'Hóa đơn': Icons.receipt,
      'Khác': Icons.category,
    };

    final Map<String, IconData> incomeIcons = {
      'Lương': Icons.work,
      'Thưởng': Icons.star,
      'Đầu tư': Icons.trending_up,
      'Bán hàng': Icons.store,
      'Khác': Icons.category,
    };

    return isExpense 
        ? expenseIcons[category] ?? Icons.help_outline
        : incomeIcons[category] ?? Icons.help_outline;
  }

  Color _getCategoryColor(String category, bool isExpense) {
    final Map<String, Color> expenseColors = {
      'Ăn uống': Colors.blue,
      'Di chuyển': Colors.red,
      'Mua sắm': Colors.green,
      'Giải trí': Colors.purple,
      'Hóa đơn': Colors.orange,
      'Khác': Colors.grey,
    };

    final Map<String, Color> incomeColors = {
      'Lương': Colors.green,
      'Thưởng': Colors.amber,
      'Đầu tư': Colors.blue,
      'Bán hàng': Colors.orange,
      'Khác': Colors.grey,
    };

    return isExpense 
        ? expenseColors[category] ?? Colors.grey
        : incomeColors[category] ?? Colors.grey;
  }
}