import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/category_provider.dart';
import '../../providers/expense_provider.dart';
import '../../widgets/category_pie_chart_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/report_summary_card.dart';
import '../../widgets/spending_bar_chart_card.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final expenseProvider = context.watch<ExpenseProvider>();
    final categoryProvider = context.watch<CategoryProvider>();

    // Handle empty state
    if (expenseProvider.expenses.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Reports')),
        body: EmptyState(
          icon: Icons.trending_up_outlined,
          title: 'No expense data yet',
          message: 'Start adding expenses to see charts and analytics',
        ),
      );
    }

    // Get data for summary cards
    final totalToday = expenseProvider.totalToday;
    final totalThisMonth = expenseProvider.totalThisMonth;
    final expenseCount = expenseProvider.expenseCountThisMonth;
    final topCategoryId = expenseProvider.topCategoryId;
    final topCategory = topCategoryId != null
        ? categoryProvider.getById(topCategoryId)
        : null;
    final topCategoryName = topCategory?.name ?? 'N/A';

    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Summary section
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width > 600
                        ? (MediaQuery.of(context).size.width - 48) / 3
                        : (MediaQuery.of(context).size.width - 40) / 2 - 6,
                    height: 120,
                    child: ReportSummaryCard(
                      label: 'Today',
                      value: NumberFormat.currency(symbol: '\$')
                          .format(totalToday),
                      backgroundColor: Colors.blue.shade50,
                      textColor: Colors.blue.shade900,
                    ),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width > 600
                        ? (MediaQuery.of(context).size.width - 48) / 3
                        : (MediaQuery.of(context).size.width - 40) / 2 - 6,
                    height: 120,
                    child: ReportSummaryCard(
                      label: 'This Month',
                      value: NumberFormat.currency(symbol: '\$')
                          .format(totalThisMonth),
                      backgroundColor: Colors.green.shade50,
                      textColor: Colors.green.shade900,
                    ),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width > 600
                        ? (MediaQuery.of(context).size.width - 48) / 3
                        : (MediaQuery.of(context).size.width - 40) / 2 - 6,
                    height: 120,
                    child: ReportSummaryCard(
                      label: 'Expenses',
                      value: expenseCount.toString(),
                      backgroundColor: Colors.purple.shade50,
                      textColor: Colors.purple.shade900,
                    ),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width > 600
                        ? (MediaQuery.of(context).size.width - 48) / 3
                        : (MediaQuery.of(context).size.width - 40) / 2 - 6,
                    height: 120,
                    child: ReportSummaryCard(
                      label: 'Top Category',
                      value: topCategoryName,
                      backgroundColor: Colors.orange.shade50,
                      textColor: Colors.orange.shade900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Bar chart section
              SpendingBarChartCard(expenseProvider: expenseProvider),
              const SizedBox(height: 16),
              // Pie chart section
              CategoryPieChartCard(
                expenseProvider: expenseProvider,
                categoryProvider: categoryProvider,
              ),
            ],
          ),
        ),
      ),
    );
  }
}