import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../core/utils/currency_utils.dart';
import '../providers/category_provider.dart';
import '../providers/expense_provider.dart';

class CategoryPieChartCard extends StatelessWidget {
  final ExpenseProvider expenseProvider;
  final CategoryProvider categoryProvider;

  const CategoryPieChartCard({
    super.key,
    required this.expenseProvider,
    required this.categoryProvider,
  });

  @override
  Widget build(BuildContext context) {
    final totals = expenseProvider.totalsByCategory();
    final filteredTotals = Map.fromEntries(
      totals.entries.where((e) => e.value > 0),
    );

    if (filteredTotals.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 200,
            child: Center(
              child: Text(
                'No category data',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
        ),
      );
    }

    final total = filteredTotals.values.fold<double>(0, (a, b) => a + b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Spending by Category',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: PieChart(
                PieChartData(
                  sections: filteredTotals.entries.map((entry) {
                    final categoryId = entry.key;
                    final amount = entry.value;
                    final percentage = (amount / total * 100);
                    final category = categoryProvider.getById(categoryId);

                    return PieChartSectionData(
                      value: amount,
                      title: '${percentage.toStringAsFixed(0)}%',
                      radius: 50,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      color: Color(category?.colorValue ?? 0xFF9E9E9E),
                    );
                  }).toList(),
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...filteredTotals.entries.map((entry) {
              final category = categoryProvider.getById(entry.key);
              final categoryName = category?.name ?? 'Unknown';
              final amount = entry.value;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Color(category?.colorValue ?? 0xFF9E9E9E),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(categoryName),
                    ),
                    Text(
                      CurrencyUtils.format(amount),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
