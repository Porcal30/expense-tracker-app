import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../core/utils/currency_utils.dart';
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
    final entries = last7Days.entries.toList();

    final maxAmount = last7Days.values.fold<double>(
      0,
      (max, val) => val > max ? val : max,
    );

    const weekdayLabels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    final barGroups = entries.asMap().entries.map((e) {
      final index = e.key;
      final entry = e.value;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: entry.value,
            color: Colors.blue,
            width: 16,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(4),
            ),
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
                        reservedSize: 72,
                        getTitlesWidget: (value, meta) {
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              CurrencyUtils.format(value.toDouble()),
                              style: const TextStyle(fontSize: 9),
                              maxLines: 1,
                              overflow: TextOverflow.clip,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= entries.length) {
                            return const SizedBox.shrink();
                          }

                          final key = entries[index].key;
                          final parts = key.split('/');

                          int month = 1;
                          int day = 1;

                          if (parts.length == 2) {
                            month = int.tryParse(parts[0]) ?? 1;
                            day = int.tryParse(parts[1]) ?? 1;
                          }

                          final now = DateTime.now();
                          final date = DateTime(now.year, month, day);
                          final label = weekdayLabels[date.weekday % 7];

                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              label,
                              style: const TextStyle(fontSize: 10),
                            ),
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