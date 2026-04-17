import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../providers/expense_provider.dart';

class SpendingBarChartCard extends StatelessWidget {
  final ExpenseProvider expenseProvider;

  const SpendingBarChartCard({
    super.key,
    required this.expenseProvider,
  });

  @override
  Widget build(BuildContext context) {
    final last7Days = expenseProvider.last7DaysTotals();
    final maxAmount = last7Days.values.fold<double>(
      0,
      (max, val) => val > max ? val : max,
    );

    // Create bar group data
    final barGroups = last7Days.entries.toList().asMap().entries.map((e) {
      final index = e.key;
      final entry = e.value;
      
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: entry.value,
            color: Colors.blue,
            width: 16,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Last 7 Days',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  barGroups: barGroups,
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(
                    show: true,
                    drawVerticalLine: false,
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '\$${value.toInt()}',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= last7Days.length) {
                            return const Text('');
                          }
                          final key = last7Days.keys.toList()[index];
                          final parts = key.split('/');
                          return Text(
                            'M${parts[0]}/D${parts[1]}',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  minY: 0,
                  maxY: maxAmount > 0 ? maxAmount * 1.1 : 100,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
