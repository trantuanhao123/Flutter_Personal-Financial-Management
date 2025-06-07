import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class StatisticsChart extends StatelessWidget {
  final List<double> monthlyExpense;
  final List<double> monthlyIncome;
  final NumberFormat currencyFormat;

  const StatisticsChart({
    Key? key,
    required this.monthlyExpense,
    required this.monthlyIncome,
    required this.currencyFormat,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.7,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: [
              Colors.black87,
              Colors.black54,
            ],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
        ),
        child: Stack(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    'Thống kê Thu - Chi theo tháng',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Đơn vị: ${currencyFormat.format(1000000)}',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: BarChart(
                        mainBarData(),
                        swapAnimationDuration: const Duration(milliseconds: 900),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  BarChartData mainBarData() {
    return BarChartData(
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          tooltipBgColor: Colors.black87,
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            String monthName = DateFormat('MM/yyyy').format(
              DateTime(DateTime.now().year, group.x.toInt() + 1),
            );
            return BarTooltipItem(
              '$monthName\n',
              const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              children: <TextSpan>[
                TextSpan(
                  text: rodIndex == 0
                      ? 'Chi: ${currencyFormat.format(rod.toY)}\n'
                      : 'Thu: ${currencyFormat.format(rod.toY)}',
                  style: TextStyle(
                    color: rodIndex == 0 ? Colors.red : Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            );
          },
        ),
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              return SideTitleWidget(
                axisSide: meta.axisSide,
                space: 16,
                child: Text(
                  'T${value.toInt() + 1}',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              );
            },
            reservedSize: 38,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 60,
            interval: 1000000,
            getTitlesWidget: (value, meta) {
              return SideTitleWidget(
                axisSide: meta.axisSide,
                space: 0,
                child: Text(
                  NumberFormat.compact(locale: 'vi').format(value),
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(
        show: false,
      ),
      barGroups: List.generate(12, (i) {
        return makeGroupData(i, monthlyExpense[i], monthlyIncome[i]);
      }),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 1000000,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.white10,
            strokeWidth: 1,
          );
        },
      ),
    );
  }

  BarChartGroupData makeGroupData(int x, double expense, double income) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: expense,
          color: Colors.red,
          width: 8,
          borderRadius: BorderRadius.circular(4),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 10000000,
            color: Colors.white10,
          ),
        ),
        BarChartRodData(
          toY: income,
          color: Colors.green,
          width: 8,
          borderRadius: BorderRadius.circular(4),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 10000000,
            color: Colors.white10,
          ),
        ),
      ],
    );
  }
} 