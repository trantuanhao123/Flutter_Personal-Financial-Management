import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:do_an_mobile/models/models.dart';
import '../services/realm_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../neon_styles.dart';
import 'package:flutter/services.dart';

class ReportScreen extends StatefulWidget {
  final RealmService realmService;
  const ReportScreen({super.key, required this.realmService});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> with SingleTickerProviderStateMixin {
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
  int _selectedTimeRange = 1; // 0: tháng, 1: quý, 2: năm
  int _selectedChartTab = 0; // 0: Thu/Chi, 1: Danh mục

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<String> _months = ['Tháng 1', 'Tháng 2', 'Tháng 3', 'Tháng 4', 'Tháng 5', 'Tháng 6',
    'Tháng 7', 'Tháng 8', 'Tháng 9', 'Tháng 10', 'Tháng 11', 'Tháng 12'];
  final int _currentMonth = DateTime.now().month - 1;

  // Thêm các biến state mới
  bool _isLoading = false;
  List<GiaoDich> _transactions = [];
  double _totalIncome = 0;
  double _totalExpense = 0;
  double _totalRemain = 0;
  int? _touchedPieIndex;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
    _fetchData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });

    final realmService = widget.realmService;
    if (realmService == null) {
      setState(() {
        _transactions = [];
        _totalIncome = 0;
        _totalExpense = 0;
        _totalRemain = 0;
        _isLoading = false;
      });
      return;
    }

    try {
      if (!realmService.isInitialized) {
        await realmService.initialize();
      }

      // Define date range based on _selectedTimeRange
      DateTime startDate, endDate;
      final now = DateTime.now();
      switch (_selectedTimeRange) {
        case 0: // Month
          startDate = DateTime(now.year, now.month, 1);
          endDate = DateTime(now.year, now.month + 1, 0);
          break;
        case 1: // Quarter
          int quarter = (now.month / 3).ceil();
          startDate = DateTime(now.year, (quarter - 1) * 3 + 1, 1);
          endDate = DateTime(now.year, quarter * 3 + 1, 0);
          break;
        case 2: // Year
          startDate = DateTime(now.year, 1, 1);
          endDate = DateTime(now.year, 12, 31);
          break;
        default:
          startDate = DateTime(now.year, now.month, 1);
          endDate = DateTime(now.year, now.month + 1, 0);
      }

      // Fetch filtered transactions and categories
      final transactions = await realmService.getFilteredTransactions(
        startDate: startDate,
        endDate: endDate,
      );
      final categories = await realmService.getAllCategories();

      // Create a map of category IDs to names for faster lookup
      final categoryMap = {for (var c in categories) c.id: c};

      // Calculate totals and map category IDs to names
      double totalIncome = 0;
      double totalExpense = 0;
      final List<GiaoDich> mappedTransactions = [];

      for (var t in transactions) {
        // Get category from map, use "Khác" if not found
        final category = categoryMap[t.category] ?? categories.firstWhere(
          (c) => c.name == 'Khác' && c.type == t.type,
          orElse: () {
            final category = DanhMuc(
              'unknown',
              'Không xác định',
              t.type,
              icon: 'help_outline',
              color: '#9E9E9E',
            );
            return category;
          },
        );

        // Create new transaction with category name
        final mappedTransaction = GiaoDich(
          t.id,
          t.amount,
          category.name, // Use category name for display
          t.date,
          t.type,
          t.isPinned,
          note: t.note,
        );
        mappedTransactions.add(mappedTransaction);

        if (t.type == 'Thu') {
          totalIncome += t.amount;
        } else {
          totalExpense += t.amount;
        }
      }

      setState(() {
        _transactions = mappedTransactions;
        _totalIncome = totalIncome;
        _totalExpense = totalExpense;
        _totalRemain = totalIncome - totalExpense;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _transactions = [];
        _totalIncome = 0;
        _totalExpense = 0;
        _totalRemain = 0;
        _isLoading = false;
      });
      print('DEBUG: Error fetching Realm data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isAccessibility = MediaQuery.of(context).textScaleFactor > 1.2;
    final double baseFont = isAccessibility ? 20 : 16;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Báo cáo tài chính',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt_rounded, color: Colors.white),
            onPressed: _showFilterBottomSheet,
            tooltip: 'Bộ lọc',
          ),
        ],
      ),
      body: Container(
        decoration: NeonStyles.neonGalaxyBackground(),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : _transactions.isEmpty
              ? _buildEmptyState(theme, baseFont)
              : _buildMainContent(theme, baseFont),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: theme.primaryColor.withOpacity(0.25),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
          borderRadius: BorderRadius.circular(30),
        ),
        child: FloatingActionButton.extended(
          backgroundColor: theme.primaryColor,
          onPressed: () => _exportPdf(context),
          icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
          label: const Text('Xuất PDF', style: TextStyle(color: Colors.white)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, double baseFont) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inbox, size: 80, color: Colors.white70),
          const SizedBox(height: 20),
          Text(
            'Không có dữ liệu giao dịch!',
            style: GoogleFonts.inter(
              fontSize: baseFont + 4,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Thêm giao dịch để xem báo cáo chi tiết',
            style: GoogleFonts.inter(
              fontSize: baseFont,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.add),
            label: const Text('Thêm giao dịch'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: theme.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              textStyle: GoogleFonts.inter(fontSize: baseFont, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(ThemeData theme, double baseFont) {
    return Column(
      children: [
        _buildTimeRangeSelector(theme, baseFont),
        const SizedBox(height: 16),
        _buildSummarySection(theme, baseFont),
        const SizedBox(height: 16),
        Expanded(
          child: Container(
            decoration: NeonStyles.neonContentBackground(),
            child: Column(
              children: [
                _buildTabSelector(theme, baseFont),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: _selectedChartTab == 0
                        ? _buildIncomeExpenseReport(theme, baseFont)
                        : _buildCategoryReport(theme, baseFont),
                    transitionBuilder: (child, animation) =>
                        FadeTransition(opacity: animation, child: child),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeRangeSelector(ThemeData theme, double baseFont) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          Expanded(child: _buildTimeRangeButton(0, 'Tháng', theme, baseFont)),
          Expanded(child: _buildTimeRangeButton(1, 'Quý', theme, baseFont)),
          Expanded(child: _buildTimeRangeButton(2, 'Năm', theme, baseFont)),
        ],
      ),
    );
  }

  Widget _buildTimeRangeButton(int index, String label, ThemeData theme, double baseFont) {
    final isSelected = _selectedTimeRange == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedTimeRange = index;
        });
        _fetchData();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          color: isSelected ? Colors.white : Colors.transparent,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? theme.primaryColor : Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: baseFont,
          ),
        ),
      ),
    );
  }

  Widget _buildSummarySection(ThemeData theme, double baseFont) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: NeonStyles.neonCard(color: NeonStyles.neonGreen),
      child: Column(
        children: [
          _buildSummaryRow('Tổng thu nhập', _totalIncome, Colors.greenAccent, theme, baseFont),
          const Divider(color: Colors.white30),
          _buildSummaryRow('Tổng chi tiêu', _totalExpense, Colors.redAccent, theme, baseFont),
          const Divider(color: Colors.white30),
          _buildSummaryRow('Còn lại', _totalRemain,
              _totalRemain >= 0 ? Colors.greenAccent : Colors.redAccent, theme, baseFont),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, Color valueColor, ThemeData theme, double baseFont) {
    IconData icon = Icons.account_balance_wallet;
    if (label.contains('thu')) icon = Icons.trending_up;
    if (label.contains('chi')) icon = Icons.trending_down;
    if (label.contains('Còn lại')) icon = Icons.savings;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: valueColor, size: 20),
              const SizedBox(width: 12),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: baseFont,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          Text(
            currencyFormat.format(amount),
            style: GoogleFonts.inter(
              fontSize: baseFont,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSelector(ThemeData theme, double baseFont) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(child: _buildTabButton(0, 'Thu & Chi', theme, baseFont)),
          const SizedBox(width: 16),
          Expanded(child: _buildTabButton(1, 'Danh mục', theme, baseFont)),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String label, ThemeData theme, double baseFont) {
    final isSelected = _selectedChartTab == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedChartTab = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: isSelected
            ? BoxDecoration(
                gradient: NeonStyles.neonGalaxyGradient(),
                borderRadius: BorderRadius.circular(10),
              )
            : BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[600],
            fontWeight: FontWeight.bold,
            fontSize: baseFont,
          ),
        ),
      ),
    );
  }

  Widget _buildIncomeExpenseReport(ThemeData theme, double baseFont) {
    final data = _getTimeSeriesData();
    if (data.isEmpty) {
      return const Center(
        child: Text('Không có dữ liệu để hiển thị biểu đồ'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: NeonStyles.neonCard(color: NeonStyles.neonCyan),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Biểu đồ thu chi',
                style: NeonStyles.neonWhite(fontSize: 18),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 300,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: _getMaxValue(data) * 1.2,
                    barTouchData: BarTouchData(enabled: true),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) => _getBottomTitle(value.toInt()),
                          reservedSize: 30,
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) => _getLeftTitle(value),
                          reservedSize: 60,
                        ),
                      ),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: FlGridData(show: true),
                    borderData: FlBorderData(show: true),
                    barGroups: _buildBarGroups(data),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildLegend(baseFont),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryReport(ThemeData theme, double baseFont) {
    final data = _getExpenseByCategory();
    if (data.isEmpty) {
      return const Center(
        child: Text(
          'Không có dữ liệu danh mục để hiển thị',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    final total = data.values.fold(0.0, (a, b) => a + b);
    final sortedEntries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: NeonStyles.neonCard(color: NeonStyles.neonPurple),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chi tiêu theo danh mục',
                style: NeonStyles.neonWhite(fontSize: 18),
              ),
              const SizedBox(height: 16),
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.account_balance_wallet, color: Colors.white70),
                    const SizedBox(width: 8),
                    Text(
                      'Tổng chi: ${_formatCompactMoney(total)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              AspectRatio(
                aspectRatio: 1.3,
                child: PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              pieTouchResponse == null ||
                              pieTouchResponse.touchedSection == null) {
                            _touchedPieIndex = -1;
                            return;
                          }
                          _touchedPieIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                    sectionsSpace: 3,
                    centerSpaceRadius: 50,
                    sections: _buildPieChartSections(data),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Column(
                children: List.generate(sortedEntries.length, (index) {
                  final entry = sortedEntries[index];
                  final percent = (entry.value / total * 100).toStringAsFixed(1);
                  final color = _getCategoryColor(index);
                  final icon = _getCategoryIcon(entry.key);
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(icon, color: color, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.key,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                _formatCompactMoney(entry.value),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$percent%',
                            style: TextStyle(
                              color: color,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(int index) {
    final colors = [
      const Color(0xFF2196F3), // Blue
      const Color(0xFF4CAF50), // Green
      const Color(0xFFFFC107), // Amber
      const Color(0xFFE91E63), // Pink
      const Color(0xFF9C27B0), // Purple
      const Color(0xFF795548), // Brown
    ];
    return colors[index % colors.length];
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'ăn uống':
        return Icons.restaurant;
      case 'di chuyển':
        return Icons.directions_car;
      case 'mua sắm':
        return Icons.shopping_bag;
      case 'giải trí':
        return Icons.sports_esports;
      case 'giáo dục':
        return Icons.school;
      case 'sức khỏe':
        return Icons.medical_services;
      default:
        return Icons.category;
    }
  }

  List<PieChartSectionData> _buildPieChartSections(Map<String, double> data) {
    final total = data.values.fold(0.0, (a, b) => a + b);
    final sortedEntries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return List.generate(sortedEntries.length, (i) {
      final entry = sortedEntries[i];
      final percent = (entry.value / total * 100).toDouble();
      final color = _getCategoryColor(i);
      final isTouched = i == _touchedPieIndex;
      final fontSize = isTouched ? 22.0 : 16.0;
      final radius = isTouched ? 110.0 : 100.0;

      return PieChartSectionData(
        value: percent,
        title: '${percent.toStringAsFixed(1)}%',
        color: color,
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        badgeWidget: _buildBadgeWidget(
          entry.key,
          _formatCompactMoney(entry.value),
          color,
          _getCategoryIcon(entry.key),
        ),
        badgePositionPercentageOffset: 1.5,
      );
    });
  }

  Widget? _buildBadgeWidget(String category, String amount, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 4),
              Text(
                category,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCompactMoney(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    );
    
    if (amount >= 1000000000) {
      return '${(amount / 1000000000).toStringAsFixed(1)}tỷ';
    } else if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}tr';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}k';
    }
    return formatter.format(amount);
  }

  // Helper methods
  List<Map<String, double>> _getTimeSeriesData() {
    List<Map<String, double>> result = [];
    if (_transactions.isEmpty) return [];

    final now = DateTime.now();
    switch (_selectedTimeRange) {
      case 0: // Month - show weeks
        for (int week = 1; week <= 4; week++) {
          double income = 0, expense = 0;
          for (var t in _transactions) {
            int transactionWeek = (t.date.day / 7).ceil();
            if (transactionWeek == week) {
              if (t.type == 'Thu') income += t.amount;
              else expense += t.amount;
            }
          }
          result.add({'income': income, 'expense': expense});
        }
        break;
      case 1: // Quarter - show months
        int quarter = (now.month / 3).ceil();
        for (int i = 0; i < 3; i++) {
          int month = (quarter - 1) * 3 + i + 1;
          double income = 0, expense = 0;
          for (var t in _transactions) {
            if (t.date.month == month && t.date.year == now.year) {
              if (t.type == 'Thu') income += t.amount;
              else expense += t.amount;
            }
          }
          result.add({'income': income, 'expense': expense});
        }
        break;
      case 2: // Year - show quarters
        for (int quarter = 1; quarter <= 4; quarter++) {
          double income = 0, expense = 0;
          for (var t in _transactions) {
            int tQuarter = ((t.date.month - 1) / 3).floor() + 1;
            if (tQuarter == quarter && t.date.year == now.year) {
              if (t.type == 'Thu') income += t.amount;
              else expense += t.amount;
            }
          }
          result.add({'income': income, 'expense': expense});
        }
        break;
    }
    return result;
  }

  Map<String, double> _getExpenseByCategory() {
    Map<String, double> map = {};
    for (var t in _transactions) {
      if (t.type == 'Chi') {
        map[t.category] = (map[t.category] ?? 0) + t.amount;
      }
    }
    return map;
  }

  double _getMaxValue(List<Map<String, double>> data) {
    double max = 0;
    for (var item in data) {
      if (item['income']! > max) max = item['income']!;
      if (item['expense']! > max) max = item['expense']!;
    }
    return max == 0 ? 1000000 : max; // Minimum scale
  }

  Widget _getBottomTitle(int index) {
    String text = '';
    switch (_selectedTimeRange) {
      case 0: // Month
        text = 'T${index + 1}';
        break;
      case 1: // Quarter
        final months = ['T${(DateTime.now().month / 3).floor() * 3 + index + 1}'];
        text = months.isNotEmpty ? months[0] : 'T${index + 1}';
        break;
      case 2: // Year
        text = 'Q${index + 1}';
        break;
    }
    return Text(text, style: const TextStyle(fontSize: 12));
  }

  Widget _getLeftTitle(double value) {
    if (value == 0) return const Text('0');
    if (value >= 1000000) {
      return Text('${(value / 1000000).toStringAsFixed(0)}M',
          style: const TextStyle(fontSize: 10));
    }
    return Text('${(value / 1000).toStringAsFixed(0)}K',
        style: const TextStyle(fontSize: 10));
  }

  List<BarChartGroupData> _buildBarGroups(List<Map<String, double>> data) {
    return List.generate(data.length, (i) => BarChartGroupData(
      x: i,
      barRods: [
        BarChartRodData(
          toY: data[i]['income']!,
          color: Colors.green,
          width: 12,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(4),
          ),
        ),
        BarChartRodData(
          toY: data[i]['expense']!,
          color: Colors.red,
          width: 12,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(4),
          ),
        ),
      ],
    ));
  }

  Widget _buildLegend(double baseFont) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildLegendItem('Thu nhập', Colors.green, currencyFormat.format(_totalIncome), baseFont),
        _buildLegendItem('Chi tiêu', Colors.red, currencyFormat.format(_totalExpense), baseFont),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color, String value, double baseFont) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: baseFont - 2,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: baseFont - 2,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        height: 200,
        child: Column(
          children: [
            const Text('Bộ lọc', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            const Text('Tính năng đang phát triển...'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportPdf(BuildContext context) async {
    try {
      final pdf = pw.Document();
      
      // Load Roboto font from assets
      final fontData = await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
      final ttf = pw.Font.ttf(fontData);
      
      // Get category data
      final categoryData = _getExpenseByCategory();
      final total = categoryData.values.fold(0.0, (a, b) => a + b);
      final sortedEntries = categoryData.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'BÁO CÁO CHI TIÊU',
                          style: pw.TextStyle(
                            font: ttf,
                            fontSize: 24,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Thời gian: ${_getReportPeriod()}',
                          style: pw.TextStyle(
                            font: ttf,
                            fontSize: 12,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                    ),
                    pw.Text(
                      'Ngày xuất: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
                      style: pw.TextStyle(
                        font: ttf,
                        fontSize: 12,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 24),

                // Summary box
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue50,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Tổng chi tiêu',
                            style: pw.TextStyle(
                              font: ttf,
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blue900,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            currencyFormat.format(total),
                            style: pw.TextStyle(
                              font: ttf,
                              fontSize: 20,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.red700,
                            ),
                          ),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            'Số giao dịch',
                            style: pw.TextStyle(
                              font: ttf,
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blue900,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            '${_transactions.length}',
                            style: pw.TextStyle(
                              font: ttf,
                              fontSize: 20,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blue700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 24),

                // Category breakdown
                pw.Text(
                  'Chi tiết theo danh mục',
                  style: pw.TextStyle(
                    font: ttf,
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
                pw.SizedBox(height: 16),

                // Category table
                pw.Table(
                  border: pw.TableBorder.all(
                    color: PdfColors.grey300,
                    width: 0.5,
                  ),
                  children: [
                    // Header row
                    pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: PdfColors.blue100,
                      ),
                      children: [
                        _buildTableCell('Danh mục', ttf, isHeader: true),
                        _buildTableCell('Số tiền', ttf, isHeader: true, alignment: pw.Alignment.centerRight),
                        _buildTableCell('Tỷ lệ', ttf, isHeader: true, alignment: pw.Alignment.center),
                      ],
                    ),
                    // Data rows
                    ...sortedEntries.map((entry) {
                      final percent = (entry.value / total * 100).toStringAsFixed(1);
                      return pw.TableRow(
                        children: [
                          _buildTableCell(entry.key, ttf),
                          _buildTableCell(
                            currencyFormat.format(entry.value),
                            ttf,
                            alignment: pw.Alignment.centerRight,
                          ),
                          _buildTableCell(
                            '$percent%',
                            ttf,
                            alignment: pw.Alignment.center,
                          ),
                        ],
                      );
                    }).toList(),
                    // Total row
                    pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey100,
                      ),
                      children: [
                        _buildTableCell(
                          'Tổng cộng',
                          ttf,
                          isHeader: true,
                        ),
                        _buildTableCell(
                          currencyFormat.format(total),
                          ttf,
                          isHeader: true,
                          alignment: pw.Alignment.centerRight,
                        ),
                        _buildTableCell(
                          '100%',
                          ttf,
                          isHeader: true,
                          alignment: pw.Alignment.center,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi xuất PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  pw.Widget _buildTableCell(
    String text,
    pw.Font ttf, {
    bool isHeader = false,
    pw.Alignment alignment = pw.Alignment.centerLeft,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      alignment: alignment,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: ttf,
          fontSize: 12,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? PdfColors.blue900 : PdfColors.black,
        ),
      ),
    );
  }

  String _getReportPeriod() {
    final now = DateTime.now();
    switch (_selectedTimeRange) {
      case 0: // Month
        return 'Tháng ${now.month}/${now.year}';
      case 1: // Quarter
        final quarter = (now.month / 3).ceil();
        return 'Quý $quarter/${now.year}';
      case 2: // Year
        return 'Năm ${now.year}';
      default:
        return 'Tháng ${now.month}/${now.year}';
    }
  }
}